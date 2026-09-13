#!/usr/bin/env bash
set -e

cat > RELIABILITY.md << 'EOF'
# Reliability Brief — Verity

## 1. Architecture

```
                    ┌─────────────────┐
                    │   agent/main.py   │  CLI: --dry-run / --apply / --fault
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │   agent/loop.py   │  Groq tool-use loop
                    │  step cap: 12      │  token ceiling: 20k
                    │  dry-run gate      │
                    └────────┬─────────┘
                             │
                ┌────────────▼────────────┐
                │  agent/tools/registry.py │  allowlist enforced in code
                │  (3 tools only)          │
                └────────────┬────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                     ▼
  tools/airtable.py    tools/slack.py       tools/linear.py
        │                    │                     │
        └────────────────────┼────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │  infra/http.py     │  single choke point:
                    │                    │  retries, fault injection,
                    │                    │  tracing
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
      infra/ledger.py  infra/trace.py  agent/verifier.py
      (idempotency)    (JSONL log)     (independent re-check
                                         of Slack + Linear state,
                                         separate from the agent's
                                         own claims)
```

Every outbound HTTP call, from any of the three tools, passes through the same single function in `infra/http.py`. This is what makes fault injection and tracing work uniformly without each tool needing its own retry logic.

## 2. Failure modes table

| Failure | Detection | Response | Evidence |
|---|---|---|---|
| Rate limit (429) | HTTP status check in `infra/http.py` | Exponential backoff with jitter, up to 3 attempts | `--fault linear:429` demo, eval scenario 3 |
| Bad credentials (401/403) | HTTP status check | Fail immediately, zero retries | Eval scenario 5, asserts exactly 1 call made |
| Third-party service down (5xx) | HTTP status check | Retry same as 429, then report degraded if still failing | `--fault slack:500` demo, eval scenario 4 |
| Duplicate write on re-run | SQLite ledger fingerprint (account + state + action) | Skip the write, return prior result reference | Live-confirmed: second `--apply` run on unchanged accounts correctly skipped |
| Agent claims a write succeeded, but it didn't | Independent re-fetch via `verifier.py`, not the agent's own tool result | Marked mismatched in the trace, surfaced in the report, never hidden | Live-caught: real Slack scope bug found and fixed this way (see section 5) |
| Partial completion reported as done | Verifier checks every claimed write independently, not just one | Any missing confirmation counts as incomplete | Eval scenario 8 |
| Prompt injection in account data | Tool allowlist enforced in `registry.py` at dispatch time, not just in the prompt | Non-allowlisted actions refused regardless of what the text says | Eval scenario 9, and live: Aevry's HealthNote field contains an injection string, had zero effect on behavior |
| Ambiguous or incomplete account data | Explicit field checks in `airtable.py` before flagging | Account skipped rather than flagged with invented reasoning | Eval scenario 6 |
| Runaway agent loop | Hard step cap (12) and token ceiling (20,000) in `loop.py` | Loop terminates and reports, rather than running indefinitely | Enforced in code, not yet stress-tested live |

## 3. Eval results

```
python3 -m evals.run_evals
```

10/10 scenarios passing, full suite runs in under 6ms.

| # | Scenario | Result |
|---|---|---|
| 1 | Clean stalled account | PASS |
| 2 | No duplicate on re-run | PASS |
| 3 | Linear 429 then success | PASS |
| 4 | Slack down, degrades gracefully | PASS |
| 5 | Airtable 401 fails fast | PASS |
| 6 | Low confidence, no invented data | PASS |
| 7 | Agent claims a write, verifier catches it's false | PASS |
| 8 | Partial completion caught, not reported as done | PASS |
| 9 | Prompt injection ignored | PASS |
| 10 | Crash mid-run, resume without duplicating | PASS |

Scenarios 7 and 8 are the ones directly answering the two largest failure categories identified in Arga Labs' ArgaBench research (published Sept 4, 2026, 8 days before this event): incomplete outcomes reported as done, and claims that don't match final system state.

**Honest note on methodology:** these 10 scenarios run against fixture HTTP responses, not live third-party services. A real rate limit or auth failure isn't reliably reproducible on demand, so the HTTP layer is swapped for deterministic fake responses — the same principle behind Arga Labs' own "digital twin" product. What is not mocked: the retry logic, the idempotency ledger, the allowlist enforcement, and the verifier's comparison logic all run for real, unmocked, against those fixture inputs.

## 4. Known gaps

- Evals run against mocked HTTP, not live services (explained above — deliberate scope choice for a one-day build, not an oversight).
- The step cap (12) and token ceiling (20,000) are implemented and enforced in code, but have not been stress-tested against a real runaway scenario live — only unit-level reasoning confirms they'd trigger correctly.
- The verifier currently checks Slack and Linear independently, but does not yet cross-check that both systems agree with each other (e.g., a Slack message referencing a Linear ticket ID that doesn't actually exist). This would be the next reliability layer to add.
- No automated retry/backoff testing against real rate limits — only against fixture 429s. Real-world backoff timing under load is unverified.
- Airtable data is currently read-only for the agent; there's no equivalent verification step confirming Airtable itself reflects any downstream state changes, since the agent never writes back to Airtable in this build.

## 5. A real bug, found and fixed live

During development, a genuine reliability failure was caught by the exact mechanism this project is built around, not staged for this document.

After the verifier was wired up, a live `--apply` run showed:

```
[FAIL] step 2 (draft_slack_approval): agent claimed a post, but no matching message found in channel
```

The agent's tool call had returned `"posted": True` — a real HTTP 200 from Slack's `chat.postMessage`. But the verifier's independent re-check via `conversations.history` returned `missing_scope`: the Slack app's bot token had `chat:write` but not `channels:history`, so it could post messages but couldn't read them back.

This is precisely the gap the whole project exists to catch: a tool call that returns success is not the same thing as the action being independently confirmable. The scope was added, the app reinstalled, and the same verification step — re-run, not assumed — confirmed the fix actually worked, showing the real posted message content pulled back from Slack.

No part of this was scripted for the demo. It is the system working as designed, against a mistake nobody planned to make.
EOF
echo "wrote RELIABILITY.md"
