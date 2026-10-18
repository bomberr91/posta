#!/usr/bin/env bash
# postino.sh — il ponte: prende i compiti da ~/posta/da_me, li fa eseguire a OpenCode (o bash per .sh),
# mette il risultato in ~/posta/dal_pc e lo spinge su GitHub (repo "posta").
set -u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
if [ -f "$HOME/CHIAVI_LOCALI.md" ]; then
  OC_KEY=$(grep -oE 'oc_sk_[A-Za-z0-9_-]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
  [ -n "$OC_KEY" ] && export OPENCODE_API_KEY="$OC_KEY"
fi
pgrep -f 'magpie serve' >/dev/null 2>&1 || (nohup magpie serve >/dev/null 2>&1 &)

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$DIR/postino.log"
mkdir -p "$DIR/da_me" "$DIR/dal_pc" "$DIR/fatti"
cd "$DIR" || exit 1

TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
LOGIN=""; [ -s "$HOME/.posta_login" ] && LOGIN="$(tr -d '\r\n' < "$HOME/.posta_login")"
[ -z "$LOGIN" ] && [ -s "$DIR/.padrone" ] && LOGIN="$(tr -d '\r\n' < "$DIR/.padrone")"
REMOTE="origin"
[ -n "$TOKEN" ] && [ -n "$LOGIN" ] && REMOTE="https://x-access-token:$TOKEN@github.com/$LOGIN/posta.git"

say(){ echo "[$(date '+%d/%m %H:%M')] $*" | tee -a "$LOG"; }

sync_down(){
  git pull -q --rebase "$REMOTE" main >/dev/null 2>&1 || git pull -q --rebase >/dev/null 2>&1 || true
  if [ -f "$DIR/skills_pack.tar.gz" ] && [ ! -f "$HOME/.skills_v2_installed" ]; then
    tar -xzf "$DIR/skills_pack.tar.gz" -C "$HOME" && date -Is > "$HOME/.skills_v2_installed"
    say "✓ 26 skill aggiornate automaticamente in ~/.config/opencode e ~/.config/goose"
  fi
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
    b="$(basename "$f")"; n="${b%.*}"; ext="${b##*.}"
    [ -f "fatti/$n.done" ] && continue
    say "→ compito: $b"
    OUT="dal_pc/$n.md"
    { echo "# Risposta a «$n»"; echo; echo "_$(date '+%d/%m/%Y %H:%M') · $(hostname)_"; echo; } > "$OUT"
    if [ "$ext" = "sh" ]; then
      timeout 1800 bash "$f" >> "$OUT" 2>&1
    else
      timeout 2700 opencode run -m opencode/big-pickle "$(cat "$f")" >> "$OUT" 2>&1 \
        || timeout 2700 opencode run "$(cat "$f")" >> "$OUT" 2>&1
    fi
    echo "" >> "$OUT"; echo "<!-- fine $n -->" >> "$OUT"
    mv "$f" "fatti/$b"; date -Is > "fatti/$n.done"
    sync_up
    say "✓ risposta pronta in dal_pc/$n.md"
  done
  sync_up
}

say "postino acceso · repo: ${LOGIN:-?} · opencode: $(command -v opencode || echo NON_TROVATO)"
if [ "${1:-}" = "--loop" ]; then
  while :; do gira; sleep 45; done
else
  gira
fi
