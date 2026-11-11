#!/bin/bash
# scorta_swarmchat.sh — GUARDIANO DELLA CHAT TRA AGENTI (11/11, su ordine capo)
# Il server swarmchat (:8484) non aveva nessuna scorta: morto in silenzio.
# Controlla la porta e riaccende col comando di casa (CANONE 03: swarmchat serve).
LOG=/tmp/scorta_swarmchat.log
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
say "guardiano avviato (pid $$)"

while true; do
  if ! (exec 3<>/dev/tcp/127.0.0.1/8484) 2>/dev/null; then
    say "swarmchat DOWN: lo riaccendo"
    if flock -w 60 /tmp/swarmchat.lk bash -c \
      'nohup "$HOME/.local/bin/swarmchat" serve >> /tmp/swarmchat.log 2>&1 & sleep 3' ; then
      if (exec 3<>/dev/tcp/127.0.0.1/8484) 2>/dev/null; then
        say "swarmchat risorto"
      else
        say "riaccensione non riuscita: riprovo al giro"
      fi
    fi
  fi
  sleep 120
done
