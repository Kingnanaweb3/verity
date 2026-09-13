"""
Airtable — the CRM. Read-only for now: lists accounts whose days-since-
last-activity exceeds THEIR OWN baseline check-in frequency.
"""
import os
from datetime import datetime, timezone

from agent.infra.http import request

AIRTABLE_API_KEY = os.environ.get("AIRTABLE_API_KEY", "")
BASE_ID = os.environ.get("AIRTABLE_BASE_ID", "")
TABLE_NAME = os.environ.get("AIRTABLE_TABLE_NAME", "Accounts")

BASE_URL = f"https://api.airtable.com/v0/{BASE_ID}/{TABLE_NAME}"


def list_stalled_accounts(trace=None):
    """
    Expected Airtable columns per row:
      Name, LastActivityDate (YYYY-MM-DD), NormalFrequencyDays, HealthNote

    An account is "stalled" when:
      (today - LastActivityDate).days > NormalFrequencyDays
    i.e. compared against ITS OWN pattern, not a fixed number for everyone.
    """
    resp = request(
        service="airtable",
        method="GET",
        url=BASE_URL,
        trace=trace,
        headers={"Authorization": f"Bearer {AIRTABLE_API_KEY}"},
    )

    if resp.status_code >= 400:
        return {"error": f"Airtable read failed: {resp.status_code}", "records": []}

    records = resp.json().get("records", [])
    today = datetime.now(timezone.utc).date()
    stalled = []

    for r in records:
        fields = r.get("fields", {})
        last_activity = fields.get("LastActivityDate")
        normal_freq = fields.get("NormalFrequencyDays")
        if not last_activity or not normal_freq:
            continue

        last_date = datetime.strptime(last_activity, "%Y-%m-%d").date()
        days_since = (today - last_date).days

        if days_since > normal_freq:
            stalled.append({
                "account_id": r["id"],
                "account_name": fields.get("Name", "Unknown"),
                "days_since_activity": days_since,
                "normal_frequency_days": normal_freq,
                "health_note": fields.get("HealthNote", ""),
                "last_activity_date": last_activity,  # used by ledger fingerprint
            })

    return {"stalled_accounts": stalled}
