#!/usr/bin/env bash
set -e

cat >> progress.md << 'EOF'

## Linear credential confirmed working
- done: Personal API key generated (Security & access, not the workspace
  API admin page — those are different pages, easy to confuse)
- done: LINEAR_API_KEY and LINEAR_TEAM_ID (Kingnanaweb3, key "KIN") added to .env
- verified: curl to teams query and viewer query both returned correct data
- blocked: only Airtable left — API key, base ID, and the Accounts table
  with seed data
- next: Airtable setup, then a real end-to-end --dry-run smoke test
EOF
echo "progress.md updated"

sed -i.bak 's/SLACK — DONE.*/SLACK — DONE. LINEAR — DONE (API key + team ID confirmed via curl). Airtable still pending./' HANDOFF.md
rm -f HANDOFF.md.bak

sed -i.bak 's/Credentials: SLACK DONE.*/Credentials: SLACK DONE, LINEAR DONE. Airtable still pending — this is the last credential blocking a real end-to-end smoke test./' HANDOFF.md
rm -f HANDOFF.md.bak

echo "HANDOFF.md updated"
