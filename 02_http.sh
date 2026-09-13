#!/usr/bin/env bash
set -e

cat > agent/infra/http.py << 'EOF'
"""
Single HTTP client for the whole agent.
Every tool (airtable, slack, linear) calls through here — never httpx directly.
This is where retries, fault injection, and tracing all live in one place.
"""
import time
import random
import httpx

# --fault CLI flag sets this before any calls happen.
# Format: "service:code" e.g. "slack:500" or "linear:429"
ACTIVE_FAULT = {"service": None, "code": None}


def set_fault(fault_str: str | None):
    """Called once at startup from main.py if --fault was passed."""
    if not fault_str:
        return
    service, code = fault_str.split(":")
    ACTIVE_FAULT["service"] = service
    ACTIVE_FAULT["code"] = int(code)


def request(service: str, method: str, url: str, trace=None, **kwargs) -> httpx.Response:
    """
    service: "airtable" | "slack" | "linear" — used to match fault injection
    trace: optional Trace object (infra/trace.py) to log each attempt
    """
    max_attempts = 3
    attempt = 0

    while True:
        attempt += 1

        # Fault injection: fake a bad response instead of calling the real API
        if ACTIVE_FAULT["service"] == service:
            status = ACTIVE_FAULT["code"]
            resp = httpx.Response(status_code=status, request=httpx.Request(method, url))
        else:
            resp = httpx.request(method, url, **kwargs)

        if trace:
            trace.log_attempt(service=service, attempt=attempt, status=resp.status_code)

        # Never retry auth failures — a retry loop on bad credentials is a bug
        # that looks like resilience. Fail fast and loud instead.
        if resp.status_code in (401, 403):
            return resp

        # Only retry on rate-limit or server errors
        if resp.status_code == 429 or resp.status_code >= 500:
            if attempt >= max_attempts:
                return resp

            # Respect Retry-After if the server sent one
            retry_after = resp.headers.get("Retry-After")
            if retry_after:
                delay = float(retry_after)
            else:
                # Exponential backoff with jitter: 1s, 2s, 4s (+/- randomness)
                delay = (2 ** (attempt - 1)) + random.uniform(0, 0.5)

            time.sleep(delay)
            continue

        # 2xx or any other non-retryable status — return as-is
        return resp
EOF

echo "wrote agent/infra/http.py"
