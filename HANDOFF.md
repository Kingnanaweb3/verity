# HANDOFF — Verity

Read this first if you're a new Claude session picking this up mid-build.
Event: Multi-App AI Agent Hackathon, Sun Sep 13 2026. Build 9:30am–4pm PT
(12:30–7pm ET / 5:30pm–12am WAT Lagos). Submissions close 4pm PT / 12am WAT.
Builder: Almond (Ibadan, Nigeria), solo.

## The product, in one line
Verity: a CRM/outreach agent (Airtable + Slack + Linear) that flags stalled
accounts against their own baseline, drafts a human-approval message — and
then, after every run, an independent verifier step re-reads Slack and
Linear directly to confirm the draft actually posted and the ticket
actually updated. The agent's claim and the verified reality are shown
side by side. Mismatch = flagged, never hidden.

## Why this exact idea (don't re-litigate this under time pressure)
Hosts: Lemma AI + Comma Capital. Judges: founders of Arga Labs and Userlens.
- Arga Labs' co-founder Akira Tong published "ArgaBench" on Sep 4 2026
  (8 days before this event) benchmarking frontier agents across 5 domains.
  Findings that shaped this build:
  - CRM & outreach was the WORST-performing domain (35.1% pass)
  - Biggest failure mode (54.3%): agent does the internal work but never
    creates the final human-facing artifact (e.g. approval draft)
  - 28.4%: unauthorized/wrong-target writes
  - 11.8%: cross-system state not in sync
  - 5.2%: agent CLAIMS success but the actual system state shows it didn't happen
- Lemma AI's entire product thesis is the same coin, flip side: "agents can
  look like they're working even when they've failed."
- Userlens (the other judge's company) IS an AI CSM that watches account
  health signals — same domain as this build, so it reads as informed,
  not accidental.
- Conclusion: build a CRM/outreach agent whose headline feature is
  INDEPENDENT VERIFICATION of its own claims. This directly answers the
  single largest failure mode in research the judge published last week.

## Apps (token-only, zero OAuth — do not add a 4th app)
| App      | Role                                   | Auth            |
|----------|----------------------------------------|-----------------|
| Airtable | CRM — accounts, baseline check-in freq | API key         |
| Slack    | Approval-gate draft messages           | Bot token xoxb- |
| Linear   | Ticket created/updated per account     | API key         |

## Repo layout
```
verity/
  agent/
    main.py          # CLI entry — NOT YET WRITTEN
    loop.py           # tool-use loop, step cap — NOT YET WRITTEN
    prompts.py         # system prompt — NOT YET WRITTEN
    verifier.py          # re-checks Slack/Linear state post-run — NOT YET WRITTEN
    tools/
      airtable.py         # NOT YET WRITTEN
      slack.py             # NOT YET WRITTEN
      linear.py             # NOT YET WRITTEN
      registry.py            # schemas + dispatch + allowlist — NOT YET WRITTEN
    infra/
      http.py           # DONE — single choke point, retries, fault injection
      ledger.py          # DONE — SQLite idempotency (fingerprint = account_id +
                          #   last_activity_date + action)
      trace.py            # DONE — JSONL log + rich table summary. Has a
                           #   `verified` field per tool-call entry, set later
                           #   by verifier.py via trace.mark_verified(step, bool)
  evals/
    scenarios.py     # NOT YET WRITTEN — 10 cases, see plan below
    run_evals.py       # NOT YET WRITTEN
  README.md            # NOT YET WRITTEN
  RELIABILITY.md         # NOT YET WRITTEN
  progress.md              # timestamped build log, append-only — KEEP UPDATING
  HANDOFF.md                 # this file
```

## Build order so far (delivered as numbered .sh scripts, run in order)
- 01_scaffold.sh — folder tree, .gitignore, .env.example, progress.md — DONE
- 02_http.sh — agent/infra/http.py — DONE
- 03_infra.sh — agent/infra/trace.py + agent/infra/ledger.py — DONE
- 04_handoff.sh — this file — DONE
- 05 (next) — agent/tools/registry.py (schemas + dispatch + allowlist)
- then — agent/tools/{airtable,slack,linear}.py
- then — agent/loop.py + agent/prompts.py + agent/main.py
- then — agent/verifier.py
- then — evals/scenarios.py + evals/run_evals.py
- then — README.md + RELIABILITY.md

## Design decisions locked in
- Every outbound HTTP call MUST go through infra/http.py. No tool module
  calls httpx directly. This is what makes fault injection (`--fault
  slack:500`) and tracing work everywhere for free.
- Retry only 429/5xx, exponential backoff + jitter, max 3 attempts.
  NEVER retry 401/403 — fail fast, that's a credentials bug not a
  transient fault.
- Dry-run is the default. Real writes require `--apply`.
- Hard step cap on the agent loop (12 tool calls) — not yet implemented,
  needs to land in loop.py.
- Idempotency fingerprint = sha256(account_id + last_activity_date +
  action) — if account state hasn't changed, re-running must not re-act.
- Trace log's `verified` field starts as None, agent's own claim never
  sets it — ONLY verifier.py may set it via trace.mark_verified(). This
  separation is the whole point of the product; don't let the agent
  self-report verification.

## Eval suite plan (10 scenarios — none written yet)
1. Clean stalled account → Slack draft + Linear ticket, both verified
2. Same account run twice → no duplicate, verifier confirms single state
3. Linear 429 → retries, succeeds, verified
4. Slack down → degrades, Linear still written, reported partial
5. Airtable 401 → fails fast, zero writes
6. Ambiguous/low-confidence account → flags low confidence, no invented owner
7. Agent CLAIMS Slack post succeeded but verifier finds no message →
   flagged mismatch (this is the ArgaBench-inspired scenario, don't cut it)
8. Verifier catches partial completion — Linear updated, Slack never
   posted → reports incomplete, not done (also ArgaBench-inspired)
9. Prompt injection in account notes field → ignored, stays in allowlist
10. Crash mid-run, re-run → verifier confirms no duplicate, correct resume

Scenarios 7 and 8 are the differentiator — never cut these under time
pressure even if others get trimmed.

## Credentials status
Not yet confirmed as of last update — check progress.md for the latest
line, and verify with curl before assuming any token works.

## If you're a fresh session starting here
1. Read progress.md for the actual current timestamp/status (source of truth,
   more current than this file).
2. Ask the builder which numbered .sh script was last run successfully.
3. Continue from the "Build order so far" list above.
4. Do not re-litigate the product idea or the app choices — both are locked.
