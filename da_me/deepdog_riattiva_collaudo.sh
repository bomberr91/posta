#!/usr/bin/env bash
# deepdog_riattiva_collaudo.sh — 4/11 sera (v2): Deep Dog sul cervello, collaudo vero.
#
# Cosa e' emerso dal collaudo precedente: la richiesta del cane e' andata a
# OPENROUTER (errore 402 "requires more credits ... openrouter.ai"), non al
# cervello. Motivo: il cane era gia' avviato PRIMA che nel .env ci fosse
# CERVELLO_API_KEY, quindi il suo default era rimasto "openrouter".
#
# La web app di Deep Dog ha gia' un endpoint /api/setup (e' quello che usa la
# card "Setup" della UI: "Collega modelli e ricerca. Le chiavi restano in
# memoria solo durante questa sessione"). Si usa QUELLO: si imposta il provider
# "cervello" a runtime, senza ammazzare processi e senza aprire finestre CMD.
# Il .env (CERVELLO_API_KEY) fa da default per i prossimi avvii.
set -uo pipefail

REPO="$HOME/posta"
cd "$REPO" || { echo "repo non trovato"; exit 1; }
DD="/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog"

echo "### 1. stato attuale del cane (/api/status)"
python3 - << 'PYEOF'
import json, urllib.request
def get(path):
    try:
        with urllib.request.urlopen("http://127.0.0.1:8765" + path, timeout=15) as r:
            return r.read().decode("utf-8", "replace")
    except Exception as e:
        return "ERRORE: %s" % e
raw = get("/api/status")
print(raw[:1500])
try:
    d = json.loads(raw)
except Exception:
    d = {}
json.dump(d, open("/tmp/deepdog_status.json", "w"))
PYEOF

echo
echo "### 2. imposto il provider 'cervello' a runtime (/api/setup)"
python3 - << 'PYEOF'
import json, urllib.request
try:
    d = json.load(open("/tmp/deepdog_status.json"))
except Exception:
    d = {}
payload = {
    "keys": {"cervello": "sk-cervello"},
    "model_provider": "cervello",
    "search_provider": d.get("search_provider") or "tavily",
    "speed_profile": d.get("speed_profile") or "standard",
}
req = urllib.request.Request("http://127.0.0.1:8765/api/setup",
                             data=json.dumps(payload).encode("utf-8"),
                             headers={"Content-Type": "application/json"}, method="POST")
try:
    with urllib.request.urlopen(req, timeout=60) as r:
        print("POST /api/setup ->", r.status, r.read().decode("utf-8", "replace")[:800])
except Exception as e:
    body = ""
    try:
        body = e.read().decode("utf-8", "replace")[:500]
    except Exception:
        pass
    print("POST /api/setup FALLITO:", e, body)
PYEOF

echo
echo "### 3. stato dopo il setup"
python3 - << 'PYEOF'
import json, urllib.request
try:
    with urllib.request.urlopen("http://127.0.0.1:8765/api/status", timeout=15) as r:
        d = json.loads(r.read().decode("utf-8", "replace"))
    for c in ("status", "model_provider", "provider", "configured", "ready", "missing", "error"):
        if c in d:
            print("   %-16s %s" % (c, str(d[c])[:300]))
except Exception as e:
    print("   /api/status non leggibile:", e)
PYEOF

echo
echo "### 4. COLLAUDO REALE: una ricerca vera col wrapper"
bash "$REPO/lavori/deepdog_ricerca.sh" "che modelli offre il cervello locale?" > /tmp/deepdog_ricerca2.txt 2>&1
echo "exit del wrapper: $?"
tail -40 /tmp/deepdog_ricerca2.txt

echo
echo "### 5. PROVA: la chiamata e' passata dal cervello (127.0.0.1:20129)?"
echo "-- ultime righe del log del portiere:"
tail -5 "$REPO/portiere_log.jsonl" 2>/dev/null | cut -c1-300
echo "-- provider usato dal cane:"
python3 - << 'PYEOF'
import json, urllib.request
try:
    with urllib.request.urlopen("http://127.0.0.1:8765/api/status", timeout=15) as r:
        d = json.loads(r.read().decode("utf-8", "replace"))
    print("   model_provider:", d.get("model_provider"))
    print("   status:", d.get("status"), "| error:", str(d.get("error"))[:300])
except Exception as e:
    print("   non leggibile:", e)
PYEOF
echo "FINE"
exit 0
