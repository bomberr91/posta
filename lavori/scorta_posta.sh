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
#
# RIPARAZIONE (11/11, ZCode): il blocco "riaccendi la sonda LongCat" (3/11)
# lanciava `bash sonda_longcat.sh` DIRETTAMENTE (loop infinito, senza nohup/&):
# il guardiano restava APPESO dentro la sonda e non raggiungeva mai il blocco
# postino — il corriere morto non veniva più rilanciato (trovato morto il
# 11/11 sera, locale indietro con 18 file pendenti). La sonda campionava un
# provider RIMOSSO dal roster il 4/11 con 402 a ogni giro. Blocco RIMOSSO:
# la sveglia LongCat è disarmata per sempre dall'8/11; se un giorno serve una
# misura periodica, si lancia con nohup+& (mai in prima persona dal guardiano).
sleep 15
export GIT_TERMINAL_PROMPT=0
LOG="/tmp/scorta_posta.log"
say(){ echo "[$(date '+%d/%m %H:%M')] $*" | tee -a "$LOG"; }

while true; do
  # ── 1/11: il postino è gelato sul pull? ───────────────────────────────────
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

  # ── 2/11: il GUARDIANO DEL CERVELLO è vivo? ───────────────────────────────
  if ! pgrep -f 'scorta_cervello\.sh' >/dev/null 2>&1; then
    say "-> il guardiano del cervello non gira: lo riavvio"
    ( cd "$HOME/posta" && nohup bash lavori/scorta_cervello.sh >> /tmp/scorta_cervello.log 2>&1 & )
    sleep 2
  fi

  # ── 8/11: la sveglia LongCat è DISARMA per sempre (provider rimosso dal
  #    roster il 4/11, la catena .sveglia_loop/.sveglia_longcat apriva tab
  #    senza senso). Se un giorno serve una sveglia provider, si usa il
  #    widget Windows (WIDGET_AGENTROUTER.ps1) come modello. ─────────────────

  # ── 2/11: il postino è vivo ma APPESO? Il battito dice l'ultima volta che ──
  if [ -f /tmp/postino_battito ]; then
    BAT=$(stat -c %Y /tmp/postino_battito 2>/dev/null || echo 0)
    ETA=$(( $(date +%s) - BAT ))
    if [ "$ETA" -gt 420 ]; then
      say "-> il postino non batte da ${ETA}s: e' appeso, lo riavvio"
      pkill -f 'postino\.sh --loop' >/dev/null 2>&1 || true
      sleep 3
    fi
  fi

  # ── 2/11: via il FLOCK. Il lock veniva EREDITATO dai figli del postino (un
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
