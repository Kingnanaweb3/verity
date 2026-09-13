"""
SQLite idempotency ledger.
Before any write (Slack post, Linear ticket create/update), check here first.
Re-running the agent on the same account should update, never duplicate.
"""
import hashlib
import sqlite3
from pathlib import Path

DB_PATH = Path("ledger.sqlite3")


def _connect():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS ledger (
            fingerprint TEXT PRIMARY KEY,
            action TEXT NOT NULL,
            result_ref TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """)
    return conn


def fingerprint(account_id: str, last_activity_date: str, action: str) -> str:
    """
    Same recipe as the plan doc's GitHub version:
    sha256(entity + state + action) — if the account's state hasn't
    changed since we last acted, re-running should not act again.
    """
    raw = f"{account_id}:{last_activity_date}:{action}"
    return hashlib.sha256(raw.encode()).hexdigest()


def already_done(fp: str) -> str | None:
    """Returns the stored result_ref (e.g. Linear ticket ID) if this exact
    action was already performed, or None if it's new."""
    conn = _connect()
    row = conn.execute(
        "SELECT result_ref FROM ledger WHERE fingerprint = ?", (fp,)
    ).fetchone()
    conn.close()
    return row[0] if row else None


def record(fp: str, action: str, result_ref: str):
    """Call this right after a successful write, so the next run recognizes it."""
    conn = _connect()
    conn.execute(
        "INSERT OR REPLACE INTO ledger (fingerprint, action, result_ref) VALUES (?, ?, ?)",
        (fp, action, result_ref),
    )
    conn.commit()
    conn.close()
