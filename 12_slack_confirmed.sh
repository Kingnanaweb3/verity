#!/usr/bin/env bash
set -e

cat >> progress.md << 'EOF'

## Slack credential confirmed working
- done: Slack app "Verity" created in Dwell workspace, scopes trimmed to
  chat:write + channels:history (removed leftover Agent-template scopes:
  assistant:write, calls:write, calls:read, app_mentions:read)
- done: SLACK_BOT_TOKEN and SLACK_CHANNEL (#verity1, not #verity — channel
  name differs from the .env.example default, updated to match) added to .env
- verified: curl to chat.postMessage returned "ok":true, message confirmed
  visible in #verity1 in the Slack UI
- blocked: still need Airtable (API key + base ID + table schema) and
  Linear (API key + team ID)
- next: Airtable setup
EOF
echo "progress.md updated"

sed -i.bak 's/Still pending as of last update.*/SLACK — DONE (token + channel confirmed working via curl). Airtable, Linear — still pending./' HANDOFF.md
rm -f HANDOFF.md.bak

sed -i.bak 's/Credentials: not yet in .env.*/Credentials: SLACK DONE (see progress.md). Airtable + Linear still pending — this blocks a real end-to-end smoke test./' HANDOFF.md
rm -f HANDOFF.md.bak

echo "HANDOFF.md updated"
