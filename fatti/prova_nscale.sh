#!/usr/bin/env bash
# prova_nscale.sh — verifica mirata di Nscale (2/11 sera).
# 1) GET /v1/models con la chiave del portachiavi
# 2) POST /v1/chat/completions: una domanda vera, e l'esito si decide sul CORPO
#    (un 200 con HTML non prova niente).
set -u
QUI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"

KEY=$(python3 "$QUI/chiave_di.py" "Nscale" 2>/dev/null)
if [ -z "${KEY:-}" ]; then
  echo "Nscale: NESSUNA CHIAVE nel portachiavi"
  exit 1
fi
echo "Nscale: chiave trovata, ${#KEY} caratteri"

echo "--- 1) elenco modelli ---"
curl -s --max-time 60 -H "Authorization: Bearer $KEY" -H "User-Agent: $UA" \
  "https://inference.api.nscale.com/v1/models" -o /tmp/ns_models.json \
  -w "http=%{http_code}\n"
python3 -c "
import json
try:
    d = json.load(open('/tmp/ns_models.json'))
    print('modelli nel catalogo:', len(d.get('data', [])))
except Exception as e:
    print('catalogo non leggibile:', e)
"

echo "--- 2) chat vera ---"
curl -s --max-time 90 -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -H "User-Agent: $UA" \
  -d '{"model":"Qwen/Qwen3-4B-Instruct-2507","messages":[{"role":"user","content":"Reply with exactly: OK"}],"max_tokens":32}' \
  "https://inference.api.nscale.com/v1/chat/completions" -o /tmp/ns_chat.json \
  -w "http=%{http_code} tempo=%{time_total}s\n"
python3 -c "
import json
try:
    d = json.load(open('/tmp/ns_chat.json'))
    txt = ''
    try:
        txt = (d.get('choices') or [{}])[0].get('message', {}).get('content', '') or ''
    except Exception:
        pass
    if txt.strip():
        print('RISPOSTA:', txt.strip()[:120])
        print('NSCALE: RISOLTO')
    else:
        print('NSCALE: nessun testo utile ->', json.dumps(d)[:200])
except Exception as e:
    print('NSCALE: corpo non JSON ->', e)
"
