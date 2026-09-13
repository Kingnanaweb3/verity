#!/usr/bin/env bash
set -e

python3 - << 'PYEOF'
import re

path = "web/index.html"
with open(path) as f:
    content = f.read()

# Targets the smallest <div ...>...</div> wrapper that contains the text
# "The tension" specifically, regardless of exact class/attribute formatting —
# more robust than assuming the previous eyebrow markup survived unchanged.
pattern = re.compile(r'<div[^>]*>(?:(?!</div>).)*The tension(?:(?!</div>).)*</div>\s*\n?', re.DOTALL)
matches = pattern.findall(content)

if not matches:
    raise SystemExit("[FATAL] Could not find a div containing 'The tension' — aborting. Run: grep -n 'The tension' web/index.html to see its actual current markup.")

content = pattern.sub('', content, count=1)

with open(path, "w") as f:
    f.write(content)

print(f"removed the 'The tension' element ({len(matches)} match found, removed 1)")
PYEOF
