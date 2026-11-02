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
# CURA-AUDIT v5: riavviare e POI non verificare = lasciare il PC morto.
# Il collaudo condiviso aspetta la porta e prova una chat vera.
if bash "$POSTA_DIR/fatti/collaudo_cervello.sh" >> "$OUT" 2>&1; then
  echo "- Cervello riavviato col codice NUOVO e COLLAUDATO: OK" >> "$OUT"
else
  echo "- ATTENZIONE: il cervello NON risponde dopo il riavvio (collaudo fallito)" >> "$OUT"
  echo "esito: COLLAUDO FALLITO" >> "$OUT"
fi
echo >> "$OUT"; echo '## Test opencode run' >> "$OUT"; echo '```' >> "$OUT"
timeout 180 opencode run -m cervello/auto "Rispondi esattamente: CERVELLO OK" >> "$OUT" 2>&1 \
  || echo "(fallito o oltre 3 minuti)" >> "$OUT"
echo '```' >> "$OUT"
cd "$POSTA_DIR" && git config user.name bomberr91 && git config user.email bomberr91@users.noreply.github.com
git add dal_pc/ >/dev/null 2>&1; git commit -qm "prova_opencode2: esito" >/dev/null 2>&1 || true
# CURA-AUDIT v5: il push non è una verifica. Se il push fallisce, Dillo:
# un "FINITO" sopra un push fallito è la stessa bugia del collaudo muto.
if [ -n "$TOKEN" ]; then
  git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1
  if git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; then
    echo "✓ pubblicato su master"
  else
    echo "❌ PUSH FALLITO: il lavoro è locale, non è salito su master" >&2
    exit 1
  fi
fi
echo FINITO
