#!/usr/bin/env bash
# postino.sh — il ponte: prende i compiti da ~/posta/da_me, li fa eseguire a OpenCode,
# mette il risultato in ~/posta/dal_pc e lo spinge su GitHub (repo pubblico "posta").
# Uso:  ./postino.sh          → un giro e esce
#       ./postino.sh --loop   → resta acceso, controlla ogni 60 s
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$DIR/postino.log"
mkdir -p "$DIR/da_me" "$DIR/dal_pc" "$DIR/fatti"
cd "$DIR" || exit 1

TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
LOGIN=""; [ -s "$HOME/.posta_login" ] && LOGIN="$(tr -d '\r\n' < "$HOME/.posta_login")"
REMOTE="origin"
[ -n "$TOKEN" ] && [ -n "$LOGIN" ] && REMOTE="https://x-access-token:$TOKEN@github.com/$LOGIN/posta.git"

say(){ echo "[$(date '+%d/%m %H:%M')] $*" | tee -a "$LOG"; }

sync_down(){ # prende eventuali compiti nuovi messi da fuori
  git pull -q --rebase "$REMOTE" main >/dev/null 2>&1 || git pull -q --rebase >/dev/null 2>&1 || true
}
sync_up(){
  git add -A >/dev/null 2>&1
  git diff --cached --quiet && return 0
  git commit -qm "postino $(date '+%d/%m %H:%M')" >/dev/null 2>&1 || true
  git push -q "$REMOTE" HEAD:main >/dev/null 2>&1 || git push -q >/dev/null 2>&1 || say "⚠️ push fallito"
}

gira(){
  sync_down
  for f in da_me/*; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"; n="${b%.*}"
    [ -f "fatti/$n.done" ] && continue
    say "→ compito: $n"
    OUT="dal_pc/$n.md"
    { echo "# Risposta a «$n»"; echo; echo "_$(date '+%d/%m/%Y %H:%M') · $(hostname)_"; echo; } > "$OUT"
    timeout 2700 opencode run "$(cat "$f")" >> "$OUT" 2>&1
    echo "" >> "$OUT"; echo "<!-- fine $n -->" >> "$OUT"
    mv "$f" "fatti/$b"; date -Is > "fatti/$n.done"
    sync_up
    say "✓ risposta pronta in dal_pc/$n.md"
  done
  sync_up
}

say "postino acceso · repo: ${LOGIN:-?} · token: $([ -n "$TOKEN" ] && echo sì || echo no)"
if [ "${1:-}" = "--loop" ]; then
  while :; do gira; sleep 60; done
else
  gira
fi
