#!/usr/bin/env bash
set -e

python3 - << 'PYEOF'
import re

files = ["agent/tools/airtable.py", "agent/tools/slack.py", "agent/tools/linear.py"]

for path in files:
    with open(path) as f:
        content = f.read()

    old_import = "from agent.infra.http import request"
    new_import = "from agent.infra import http"
    if old_import not in content:
        raise SystemExit(f"[FATAL] {path}: import line didn't match — aborting.")
    content = content.replace(old_import, new_import)

    # Replace call sites: "request(" -> "http.request(" but only where it's
    # actually calling the function (not part of another word). Since this
    # codebase only uses `request(` for that one function, a straight
    # replace is safe here.
    content = content.replace("request(\n        service=", "http.request(\n        service=")
    content = content.replace("= request(", "= http.request(")

    with open(path, "w") as f:
        f.write(content)
    print(f"patched {path}")
PYEOF

echo ""
echo "Verifying no bare 'request(' calls remain (should be silent if clean):"
grep -n "[^.]request(" agent/tools/airtable.py agent/tools/slack.py agent/tools/linear.py || echo "  (none found — clean)"
