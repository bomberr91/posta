#!/bin/bash
# scorta_agenti.sh — GUARDIANO DEL PANNELLO AGENTI LIVE (:20201) (13/11, da Paperclip via capo)
LOG=/tmp/scorta_agenti.log
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
say "guardiano avviato (pid $$)"
while true; do
  if ! (exec 3<>/dev/tcp/127.0.0.1/20201) 2>/dev/null; then
    say "pannello DOWN: lo riaccendo"
    nohup python3 "$HOME/posta/agenti_live.py" >> /tmp/agenti_live.log 2>&1 & sleep 2
    (exec 3<>/dev/tcp/127.0.0.1/20201) 2>/dev/null && say "pannello risorto" || say "riaccensione non riuscita: riprovo al giro"
  fi
  sleep 120
done
