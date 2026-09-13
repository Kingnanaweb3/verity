#!/usr/bin/env bash
set -e

# ---------------- agent/tools/airtable.py ----------------
cat > agent/tools/airtable.py << 'EOF'
"""
Airtable — the CRM. Read-only for now: lists accounts whose days-since-
last-activity exceeds THEIR OWN baseline check-in frequency.
"""
import os
from datetime import datetime, timezone

from agent.infra.http import request

AIRTABLE_API_KEY = os.environ.get("AIRTABLE_API_KEY", "")
BASE_ID = os.environ.get("AIRTABLE_BASE_ID", "")
TABLE_NAME = os.environ.get("AIRTABLE_TABLE_NAME", "Accounts")

BASE_URL = f"https://api.airtable.com/v0/{BASE_ID}/{TABLE_NAME}"


def list_stalled_accounts(trace=None):
    """
    Expected Airtable columns per row:
      Name, LastActivityDate (YYYY-MM-DD), NormalFrequencyDays, HealthNote

    An account is "stalled" when:
      (today - LastActivityDate).days > NormalFrequencyDays
    i.e. compared against ITS OWN pattern, not a fixed number for everyone.
    """
    resp = request(
        service="airtable",
        method="GET",
        url=BASE_URL,
        trace=trace,
        headers={"Authorization": f"Bearer {AIRTABLE_API_KEY}"},
    )

    if resp.status_code >= 400:
        return {"error": f"Airtable read failed: {resp.status_code}", "records": []}

    records = resp.json().get("records", [])
    today = datetime.now(timezone.utc).date()
    stalled = []

    for r in records:
        fields = r.get("fields", {})
        last_activity = fields.get("LastActivityDate")
        normal_freq = fields.get("NormalFrequencyDays")
        if not last_activity or not normal_freq:
            continue

        last_date = datetime.strptime(last_activity, "%Y-%m-%d").date()
        days_since = (today - last_date).days

        if days_since > normal_freq:
            stalled.append({
                "account_id": r["id"],
                "account_name": fields.get("Name", "Unknown"),
                "days_since_activity": days_since,
                "normal_frequency_days": normal_freq,
                "health_note": fields.get("HealthNote", ""),
                "last_activity_date": last_activity,  # used by ledger fingerprint
            })

    return {"stalled_accounts": stalled}
EOF
echo "wrote agent/tools/airtable.py"

# ---------------- agent/tools/slack.py ----------------
cat > agent/tools/slack.py << 'EOF'
"""
Slack — posts a DRAFT for human approval. Never sends anything to a
customer directly; this is the approval gate itself.
"""
import os

from agent.infra.http import request

SLACK_BOT_TOKEN = os.environ.get("SLACK_BOT_TOKEN", "")
SLACK_CHANNEL = os.environ.get("SLACK_CHANNEL", "#verity")

POST_MESSAGE_URL = "https://slack.com/api/chat.postMessage"


def draft_approval(account_id: str, account_name: str, draft_text: str, reason: str, trace=None):
    """
    Posts a formatted message: WHY the account was flagged, then the
    draft outreach text, and asks a human to approve before anything
    goes to the actual customer (sending is out of scope for the hackathon
    build — approval-and-log is the demoable slice).
    """
    text = (
        f"*Account flagged: {account_name}*\n"
        f"_Reason:_ {reason}\n\n"
        f"*Draft outreach (awaiting approval):*\n{draft_text}"
    )

    resp = request(
        service="slack",
        method="POST",
        url=POST_MESSAGE_URL,
        trace=trace,
        headers={
            "Authorization": f"Bearer {SLACK_BOT_TOKEN}",
            "Content-Type": "application/json",
        },
        json={"channel": SLACK_CHANNEL, "text": text},
    )

    if resp.status_code >= 400:
        return {"error": f"Slack HTTP error: {resp.status_code}", "posted": False}

    body = resp.json()
    if not body.get("ok"):
        # Slack returns 200 even on failure — the real error is in the body.
        # "not_in_channel" here means the bot was never invited — the classic gotcha.
        return {"error": f"Slack API error: {body.get('error')}", "posted": False}

    return {
        "posted": True,
        "channel": SLACK_CHANNEL,
        "ts": body.get("ts"),  # message timestamp — verifier.py uses this to re-fetch and confirm
    }


