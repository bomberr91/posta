#!/bin/bash
# scorta_searxng.sh — GUARDIANO DI SearXNG (11/11, su ordine capo)
# La riserva di ricerca (port 8080) nasce con nohup e muore al riavvio:
# questa scorta la controlla e la riaccende col suo script collaudato.
LOG=/tmp/scorta_searxng.log
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
say "guardiano avviato (pid $$)"

while true; do
  if ! (exec 3<>/dev/tcp/127.0.0.1/8080) 2>/dev/null; then
    say "searxng DOWN: la riaccendo"
    # lock a tempo come le altre scorte: se un altro tentativo e' in corso, aspetto
    if flock -w 60 /tmp/searxng.lk bash "$HOME/posta/fatti/searxng_persistente.sh" >> "$LOG" 2>&1; then
      say "searxng risorta"
    else
      say "riaccensione fallita o in corso: riprovo al giro"
    fi
  fi
  sleep 120
done
