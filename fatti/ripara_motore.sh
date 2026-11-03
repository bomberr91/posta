#!/bin/bash
# ripara_motore.sh — il motore OmniRoute gira ma non tiene la porta 20128.
# Diagnostico + riavvio pulito, eseguito dal PC dal postino.
# Parla solo con lo stdout: il referto arriva in dal_pc/ripara_motore.md

echo "## Stato iniziale"
python3 - <<'PY'
import urllib.request
for path in ("/v1/models", "/", "/api/status"):
    try:
        urllib.request.urlopen("http://127.0.0.1:20128" + path, timeout=4).read()
        print(f"- 20128{path}: RISPONDE")
    except Exception as e:
        print(f"- 20128{path}: {type(e).__name__}")
PY
echo "- processi omniroute:"
ps -ef 2>/dev/null | grep -F "omniroute" | grep -v grep | sed -E 's/^[^ ]+ +[0-9]+ +[0-9]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[0-9:]+ +[0-9:]+ +//' | cut -c1-140 | sed 's/^/    /'

echo ""
echo "## Variabili d'ambiente del processo omniroute (porta/host)"
PID=$(pgrep -f 'node.*omniroute' | head -1)
if [ -n "$PID" ]; then
  tr '\0' '\n' < "/proc/$PID/environ" 2>/dev/null | grep -E "OMNIROUTE|PORT|HOST" | sed 's/=.*SECRET.*/=***/' | sed 's/^/    /' || echo "    (nessuna variabile leggibile)"
  echo "- porta dichiarata: $(tr '\0' '\n' < /proc/$PID/environ 2>/dev/null | grep -i 'PORT' | head -3 | tr '\n' ' ')"
else
  echo "    nessun processo node omniroute trovato"
fi

echo ""
echo "## Config di OmniRoute: porta dichiarata"
for f in "$HOME/.omniroute/config.json" "$HOME/.config/omniroute/config.json" "$HOME/.omniroute.json" "$HOME/.config/omniroute.json"; do
  [ -f "$f" ] && echo "- $f:" && grep -oE '"(port|host)"[[:space:]]*:[[:space:]]*[^,}]+' "$f" | sed 's/^/    /'
done

echo ""
echo "## Log di avvio (ultime 15 righe)"
for L in /tmp/scorta_motore.log "$HOME/posta/dal_pc/omni_start.log" /tmp/omni.log; do
  if [ -f "$L" ]; then
    echo "- $L:"
    tail -n 15 "$L" 2>/dev/null | cut -c1-200 | sed 's/^/    /'
  fi
done

echo ""
echo "## Riavvio del motore"
pkill -f 'node.*omniroute' >/dev/null 2>&1 || true
echo "- omniroute fermato; il guardiano lo riavvia entro 120 s"
for i in $(seq 1 30); do
  sleep 10
  if python3 - <<'PY' 2>/dev/null
import urllib.request
urllib.request.urlopen("http://127.0.0.1:20128/v1/models", timeout=4).read()
PY
  then
    echo "- porta 20128 RISPONDE dopo ~$((i*10)) s"
    break
  fi
done

echo ""
echo "## Stato finale"
python3 - <<'PY'
import urllib.request, json
try:
    d = json.loads(urllib.request.urlopen("http://127.0.0.1:20129/salute", timeout=5).read().decode())
    print("- portiere /salute:", json.dumps(d)[:300])
except Exception as e:
    print("- portiere /salute:", type(e).__name__)
try:
    r = urllib.request.urlopen("http://127.0.0.1:20128/v1/models", timeout=6).read().decode(errors="replace")
    print("- 20128/v1/models: RISPONDE,", len(r), "byte")
except Exception as e:
    print("- 20128/v1/models:", type(e).__name__)
PY
echo "- ultime righe /tmp/scorta_motore.log:"
tail -n 8 /tmp/scorta_motore.log 2>/dev/null | cut -c1-200 | sed 's/^/    /'
