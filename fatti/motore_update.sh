#!/bin/bash
. ~/.nvm/nvm.sh 2>/dev/null
echo "## AGGIORNAMENTO MOTORE DA SPENTO — $(date '+%H:%M')"
echo
echo "### 1. Spengo il motore (se vivo)"
pkill -f omniroute 2>/dev/null && echo "ucciso" || echo "non girava"
sleep 3
(exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null && echo "PORTA 20128 ANCORA OCCUPATA!" || echo "porta 20128 libera ✓"
echo
echo "### 2. Versione attuale"
omniroute --version 2>/dev/null || echo "?"
echo
echo "### 3. Backup rapido del database (resta sul PC, ~/motore_backup_31_10)"
mkdir -p ~/motore_backup_31_10
for d in ~/.omniroute ~/.config/omniroute ~/.local/share/omniroute; do
  [ -d "$d" ] && cp -a "$d" ~/motore_backup_31_10/ && echo "salvato: $d ($(du -sh "$d" | cut -f1))"
done
ls ~/motore_backup_31_10 2>/dev/null || echo "nessuna cartella dati trovata nei posti soliti"
echo
echo "### 4. Aggiorno (motore spento, niente lucchetti)"
npm install -g omniroute@latest 2>&1 | tail -3
echo
echo "### 5. Versione nuova"
omniroute --version 2>/dev/null || echo "ERRORE: CLI non risponde"
echo
echo "### 6. Il database c'è ancora?"
for d in ~/.omniroute ~/.config/omniroute ~/.local/share/omniroute; do
  [ -d "$d" ] && echo "✓ $d ($(du -sh "$d" | cut -f1))"
done
echo
echo "FATTO. Ora il capo puo' riaccendere con ACCENDI_OMNIROUTE.bat dal Desktop."
