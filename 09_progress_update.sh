#!/usr/bin/env bash
set -e

cat >> progress.md << 'EOF'

## 17:26–17:42 WAT — reliability core + tool layer complete
- done: full repo scaffold (.gitignore, .env.example, folder tree)
- done: agent/infra/http.py — single HTTP choke point, retry/backoff on
  429+5xx, fail-fast on 401/403, fault injection hook
- done: agent/infra/trace.py — JSONL trace log + rich summary table,
  `verified` field reserved for verifier.py only
- done: agent/infra/ledger.py — SQLite idempotency, fingerprint =
  account_id + last_activity_date + action
- done: HANDOFF.md — full context dump for a fresh session/account to
  pick this up cold (ArgaBench research, locked decisions, build order)
- done: agent/tools/registry.py — tool schemas + dispatch + allowlist
  enforced in code, not just prompt
- switched: provider from Anthropic to Groq — .env.example key swapped,
  registry.py TOOL_SCHEMAS restructured to Groq/OpenAI function-calling
  format (was Anthropic input_schema format)
- done: agent/tools/airtable.py — list_stalled_accounts, baseline-relative
  stall detection (own frequency, not a generic threshold)
- done: agent/tools/slack.py — draft_approval (posts draft, never sends to
  customer) + fetch_message (verifier-only, re-checks a post actually exists)
- done: agent/tools/linear.py — upsert_ticket (marker-based dedup via
  [agent-key: account_id]) + fetch_ticket (verifier-only)
- done: agent/prompts.py — system prompt, short by design, guardrails
  live in code not prose
- done: agent/loop.py — Groq tool-use loop, step cap (12), token ceiling
  (20k), dry-run gate at the loop level (write tools short-circuit before
  hitting the real API unless --apply), idempotency check before every
  write tool call
- blocked: none
- next: agent/main.py (CLI wiring: --dry-run/--apply/--fault flags),
  then agent/verifier.py (the differentiator — independently re-checks
  Slack/Linear state post-run), then evals/ (10 scenarios), then README
  + RELIABILITY.md
- credentials: still not generated — Airtable/Slack/Linear tokens pending
EOF

echo "progress.md updated"
