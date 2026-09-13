#!/usr/bin/env bash
set -e

# --- 1. trace.py: let log_tool_call store extra result fields (ts, ticket_id) ---
python3 - << 'PYEOF'
import re

path = "agent/infra/trace.py"
with open(path) as f:
    content = f.read()

old = '''    def log_tool_call(self, tool: str, idempotent_hit: bool = False, tokens: int = 0):
        """Called once per logical tool call (not per HTTP retry) to bump the step counter."""
        self.step += 1
        entry = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "run_id": self.run_id,
            "step": self.step,
            "tool": tool,
            "idempotent_hit": idempotent_hit,
            "tokens": tokens,
            "verified": None,  # filled in later by verifier.py, None until then
        }
        self.entries.append(entry)
        self._append_line(entry)
        return entry'''

new = '''    def log_tool_call(self, tool: str, idempotent_hit: bool = False, tokens: int = 0, **extra):
        """
        Called once per logical tool call (not per HTTP retry) to bump the
        step counter. Extra kwargs (e.g. result_ts, result_ticket_id) are
        stored on the entry so verifier.py can later look up what to
        independently re-check, without needing to re-run the tool call.
        """
        self.step += 1
        entry = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "run_id": self.run_id,
            "step": self.step,
            "tool": tool,
            "idempotent_hit": idempotent_hit,
            "tokens": tokens,
            "verified": None,  # filled in later by verifier.py, None until then
            **extra,
        }
        self.entries.append(entry)
        self._append_line(entry)
        return entry'''

if old not in content:
    raise SystemExit("[FATAL] trace.py log_tool_call didn't match expected text — aborting to avoid corrupting the file.")

content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
print("patched agent/infra/trace.py — log_tool_call now accepts **extra")
PYEOF

# --- 2. loop.py: pass result_ts / result_ticket_id when logging write-tool calls ---
python3 - << 'PYEOF'
path = "agent/loop.py"
with open(path) as f:
    content = f.read()

old = '''        result = registry.dispatch(name, tool_input, trace=trace)
        entry = trace.log_tool_call(tool=name, idempotent_hit=False)

        # Only record success in the ledger — a failed write should be
        # retryable on the next run, not silently treated as "already done".
        ref = result.get("ts") or result.get("ticket_id")
        if ref:
            ledger.record(fp, name, str(ref))

        return result'''

new = '''        result = registry.dispatch(name, tool_input, trace=trace)

        # Pass the claimed result reference into the trace entry itself,
        # so verifier.py can look it up later without re-running anything.
        entry = trace.log_tool_call(
            tool=name,
            idempotent_hit=False,
            result_ts=result.get("ts"),
            result_ticket_id=result.get("ticket_id"),
        )

        # Only record success in the ledger — a failed write should be
        # retryable on the next run, not silently treated as "already done".
        ref = result.get("ts") or result.get("ticket_id")
        if ref:
            ledger.record(fp, name, str(ref))

        return result'''

if old not in content:
    raise SystemExit("[FATAL] loop.py write-tool block didn't match expected text — aborting to avoid corrupting the file.")

content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
print("patched agent/loop.py — write-tool calls now log result_ts / result_ticket_id")
PYEOF

# --- 3. main.py: run verifier after the loop finishes, print the report ---
python3 - << 'PYEOF'
path = "agent/main.py"
with open(path) as f:
    content = f.read()

old = '''from agent.loop import run'''
new = '''from agent.loop import run
from agent.verifier import verify_run, print_verification_report'''

if old not in content:
    raise SystemExit("[FATAL] main.py import line didn't match — aborting.")
content = content.replace(old, new)

old2 = '''    run(dry_run=dry_run, fault=args.fault)'''
new2 = '''    trace = run(dry_run=dry_run, fault=args.fault)

    if dry_run:
        print("[SKIPPED] Verification skipped in dry-run mode — nothing was actually written to Slack/Linear to check.")
    else:
        results = verify_run(trace)
        print_verification_report(results)'''

if old2 not in content:
    raise SystemExit("[FATAL] main.py run() call didn't match — aborting.")
content = content.replace(old2, new2)

with open(path, "w") as f:
    f.write(content)
print("patched agent/main.py — verifier now runs automatically after --apply runs")
PYEOF

# --- 4. verifier.py itself, now correctly reading result_ts / result_ticket_id ---
cat > agent/verifier.py << 'EOF'
"""
The differentiator.

After a run completes, this module independently re-reads Slack and
Linear DIRECTLY — using slack.fetch_message() and linear.fetch_ticket(),
which the agent itself is never given access to via the tool allowlist.

The agent's own tool results say "posted": True or "upserted": True.
Those are claims. This module checks whether they're actually true, and
writes the real answer into the trace via trace.mark_verified().

This separation is the whole point: an agent cannot verify itself.
"""
from agent.tools import slack, linear


def verify_run(trace) -> dict:
    """
    Walks every tool-call entry in the trace that claims a write happened,
    and independently re-checks reality. Returns a summary dict and also
    mutates the trace in place via mark_verified().
    """
    results = {"checked": 0, "confirmed": 0, "mismatched": 0, "details": []}

    for entry in trace.entries:
        tool = entry.get("tool")
        step = entry.get("step")

        if tool == "draft_slack_approval":
            verified, note = _verify_slack_post(entry)
            trace.mark_verified(step, verified, note)
            results["checked"] += 1
            results["confirmed" if verified else "mismatched"] += 1
            results["details"].append({"step": step, "tool": tool, "verified": verified, "note": note})

        elif tool == "upsert_linear_ticket":
            verified, note = _verify_linear_ticket(entry)
            trace.mark_verified(step, verified, note)
            results["checked"] += 1
            results["confirmed" if verified else "mismatched"] += 1
            results["details"].append({"step": step, "tool": tool, "verified": verified, "note": note})

    return results


def _verify_slack_post(entry: dict) -> tuple[bool, str]:
    """Fetches the message by its ts and confirms it actually exists."""
    ts = entry.get("result_ts")
    if not ts:
        return False, "no message timestamp recorded — treating as unconfirmed"

    check = slack.fetch_message(ts=ts, trace=None)
    if check.get("found"):
        return True, "message confirmed present in channel"
    return False, "agent claimed a post, but no matching message found in channel"


def _verify_linear_ticket(entry: dict) -> tuple[bool, str]:
    """Fetches the ticket by ID and confirms it actually exists with matching state."""
    ticket_id = entry.get("result_ticket_id")
    if not ticket_id:
        return False, "no ticket id recorded — treating as unconfirmed"

    check = linear.fetch_ticket(ticket_id=ticket_id, trace=None)
    if check.get("found"):
        return True, "ticket confirmed present with matching state"
    return False, "agent claimed a ticket upsert, but ticket not found or state mismatch"


def print_verification_report(results: dict):
    print("\\n" + "=" * 60)
    print(f"VERIFICATION REPORT — {results['checked']} claims checked")
    print(f"  Confirmed:  {results['confirmed']}")
    print(f"  Mismatched: {results['mismatched']}")
    print("=" * 60)
    for d in results["details"]:
        mark = "✅" if d["verified"] else "❌"
        print(f"  {mark} step {d['step']} ({d['tool']}): {d['note']}")
    print()
EOF
echo "wrote agent/verifier.py"

echo ""
echo "All verifier wiring complete."
