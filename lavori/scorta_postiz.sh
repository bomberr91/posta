#!/bin/bash
# scorta_postiz.sh — guardiano del scheduler social (11/12, funzione hermes)
# Postiz vive su Docker (porta 4007): se dockerd è giù lo riaccende, e se i
# container Postiz non salgono fa il compose up (il restart:always fa il resto).
LOG=/tmp/scorta_postiz.log
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
say "guardiano avviato (pid $$)"

while true; do
  # dockerd vivo? (senza di lui tutte le funzioni Docker muoiono)
  if ! pgrep -x dockerd >/dev/null 2>&1; then
    say "dockerd DOWN: lo riaccendo"
    sudo -n nohup dockerd > /tmp/dockerd.log 2>&1 &
    sleep 8
  fi
  # Postiz vivo? (l'interfaccia è su 4007)
  if ! (exec 3<>/dev/tcp/127.0.0.1/4007) 2>/dev/null; then
    say "postiz DOWN: compose up"
    if [ -d "$HOME/postiz" ]; then
      ( cd "$HOME/postiz" && sudo -n docker compose up -d >> "$LOG" 2>&1 )
      say "compose up eseguito"
    fi
  fi
  sleep 180
done
