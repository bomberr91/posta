#!/usr/bin/env bash
# deepdog_riattiva_collaudo2.sh — 4/11 sera (v3): Deep Dog sul cervello, collaudo vero.
#
# Lo stato: il cane chiama ancora OPENROUTER (402 "requires more credits") perche'
# la sessione e' partita prima che nel .env ci fosse CERVELLO_API_KEY. Il POST
# /api/setup precedente e' stato respinto con 400 "Opzione di setup non valida"
# (i valori di search_provider/speed_profile inviati non erano validi).
#
# Questa versione:
#  1. legge nella web app le opzioni valide del setup;
#  2. prova il POST /api/setup con i valori giusti (e, se fallisce, con un
#     payload minimale);
#  3. se resta sul vecchio provider, RIAVVIA il cane (uccidendo SOLO il processo
#     che ascolta sulla porta 8765, mai "taskkill /IM python.exe": il cervello
#     gira in WSL, ma la regola vale lo stesso);
#  4. fa UNA ricerca vera e guarda nei log se la chiamata passa da 20129.
set -uo pipefail

REPO="$HOME/posta"
cd "$REPO" || { echo "repo non trovato"; exit 1; }
DD="/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog"
BAT='C:\Users\giopi\Documents\AgentWorkspace\deepdog\Avvia Deep Dog Web.bat'

echo "### 1. opzioni di setup che la web app accetta"
grep -n "speed_profile\|search_profile\|search_provider\|SPEED_PROFILES\|SEARCH_PROVIDERS\|Opzione di setup" \
  "$DD/web_app.py" 2>/dev/null | head -25
echo "-- chiavi riconosciute:"
grep -n "keyFields\|openrouterKey\|cervelloKey\|deepseekKey" "$DD/web_app.py" 2>/dev/null | head -10

echo
echo "### 2. stato prima"
python3 - << 'PYEOF'
import json, urllib.request
def get():
    try:
        with urllib.request.urlopen("http://127.0.0.1:8765/api/status", timeout=15) as r:
            return json.loads(r.read().decode("utf-8", "replace"))
    except Exception as e:
        return {"errore": str(e)}
d = get()
for c in ("status", "model_provider", "search_provider", "speed_profile", "configured", "ready", "error"):
    if c in d:
        print("   %-16s %s" % (c, str(d[c])[:250]))
json.dump(d, open("/tmp/dd_status.json", "w"))
PYEOF

echo
echo "### 3. POST /api/setup con il provider 'cervello'"
python3 - << 'PYEOF'
import json, urllib.request

def post(payload):
    req = urllib.request.Request("http://127.0.0.1:8765/api/setup",
                                 data=json.dumps(payload).encode("utf-8"),
                                 headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except Exception as e:
        body = ""
        try:
            body = e.read().decode("utf-8", "replace")[:400]
        except Exception:
            pass
        return "ERRORE", "%s %s" % (e, body)

varianti = [
    {"keys": {"cervello": "sk-cervello"}, "model_provider": "cervello"},
    {"keys": {"cervello": "sk-cervello"}, "model_provider": "cervello",
     "search_provider": "tavily", "speed_profile": "standard"},
    {"keys": {"cervello": "sk-cervello"}, "model_provider": "cervello",
     "search_provider": "tavily", "speed_profile": "balanced"},
]
for v in varianti:
    st, txt = post(v)
    print("   payload %s -> %s %s" % (sorted(v.keys()), st, txt[:300]))
    if st == 200:
        break
PYEOF

echo
echo "### 4. stato dopo il setup"
python3 - << 'PYEOF'
import json, urllib.request
try:
    with urllib.request.urlopen("http://127.0.0.1:8765/api/status", timeout=15) as r:
        d = json.loads(r.read().decode("utf-8", "replace"))
    print("   model_provider:", d.get("model_provider"), "| status:", d.get("status"))
except Exception as e:
    print("   non leggibile:", e)
PYEOF

echo
echo "### 5. se il cane e' ancora sul vecchio provider: riavvio (uccido SOLO chi sta sulla 8765)"
PID=$(cmd.exe /c netstat -ano 2>/dev/null | grep -E "[:.]8765\s" | grep LISTENING | awk '{print $NF}' | head -1 | tr -d '\r')
echo "   processo in ascolto sulla 8765: ${PID:-nessuno}"
if [ -n "${PID:-}" ]; then
  echo "   uccido il PID $PID (il cane) e riavvio"
  cmd.exe /c taskkill /F /PID "$PID" >/dev/null 2>&1 || true
  sleep 3
  cmd.exe /c start "" "$BAT" >/dev/null 2>&1
  for i in $(seq 1 15); do
    sleep 5
    if python3 -c "import socket;s=socket.socket();s.settimeout(5);raise SystemExit(0 if s.connect_ex(('127.0.0.1',8765))==0 else 1)" 2>/dev/null; then
      echo "   cane di nuovo vivo (~$((i*5))s)"; break
    fi
  done
else
  echo "   nessun processo in ascolto: avvio il cane"
  cmd.exe /c start "" "$BAT" >/dev/null 2>&1
fi

echo
echo "### 6. COLLAUDO REALE: una ricerca vera col wrapper"
bash "$REPO/lavori/deepdog_ricerca.sh" "che modelli offre il cervello locale?" > /tmp/deepdog_ricerca3.txt 2>&1
echo "exit del wrapper: $?"
tail -40 /tmp/deepdog_ricerca3.txt

echo
echo "### 7. PROVA finale: provider usato e log del portiere"
python3 - << 'PYEOF'
import json, urllib.request
try:
    with urllib.request.urlopen("http://127.0.0.1:8765/api/status", timeout=15) as r:
        d = json.loads(r.read().decode("utf-8", "replace"))
    print("   model_provider:", d.get("model_provider"))
    print("   status:", d.get("status"), "| error:", str(d.get("error"))[:250])
except Exception as e:
    print("   non leggibile:", e)
PYEOF
echo "-- ultime righe del log del portiere:"
tail -4 "$REPO/portiere_log.jsonl" 2>/dev/null | cut -c1-250
echo "FINE"
exit 0
