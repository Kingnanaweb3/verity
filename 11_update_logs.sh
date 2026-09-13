#!/usr/bin/env bash
set -e

cat >> progress.md << 'EOF'

## agent/main.py wired and smoke-tested
- done: agent/main.py — CLI with --dry-run/--apply/--fault, load_dotenv,
  required-env-var check
- verified: python3 -m agent.main --dry-run correctly fails fast with
  [FATAL] Missing required environment variables when .env is unpopulated
  (this is the intended behavior, not a bug)
- pushed: all files above committed and pushed to
  https://github.com/Kingnanaweb3/verity
- blocked: waiting on real credentials — Airtable (API key + base ID +
  table schema), Slack (bot token + #verity channel + bot invited),
  Linear (API key + team ID), Groq (API key)
- next once credentials are in .env: verify each with curl, then run
  python3 -m agent.main --dry-run for a real end-to-end smoke test,
  then agent/verifier.py, then evals/
EOF
echo "progress.md updated"

# Update HANDOFF.md's status lines to match current reality
sed -i.bak \
  -e 's/main.py          # CLI entry — NOT YET WRITTEN/main.py          # CLI entry — DONE/' \
  -e 's/loop.py           # tool-use loop, step cap — NOT YET WRITTEN/loop.py           # tool-use loop, step cap — DONE (Groq, not Anthropic)/' \
  -e 's/prompts.py         # system prompt — NOT YET WRITTEN/prompts.py         # system prompt — DONE/' \
  -e 's/registry.py            # schemas + dispatch + allowlist — NOT YET WRITTEN/registry.py            # schemas + dispatch + allowlist — DONE (Groq format)/' \
  -e 's/airtable.py         # NOT YET WRITTEN/airtable.py         # DONE/' \
  -e 's/slack.py             # NOT YET WRITTEN/slack.py             # DONE/' \
  -e 's/linear.py             # NOT YET WRITTEN/linear.py             # DONE/' \
  HANDOFF.md
rm -f HANDOFF.md.bak

sed -i.bak 's/## Credentials status\nNot yet confirmed.*/## Credentials status\nStill pending as of last update — see progress.md for latest./' HANDOFF.md 2>/dev/null || true
rm -f HANDOFF.md.bak

sed -i.bak \
  -e '/^## Credentials status$/,/^$/{ /^Not yet confirmed/d; }' \
  HANDOFF.md
rm -f HANDOFF.md.bak

cat >> HANDOFF.md << 'EOF'

## Provider note (important — read this)
Switched from Anthropic to GROQ partway through the build. loop.py uses
the `groq` Python SDK, model defaults to llama-3.3-70b-versatile via
GROQ_MODEL env var. registry.py's TOOL_SCHEMAS are in Groq/OpenAI
function-calling format ({"type": "function", "function": {...}}), NOT
Anthropic's input_schema format. Do not revert this without updating
both files together.

## Status as of last handoff update
main.py, loop.py, prompts.py, registry.py, airtable.py, slack.py,
linear.py, http.py, trace.py, ledger.py are all DONE and pushed to
https://github.com/Kingnanaweb3/verity
Still pending: agent/verifier.py, evals/scenarios.py, evals/run_evals.py,
README.md, RELIABILITY.md
Credentials: not yet in .env — this blocks any real smoke test.
EOF
echo "HANDOFF.md updated"
