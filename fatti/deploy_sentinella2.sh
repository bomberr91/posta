#!/bin/bash
# DEPLOY SENTINELLA 2 OCCHI — CURA-AUDIT (1/11 sera): collaudo vero.
set -uo pipefail
cd ~/posta || exit 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=fatti/collaudo_cervello.sh
. "$DIR/fatti/collaudo_cervello.sh"

echo "## DEPLOY SENTINELLA 2 OCCHI — $(date '+%H:%M')"
pkill -f '^python3 cervello\.py$' && echo "ucciso" || echo "non girava"
collaudo || { echo "❌ COLLAUDO FALLITO: il Portiere NON funziona, il deploy NON è riuscito"; exit 1; }

sleep 3
echo "### Stato sentinella (deve avere 2 repo in 'visti')"
python3 -c "
import json
st = json.load(open('portiere_stato.json')).get('sentinella', {})
visti = st.get('visti', {})
assert len(visti) >= 2, 'occhio solo %d, ne servono 2: %s' % (len(visti), sorted(visti))
print('   ✓ occhi:', sorted(visti))
print('   avviso attivo:', st.get('avviso', 'nessuno (normale: baseline)'))" || {
  echo "   ✗ la sentinella non ha i due occhi"; exit 1; }

echo "✅ DEPLOY SENTINELLA RIUSCITO"
