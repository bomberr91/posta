#!/bin/bash
# DEPLOY SENTINELLE-PAGINE — CURA-AUDIT (1/11 sera): collaudo vero.
set -uo pipefail
cd ~/posta || exit 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=fatti/collaudo_cervello.sh
. "$DIR/fatti/collaudo_cervello.sh"

pkill -f '^python3 cervello\.py$' && echo "resurrezione con gli occhi-pagina..." || echo "non girava"
collaudo || { echo "❌ COLLAUDO FALLITO: il Portiere NON funziona, il deploy NON è riuscito"; exit 1; }

echo "### azzeriamo il battito per far partire la sentinella"
python3 -c "
import json
d = json.load(open('portiere_stato.json'))
d.setdefault('sentinella', {})['controllo'] = 0
json.dump(d, open('portiere_stato.json','w'))" 2>/dev/null

pkill -f '^python3 cervello\.py$' 2>/dev/null
attendi || { echo "❌ il Portiere non è tornato"; exit 1; }
curl -fsS -m 60 -H 'Content-Type: application/json' \
  -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' \
  "$CERVELLO_URL/v1/chat/completions" >/dev/null 2>&1
sleep 8

echo "### occhi della sentinella"
python3 -c "
import json
st = json.load(open('portiere_stato.json')).get('sentinella', {})
occhi = st.get('visti', {})
pagine = [k for k in occhi if k.startswith('pg:')]
assert pagine, 'nessun occhio sulle pagine: %s' % sorted(occhi)
for k in sorted(occhi): print('   👁', k, '→', occhi[k])
print('   avviso:', st.get('avviso', 'nessuno (baseline presa)'))" || {
  echo "   ✗ gli occhi sulle pagine non ci sono"; exit 1; }

echo "✅ DEPLOY SENTINELLE-PAGINE RIUSCITO"
