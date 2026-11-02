#!/bin/bash
D="[CHIAVE-RIMOSSA]"
echo "## 🕵️ IL MISTERO DEL CANE — $(date '+%H:%M')"
echo "### 1. La logica del Setup (web_app.py, cuore della validazione)"
sed -n '40,180p' "$D/web_app.py" | grep -vE "^\s*$" | head -60
echo
echo "### 2. Dove salva la scelta? C'è un file di setup persistito?"
grep -n "json.dump\|save\|setup.json\|SETUP" "$D/web_app.py" | head -10
ls "$D"/*.json "$D"/setup* 2>/dev/null
echo
echo "### 3. INTERROGO IL SERVER DAL VIVO (20 secondi)"
cd "$D"
nohup .venv/Scripts/python.exe web_app.py > /tmp/dd_live.log 2>&1 &
PID=$!
sleep 12
for EP in "/api/status" "/api/setup" "/status" "/api/config" "/api/state"; do
  R=$(curl -s -m 5 "http://127.0.0.1:8765$EP" | head -c 400)
  [ -n "$R" ] && echo "— $EP → $R"
done
kill $PID 2>/dev/null
echo
echo "### 4. log d'avvio del server"
head -20 /tmp/dd_live.log
