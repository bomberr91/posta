#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
OUT=dal_pc/consiglio_saggio.md
KEY="sk-be311327ce941004-4df42c-cf76ba39"
MODELS=$(curl -s -m 10 -H "Authorization: Bearer $KEY" http://127.0.0.1:20128/v1/models)
SCELTO=""
for pat in "claude-sonnet" "claude" "deepseek-v4-pro" "deepseek-v4" "glm-5" "kimi-k3" "kimi" "qwen3-max" "qwen3" "deepseek"; do
  SCELTO=$(echo "$MODELS" | grep -oE '"id" *: *"[^"]*'"$pat"'[^"]*"' | head -1 | sed 's/.*: *"//; s/"$//')
  [ -n "$SCELTO" ] && break
done
[ -z "$SCELTO" ] && SCELTO="auto"
python3 - "$SCELTO" << 'PYEOF'
import json, sys, urllib.request
modello = sys.argv[1]
dossier = open('missione/DOSSIER_SAGGIO.md').read()
req = urllib.request.Request('http://127.0.0.1:20128/v1/chat/completions',
  data=json.dumps({"model": modello, "messages":[{"role":"user","content":dossier}],
                   "max_tokens": 4000, "temperature": 0.3}).encode(),
  headers={"Content-Type":"application/json","Authorization":"Bearer sk-be311327ce941004-4df42c-cf76ba39"})
try:
    r = json.load(urllib.request.urlopen(req, timeout=300))
    testo = r["choices"][0]["message"]["content"]
    usato = r.get("model", modello)
except Exception as e:
    testo = f"ERRORE: {e}"; usato = modello
open('dal_pc/consiglio_saggio.md','w').write(
  f"# TERZO PARERE — CONSIGLIERE SAGGIO\n- modello scelto: {modello}\n- modello effettivo: {usato}\n\n{testo}\n")
PYEOF
git add dal_pc missione >/dev/null 2>&1; git commit -m "terzo parere del saggio ($SCELTO)" >/dev/null 2>&1
git pull --rebase >/dev/null 2>&1; git push >/dev/null 2>&1
echo "fatto: modello $SCELTO"
