#!/bin/bash
# scorta_ponte.sh — guardiano del poller (stesso schema di scorta_posta/cervello/motore):
# se il poller non c'è, lo riavvia; il lock del poller impedisce i doppioni.
# Il poller gira staccato (nohup): se la scorta muore, il poller resta vivo.
LOG=/tmp/scorta_ponte.log
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
cd ~/posta/lavori/ponte || { say "non trovo la cartella del ponte"; exit 1; }
say "scorta del ponte avviata (pid $$)"

while true; do
  if ! pgrep -f 'python3 poller[.]py' > /dev/null; then
    rm -f _stato/poller.lock   # lock orfano (il processo non c'è più)
    nohup python3 poller.py >> poller.log 2>&1 &
    say "poller riavviato (pid $!)"
  fi
  sleep 60
done