def fetch_message(ts: str, trace=None):
    """
    Used ONLY by verifier.py — independently re-reads a message by its
    timestamp to confirm it actually exists, rather than trusting the
    agent's own "posted": True claim.
    """
    resp = request(
        service="slack",
        method="GET",
        url="https://slack.com/api/conversations.history",
        trace=trace,
        headers={"Authorization": f"Bearer {SLACK_BOT_TOKEN}"},
        params={"channel": SLACK_CHANNEL, "latest": ts, "inclusive": "true", "limit": 1},
    )
    if resp.status_code >= 400:
        return {"found": False}

    body = resp.json()
    messages = body.get("messages", [])
    found = any(m.get("ts") == ts for m in messages)
    return {"found": found}
EOF
echo "wrote agent/tools/slack.py"

# ---------------- agent/tools/linear.py ----------------
cat > agent/tools/linear.py << 'EOF'
"""
Linear — creates or updates a ticket per flagged account. Searches for
an existing ticket via the [agent-key: account_id] marker first, so
re-running the agent updates rather than duplicates.
"""
import os

from agent.infra.http import request

LINEAR_API_KEY = os.environ.get("LINEAR_API_KEY", "")
LINEAR_TEAM_ID = os.environ.get("LINEAR_TEAM_ID", "")

GRAPHQL_URL = "https://api.linear.app/graphql"


def _graphql(query: str, variables: dict, trace=None):
    return request(
        service="linear",
        method="POST",
        url=GRAPHQL_URL,
        trace=trace,
        headers={
            "Authorization": LINEAR_API_KEY,
            "Content-Type": "application/json",
        },
        json={"query": query, "variables": variables},
    )


def _find_existing_ticket(account_id: str, trace=None):
    marker = f"[agent-key: {account_id}]"
    query = """
    query($teamId: String!) {
      issues(filter: { team: { id: { eq: $teamId } } }, first: 50) {
        nodes { id identifier description }
      }
    }
    """
    resp = _graphql(query, {"teamId": LINEAR_TEAM_ID}, trace=trace)
    if resp.status_code >= 400:
        return None

    nodes = resp.json().get("data", {}).get("issues", {}).get("nodes", [])
    for n in nodes:
        if marker in (n.get("description") or ""):
            return n["id"]
    return None


def upsert_ticket(account_id: str, account_name: str, summary: str, trace=None):
    marker = f"[agent-key: {account_id}]"
    description = f"{summary}\n\n{marker}"

    existing_id = _find_existing_ticket(account_id, trace=trace)

    if existing_id:
        mutation = """
        mutation($id: String!, $description: String!) {
          issueUpdate(id: $id, input: { description: $description }) {
            success
            issue { id identifier }
          }
        }
        """
        resp = _graphql(
            mutation, {"id": existing_id, "description": description}, trace=trace
        )
    else:
        mutation = """
        mutation($teamId: String!, $title: String!, $description: String!) {
          issueCreate(input: { teamId: $teamId, title: $title, description: $description }) {
            success
            issue { id identifier }
          }
        }
        """
        resp = _graphql(
            mutation,
            {
                "teamId": LINEAR_TEAM_ID,
                "title": f"Verity: check in on {account_name}",
                "description": description,
            },
            trace=trace,
        )

    if resp.status_code >= 400:
        return {"error": f"Linear HTTP error: {resp.status_code}", "upserted": False}

    body = resp.json()
    data = body.get("data", {})
    result = data.get("issueUpdate") or data.get("issueCreate")

    if not result or not result.get("success"):
        return {"error": "Linear mutation failed", "upserted": False}

    return {
        "upserted": True,
        "ticket_id": result["issue"]["id"],
        "identifier": result["issue"]["identifier"],
        "was_update": existing_id is not None,
    }


def fetch_ticket(ticket_id: str, trace=None):
    """
    Used ONLY by verifier.py — independently re-reads a ticket by ID to
    confirm the description/marker actually match what was claimed.
    """
    query = """
    query($id: String!) {
      issue(id: $id) { id identifier description }
    }
    """
    resp = _graphql(query, {"id": ticket_id}, trace=trace)
    if resp.status_code >= 400:
        return {"found": False}

    issue = resp.json().get("data", {}).get("issue")
    return {"found": issue is not None, "issue": issue}
EOF
echo "wrote agent/tools/linear.py"
