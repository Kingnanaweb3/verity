"""
JSONL trace log — one line per tool call attempt.
Every call that goes through infra/http.py gets logged here.

This is also where Verity's differentiator lives: each entry can carry
a `verified` field, set later by verifier.py once it independently
re-checks whether the claimed action actually happened.
"""
import json
import time
import uuid
from pathlib import Path

from rich.console import Console
from rich.table import Table

TRACE_DIR = Path("traces")
TRACE_DIR.mkdir(exist_ok=True)


class Trace:
    def __init__(self, run_id: str | None = None):
        # A fresh run_id groups every line from one CLI invocation together,
        # so you can pull up "everything that happened in this run" later.
        self.run_id = run_id or str(uuid.uuid4())[:8]
        self.path = TRACE_DIR / f"{self.run_id}.jsonl"
        self.entries = []
        self.step = 0

    def log_attempt(self, service: str, attempt: int, status: int, **extra):
        """Called from infra/http.py on every single HTTP attempt, including retries."""
        entry = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "run_id": self.run_id,
            "step": self.step,
            "tool": service,
            "attempt": attempt,
            "status": "ok" if status < 400 else "error",
            "http": status,
            **extra,
        }
        self.entries.append(entry)
        self._append_line(entry)

    def log_tool_call(self, tool: str, idempotent_hit: bool = False, tokens: int = 0):
        """Called once per logical tool call (not per HTTP retry) to bump the step counter."""
        self.step += 1
        entry = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "run_id": self.run_id,
            "step": self.step,
            "tool": tool,
            "idempotent_hit": idempotent_hit,
            "tokens": tokens,
            "verified": None,  # filled in later by verifier.py, None until then
        }
        self.entries.append(entry)
        self._append_line(entry)
        return entry

    def mark_verified(self, step: int, verified: bool, note: str = ""):
        """
        Called by verifier.py after independently re-checking Slack/Linear state.
        This is what separates 'the agent claims it worked' from 'we confirmed it worked'.
        """
        for e in self.entries:
            if e["step"] == step:
                e["verified"] = verified
                e["verify_note"] = note
        self._rewrite_file()

    def _append_line(self, entry: dict):
        with open(self.path, "a") as f:
            f.write(json.dumps(entry) + "\n")

    def _rewrite_file(self):
        # Only used by mark_verified, which needs to update an existing line —
        # JSONL doesn't support in-place edits, so we rewrite the whole file.
        with open(self.path, "w") as f:
            for e in self.entries:
                f.write(json.dumps(e) + "\n")

    def print_summary(self):
        """Formatted table at the end of every run — this is what you show on camera."""
        console = Console()
        table = Table(title=f"Trace summary — run {self.run_id}")
        table.add_column("Step")
        table.add_column("Tool")
        table.add_column("Status")
        table.add_column("Verified")

        for e in self.entries:
            if "tool" in e and "idempotent_hit" in e:
                verified = e.get("verified")
                verified_str = (
                    "✅" if verified is True else "❌" if verified is False else "—"
                )
                table.add_row(str(e["step"]), e["tool"], "claimed done", verified_str)

        console.print(table)
