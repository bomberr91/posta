#!/usr/bin/env bash
# punta_secondhand.sh — punta Secondhand (Open Interpreter 0.0.56, clone di Codex) al cervello e collauda
set -u
POSTA_DIR="$HOME/posta"; OUT="$POSTA_DIR/dal_pc/punta_secondhand.md"
TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
CFGDIR="$HOME/.openinterpreter"; CFG="$CFGDIR/config.toml"
mkdir -p "$CFGDIR"
echo "# Puntamento Secondhand -> cervello — $(date '+%d/%m %H:%M')" > "$OUT"
[ -f "$CFG" ] && { cp "$CFG" "$CFG.bak-$(date +%Y%m%d-%H%M%S)"; echo "- backup config precedente fatto" >> "$OUT"; }
cat > "$CFG" << 'TOML'
model = "auto"
model_provider = "cervello"

[model_providers.cervello]
name = "Cervello"
base_url = "http://127.0.0.1:20129/v1"
wire_api = "chat"
TOML
echo "- config scritta in ~/.openinterpreter/config.toml (provider cervello, modello auto, wire chat)" | tee -a "$OUT"
# cervello acceso?
if ! curl -s -m 3 http://127.0.0.1:20129/v1/models >/dev/null; then
  echo "- ⚠ cervello SPENTO: accendilo (finestra verde) e rilancia questo test" | tee -a "$OUT"
else
  echo "- cervello acceso: OK" | tee -a "$OUT"
  echo '## Test' >> "$OUT"; echo '```' >> "$OUT"
  timeout 180 "$HOME/.local/bin/interpreter" exec -s read-only "Rispondi esattamente: CERVELLO OK" 2>&1 | tee -a "$OUT"
  echo '```' >> "$OUT"
fi
cd "$POSTA_DIR" && git config user.name bomberr91 && git config user.email bomberr91@users.noreply.github.com
git add dal_pc/ >/dev/null 2>&1; git commit -qm "punta_secondhand: esito" >/dev/null 2>&1 || true
[ -n "$TOKEN" ] && { git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1; git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; }
echo FINITO
