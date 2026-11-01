#!/bin/bash
# STATO DEGLI INVISIBILI — CURA-AUDIT v5 (1/11 sera): collauda per davvero.
set -uo pipefail
cd ~/posta || exit 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=fatti/collaudo_cervello.sh
. "$DIR/fatti/collaudo_cervello.sh"

echo "## STATO DEGLI INVISIBILI — $(date '+%H:%M')"
echo "(se stai leggendo questo, IL POSTINO INVISIBILE FUNZIONA ✓)"
echo
echo "### Porte"
(exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && echo "🟢 cervello :20129 vivo" || echo "🔴 cervello :20129 SPENTO"
(exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null && echo "🟢 OmniRoute :20128 vivo" || echo "🟡 OmniRoute :20128 ancora in avvio (o spento)"
echo
echo "### Processi guardiani e figli"
ps aux | grep -E "flock|postino\.sh --loop|cervello\.p[y]|omnirout[e]" | grep -v grep | awk '{printf "  pid %s · %s\n", $2, substr($0, index($0,$11), 90)}' | head -10
echo
echo "### Il cervello che dice"
curl -fsS -m 30 "$CERVELLO_URL/cervello" | python3 -c "import json,sys; d=json.load(sys.stdin); print('  motore:', d.get('motore'), '· adesso:', d.get('adesso'))" || { echo "  ❌ /cervello non risponde"; exit 1; }
echo
echo "### COLLAUDO (la porta aperta non basta: deve PARLARE)"
collaudo || { echo "❌ il cervello non passa il collaudo"; exit 1; }
echo
echo "✅ STATO RACCONTATO (tutto bene)"
