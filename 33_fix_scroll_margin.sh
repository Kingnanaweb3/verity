#!/usr/bin/env bash
set -e

python3 - << 'PYEOF'
path = "web/style.css"
with open(path) as f:
    content = f.read()

old = "section{position:relative;padding:clamp(96px,10vw,148px) clamp(32px,7vw,96px);}"
new = "section{position:relative;padding:clamp(96px,10vw,148px) clamp(32px,7vw,96px);scroll-margin-top:90px;}"

if old not in content:
    raise SystemExit("[FATAL] base section rule didn't match — aborting.")
content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
print("patched web/style.css — every section now has scroll-margin-top: 90px")
PYEOF
