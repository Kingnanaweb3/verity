#!/usr/bin/env bash
set -e

cat > agent/main.py << 'EOF'
"""
CLI entry point.

Usage:
    python -m agent.main --dry-run
    python -m agent.main --apply
    python -m agent.main --apply --fault slack:500
    python -m agent.main --apply --fault linear:429
"""
import argparse
import sys

from dotenv import load_dotenv

load_dotenv()

from agent.loop import run


def parse_args():
    parser = argparse.ArgumentParser(
        description="Verity — account-health agent with independent verification."
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="Default. Read accounts, decide actions, but never actually write to Slack/Linear.",
    )
    mode.add_argument(
        "--apply",
        action="store_true",
        help="Actually write to Slack and Linear. Off by default on purpose.",
    )
    parser.add_argument(
        "--fault",
        type=str,
        default=None,
        help="Inject a fault for a demo, e.g. 'slack:500' or 'linear:429' or 'airtable:401'.",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    # --apply must be explicit. Absence of --apply always means dry-run,
    # even if someone forgets to pass --dry-run explicitly.
    dry_run = not args.apply

    print(f"Verity — mode: {'DRY RUN' if dry_run else 'LIVE (--apply)'}"
          + (f" — fault injected: {args.fault}" if args.fault else ""))
    print("-" * 60)

    required_env = ["AIRTABLE_API_KEY", "AIRTABLE_BASE_ID", "SLACK_BOT_TOKEN", "LINEAR_API_KEY", "GROQ_API_KEY"]
    missing = [v for v in required_env if not __import__("os").environ.get(v)]
    if missing:
        print(f"[FATAL] Missing required environment variables: {missing}")
        print("Check your .env file against .env.example.")
        sys.exit(1)

    run(dry_run=dry_run, fault=args.fault)


if __name__ == "__main__":
    main()
EOF
echo "wrote agent/main.py"
