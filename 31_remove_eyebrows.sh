#!/usr/bin/env bash
set -e

python3 - << 'PYEOF'
import re

path = "web/index.html"
with open(path) as f:
    content = f.read()

# Remove every eyebrow div, regardless of its exact inner content or class attrs.
# Matches things like:
#   <div class="eyebrow reveal"><i></i>The tension</div>
#   <div class="eyebrow" style="justify-content:center"><i></i>Findings</div>
pattern = re.compile(r'<div class="eyebrow"[^>]*>.*?</div>\s*\n?', re.DOTALL)
count_before = len(pattern.findall(content))

if count_before == 0:
    raise SystemExit("[FATAL] No eyebrow divs matched — check the pattern before proceeding.")

content = pattern.sub('', content)

with open(path, "w") as f:
    f.write(content)

print(f"removed {count_before} eyebrow element(s) from web/index.html")
PYEOF
