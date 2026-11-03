#!/bin/bash
# scorta_motore.sh — guardiano del MOTORE (OmniRoute, porta 20128).
#
# 3/11 sera: era un guardiano MUTO. Avviava OmniRoute in loop e non scriveva
# NULLA: se il processo restava vivo ma la porta 20128 non saliva, nessuno se
# ne accorgeva e il portiere cadeva sul fallback (rotta motore-mappato morta).
# Il cervello invece ha un guardiano che parla (/tmp/scorta_cervello.log).
# Ora anche il motore parla, controlla la porta e riavvia se muore.
#
# Il pkill sta in un file di script e non in linea: in linea uccide la shell
# che lo esegue (è successo il 1/11).
LOG=/tmp/scorta_motore.log
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }

sleep 25
MORTI=0
while true; do
  flock -n /tmp/omni.lk bash -c '. ~/.nvm/nvm.sh; OMNIROUTE_SERVER_HOST=127.0.0.1 omniroute' >> "$LOG" 2>&1
  sleep 120
  if (exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null; then
    if [ "$MORTI" -gt 0 ]; then say "porta 20128 risorta dopo $MORTI controlli muti"; fi
    MORTI=0
  else
    MORTI=$((MORTI+1))
    say "porta 20128 muta (controllo $MORTI)"
    # due controlli muti di fila = 4 minuti: a quel punto il motore e' davvero
    # bloccato (non e' solo il suo avvio lento, che dura 2-3 minuti) e si
    # riavvia. Il loop riporta OmniRoute su in background.
    if [ "$MORTI" -ge 2 ]; then
      say "motore bloccato: lo riavvio"
      pkill -f 'node.*omniroute' >/dev/null 2>&1 || true
      sleep 5
      MORTI=0
    fi
  fi
done
