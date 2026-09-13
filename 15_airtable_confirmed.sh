#!/usr/bin/env bash
set -e

cat >> progress.md << 'EOF'

## Airtable credential confirmed working — ALL THREE APPS NOW LIVE
- done: Airtable base created (appPjR39OyfzriGNd), Accounts table with
  columns Name/LastActivityDate/NormalFrequencyDays/HealthNote
- done: AIRTABLE_API_KEY (write scope required — read-only initially
  failed with INVALID_PERMISSIONS_OR_MODEL_NOT_FOUND, fixed by adding
  data.records:write scope to the token)
- done: AIRTABLE_TABLE_NAME set to the table ID (tblX7qubawWfsGBr0)
  instead of "Accounts" — the table's actual tab name didn't match the
  default, using the ID sidesteps that entirely
- done: seeded 4 records via API instead of manual entry — Almonds
  (stalled, 25 days vs 7-day baseline), Gloriet (healthy), Aevry
  (stalled, 40 days vs 10-day baseline, ALSO carries the prompt-injection
  test string in HealthNote), Selene ltd (healthy)
- verified: all 4 records created successfully with real Airtable record IDs
- ALL THREE CREDENTIALS NOW CONFIRMED: Slack, Linear, Airtable
- next: real end-to-end python3 -m agent.main --dry-run smoke test —
  this is the first time the full loop can actually run
EOF
echo "progress.md updated"

sed -i.bak 's/SLACK — DONE. LINEAR — DONE.*/SLACK, LINEAR, AND AIRTABLE ALL DONE AND CONFIRMED WORKING. Note: AIRTABLE_TABLE_NAME is set to a table ID (tblX7qubawWfsGBr0), not the literal string "Accounts" — the base'"'"'s tab name did not match the .env.example default./' HANDOFF.md
rm -f HANDOFF.md.bak

sed -i.bak 's/Credentials: SLACK DONE, LINEAR DONE.*/Credentials: ALL THREE CONFIRMED WORKING (Slack, Linear, Airtable). Ready for a real end-to-end --dry-run test./' HANDOFF.md
rm -f HANDOFF.md.bak

echo "HANDOFF.md updated"
