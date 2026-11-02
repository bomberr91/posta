#!/usr/bin/env bash
# riavvia_guardiano_cervello.sh — riavvia il guardiano del cervello.
#
# PERCHÉ: il 2/11 al guardiano è stato agganciata la sentinella delle chiavi
# (lavori/sentinella_chiavi.sh: catalogo + ri-prova dei cooldown + check-in
# AgentRouter, ogni 6 ore). Il guardiano già in esecuzione ha il codice VECCHIO
# in memoria: va riavviato, altrimenti la sentinella non parte mai.
#
# Uso:  bash ~/posta/fatti/riavvia_guardiano_cervello.sh
#
# NOTA: il pkill sta in un file di script e non in linea: così non uccide la
# shell che lo esegue (è successo il 1/11: il pkill ha ammazzato il cmd).
set -uo pipefail
REPO="$HOME/posta"
LOG="/tmp/scorta_cervello.log"
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }

cd "$REPO" || { echo "non trovo $REPO"; exit 1; }

say "1. fermo il guardiano vecchio (se c'è)"
pkill -f 'scorta_cervello\.sh' >/dev/null 2>&1 || true
sleep 2
pgrep -f 'scorta_cervello\.sh' >/dev/null && say "   c'è ancora un guardiano vivo" || say "   nessun guardiano attivo"

say "2. avvio il guardiano NUOVO (quello con la sentinella agganciata)"
nohup bash "$REPO/lavori/scorta_cervello.sh" >> "$LOG" 2>&1 &
sleep 4
if pgrep -f 'scorta_cervello\.sh' >/dev/null; then
  say "   guardiano avviato"
else
  say "   il guardiano NON e' partito: ultime righe di $LOG"
  tail -5 "$LOG" 2>/dev/null
  exit 1
fi

say "3. il cervello risponde?"
if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
  say "   cervello vivo sulla porta 20129"
else
  say "   il cervello non risponde: il guardiano lo riprova da solo, aspetta 30 secondi"
fi

say "4. la sentinella e' agganciata?"
if grep -q "sentinella_chiavi.sh" "$REPO/lavori/scorta_cervello.sh"; then
  say "   si': la sentinella gira ogni 6 ore"
else
  say "   NO: il guardiano non la chiama (manca l'aggancio)"
fi
say "fatto"
