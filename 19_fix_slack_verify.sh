#!/usr/bin/env bash
set -e

# --- 1. slack.py: return the real channel ID from draft_approval, and let
#        fetch_message accept an explicit channel instead of only the configured name ---
python3 - << 'PYEOF'
path = "agent/tools/slack.py"
with open(path) as f:
    content = f.read()

old = '''    return {
        "posted": True,
        "channel": SLACK_CHANNEL,
        "ts": body.get("ts"),  # message timestamp — verifier.py uses this to re-fetch and confirm
    }'''
new = '''    return {
        "posted": True,
        # Slack's chat.postMessage accepts "#name" but returns the REAL
        # channel ID here — conversations.history (used by fetch_message)
        # requires that real ID, not the name. Returning it lets verifier.py
        # check the right place instead of assuming the configured name works.
        "channel": body.get("channel"),
        "ts": body.get("ts"),
    }'''

if old not in content:
    raise SystemExit("[FATAL] slack.py draft_approval return block didn't match — aborting.")
content = content.replace(old, new)

old2 = '''def fetch_message(ts: str, trace=None):
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
    )'''
new2 = '''def fetch_message(ts: str, channel: str = None, trace=None):
    """
    Used ONLY by verifier.py — independently re-reads a message by its
    timestamp to confirm it actually exists, rather than trusting the
    agent's own "posted": True claim.

    `channel` should be the REAL channel ID returned by draft_approval's
    result (e.g. "C0C1D6GJXGV"), not the configured "#name" — Slack's
    conversations.history endpoint requires the real ID.
    """
    target_channel = channel or SLACK_CHANNEL
    resp = request(
        service="slack",
        method="GET",
        url="https://slack.com/api/conversations.history",
        trace=trace,
        headers={"Authorization": f"Bearer {SLACK_BOT_TOKEN}"},
        params={"channel": target_channel, "latest": ts, "inclusive": "true", "limit": 1},
    )'''

if old2 not in content:
    raise SystemExit("[FATAL] slack.py fetch_message didn't match — aborting.")
content = content.replace(old2, new2)

with open(path, "w") as f:
    f.write(content)
print("patched agent/tools/slack.py")
PYEOF

# --- 2. loop.py: also capture and log the real channel ID from the result ---
python3 - << 'PYEOF'
path = "agent/loop.py"
with open(path) as f:
    content = f.read()

old = '''        entry = trace.log_tool_call(
            tool=name,
            idempotent_hit=False,
            result_ts=result.get("ts"),
            result_ticket_id=result.get("ticket_id"),
        )'''
new = '''        entry = trace.log_tool_call(
            tool=name,
            idempotent_hit=False,
            result_ts=result.get("ts"),
            result_ticket_id=result.get("ticket_id"),
            result_channel=result.get("channel"),
        )'''

if old not in content:
    raise SystemExit("[FATAL] loop.py log_tool_call block didn't match — aborting.")
content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
print("patched agent/loop.py")
PYEOF

# --- 3. verifier.py: pass the real channel ID through to fetch_message ---
python3 - << 'PYEOF'
path = "agent/verifier.py"
with open(path) as f:
    content = f.read()

old = '''def _verify_slack_post(entry: dict) -> tuple[bool, str]:
    """Fetches the message by its ts and confirms it actually exists."""
    ts = entry.get("result_ts")
    if not ts:
        return False, "no message timestamp recorded — treating as unconfirmed"

    check = slack.fetch_message(ts=ts, trace=None)
    if check.get("found"):
        return True, "message confirmed present in channel"
    return False, "agent claimed a post, but no matching message found in channel"'''
new = '''def _verify_slack_post(entry: dict) -> tuple[bool, str]:
    """Fetches the message by its ts and confirms it actually exists."""
    ts = entry.get("result_ts")
    channel = entry.get("result_channel")
    if not ts:
        return False, "no message timestamp recorded — treating as unconfirmed"

    check = slack.fetch_message(ts=ts, channel=channel, trace=None)
    if check.get("found"):
        return True, "message confirmed present in channel"
    return False, "agent claimed a post, but no matching message found in channel"'''

if old not in content:
    raise SystemExit("[FATAL] verifier.py _verify_slack_post didn't match — aborting.")
content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
print("patched agent/verifier.py")
PYEOF

echo ""
echo "Fix complete — rerun: python3 -m agent.main --apply"
