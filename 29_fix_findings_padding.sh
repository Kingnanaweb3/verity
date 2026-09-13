#!/usr/bin/env bash
set -e

python3 - << 'PYEOF'
path = "web/style.css"
with open(path) as f:
    content = f.read()

old = '''.findings-grid{
  display:grid;grid-template-columns:repeat(4,1fr);gap:32px;max-width:1160px;margin:-40px auto 0;position:relative;
}'''
new = '''.findings-grid{
  display:grid;grid-template-columns:repeat(4,1fr);gap:32px;max-width:1160px;
  margin:-40px auto 0;position:relative;
  padding:0 clamp(24px,6vw,48px);
}'''

if old not in content:
    raise SystemExit("[FATAL] .findings-grid rule didn't match — aborting.")
content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
print("patched web/style.css — findings grid now has its own side padding")
PYEOF
