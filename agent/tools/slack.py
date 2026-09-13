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
