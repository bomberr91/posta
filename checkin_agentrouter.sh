#!/usr/bin/env bash
# checkin_agentrouter.sh — wrapper: esegue il check-in +25$/gg e manda il rapporto sul ponte
set -u
DIR="$HOME/posta"; mkdir -p "$DIR/dal_pc"
R="$DIR/dal_pc/agentrouter_checkin.md"
{
  echo "# 💰 Check-in AgentRouter — $(date '+%d/%m/%Y %H:%M')"
  python3 "$DIR/checkin_agentrouter.py" 2>&1
  echo "esito: $?"
} > "$R"
cat "$R"
cd "$DIR" || exit 0
git add -A >/dev/null 2>&1; git commit -qm "check-in agentrouter $(date '+%d/%m %H:%M')" >/dev/null 2>&1 || true
TOK=$(grep -oE 'ghp_[A-Za-z0-9]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
git push -q origin main >/dev/null 2>&1 || { [ -n "$TOK" ] && git push -q "https://x-access-token:$TOK@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; } || true
