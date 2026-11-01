#!/bin/bash
# DEPLOY FASE 3 + RESURREZIONE — CURA-AUDIT (1/11 sera): collaudo vero.
set -uo pipefail
cd ~/posta || exit 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=fatti/collaudo_cervello.sh
. "$DIR/fatti/collaudo_cervello.sh"

echo "## DEPLOY FASE 3 + RESURREZIONE — $(date '+%H:%M')"
pkill -f '^python3 cervello\.py$' && echo "vecchio ucciso" || echo "non girava"
collaudo || { echo "❌ COLLAUDO FALLITO: il Portiere NON funziona, il deploy NON è riuscito"; exit 1; }

echo "### Moduli gemelli caricati?"
python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('c','cervello.py')
c = importlib.util.module_from_spec(spec); spec.loader.exec_module(c)
assert c.F3_OK, 'F3_OK è False: compressione e profili non sono caricati'
print('   ✓ F3_OK =', c.F3_OK)" || { echo "   ✗ i moduli gemelli non sono caricati"; exit 1; }

echo "### Sentinella: primo battito (baseline)"
sleep 1
python3 -c "
import json
d = json.load(open('portiere_stato.json'))
print('   sentinella:', d.get('sentinella', 'non ancora battuta (parte col primo traffico)'))" 2>/dev/null

echo "✅ DEPLOY FASE 3 RIUSCITO"
