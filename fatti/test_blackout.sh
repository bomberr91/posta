#!/bin/bash
# TEST DEL BLACKOUT: IL CERVELLO DA SOLO — CURA-AUDIT v5 (1/11 sera):
# collauda per davvero e può dire FALLITO.
set -uo pipefail
cd ~/posta || exit 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=fatti/collaudo_cervello.sh
. "$DIR/fatti/collaudo_cervello.sh"
B="$CERVELLO_URL"

echo "## TEST DEL BLACKOUT: IL CERVELLO DA SOLO — $(date '+%H:%M')"
echo
echo "### 1. Spengo OmniRoute"
pkill -f omniroute 2>/dev/null && echo "spento" || echo "era gia' spento"
sleep 3
(exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null && echo "⚠ 20128 ANCORA VIVA" || echo "✓ porta 20128 MORTA — il cervello e' solo"
echo
leggi() { python3 -c "
import json, sys
d = json.load(sys.stdin)
msg = (d.get('choices') or [{}])[0].get('message', {}).get('content', '')
print(d.get('model', '?'), '→', (msg[:70].replace(chr(10), ' ') if msg else (d.get('error') or {}).get('message', '')[:110]))"; }
echo "### 2. auto (deve rispondere la RISERVA)"
curl -fsS -m 240 -H 'Content-Type: application/json' -d '{"model":"auto","max_tokens":40,"messages":[{"role":"user","content":"Il motore e morto. Chi mi sta rispondendo? Una frase."}]}' "$B/v1/chat/completions" | leggi || { echo "  ✗ auto non ha risposto"; exit 1; }
echo
echo "### 3. migliore (senza motore → riserva coi modelli FORTI)"
curl -fsS -m 240 -H 'Content-Type: application/json' -d '{"model":"migliore","max_tokens":40,"messages":[{"role":"user","content":"Quanto fa 17 per 23? Solo il numero."}]}' "$B/v1/chat/completions" | leggi || { echo "  ✗ migliore non ha risposto"; exit 1; }
echo
echo "### 4. gratis (solo keyless)"
curl -fsS -m 240 -H 'Content-Type: application/json' -d '{"model":"gratis","max_tokens":40,"messages":[{"role":"user","content":"Capitale della Francia? Una parola."}]}' "$B/v1/chat/completions" | leggi || { echo "  ✗ gratis non ha risposto"; exit 1; }
echo
echo "### 5. ping in casa + cache (2 volte stessa domanda)"
curl -fsS -m 60 -H 'Content-Type: application/json' -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' "$B/v1/chat/completions" | python3 -c "import json,sys; print('  ping →', json.load(sys.stdin).get('model','?'))" || { echo "  ✗ il ping non è passato"; exit 1; }
Q='{"model":"auto","max_tokens":30,"messages":[{"role":"user","content":"Colore del sole? Una parola."}]}'
curl -fsS -m 240 -H 'Content-Type: application/json' -d "$Q" "$B/v1/chat/completions" | python3 -c "import json,sys; print('  1ª:', json.load(sys.stdin).get('model','?'))" || { echo "  ✗ la prima non è passata"; exit 1; }
sleep 2
curl -fsS -m 240 -H 'Content-Type: application/json' -d "$Q" "$B/v1/chat/completions" | python3 -c "import json,sys; print('  2ª:', json.load(sys.stdin).get('model','?'))" || { echo "  ✗ la seconda non è passata"; exit 1; }
echo
echo "### 6. Chi ha lavorato (glass-box, ultime 8)"
tail -8 portiere_log.jsonl
echo
echo "### 7. /cervello"
curl -fsS -m 30 "$B/cervello" | python3 -c "import json,sys; d=json.load(sys.stdin); print('motore:', d.get('motore'), '· adesso:', d.get('adesso'), '· riserve pronte:', d.get('risponde'))" || { echo "  ✗ /cervello non risponde"; exit 1; }
echo
echo "### 8. COLLAUDO DI BASE (la porta aperta non basta: deve PARLARE)"
collaudo || { echo "❌ il cervello non passa il collaudo"; exit 1; }
echo
echo "✅ BLACKOUT SUPERATO: il cervello regge da solo"
