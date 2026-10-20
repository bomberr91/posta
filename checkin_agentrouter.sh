#!/usr/bin/env bash
# checkin_agentrouter.sh — wrapper: esegue il check-in +25$/gg, scrive il rapporto, pusha sul ponte.
# v2 (20/10): rispetta il flag "serve login manuale" e non insiste (niente logout a vuoto).
#   FORZA=1 → tenta comunque, anche se il flag è presente.
set -u
DIR="$HOME/posta"; mkdir -p "$DIR/dal_pc"
R="$DIR/dal_pc/agentrouter_checkin.md"
LM="$HOME/.ar_login_manuale"

if [ -f "$LM" ] && [ "${FORZA:-0}" != "1" ]; then
  echo "↷ check-in saltato: serve un login manuale nel BROWSER_AGENTI ($(cat "$LM" 2>/dev/null))"
  exit 0
fi

OUT="$(python3 "$DIR/checkin_agentrouter.py" 2>&1)"; RC=$?

{
  echo "# 💰 Check-in AgentRouter — $(date '+%d/%m/%Y %H:%M')"
  echo
  echo '```'
  echo "$OUT"
  echo "esito: $RC"
  echo '```'
} > "$R"
cat "$R"

case "$RC" in
  0) rm -f "$LM" ;;
  3)
    mkdir -p "$(dirname "$LM")"
    { date '+%d/%m/%Y %H:%M'; echo "· $(echo "$OUT" | grep -m1 '^\[login_manuale\]' | sed 's/\[login_manuale\]//')"; } > "$LM"
    ;;
esac

# sul ponte solo quando c'è qualcosa da dire (esito buono o login mancante): niente commit a vuoto
if [ "$RC" = "0" ] || [ "$RC" = "3" ]; then
  cd "$DIR" || exit 0
  git add -A >/dev/null 2>&1
  git diff --cached --quiet || git commit -qm "check-in agentrouter $(date '+%d/%m %H:%M') · esito $RC" >/dev/null 2>&1
  TOK=$(grep -oE 'ghp_[A-Za-z0-9]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
  git push -q origin main >/dev/null 2>&1 || { [ -n "$TOK" ] && git push -q "https://x-access-token:$TOK@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; } || true
fi
exit "$RC"
