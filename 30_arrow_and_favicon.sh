#!/usr/bin/env bash
set -e

# Copy the logo image into the repo for use as both favicon and nav mark
cp ~/Downloads/663B368D-64C3-4313-B3F0-DDE27957CC73.PNG web/logo.png
echo "copied logo into web/logo.png"

python3 - << 'PYEOF'
path = "web/index.html"
with open(path) as f:
    content = f.read()

# ---- 1. Add favicon link in <head> ----
old_head = '<link rel="stylesheet" href="style.css">'
new_head = '<link rel="stylesheet" href="style.css">\n<link rel="icon" type="image/png" href="logo.png">'
if old_head not in content:
    raise SystemExit("[FATAL] head stylesheet link didn't match — aborting.")
content = content.replace(old_head, new_head)

# ---- 2. Swap nav logo checkmark SVG for the real logo image ----
old_nav_logo = '''  <a href="#" class="nav-logo">
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
    Verity
  </a>'''
new_nav_logo = '''  <a href="#" class="nav-logo">
    <img src="logo.png" width="22" height="22" alt="Verity logo" style="border-radius:6px">
    Verity
  </a>'''
if old_nav_logo not in content:
    raise SystemExit("[FATAL] nav logo block didn't match — aborting.")
content = content.replace(old_nav_logo, new_nav_logo)

# ---- 3. Swap footer logo checkmark SVG too, for consistency ----
old_footer_logo = '''        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
        Verity'''
new_footer_logo = '''        <img src="logo.png" width="20" height="20" alt="Verity logo" style="border-radius:5px">
        Verity'''
if old_footer_logo not in content:
    raise SystemExit("[FATAL] footer logo block didn't match — aborting.")
content = content.replace(old_footer_logo, new_footer_logo)

# ---- 4. Replace the "↗" text glyph with a proper SVG arrow icon on every CTA ----
arrow_svg = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="7" y1="17" x2="17" y2="7"/><polyline points="7 7 17 7 17 17"/></svg>'

replacements = [
    ("See it running ↗", f"See it running {arrow_svg}"),
    ("Read the reliability brief ↗", f"Read the reliability brief {arrow_svg}"),
    (">View the repo<", f">View the repo {arrow_svg}<"),
]

for old_txt, new_txt in replacements:
    count = content.count(old_txt)
    if count == 0:
        raise SystemExit(f"[FATAL] '{old_txt}' not found — aborting.")
    content = content.replace(old_txt, new_txt)
    print(f"replaced {count} occurrence(s) of '{old_txt}'")

with open(path, "w") as f:
    f.write(content)
print("patched web/index.html — favicon, nav/footer logo, and arrow icons updated")
PYEOF
