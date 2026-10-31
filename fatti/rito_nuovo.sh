#!/bin/bash
cd ~/posta
echo "## RITO NUOVO + COLLAUDO INTERRUTTORE — $(date '+%H:%M')"
echo
echo "### 1. Ammazzo il cervello vecchio (il guardiano lo risusciterà col codice nuovo)"
pkill -f '^python3 cervello\.py$' && echo "ucciso" || echo "non girava"
echo "aspetto il guardiano (max 75s)..."
for i in $(seq 1 15); do
  sleep 5
  (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && { echo "risorto dopo ~$((i*5))s"; break; }
done
sleep 2
echo
echo "### 2. Interruttore SPENTO (file assente) → motore usato"
rm -f SOLO_CERVELLO.txt
curl -s -m 10 http://127.0.0.1:20129/cervello | python3 -c "import json,sys; d=json.load(sys.stdin); print('  interruttore:', d.get('interruttore_solo_cervello'), '· motore:', d.get('motore'), '· adesso:', d.get('adesso'))"
echo
echo "### 3. ACCENDO l'interruttore (creo SOLO_CERVELLO.txt) → motore ignorato"
echo "il capo comanda" > SOLO_CERVELLO.txt
curl -s -m 10 http://127.0.0.1:20129/cervello | python3 -c "import json,sys; d=json.load(sys.stdin); print('  interruttore:', d.get('interruttore_solo_cervello'), '· motore:', d.get('motore'), '· adesso:', d.get('adesso'))"
curl -s -m 120 -H Content-Type:application/json -d '{"model":"auto","max_tokens":30,"messages":[{"role":"user","content":"OmniRoute e acceso ma io ti ignoro. Chi risponde? Breve."}]}' http://127.0.0.1:20129/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print('  richiesta auto →', d.get('model','?'))"
echo
echo "### 4. RISPENGO l'interruttore (torna il motore)"
rm -f SOLO_CERVELLO.txt
curl -s -m 10 http://127.0.0.1:20129/cervello | python3 -c "import json,sys; d=json.load(sys.stdin); print('  interruttore:', d.get('interruttore_solo_cervello'), '· motore:', d.get('motore'), '· adesso:', d.get('adesso'))"
