#!/usr/bin/env bash
# libera_postino.sh — sblocca il postino e rimette in moto la coda (2/11).
#
# PERCHÉ (2/11 13:30): il postino è morto alle 11:29 e il guardiano non è
# riuscito a riavviarlo per ~2 ore. Motivo: il guardiano avvia il postino con
# `flock -n /tmp/postino.lk bash -c '...'`. Il lock viene EREDITATO dai figli
# (un `opencode run` rimasto appeso): se il postino muore, il figlio tiene
# ancora il lock e `flock -n` fallisce per sempre, IN SILENZIO (il guardiano
# non scrive nulla). Risultato: coda muta, nessun report, nessuna notizia.
#
# QUI: 1) si trovano e si ammazzano i processi che tengono il lock
#       2) si toglie il file di lock
#       3) si riavvia il guardiano (che ora non usa più il flock)
#       4) si verifica che il postino torni vivo e dica cosa c'è in coda
#
# Uso:  bash ~/posta/fatti/libera_postino.sh
set -uo pipefail
REPO="$HOME/posta"
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }

cd "$REPO" || { say "non trovo $REPO"; exit 1; }

say "1. chi tiene il lock del postino"
TENGONO=""
for fd in /proc/[0-9]*/fd/*; do
  tgt=$(readlink "$fd" 2>/dev/null) || continue
  case "$tgt" in
    *postino.lk*)
      pid=$(echo "$fd" | cut -d/ -f3)
      [ "$pid" = "$$" ] && continue
      TENGONO="$TENGONO $pid"
      ;;
  esac
done
if [ -n "$TENGONO" ]; then
  for pid in $TENGONO; do
    riga=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | cut -c1-100)
    say "   pid $pid tiene il lock: $riga"
  done
else
  say "   nessun processo tiene il lock"
fi

say "2. ammazzo i processi residui che lo tengono (solo 'opencode run': sono compiti interrotti)"
for p in $(pgrep -f 'opencode run' 2>/dev/null); do
  [ "$p" = "$$" ] && continue
  kill -9 "$p" 2>/dev/null && say "   ucciso opencode residuo $p"
done

say "3. libero il lock"
rm -f /tmp/postino.lk
say "   lock rimosso"

say "4. riavvio il guardiano (codice nuovo: niente flock, controlla col pgrep)"
pkill -f 'scorta_posta\.sh' >/dev/null 2>&1 || true
sleep 2
nohup bash "$REPO/lavori/scorta_posta.sh" >> /tmp/scorta_posta.log 2>&1 &
sleep 20

say "5. il postino e' vivo?"
VIVO=0
for i in $(seq 1 24); do
  if pgrep -f 'postino\.sh --loop' >/dev/null 2>&1; then VIVO=1; break; fi
  sleep 5
done
if [ "$VIVO" = "1" ]; then
  say "   ✓ postino VIVO"
  say "   stato: $(cat /tmp/postino_stato 2>/dev/null)"
  say "   ultime righe del log:"
  tail -6 /tmp/postino.log 2>/dev/null | sed 's/^/   /'
else
  say "   ⚠ il postino non parte: guardo il log del guardiano"
  tail -12 /tmp/scorta_posta.log 2>/dev/null | sed 's/^/   /'
fi

say "6. la coda"
if [ -n "$(ls -A da_me/ 2>/dev/null)" ]; then
  ls -1 da_me/ 2>/dev/null | sed 's/^/   → /'
else
  say "   (coda vuota)"
fi
say "fatto"
