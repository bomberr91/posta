#!/usr/bin/env bash
# riavvia_guardiani.sh — riavvia i DUE guardiani con il codice nuovo.
#
# PERCHÉ (2/11): i guardiani sono il "canale" che tiene vivo il PC. Se uno dei
# due muore in silenzio, la coda dei compiti si ferma e non arriva nessuna
# notizia: il 2/11 il postino era morto dalle 11:29 e nessuno se n'era accorto
# fino alle 13:15 (due ore di coda muta).
#
#   guardiano del postino  -> lavori/scorta_posta.sh   (tiene vivo il postino)
#   guardiano del cervello -> lavori/scorta_cervello.sh (tiene vivo il cervello
#                             sulla porta 20129 e la sentinella delle chiavi)
#
# Uso:  bash ~/posta/fatti/riavvia_guardiani.sh
#
# NOTA: NON ammazza il postino: se sta eseguendo un compito, quel lavoro non
# viene buttato via. Si riavviano solo i guardiani (che caricano il codice nuovo).
set -uo pipefail
REPO="$HOME/posta"
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }

cd "$REPO" || { say "non trovo $REPO"; exit 1; }

say "1. fermo i guardiani vecchi (caricano il codice nuovo al prossimo giro)"
pkill -f 'scorta_posta\.sh' >/dev/null 2>&1 || true
pkill -f 'scorta_cervello\.sh' >/dev/null 2>&1 || true
sleep 3

say "2. avvio i guardiani nuovi"
nohup bash "$REPO/lavori/scorta_posta.sh" >> /tmp/scorta_posta.log 2>&1 &
nohup bash "$REPO/lavori/scorta_cervello.sh" >> /tmp/scorta_cervello.log 2>&1 &
sleep 6

for g in scorta_posta scorta_cervello; do
  if pgrep -f "$g\.sh" >/dev/null 2>&1; then say "   ✓ $g vivo"; else say "   ✗ $g NON parte"; fi
done

say "3. il postino (quello vecchio può continuare il compito che sta facendo)"
if pgrep -f 'postino\.sh --loop' >/dev/null 2>&1; then
  say "   ✓ postino vivo: stato $(cat /tmp/postino_stato 2>/dev/null)"
else
  say "   il postino non gira: lo lascio riavviare al guardiano (aspetta un minuto)"
fi

say "4. il cervello risponde?"
if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
  say "   ✓ cervello vivo sulla porta 20129"
else
  say "   il cervello non risponde ancora: il guardiano lo riprova da solo (30 s)"
fi

say "5. la sentinella delle chiavi e' agganciata?"
if grep -q "sentinella_chiavi.sh" "$REPO/lavori/scorta_cervello.sh"; then
  say "   ✓ la sentinella gira ogni 6 ore"
else
  say "   ✗ la sentinella NON e' agganciata"
fi

say "6. la coda"
if [ -n "$(ls -A da_me/ 2>/dev/null)" ]; then
  ls -1 da_me/ 2>/dev/null | sed 's/^/   → /'
else
  say "   (coda vuota)"
fi
say "fatto"
