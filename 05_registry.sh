#!/usr/bin/env bash
set -e

cat > agent/tools/registry.py << 'EOF'
"""
Tool schemas + dispatch + allowlist.

This is the ONLY place the agent loop calls into to execute a tool.
The allowlist check happens here, in code — not just as an instruction
in the system prompt. A prompt-injected instruction telling the agent to
call a tool outside this list will fail here regardless of what the
model decided to do.
"""
from agent.tools import airtable, slack, linear

# ---- The allowlist. Anything not in here cannot execute, full stop. ----
ALLOWLIST = {
    "list_stalled_accounts",
    "draft_slack_approval",
    "upsert_linear_ticket",
}

# ---- Tool schemas, Anthropic tool-use format ----
TOOL_SCHEMAS = [
    {
        "name": "list_stalled_accounts",
        "description": (
            "Read Airtable and return accounts whose days-since-last-activity "
            "exceeds their OWN baseline check-in frequency (not a generic "
            "threshold). Read-only, always safe to call."
        ),
        "input_schema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "draft_slack_approval",
        "description": (
            "Post a DRAFT outreach message to the approval Slack channel for "
            "a single flagged account. This does NOT send anything to the "
            "customer — it asks a human to approve first. Requires account_id "
            "and draft_text."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "account_id": {"type": "string"},
                "account_name": {"type": "string"},
                "draft_text": {"type": "string"},
                "reason": {
                    "type": "string",
                    "description": "Why this account was flagged — shown above the draft.",
                },
            },
            "required": ["account_id", "account_name", "draft_text", "reason"],
        },
    },
    {
        "name": "upsert_linear_ticket",
        "description": (
            "Create or update a Linear ticket for a flagged account. Searches "
            "for an existing ticket via the [agent-key: account_id] marker "
            "before creating — never creates a duplicate."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "account_id": {"type": "string"},
                "account_name": {"type": "string"},
                "summary": {"type": "string"},
            },
            "required": ["account_id", "account_name", "summary"],
        },
    },
]


def dispatch(tool_name: str, tool_input: dict, trace, ledger_module=None):
    """
    Every tool call from the agent loop goes through here.

    1. Allowlist check FIRST, before anything else runs.
    2. Basic required-field check against the schema (belt and suspenders —
       the model usually gets this right, but we don't trust it blindly).
    3. Dispatch to the real implementation in tools/{airtable,slack,linear}.py.
    """
    if tool_name not in ALLOWLIST:
        return {
            "error": f"'{tool_name}' is not an allowed tool. Refusing to execute."
        }

    schema = next((t for t in TOOL_SCHEMAS if t["name"] == tool_name), None)
    if schema:
        required = schema["input_schema"].get("required", [])
        missing = [f for f in required if f not in tool_input]
        if missing:
            return {"error": f"Missing required fields for {tool_name}: {missing}"}

    if tool_name == "list_stalled_accounts":
        return airtable.list_stalled_accounts(trace=trace)

    if tool_name == "draft_slack_approval":
        return slack.draft_approval(
            account_id=tool_input["account_id"],
            account_name=tool_input["account_name"],
            draft_text=tool_input["draft_text"],
            reason=tool_input["reason"],
            trace=trace,
        )

    if tool_name == "upsert_linear_ticket":
        return linear.upsert_ticket(
            account_id=tool_input["account_id"],
            account_name=tool_input["account_name"],
            summary=tool_input["summary"],
            trace=trace,
        )

    # Should be unreachable — allowlist and this if-chain must stay in sync.
    return {"error": f"'{tool_name}' passed the allowlist but has no dispatch case."}
EOF

echo "wrote agent/tools/registry.py"
