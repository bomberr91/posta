#!/bin/bash
# scorta del corriere: lo rilancia per sempre se muore (nome file innocuo apposta)
#
# CURA-AUDIT (1/11 sera): il guardiano non è solo "rilancia se muore" —
# il 1/11 il postino era VIVO ma GELATO (appeso su un prompt di credenziali
# di git: lock tenuto, nessun compito visto, nessuna notizia per 40 minuti)
# e con `flock -n` nessuno poteva sostituirlo. Ora:
#   · git non aspetta mai una password (GIT_TERMINAL_PROMPT=0) e ha un timeout
#   · se il postino resta sul pull per oltre 3 minuti, è congelato: lo
#     ammazziamo e lo riavviamo
#   · il log del guardiano è in /tmp/scorta_posta.log
sleep 15
export GIT_TERMINAL_PROMPT=0
LOG="/tmp/scorta_posta.log"
say(){ echo "[$(date '+%d/%m %H:%M')] $*" | tee -a "$LOG"; }

while true; do
  # ── il postino è gelato? (stato "pull" vecchio) ───────────────────────────
  if [ -f /tmp/postino_stato ]; then
    read -r STATO T0 < /tmp/postino_stato 2>/dev/null || STATO=""
    if [ "${STATO:-}" = "pull" ]; then
      ETA=$(( $(date +%s) - ${T0:-0} ))
      if [ "$ETA" -gt 180 ]; then
        say "⚠ il postino è GELATO sul pull da ${ETA}s: lo ammazzo e lo riavvio"
        pkill -f '^bash postino\.sh --loop$' 2>/dev/null || true
        sleep 3
        pkill -f 'postino\.sh --loop' 2>/dev/null || true   # anche il wrapper del flock
        sleep 2
      fi
    fi
  fi

  # 2/11: via il FLOCK. Il lock veniva EREDITATO dai figli del postino (un
  # `opencode run` interrotto): se il postino moriva, il figlio teneva ancora
  # il lock e `flock -n` falliva PER SEMPRE, in silenzio (due ore di coda muta).
  # Ora il guardiano chiede semplicemente: il postino c'e' gia'? se no, riavvialo.
  if pgrep -f 'postino\.sh --loop' >/dev/null 2>&1; then
    sleep 60
    continue
  fi
  say "-> il postino non gira: lo riavvio"
  ( cd "$HOME/posta" && nohup bash postino.sh --loop >> /tmp/postino_console.log 2>&1 & )
  sleep 60
done
