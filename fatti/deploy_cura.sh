#!/bin/bash
# DEPLOY CURA — CURA-AUDIT (1/11 sera): collaudo vero e uscita onesta.
set -uo pipefail
cd ~/posta || exit 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=fatti/collaudo_cervello.sh
. "$DIR/fatti/collaudo_cervello.sh"

pkill -f '^python3 cervello\.py$' && echo "resurrezione con la cura..." || echo "non girava"
collaudo || { echo "❌ COLLAUDO FALLITO: il Portiere NON funziona, il deploy NON è riuscito"; exit 1; }

echo "### guardia solo-gratis (deve RIFIUTARE un modello a pagamento)"
curl -s -m 30 -H 'Content-Type: application/json' \
  -d '{"model":"gemini-2.5-pro","messages":[{"role":"user","content":"x"}]}' \
  "$CERVELLO_URL/v1/chat/completions" | python3 -c "
import json, sys
d = json.load(sys.stdin)
msg = (d.get('error') or {}).get('message', '')
assert 'solo-gratis' in msg, 'il modello a pagamento è passato: %s' % str(d)[:160]
print('   ✓ guardia solo-gratis attiva')" || {
  echo "   ✗ la guardia solo-gratis non funziona"; exit 1; }

echo "✅ DEPLOY CURA RIUSCITO"
