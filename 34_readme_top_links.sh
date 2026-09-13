#!/usr/bin/env bash
set -e

python3 - << 'PYEOF'
path = "README.md"
with open(path) as f:
    content = f.read()

old = "# Verity\n"
new = '''# Verity

**Live demo:** [DEMO_VIDEO_URL_HERE]
**Landing page:** [LANDING_PAGE_URL_HERE]

**Want to verify the reliability claims yourself, with zero setup?** No API keys needed:
```
git clone https://github.com/Kingnanaweb3/verity
cd verity
pip install anthropic httpx python-dotenv rich groq
python3 -m evals.run_evals
```
10 scenarios, fully mocked, runs in under 6ms. This checks the same retry logic,
idempotency, allow list, and verifier behavior described below, independently
of anything claimed in this document.
'''

if old not in content:
    raise SystemExit("[FATAL] README.md title line didn't match — aborting.")
content = content.replace(old, new, 1)

with open(path, "w") as f:
    f.write(content)
print("patched README.md — added top links placeholders and zero-setup eval callout")
PYEOF
