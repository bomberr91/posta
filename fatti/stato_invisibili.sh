#!/bin/bash
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
curl -s -m 10 http://127.0.0.1:20129/cervello | python3 -c "import json,sys; d=json.load(sys.stdin); print('  motore:', d.get('motore'), '· adesso:', d.get('adesso'))" 2>&1
