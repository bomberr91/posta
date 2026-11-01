#!/bin/bash
# DEPLOY JSON RICCO — CURA-AUDIT (1/11 sera): collaudo vero.
set -uo pipefail
cd ~/posta || exit 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=fatti/collaudo_cervello.sh
. "$DIR/fatti/collaudo_cervello.sh"

pkill -f '^python3 cervello\.py$' && echo "resurrezione col json ricco..." || echo "non girava"
collaudo || { echo "❌ COLLAUDO FALLITO: il Portiere NON funziona, il deploy NON è riuscito"; exit 1; }

echo "### campi nuovi su /portiere.json"
curl -fsS -m 20 "$CERVELLO_URL/portiere.json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
campi = [k for k in ('pagelle','castighi','uso_oggi','sentinella_avviso') if k in d]
assert campi, 'nessun campo nuovo: %s' % sorted(d)
print('   ✓ campi nuovi:', campi)
print('   ✓ pagelle:', len(d.get('pagelle', {})), '· castighi attivi:', len(d.get('castighi', {})))" || {
  echo "   ✗ il json ricco non c'è"; exit 1; }

echo "✅ DEPLOY JSON RICCO RIUSCITO"
