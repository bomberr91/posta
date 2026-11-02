#!/bin/bash
# GUARDIANO: installa la versione nuova e la collauda sul vivo (1/11 sera)
#
# Fa tre cose, in quest'ordine:
#  1) dice se il guardiano vecchio era vivo e lo ferma (senza uccidere la shell)
#  2) avvia il guardiano nuovo (quello col log)
#  3) COLLAUDO VIVO: ammazza il cervello e verifica che TORNINO DA SOLI
#     (è il punto che stasera falliva due volte). Se non torna, lo dice e
#     lo riavvia a mano, così il PC non resta morto in silenzio.
set -uo pipefail
cd "$HOME/posta" || { echo "non trovo ~/posta"; exit 1; }
LOG="/tmp/scorta_cervello.log"

echo "### 1. il guardiano vecchio era vivo?"
if pgrep -af '[s]corta_cervello.sh' | head -3; then
  echo "   (fermo quello vecchio)"
  pkill -f '[s]corta_cervello.sh' 2>/dev/null
  sleep 2
else
  echo "   NESSUN guardiano in giro: Ecco perche' il cervello restava giu"
fi

echo
echo "### 2. avvio il guardiano nuovo"
nohup bash "$[CHIAVE-RIMOSSA].sh" > /tmp/guardiano_avvio.log 2>&1 &
sleep 8
pgrep -af '[s]corta_cervello.sh' | head -2 || echo "   il guardiano non e' partito"
tail -3 "$LOG" 2>/dev/null

echo
echo "### 3. COLLAUDO VIVO: ammazzo il cervello e guardo se torna da solo"
if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
  pkill -f '^python3 cervello\.py$'
  echo "   cervello ammazzato"
else
  echo "   il cervello era gia' giu"
fi
TORNATO=0
for i in $(seq 1 24); do
  sleep 5
  if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
    echo "   TORNATO DA SOLO dopo ~$((i*5))s"
    TORNATO=1
    break
  fi
done
if [ "$TORNATO" -ne 1 ]; then
  echo "   NON e' tornato da solo. Ecco il log del guardiano:"
  tail -12 "$LOG" 2>/dev/null
  echo "   ---- e l'output del cervello:"
  tail -12 /tmp/cervello.log 2>/dev/null
  echo "   -> lo riavvio a mano cosi' il PC non resta morto"
  nohup python3 cervello.py >> /tmp/cervello.log 2>&1 &
  sleep 8
fi

echo
echo "### 4. salute"
curl -fsS -m 15 http://127.0.0.1:20129/salute | head -c 400; echo
echo
echo "### 5. il log del guardiano (le ultime righe)"
tail -8 "$LOG" 2>/dev/null || echo "   (nessun log)"
echo
if [ "$TORNATO" -eq 1 ]; then
  echo "GUARDIANO OK: il cervello e' tornato da solo, senza che nessuno lo avviasse a mano"
  exit 0
else
  echo "il guardiano NON risuscita il cervello (l'ho riavviato a mano per non lasciare il PC morto)"
  exit 1
fi
