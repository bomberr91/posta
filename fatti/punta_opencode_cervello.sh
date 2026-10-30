#!/usr/bin/env bash
# punta_opencode_cervello.sh — 30/10/2026
# Collega OpenCode al cervello (Portiere :20129): provider "cervello"
# con modello "auto", backup della config, test automatico finale.
# Risultato in dal_pc/punta_opencode.md
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

POSTA_DIR="$HOME/posta"
OUT="$POSTA_DIR/dal_pc/punta_opencode.md"
TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
[ -z "$TOKEN" ] && [ -f "$HOME/CHIAVI_LOCALI.md" ] && TOKEN="$(grep -oE 'ghp_[A-Za-z0-9]{30,}' "$HOME/CHIAVI_LOCALI.md" | head -1)"

push_git(){
  cd "$POSTA_DIR" || return
  git config user.name "bomberr91"
  git config user.email "bomberr91@users.noreply.github.com"
  git add dal_pc/ >/dev/null 2>&1
  git commit -qm "punta_opencode: esito" >/dev/null 2>&1 || true
  if [ -n "$TOKEN" ]; then
    git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1 || true
    git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1 || true
  fi
}

echo "# Puntamento OpenCode -> cervello — $(date '+%d/%m %H:%M')" > "$OUT"
echo >> "$OUT"

# 1. cervello acceso?
if curl -s -m 3 http://127.0.0.1:20129/v1/models >/dev/null 2>&1; then
  echo "- Cervello (20129): ACCESO" >> "$OUT"
else
  echo "- Cervello (20129): spento, lo accendo io in background" >> "$OUT"
  (cd "$POSTA_DIR" && nohup python3 cervello.py >/dev/null 2>&1 &)
  sleep 3
  curl -s -m 3 http://127.0.0.1:20129/v1/models >/dev/null 2>&1 \
    && echo "- Acceso ora: OK" >> "$OUT" \
    || echo "- NON sono riuscito ad accenderlo: il test sotto fallira'" >> "$OUT"
fi

# 2. config con backup + merge (niente sovrascritture cieche)
python3 - "$OUT" << 'PYEOF'
import json, os, sys, time, shutil
out = sys.argv[1]
cfg_dir = os.path.expanduser("~/.config/opencode")
cfg = os.path.join(cfg_dir, "opencode.json")
os.makedirs(cfg_dir, exist_ok=True)
dati = {}
if os.path.exists(cfg):
    shutil.copy2(cfg, cfg + ".bak-" + time.strftime("%Y%m%d-%H%M%S"))
    try:
        dati = json.load(open(cfg))
    except Exception:
        dati = {}
dati.setdefault("$schema", "https://opencode.ai/config.json")
prov = dati.setdefault("provider", {})
prov["cervello"] = {
    "npm": "@ai-sdk/openai-compatible",
    "name": "Cervello",
    "options": {"baseURL": "http://127.0.0.1:20129/v1", "apiKey": "sk-cervello"},
    "models": {"auto": {"name": "Cervello (auto)"}}
}
dati["model"] = "cervello/auto"
json.dump(dati, open(cfg, "w"), ensure_ascii=False, indent=2)
with open(out, "a") as f:
    f.write("- Config scritta in ~/.config/opencode/opencode.json (backup fatto se esisteva)\n")
    f.write("- Provider: cervello -> http://127.0.0.1:20129/v1, modello di default: cervello/auto\n")
PYEOF

# 3. test vero
echo >> "$OUT"
echo "## Test (opencode run con modello cervello/auto)" >> "$OUT"
echo '```' >> "$OUT"
timeout 180 opencode run -m cervello/auto "Rispondi esattamente: CERVELLO OK" >> "$OUT" 2>&1 \
  || echo "(il comando e' fallito o ha superato i 3 minuti)" >> "$OUT"
echo '```' >> "$OUT"

push_git
echo "FINITO: vedi dal_pc/punta_opencode.md"
