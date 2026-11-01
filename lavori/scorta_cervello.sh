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
      nohup python3 cervello.py >> "$CERV" 2>&1 &
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
  sleep 30
done
