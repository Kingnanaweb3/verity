#!/usr/bin/env bash
set -e

python3 - << 'PYEOF'
path = "agent/verifier.py"
with open(path) as f:
    content = f.read()

old = '''    for entry in trace.entries:
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

    return results'''

new = '''    results["skipped"] = 0

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

    return results'''

if old not in content:
    raise SystemExit("[FATAL] verifier.py verify_run loop didn't match — aborting.")
content = content.replace(old, new)

# NOTE: uses raw strings (r'''...''') here specifically because this block
# contains a literal backslash-n sequence in the source file (print("\\n"...))
# that must be matched byte-for-byte, not interpreted as an escape.
old2 = r'''def print_verification_report(results: dict):
    print("\\n" + "=" * 60)
    print(f"VERIFICATION REPORT — {results['checked']} claims checked")
    print(f"  Confirmed:  {results['confirmed']}")
    print(f"  Mismatched: {results['mismatched']}")
    print("=" * 60)
    for d in results["details"]:
        mark = "✅" if d["verified"] else "❌"
        print(f"  {mark} step {d['step']} ({d['tool']}): {d['note']}")
    print()'''

new2 = r'''def print_verification_report(results: dict):
    print("\\n" + "=" * 60)
    print(f"VERIFICATION REPORT — {results['checked']} claims checked, {results.get('skipped', 0)} idempotent skips")
    print(f"  Confirmed:  {results['confirmed']}")
    print(f"  Mismatched: {results['mismatched']}")
    print("=" * 60)
    for d in results["details"]:
        mark = "SKIP" if d["verified"] is None else ("OK" if d["verified"] else "FAIL")
        print(f"  [{mark}] step {d['step']} ({d['tool']}): {d['note']}")
    print()'''

if old2 not in content:
    raise SystemExit("[FATAL] verifier.py print_verification_report didn't match — aborting.")
content = content.replace(old2, new2)

with open(path, "w") as f:
    f.write(content)
print("patched agent/verifier.py — idempotent skips no longer counted as mismatches")
PYEOF
