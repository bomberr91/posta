#!/bin/bash
D="[CHIAVE-RIMOSSA]"
echo "## 🔎 EXA: VERIFICA + DOPPIA RICERCA + SKILL — $(date '+%H:%M')"
echo "### 1. .env (mascherato)"
grep -E "^[A-Z_]+=." "$D/.env" | sed 's/=\(.\{6\}\).*/=\1•••/'
echo
echo "### 2. valori ammessi per WEB_SEARCH_ENGINE"
grep -n -B2 -A6 'WEB_SEARCH_ENGINE = os.environ' "$D/deep_research/config.py" | head -14
echo
echo "### 3. skill ufficiale build-with-exa nei 3 nidi"
rm -rf /tmp/exask && git clone -q --depth 1 https://github.com/exa-labs/agent-skills.git /tmp/exask 2>/dev/null
S=$(find /tmp/exask -type d -name "build-with-exa" | head -1)
if [ -n "$S" ]; then
  for NIDO in ~/.claude/skills ~/.agents/skills ~/.config/opencode/skills; do
    cp -rn "$S" "$NIDO/" && echo "  ✓ innestata in $NIDO"
  done
  head -8 "$S/SKILL.md" 2>/dev/null
else
  echo "  struttura repo:"; find /tmp/exask -name "SKILL.md" | head -5
fi
