#!/usr/bin/env bash
# deepdog_cervello_collaudo.sh — 4/11 sera: collaudo meccanico di Deep Dog sul cervello.
#
# Perche' questo script: gli agenti (goose) hanno fatto le modifiche al codice
# (provider "cervello" in deep_research/config.py e nella web app) ma non sono
# riusciti a finire il collaudo (il wrapper non era eseguibile, e il wrapper
# usava `curl` che nella WSL del PC NON esiste -> l'ho corretto in python3).
# Qui si fa la parte meccanica, deterministica: si avvia il cane SE e solo SE
# non gira gia' (una sola finestra), si fa UNA ricerca vera e si guarda nei log
# del cervello se la chiamata e' passata da 127.0.0.1:20129.
#
# ATTENZIONE: NON si usa taskkill /IM python.exe (ammazzerebbe anche il cervello).
set -uo pipefail

REPO="$HOME/posta"
cd "$REPO" || { echo "repo non trovato"; exit 1; }
DD="/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog"
BAT='C:\Users\giopi\Documents\AgentWorkspace\deepdog\Avvia Deep Dog Web.bat'

echo "### 1. .env del cane: serve CERVELLO_API_KEY (e' la chiave fissa del portone)"
if grep -q "^CERVELLO_API_KEY" "$DD/.env" 2>/dev/null; then
  echo "CERVELLO_API_KEY gia' presente"
else
  printf 'CERVELLO_API_KEY=sk-cervello\n' >> "$DD/.env"
  echo "CERVELLO_API_KEY aggiunta al .env"
fi
grep -n "^CERVELLO_API_KEY" "$DD/.env" 2>/dev/null | sed 's/=.*/=«chiave mascherata»/'
grep -n "^OPENROUTER_API_KEY\|^DEEPSEEK_API_KEY" "$DD/.env" 2>/dev/null | sed 's/=.*/=«chiave mascherata»/' || true

echo
echo "### 2. il cane e' vivo? (se e' gia' vivo NON apro un'altra finestra)"
vivo() {
  python3 -c "import socket;s=socket.socket();s.settimeout(5);print('APERTA' if s.connect_ex(('127.0.0.1',8765))==0 else 'CHIUSA')" 2>/dev/null | grep -q APERTA
}
if vivo; then
  echo "il cane e' gia' vivo: non avvio un'altra finestra"
else
  echo "il cane non gira: lo avvio (una volta sola)"
  cmd.exe /c start "" "$BAT" >/dev/null 2>&1
  for i in $(seq 1 15); do
    sleep 5
    if vivo; then echo "cane avviato e vivo (~$((i*5))s)"; break; fi
  done
fi
if vivo; then echo "8765: APERTA"; else echo "8765: CHIUSA"; fi

echo
echo "### 3. i processi Windows di Deep Dog (dal lato WSL ps non si vedono)"
cmd.exe /c tasklist 2>/dev/null | grep -i "python.exe" | head -10 || echo "(tasklist non ha risposto)"

echo
echo "### 4. COLLAUDO REALE: una ricerca vera col wrapper (ora python3, non curl)"
bash "$REPO/lavori/deepdog_ricerca.sh" "che modelli offre il cervello locale?" > /tmp/deepdog_ricerca.txt 2>&1
ESITO=$?
echo "exit del wrapper: $ESITO"
tail -45 /tmp/deepdog_ricerca.txt

echo
echo "### 5. PROVA: la chiamata LLM e' passata dal cervello?"
echo "-- ultime righe del log del portiere (20129):"
tail -4 "$REPO/portiere_log.jsonl" 2>/dev/null | cut -c1-400
echo "-- stato del cane:"
python3 - << 'PYEOF'
import json, urllib.request
try:
    with urllib.request.urlopen("http://127.0.0.1:8765/api/status", timeout=10) as r:
        d = json.loads(r.read().decode("utf-8", "replace"))
    campi = ("status", "model_provider", "provider", "configured", "ready", "error")
    for c in campi:
        if c in d:
            print("   %-16s %s" % (c, str(d[c])[:200]))
except Exception as e:
    print("   /api/status non leggibile:", e)
PYEOF

echo
echo "### 6. verdetto"
if grep -q "127.0.0.1:20129" "$REPO/portiere_log.jsonl" 2>/dev/null; then
  echo "il cervello ha registrato richieste: il cane passa da lui"
else
  echo "nessuna richiesta al cervello nel log (potrebbe essere gia' stata registrata prima): guarda /api/status qui sopra"
fi
echo "FINE"
exit 0
