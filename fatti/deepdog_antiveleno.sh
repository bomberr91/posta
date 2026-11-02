#!/bin/bash
D="[CHIAVE-RIMOSSA]"
echo "## 🐕 TOLGO L'ESCA AVVELENATA — $(date '+%H:%M')"
sed -i 's|^DEEPSEEK_API_KEY=.*|# DEEPSEEK_API_KEY= (chiave a saldo zero: PARCHEGGIATA, attirava il motore sulla via nativa vuota)|' "$D/.env"
grep -E "^[A-Z_#]" "$D/.env" | sed 's/=\(.\{6\}\).*/=\1•••/' | head -10
echo
echo "### prova dal vivo: avvio, lancio una MICRO-ricerca, leggo l'esito"
cd "$D"
nohup .venv/Scripts/python.exe web_app.py > /tmp/dd2.log 2>&1 &
PID=$!
sleep 10
curl -s -m 10 -X POST "http://127.0.0.1:8765/api/run" -H "Content-Type: application/json" -d '{"prompt":"What is Exa.ai in one paragraph?"}' | head -c 200
echo
sleep 45
curl -s -m 10 "http://127.0.0.1:8765/api/status" | python3 -c "
import json,sys
d = json.load(sys.stdin)
print('status:', d.get('status'), '| msg:', d.get('message'))
print('error:', (d.get('error') or 'NESSUNO')[:120])
print('eventi:', ' → '.join(d.get('events', [])[:6]))"
kill $PID 2>/dev/null
