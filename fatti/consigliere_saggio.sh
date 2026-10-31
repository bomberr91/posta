#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
OUT=dal_pc/consiglio_saggio.md
KEY="sk-be311327ce941004-4df42c-cf76ba39"
vivo(){ curl -s -m 4 -H "Authorization: Bearer $KEY" http://127.0.0.1:20128/v1/models | grep -q data; }
# sveglia OmniRoute se dorme (mattina dopo riavvio)
if ! vivo; then
  export NVM_DIR="/home/agenti/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
  [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1
  OMNIROUTE_SERVER_HOST=127.0.0.1 nohup omniroute >> dal_pc/omni_start.log 2>&1 &
  for i in $(seq 1 36); do sleep 5; vivo && break; done
fi
BASE="http://127.0.0.1:20128"; AUTH="$KEY"; SCELTO=""
if vivo; then
  MODELS=$(curl -s -m 10 -H "Authorization: Bearer $KEY" $BASE/v1/models)
  for pat in "claude-sonnet" "claude" "deepseek-v4-pro" "deepseek-v4" "glm-5" "kimi-k3" "kimi" "qwen3-max" "qwen3" "deepseek"; do
    SCELTO=$(echo "$MODELS" | grep -oE '"id" *: *"[^"]*'"$pat"'[^"]*"' | head -1 | sed 's/.*: *"//; s/"$//')
    [ -n "$SCELTO" ] && break
  done
fi
if [ -z "$SCELTO" ]; then BASE="http://127.0.0.1:20129"; AUTH="sk-cervello"; SCELTO="auto"; fi
export BASE AUTH SCELTO
python3 << 'PYEOF'
import json, os, urllib.request
base, auth, modello = os.environ['BASE'], os.environ['AUTH'], os.environ['SCELTO']
dossier = open('missione/DOSSIER_SAGGIO.md').read()
req = urllib.request.Request(base + '/v1/chat/completions',
  data=json.dumps({"model": modello, "messages":[{"role":"user","content":dossier}],
                   "max_tokens": 4000, "temperature": 0.3}).encode(),
  headers={"Content-Type":"application/json","Authorization":"Bearer " + auth})
try:
    r = json.load(urllib.request.urlopen(req, timeout=300))
    testo = r["choices"][0]["message"]["content"]
    usato = r.get("model", modello)
except Exception as e:
    testo = "ERRORE: %s" % e; usato = modello
open('dal_pc/consiglio_saggio.md','w').write(
  "# TERZO PARERE - CONSIGLIERE SAGGIO\n- canale: %s\n- modello scelto: %s\n- modello effettivo: %s\n\n%s\n" % (base, modello, usato, testo))
PYEOF
git add dal_pc >/dev/null 2>&1; git commit -m "terzo parere saggio ($SCELTO via $BASE)" >/dev/null 2>&1
git pull --rebase >/dev/null 2>&1; git push >/dev/null 2>&1
echo "fatto: $SCELTO via $BASE"
