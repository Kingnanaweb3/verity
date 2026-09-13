"""
The tool-use loop, running against Groq.

Guardrails enforced here (not just in the prompt):
- Hard step cap — terminate and report rather than run forever.
- Token ceiling — a cost guard for the whole run.
- Dry-run gate — write tools are only actually called with --apply.
- Idempotency — checked against the ledger before any write tool runs.
"""
import os
import json

from groq import Groq

from agent.prompts import SYSTEM_PROMPT, build_user_prompt
from agent.tools import registry
from agent.infra import ledger
from agent.infra.trace import Trace
from agent.infra.http import set_fault

GROQ_MODEL = os.environ.get("GROQ_MODEL", "llama-3.3-70b-versatile")

MAX_STEPS = 12
MAX_TOKENS_PER_RUN = 20000

WRITE_TOOLS = {"draft_slack_approval", "upsert_linear_ticket"}


def run(dry_run: bool = True, fault: str | None = None) -> Trace:
    set_fault(fault)
    client = Groq(api_key=os.environ["GROQ_API_KEY"])
    trace = Trace()

    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": build_user_prompt(dry_run)},
    ]

    # Populated once list_stalled_accounts runs, so write-tool calls can be
    # fingerprinted against the account's actual last_activity_date without
    # asking the model to pass that field through itself (it doesn't need to
    # know the ledger exists).
    account_state = {}

    total_tokens = 0
    step = 0

    while step < MAX_STEPS:
        step += 1

        response = client.chat.completions.create(
            model=GROQ_MODEL,
            messages=messages,
            tools=registry.TOOL_SCHEMAS,
            tool_choice="auto",
        )

        usage = getattr(response, "usage", None)
        if usage:
            total_tokens += usage.total_tokens

        if total_tokens > MAX_TOKENS_PER_RUN:
            print(f"[STOPPED] token ceiling reached ({total_tokens} tokens) at step {step}")
            break

        choice = response.choices[0]
        message = choice.message
        messages.append(message.model_dump(exclude_none=True))

        tool_calls = message.tool_calls or []

        if not tool_calls:
            # Model gave a final answer, no more tools to call — done.
            print(f"\n[FINAL] {message.content}\n")
            break

        for call in tool_calls:
            name = call.function.name
            try:
                tool_input = json.loads(call.function.arguments or "{}")
            except json.JSONDecodeError:
                tool_input = {}

            result = _execute_tool(name, tool_input, dry_run, account_state, trace)

            messages.append({
                "role": "tool",
                "tool_call_id": call.id,
                "content": json.dumps(result),
            })
    else:
        print(f"[STOPPED] step cap reached ({MAX_STEPS} tool calls) — terminating and reporting")

    trace.print_summary()
    return trace


def _execute_tool(name: str, tool_input: dict, dry_run: bool, account_state: dict, trace) -> dict:
    """
    Wraps registry.dispatch with the two guardrails that live at the loop
    level rather than inside registry.py: the dry-run gate and idempotency.
    """
    # Cache account data as soon as we read it, so write tools can be
    # fingerprinted correctly later in this same run.
    if name == "list_stalled_accounts":
        result = registry.dispatch(name, tool_input, trace=trace)
        for acct in result.get("stalled_accounts", []):
            account_state[acct["account_id"]] = acct
        trace.log_tool_call(tool=name, idempotent_hit=False)
        return result

    if name in WRITE_TOOLS:
        account_id = tool_input.get("account_id", "unknown")
        last_activity = account_state.get(account_id, {}).get("last_activity_date", "unknown")
        fp = ledger.fingerprint(account_id, last_activity, name)

        existing = ledger.already_done(fp)
        if existing:
            trace.log_tool_call(tool=name, idempotent_hit=True)
            return {
                "skipped": True,
                "reason": "already performed for this account state",
                "previous_result_ref": existing,
            }

        if dry_run:
            trace.log_tool_call(tool=name, idempotent_hit=False)
            return {"dry_run": True, "would_execute": name, "input": tool_input}

        result = registry.dispatch(name, tool_input, trace=trace)
        entry = trace.log_tool_call(tool=name, idempotent_hit=False)

        # Only record success in the ledger — a failed write should be
        # retryable on the next run, not silently treated as "already done".
        ref = result.get("ts") or result.get("ticket_id")
        if ref:
            ledger.record(fp, name, str(ref))

        return result

    # Any other allowlisted tool with no special guardrail needs.
    result = registry.dispatch(name, tool_input, trace=trace)
    trace.log_tool_call(tool=name, idempotent_hit=False)
    return result
