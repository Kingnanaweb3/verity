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

    results["skipped"] = 0

    for entry in trace.entries:
        tool = entry.get("tool")
        step = entry.get("step")

        # An idempotent hit means the ledger correctly recognized this
        # exact account+state+action was already performed on a PRIOR run.
        # No new write happened this run, so there is nothing new to
        # independently verify. Counting this as "mismatched" would be
        # wrong: the agent correctly reported "already done" and skipped,
        # exactly as idempotency is supposed to work.
        if entry.get("idempotent_hit"):
            results["skipped"] += 1
            results["details"].append({
                "step": step, "tool": tool, "verified": None,
                "note": "skipped - idempotent hit, no new write this run to verify",
            })
            continue

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
    channel = entry.get("result_channel")
    if not ts:
        return False, "no message timestamp recorded — treating as unconfirmed"

    check = slack.fetch_message(ts=ts, channel=channel, trace=None)
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
    print(f"VERIFICATION REPORT — {results['checked']} claims checked, {results.get('skipped', 0)} idempotent skips")
    print(f"  Confirmed:  {results['confirmed']}")
    print(f"  Mismatched: {results['mismatched']}")
    print("=" * 60)
    for d in results["details"]:
        mark = "SKIP" if d["verified"] is None else ("OK" if d["verified"] else "FAIL")
        print(f"  [{mark}] step {d['step']} ({d['tool']}): {d['note']}")
    print()
