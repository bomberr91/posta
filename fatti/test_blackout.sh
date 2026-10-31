#!/bin/bash
cd ~/posta
B=http://127.0.0.1:20129
echo "## TEST DEL BLACKOUT: IL CERVELLO DA SOLO — $(date '+%H:%M')"
echo
echo "### 1. Spengo OmniRoute"
pkill -f omniroute 2>/dev/null && echo "spento" || echo "era gia' spento"
sleep 3
(exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null && echo "⚠ 20128 ANCORA VIVA" || echo "✓ porta 20128 MORTA — il cervello e' solo"
echo
leggi() { python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model','?'),'→',(d.get('choices') or [{}])[0].get('message',{}).get('content','')[:70].replace(chr(10),' ') or d.get('error',{}).get('message','')[:110])"; }
echo "### 2. auto (deve rispondere la RISERVA)"
curl -s -m 120 -H Content-Type:application/json -d '{"model":"auto","max_tokens":40,"messages":[{"role":"user","content":"Il motore e morto. Chi mi sta rispondendo? Una frase."}]}' $B/v1/chat/completions | leggi
echo
echo "### 3. migliore (senza motore → riserva coi modelli FORTI)"
curl -s -m 120 -H Content-Type:application/json -d '{"model":"migliore","max_tokens":40,"messages":[{"role":"user","content":"Quanto fa 17 per 23? Solo il numero."}]}' $B/v1/chat/completions | leggi
echo
echo "### 4. gratis (solo keyless)"
curl -s -m 120 -H Content-Type:application/json -d '{"model":"gratis","max_tokens":40,"messages":[{"role":"user","content":"Capitale della Francia? Una parola."}]}' $B/v1/chat/completions | leggi
echo
echo "### 5. ping in casa + cache (2 volte stessa domanda)"
curl -s -m 20 -H Content-Type:application/json -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' $B/v1/chat/completions | python3 -c "import json,sys; print(json.load(sys.stdin).get('model','?'))"
Q='{"model":"auto","max_tokens":30,"messages":[{"role":"user","content":"Colore del sole? Una parola."}]}'
curl -s -m 120 -H Content-Type:application/json -d "$Q" $B/v1/chat/completions | python3 -c "import json,sys; print('1ª:', json.load(sys.stdin).get('model','?'))"
sleep 2
curl -s -m 60 -H Content-Type:application/json -d "$Q" $B/v1/chat/completions | python3 -c "import json,sys; print('2ª:', json.load(sys.stdin).get('model','?'))"
echo
echo "### 6. Chi ha lavorato (glass-box, ultime 8)"
tail -8 portiere_log.jsonl
echo
echo "### 7. /cervello"
curl -s -m 10 $B/cervello | python3 -c "import json,sys; d=json.load(sys.stdin); print('motore:', d.get('motore'), '· adesso:', d.get('adesso'), '· riserve pronte:', d.get('risponde'))"
