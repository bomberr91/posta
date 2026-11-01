#!/bin/bash
# SBLOCCA IL POSTINO — CURA-AUDIT (1/11 sera)
#
# Uso:  bash ~/posta/fatti/sblocca_postino.sh
#
# Perché: il 1/11 ~19:02 il postino del PC è rimasto GELATO dentro un
# `git pull` (appeso su un prompt di credenziali). Con `flock -n` teneva il
# lock: nessuno poteva sostituirlo, i compiti in coda non arrivavano e non
# c'era una sola notizia. Questo script lo sblocca, rimedia allo stato del
# repo, riavvia il guardiano con il codice NUOVO (che sa riconoscere il gelo)
# e poi VERIFICA che il postino sia vivo.
#
# L'ORDINE CONTA: prima il PULL (il codice nuovo), POI il guardiano. Se si
# riavvia il guardiano prima, riparte con il codice vecchio e si ricade nel
# gelo che si voleva rimediare.
set -uo pipefail
REPO="$HOME/posta"
cd "$REPO" || { echo "❌ non trovo $REPO"; exit 1; }
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }

say "1. uccido il postino (se è gelato, tiene il lock e blocca tutto)"
pkill -f '^bash postino\.sh --loop$' 2>/dev/null || true
sleep 2
pkill -f 'postino\.sh --loop' 2>/dev/null || true
sleep 2
pgrep -f 'postino.sh --loop' >/dev/null && say "   ⚠ c'è ancora un postino vivo" || say "   ✓ nessun postino attivo"

say "2. rimedio lo stato del repo (lock, rebase, stash, file runtime)"
rm -f .git/index.lock
git rebase --abort >/dev/null 2>&1 || true
git merge --abort >/dev/null 2>&1 || true
git stash drop >/dev/null 2>&1 || true
git checkout -- portiere_log.jsonl portiere_stato.json >/dev/null 2>&1 || true
echo "   — situazione:"; git status --short | head -8

say "3. PULL del codice nuovo (prima del guardiano: è lui che deve ripartire nuovo)"
GIT_TERMINAL_PROMPT=0 timeout 120 git pull --rebase --autostash origin main 2>&1 | tail -3
echo "   — testa: $(git log --oneline -1 2>/dev/null)"

say "4. riavvio il guardiano (così prende il codice col controllo del gelo)"
pkill -f 'scorta_posta.sh' 2>/dev/null || true
sleep 2
nohup bash "$REPO/lavori/scorta_posta.sh" >> /tmp/scorta_posta.log 2>&1 &
sleep 4
pgrep -f 'scorta_posta.sh' >/dev/null && say "   ✓ guardiano avviato" || say "   ❌ il guardiano non parte"

say "5. il postino riparte? (aspetto 120s che scriva lo stato)"
VIVO=0
for i in $(seq 1 24); do
  sleep 5
  if [ -f /tmp/postino_stato ]; then
    ETA=$(( $(date +%s) - $(stat -c %Y /tmp/postino_stato) ))
    if [ "$ETA" -lt 150 ]; then
      VIVO=1
      say "   ✓ il postino è VIVO (stato: $(cat /tmp/postino_stato))"
      break
    fi
  fi
done
[ "$VIVO" -eq 1 ] || say "   ⚠ il postino non ha ancora scritto lo stato: guarda /tmp/postino.log e /tmp/scorta_posta.log"

say "6. i compiti in coda"
if [ -n "$(ls -A da_me/ 2>/dev/null)" ]; then
  ls -1 da_me/ 2>/dev/null | sed 's/^/   → /'
else
  say "   (coda vuota)"
fi
say ""
say "Se la coda è piena e il postino è vivo: aspetta un giro (45s) e guarda dal_pc/ per le risposte."
exit 0
