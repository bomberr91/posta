#!/bin/bash
# GUARDIANO DEL CERVELLO (1/11 sera, riscritto)
#
# PRIMA: `flock -n /tmp/cervello.lk bash -c 'cd ~/posta; python3 cervello.py'`
#   → avviava il cervello in primo piano dentro il flock, SENZA LOG.
#   Se la partenza falliva non se ne sapeva niente, e se il lock restava
#   stretto `flock -n` falliva in silenzio: il cervello restava giù e
#   nessuno se ne accorgeva (è successo due volte l'1/11 sera).
#
# ADESSO: controlla SE il cervello risponde, e se non risponde lo riavvia
#   con un log che si può leggere, usando un lock a TEMPO (non istantaneo).
#   Il cervello gira staccato dal guardiano (nohup): se il guardiano muore,
#   il cervello resta vivo.
LOG="/tmp/scorta_cervello.log"
CERV="/tmp/cervello.log"
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
cd "$HOME/posta" || { say "non trovo ~/posta"; exit 1; }
say "guardiano avviato (pid $$)"

while true; do
  if ! (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
    say "cervello DOWN: lo riavvio"
    # lock a tempo: se qualcun altro sta già tentando, aspetto e riprovo
    if flock -w 30 /tmp/cervello.lk true 2>/dev/null; then
      # AUDIT FINALE: senza PYTHONUNBUFFERED il log resta VUOTO proprio
      # quando serve (il cane muore e non si sa perche').
      PYBIN="$HOME/venv_cervello/bin/python"
[ -x "$PYBIN" ] || PYBIN=python3
PYTHONUNBUFFERED=1 nohup "$PYBIN" cervello.py >> "$CERV" 2>&1 &
      for i in $(seq 1 20); do
        sleep 3
        if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
          say "cervello risorto (~$((i*3))s)"
          break
        fi
      done
      if ! (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
        say "il cervello NON e' tornato: ultime righe di $CERV:"
        tail -5 "$CERV" >> "$LOG" 2>/dev/null
      fi
    else
      say "lock /tmp/cervello.lk occupato: aspetto e riprovo"
    fi
  fi
  # ── la sentinella delle chiavi (una volta ogni 6 ore) ──
  # Rigenera il catalogo freellmapi, ri-prova chi e' in cooldown e fa il
  # check-in AgentRouter. Il file di stato dentro la sentinella fa la guardia
  # precisa; qui si controlla solo per non lanciarla ogni 30 secondi.
  PRIMA_S=$(cat /tmp/sentinella_giro 2>/dev/null || echo 0)
  case "$PRIMA_S" in ''|*[!0-9]*) PRIMA_S=0 ;; esac
  if [ $(( $(date +%s) - PRIMA_S )) -ge 21600 ]; then
    date +%s > /tmp/sentinella_giro
    say "lancio la sentinella delle chiavi"
    timeout 1200 bash "$HOME/posta/lavori/sentinella_chiavi.sh" >> "$LOG" 2>&1 \
      || say "sentinella: esito non zero (vedi /tmp/sentinella_chiavi.log)"
  fi

  sleep 30
done
