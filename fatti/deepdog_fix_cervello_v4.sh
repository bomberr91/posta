#!/usr/bin/env bash
# deepdog_fix_cervello_v4.sh — 4/11 sera: sistemo Deep Dog in modo DETERMINISTICO.
#
# L'agente #39 e' bloccato da ~25 minuti (niente landing sul PC), quindi qui si fa
# il lavoro meccanico, con un solo script e nessuna esplorazione:
#  1. mostra il codice del setup (righe 55-115 di web_app.py) cosi' il resto
#     della patch e' preciso;
#  2. aggiunge il campo chiave del cervello (keyFields + input nella UI);
#  3. riavvia il cane (uccidendo SOLO il processo sulla 8765) cosi' prende il
#     default dal .env (CERVELLO_API_KEY -> model_provider "cervello");
#  4. imposta il provider "cervello" a runtime via /api/setup;
#  5. fa UNA ricerca vera col wrapper e mostra provider + log del portiere.
set -uo pipefail

REPO="$HOME/posta"
cd "$REPO" || { echo "repo non trovato"; exit 1; }
DD="/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog"
BAT='C:\Users\giopi\Documents\AgentWorkspace\deepdog\Avvia Deep Dog Web.bat'

echo "### 1. CODICE DEL SETUP (web_app.py righe 55-115)"
sed -n '55,115p' "$DD/web_app.py" 2>/dev/null
echo "-- keyFields e campi chiave:"
grep -n "keyFields\|deepseekKey\|openrouterKey\|cervelloKey\|CERVELLO" "$DD/web_app.py" 2>/dev/null | head -12

echo
echo "### 2. PATCH: campo chiave del cervello (backup .bak-<timestamp>)"
STAMP=$(date +%Y%m%d-%H%M%S)
cp -a "$DD/web_app.py" "$DD/web_app.py.bak-$STAMP" 2>/dev/null && echo "backup: web_app.py.bak-$STAMP"
python3 - "$DD/web_app.py" << 'PYEOF'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8", errors="replace").read()
orig = s

# a) keyFields: aggiungi la chiave del cervello
if "CERVELLO_API_KEY:['cervelloKey'" not in s:
    s = s.replace("const keyFields={DEEPSEEK_API_KEY:['deepseekKey','deepseekState']",
                  "const keyFields={CERVELLO_API_KEY:['cervelloKey','cervelloState'],DEEPSEEK_API_KEY:['deepseekKey','deepseekState']")

# b) input nella UI per la chiave del cervello (accanto a quello OpenRouter)
if 'id="cervelloKey"' not in s:
    campo = ('<div class="field"><label for="cervelloKey">Cervello locale (portone 20129) '
             '<small>(opzionale: passa le richieste al cervello)</small></label>'
             '<div class="key-wrap"><input id="cervelloKey" type="password" autocomplete="off" '
             'placeholder="sk-…"><span id="cervelloState" class="key-state">non impostata</span></div></div>')
    m = re.search(r'<div class="field"><label for="openrouterKey">.*?</div></div>', s, re.S)
    if m:
        s = s[:m.end()] + campo + s[m.end():]
    else:
        print("   (campo openrouterKey non trovato: campo del cervello NON aggiunto)")
open(p, "w", encoding="utf-8").write(s)
print("   web_app.py modificata" if s != orig else "   web_app.py gia' a posto")
print("   cervelloKey presente:", 'id="cervelloKey"' in s,
      "| keyFields con CERVELLO:", "CERVELLO_API_KEY:['cervelloKey'" in s)
PYEOF

echo
echo "### 3. RIAVVIO del cane (uccido SOLO chi ascolta sulla 8765)"
PID=$(cmd.exe /c netstat -ano 2>/dev/null | grep -E "[:.]8765\s" | grep LISTENING | awk '{print $NF}' | head -1 | tr -d '\r')
echo "   PID sulla 8765: ${PID:-nessuno}"
if [ -n "${PID:-}" ]; then cmd.exe /c taskkill /F /PID "$PID" >/dev/null 2>&1 || true; sleep 3; fi
cmd.exe /c start "" "$BAT" >/dev/null 2>&1
for i in $(seq 1 15); do
  sleep 5
  if python3 -c "import socket;s=socket.socket();s.settimeout(5);raise SystemExit(0 if s.connect_ex(('127.0.0.1',8765))==0 else 1)" 2>/dev/null; then
    echo "   cane vivo (~$((i*5))s)"; break
  fi
done

echo
echo "### 4. /api/setup con il provider 'cervello'"
python3 - << 'PYEOF'
import json, urllib.request
req = urllib.request.Request("http://127.0.0.1:8765/api/setup",
                             data=json.dumps({"keys": {"CERVELLO_API_KEY": "sk-cervello"},
                                              "model_provider": "cervello"}).encode("utf-8"),
                             headers={"Content-Type": "application/json"}, method="POST")
try:
    with urllib.request.urlopen(req, timeout=90) as r:
        print("   ->", r.status, r.read().decode("utf-8", "replace")[:400])
except Exception as e:
    body = ""
    try:
        body = e.read().decode("utf-8", "replace")[:300]
    except Exception:
        pass
    print("   -> FALLITO:", e, body)
PYEOF

echo
echo "### 5. STATO"
python3 - << 'PYEOF'
import json, urllib.request
try:
    with urllib.request.urlopen("http://127.0.0.1:8765/api/status", timeout=15) as r:
        d = json.loads(r.read().decode("utf-8", "replace"))
    for c in ("status", "model_provider", "search_provider", "speed_profile", "configured", "ready", "missing", "error"):
        if c in d:
            print("   %-16s %s" % (c, str(d[c])[:250]))
except Exception as e:
    print("   non leggibile:", e)
PYEOF

echo
echo "### 6. COLLAUDO REALE (wrapper col python3)"
bash "$REPO/lavori/deepdog_ricerca.sh" "che modelli offre il cervello locale?" > /tmp/deepdog_ricerca4.txt 2>&1
echo "exit del wrapper: $?"
tail -35 /tmp/deepdog_ricerca4.txt

echo
echo "### 7. LOG DEL PORTIERE (ultime righe)"
tail -5 "$REPO/portiere_log.jsonl" 2>/dev/null | cut -c1-250
echo "FINE"
exit 0
