#!/usr/bin/env bash
# installa_freebuff.sh — installa Freebuff CLI (7° agente) dentro WSL
set -u
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
POSTA_DIR="$HOME/posta"; OUT="$POSTA_DIR/dal_pc/installa_freebuff.md"
TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
echo "# Installazione Freebuff — $(date '+%d/%m %H:%M')" > "$OUT"
echo "- node: $(node --version 2>/dev/null || echo ASSENTE)" | tee -a "$OUT"
if npm install -g freebuff >>"$OUT" 2>&1; then
  echo "- npm install OK" | tee -a "$OUT"
else
  echo "- ERRORE npm install (vedi report)" | tee -a "$OUT"
fi
echo "- binario: $(command -v freebuff || echo NON_TROVATO)" | tee -a "$OUT"
echo "- versione: $(freebuff --version 2>/dev/null | head -1 || echo n/d)" | tee -a "$OUT"
cd "$POSTA_DIR" && git config user.name bomberr91 && git config user.email bomberr91@users.noreply.github.com
git add dal_pc/ >/dev/null 2>&1; git commit -qm "installa_freebuff: esito" >/dev/null 2>&1 || true
[ -n "$TOKEN" ] && { git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1; git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; }
echo FINITO
