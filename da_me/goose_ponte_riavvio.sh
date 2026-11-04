#!/usr/bin/env bash
# goose_ponte_riavvio.sh — collauda goose con la chiave e riavvia il poller.
#
# Perche' serve (4/11): goose c'era ma senza chiave ("No provider configured"),
# e goose 1.55 non prende la chiave dal config.yaml (vuole keyring o env).
# Qui: (1) pull del repo, (2) TEST DIRETTO del wrapper con la chiave dal
# portachiavi, (3) riavvio del poller cosi' legge il nuovo ponte.json.
#
# Exit code onesto: 0 = goose funziona davvero.
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato ($REPO)"; exit 1; }

echo "### 1. PULL (il wrapper e' in lavori/ponte/)"
git pull --rebase --autostash 2>&1 | tail -3
echo "commit in testa: $(git log --oneline -1 2>/dev/null)"
echo "wrapper presente: $([ -f "$REPO/lavori/ponte/goose_run.sh" ] && echo si || echo NO)"
echo

echo "### 2. TEST DIRETTO DEL WRAPPER (senza passare dal poller)"
timeout 300 bash "$REPO/lavori/ponte/goose_run.sh" "Rispondi esattamente con la parola OK e nient'altro." 2>&1 | tail -40
RC=${PIPESTATUS[0]}
echo "--- exit wrapper: $RC"
echo

echo "### 3. RIAVVIO DEL POLLER (deve rileggere ponte.json)"
cd "$REPO/lavori/ponte" || exit 1
if pgrep -f 'python3 poller[.]py' >/dev/null 2>&1; then
  pkill -f 'python3 poller[.]py'
  sleep 3
  echo "poller fermato"
else
  echo "poller non era in giro"
fi
rm -f _stato/poller.lock
nohup python3 poller.py >> poller.log 2>&1 &
sleep 10
if pgrep -f 'python3 poller[.]py' >/dev/null 2>&1; then
  echo "poller riavviato (pid $(pgrep -f 'python3 poller[.]py' | head -1))"
else
  echo "ATTENZIONE: il poller non riparte (vedi poller.log)"
fi
echo

echo "### 4. COME ADESSO E' CONFIGURATO GOOSE NEL PONTE"
python3 - << 'PY'
import json
c = json.load(open("ponte.json", encoding="utf-8"))
g = c["agenti"]["goose"]
print("   cmd    :", g["cmd"])
print("   workdir:", g.get("workdir"))
PY
echo
if [ "$RC" -eq 0 ]; then
  echo "VERDETTO: GOOSE FUNZIONA (chiave OpenRouter dal portachiavi, modello nvidia/nemotron-3-ultra-550b-a55b:free)"
else
  echo "VERDETTO: GOOSE ANCORA NON FUNZIONA (exit $RC) — errore esatto qui sopra"
fi
exit "$RC"
