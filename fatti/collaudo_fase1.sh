#!/bin/bash
# Collaudo FASE 1 dal vivo sul PC — CURA-AUDIT v5 (1/11 sera):
# ogni passo verifica davvero e l'uscita dice NO se qualcosa non torna.
set -uo pipefail
cd ~/posta || exit 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=fatti/collaudo_cervello.sh
. "$DIR/fatti/collaudo_cervello.sh"
B="$CERVELLO_URL"

echo "## COLLAUDO FASE 1 SUL PC — $(date '+%H:%M')"
echo
echo "### 0. COLLAUDO DI BASE (il cervello deve parlare)"
collaudo || { echo "❌ il cervello non passa il collaudo di base"; exit 1; }
echo
echo "### 1. Politiche in /v1/models (devono esserci auto/gratis/veloce/migliore)"
curl -fsS -m 30 "$B/v1/models" | python3 -c "
import json, sys
d = json.load(sys.stdin)
ids = [m['id'] for m in d.get('data', [])]
for p in ('auto', 'gratis', 'veloce', 'migliore'):
    assert p in ids, 'manca la politica %s: %s' % (p, ids[:12])
print('  ✓ politiche presenti:', [p for p in ('auto','gratis','veloce','migliore') if p in ids])" || {
  echo "  ✗ le politiche non ci sono"; exit 1; }
echo
echo "### 2. Ping risposto in casa (deve dire cervello/locale, 0 token)"
curl -fsS -m 60 -H 'Content-Type: application/json' -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' "$B/v1/chat/completions" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d.get('model','').startswith('cervello/locale'), 'il ping non è stato risposto in casa: %s' % d.get('model')
assert (d.get('usage') or {}).get('total_tokens') == 0, 'il ping ha speso token'
print('  ✓', d.get('model'), '→', d['choices'][0]['message']['content'])" || {
  echo "  ✗ il ping non è risposto in casa"; exit 1; }
echo
echo "### 3. Guardia solo-gratis (gpt-5 deve essere rifiutato)"
curl -s -m 60 -H 'Content-Type: application/json' -d '{"model":"gpt-5","messages":[{"role":"user","content":"x"}]}' "$B/v1/chat/completions" | python3 -c "
import json, sys
d = json.load(sys.stdin)
msg = (d.get('error') or {}).get('message', '')
assert 'solo-gratis' in msg, 'il modello a pagamento è passato: %s' % str(d)[:160]
print('  ✓ guardia solo-gratis attiva')" || {
  echo "  ✗ la guardia solo-gratis non funziona"; exit 1; }
echo
echo "### 4. Sonda credenziali (zero token)"
timeout 300 python3 cervello.py --sonda 2>&1
echo
echo "### 5. Glass-box: ultime righe del log"
tail -5 portiere_log.jsonl 2>/dev/null || echo "(log ancora vuoto: normale se nessuna richiesta vera è passata)"
echo
echo "✅ COLLAUDO FASE 1 RIUSCITO"
