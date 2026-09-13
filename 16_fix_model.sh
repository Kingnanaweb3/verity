#!/usr/bin/env bash
set -e

# Add GROQ_MODEL explicitly to .env so it's never left to a stale default
if grep -q "GROQ_MODEL" .env 2>/dev/null; then
  sed -i.bak 's|GROQ_MODEL=.*|GROQ_MODEL=openai/gpt-oss-20b|' .env
else
  echo "GROQ_MODEL=openai/gpt-oss-20b" >> .env
fi
rm -f .env.bak
echo "set GROQ_MODEL=openai/gpt-oss-20b in .env"

# Update the fallback default in loop.py too, in case .env is ever missing it
sed -i.bak 's|GROQ_MODEL = os.environ.get("GROQ_MODEL", "llama-3.3-70b-versatile")|GROQ_MODEL = os.environ.get("GROQ_MODEL", "openai/gpt-oss-20b")|' agent/loop.py
rm -f agent/loop.py.bak
echo "updated fallback default in agent/loop.py"
