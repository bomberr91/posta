#!/bin/bash
echo "## ☀️ RAPPORTO DEL MATTINO — $(date '+%d/%m %H:%M')"
echo
echo "### 1. I tre invisibili si sono alzati da soli? (PRIMO TEST VERO del boot!)"
(exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && echo "🟢 cervello :20129" || echo "🔴 cervello GIÙ"
(exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null && echo "🟢 OmniRoute :20128" || echo "🟡 OmniRoute giù/in avvio"
echo "📬 postino: se leggi questo, è vivo (ha consegnato lui)"
echo
echo "### 2. Targa e stato del cervello"
curl -s -m 10 http://127.0.0.1:20129/portiere | grep -o "FASE 3" | head -1
curl -s -m 10 http://127.0.0.1:20129/cervello | python3 -c "import json,sys; d=json.load(sys.stdin); print('motore:', d.get('motore'), '· adesso:', d.get('adesso'), '· riserve:', d.get('risponde'))" 2>&1
echo
echo "### 3. Sveglio la sentinella (primo battito del giorno) e controllo avvisi"
curl -s -m 15 -H Content-Type:application/json -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' http://127.0.0.1:20129/v1/chat/completions > /dev/null
sleep 5
cd ~/posta
python3 -c "
import json
st = json.load(open('portiere_stato.json')).get('sentinella', {})
print('occhi:', list(st.get('visti', {}).items()))
print('📡 avviso:', st.get('avviso', 'nessuno — fonti ferme, quote valide'))"
echo
echo "### 4. Castighi pendenti dalla notte"
python3 cervello.py --perdona > /dev/null 2>&1 && echo "amnistia mattutina data (i castighi di ieri non valgono oggi)"
