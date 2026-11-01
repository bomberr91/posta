#!/bin/bash
# DEPLOY CORS — CURA-AUDIT (1/11 sera): collaudo vero e header verificato.
set -uo pipefail
cd ~/posta || exit 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=fatti/collaudo_cervello.sh
. "$DIR/fatti/collaudo_cervello.sh"

pkill -f '^python3 cervello\.py$' && echo "ucciso, il guardiano risuscita col CORS" || echo "non girava"
collaudo || { echo "❌ COLLAUDO FALLITO: il Portiere NON funziona, il deploy NON è riuscito"; exit 1; }

echo "### header CORS"
curl -s -D - -o /dev/null --max-time 10 "$CERVELLO_URL/cervello" 2>/dev/null \
  | grep -i "access-control-allow-origin" | head -1 \
  | grep -q . && echo "   ✓ CORS attivo" || { echo "   ✗ niente header CORS"; exit 1; }

echo "✅ DEPLOY CORS RIUSCITO"
