#!/usr/bin/env bash
# prova_opencode2.sh — riavvia il cervello col codice nuovo (streaming) e riprova OpenCode
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
POSTA_DIR="$HOME/posta"; OUT="$POSTA_DIR/dal_pc/punta_opencode2.md"
TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
[ -z "$TOKEN" ] && TOKEN="$(grep -oE 'ghp_[A-Za-z0-9]{30,}' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)"
echo "# Riprova OpenCode -> cervello (streaming) — $(date '+%d/%m %H:%M')" > "$OUT"
pkill -f "cervello.py" 2>/dev/null; sleep 1
(cd "$POSTA_DIR" && nohup python3 cervello.py >/dev/null 2>&1 &)
sleep 3
curl -s -m 3 http://127.0.0.1:20129/v1/models | grep -q '"auto"' \
  && echo "- Cervello riavviato col codice NUOVO (auto nel catalogo): OK" >> "$OUT" \
  || echo "- ATTENZIONE: il cervello non mostra 'auto' (codice vecchio?)" >> "$OUT"
echo >> "$OUT"; echo '## Test opencode run' >> "$OUT"; echo '```' >> "$OUT"
timeout 180 opencode run -m cervello/auto "Rispondi esattamente: CERVELLO OK" >> "$OUT" 2>&1 \
  || echo "(fallito o oltre 3 minuti)" >> "$OUT"
echo '```' >> "$OUT"
cd "$POSTA_DIR" && git config user.name bomberr91 && git config user.email bomberr91@users.noreply.github.com
git add dal_pc/ >/dev/null 2>&1; git commit -qm "prova_opencode2: esito" >/dev/null 2>&1 || true
[ -n "$TOKEN" ] && { git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1; git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; }
echo FINITO
