#!/usr/bin/env bash
# goose_via_cervello_applica.sh — porta il wrapper di goose sul cervello e lo collauda.
#
# 4/11: goose non deve piu' usare la chiave OpenRouter (accavallamento col
# roster del cervello). Il wrapper nuovo parla col cervello locale (20129)
# con la chiave finta "sk-cervello": zero chiavi provider toccate.
# Qui: pull, verifica del file, TEST REALE del wrapper, riavvio del poller.
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato ($REPO)"; exit 1; }

echo "### 1. PULL"
git pull --rebase --autostash 2>&1 | tail -3
echo "commit in testa: $(git log --oneline -1 2>/dev/null)"
echo

echo "### 2. IL WRAPPER (deve dire 'via cervello locale' e NON contenere OPENROUTER_API_KEY)"
W="$REPO/lavori/ponte/goose_run.sh"
if [ ! -f "$W" ]; then echo "wrapper mancante: $W"; exit 1; fi
grep -n -E "OPENROUTER|cervello locale|GOOSE_PROVIDER|OPENAI_HOST" "$W" | head -8
if grep -q "OPENROUTER_API_KEY" "$W"; then
  echo "⚠ il wrapper contiene ancora OPENROUTER_API_KEY"
else
  echo "✓ nessuna chiave OpenRouter nel wrapper"
fi
echo

echo "### 3. TEST REALE DEL WRAPPER (col cervello)"
timeout 300 bash "$W" "Rispondi esattamente con la parola OK e nient'altro." 2>&1 | tail -25
RC=${PIPESTATUS[0]}
echo "--- exit wrapper: $RC"
echo

echo "### 4. RIAVVIO DEL POLLER (per sicurezza, cosi' riparte pulito)"
cd "$REPO/lavori/ponte" || exit 1
if pgrep -f 'python3 poller[.]py' >/dev/null 2>&1; then
  pkill -f 'python3 poller[.]py'
  sleep 3
  echo "poller fermato"
fi
rm -f _stato/poller.lock
nohup python3 poller.py >> poller.log 2>&1 &
sleep 8
pgrep -f 'python3 poller[.]py' >/dev/null 2>&1 && echo "poller riavviato" || echo "⚠ il poller non riparte (vedi poller.log)"
echo

if [ "$RC" -eq 0 ]; then
  echo "VERDETTO: GOOSE ORA PARLA COL CERVELLO — nessuna chiave provider accavallata"
else
  echo "VERDETTO: IL WRAPPER COL CERVELLO NON FUNZIONA (exit $RC) — errore esatto qui sopra"
fi
exit "$RC"
