"""
Linear — creates or updates a ticket per flagged account. Searches for
an existing ticket via the [agent-key: account_id] marker first, so
re-running the agent updates rather than duplicates.
"""
import os

from agent.infra import http

LINEAR_API_KEY = os.environ.get("LINEAR_API_KEY", "")
LINEAR_TEAM_ID = os.environ.get("LINEAR_TEAM_ID", "")

GRAPHQL_URL = "https://api.linear.app/graphql"


def _graphql(query: str, variables: dict, trace=None):
    return http.request(
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
