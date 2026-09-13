#!/usr/bin/env bash
set -e

mkdir -p agent/tools agent/infra evals/fixtures
touch agent/__init__.py agent/main.py agent/loop.py agent/prompts.py agent/verifier.py \
      agent/tools/__init__.py agent/tools/airtable.py agent/tools/slack.py agent/tools/linear.py agent/tools/registry.py \
      agent/infra/__init__.py agent/infra/http.py agent/infra/ledger.py agent/infra/trace.py \
      evals/__init__.py evals/scenarios.py evals/run_evals.py \
      README.md RELIABILITY.md progress.md

cat > .gitignore << 'EOF'
.env
__pycache__/
*.pyc
*.db
.venv/
*.sqlite3
EOF

cat > .env.example << 'EOF'
# Airtable — CRM records
AIRTABLE_API_KEY=
AIRTABLE_BASE_ID=
AIRTABLE_TABLE_NAME=Accounts

# Slack — approval-gate messages
SLACK_BOT_TOKEN=
SLACK_CHANNEL=#verity

# Linear — ticket log
LINEAR_API_KEY=
LINEAR_TEAM_ID=

# Anthropic — the agent loop itself
ANTHROPIC_API_KEY=
EOF

cat > progress.md << 'EOF'
# Verity — build log

Format: one line per checkpoint, appended, never rewritten.

## 17:26 WAT — repo scaffold created
- done: folder structure, .gitignore, .env.example
- blocked: none
- next: generate Airtable/Slack/Linear tokens, verify each with curl
EOF

echo "Scaffold done."
