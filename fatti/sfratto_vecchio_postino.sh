#!/bin/bash
echo "## SFRATTO DEL VECCHIO POSTINO — $(date '+%H:%M')"
echo "### 1. Disabilito il task pianificato (non partirà MAI più al boot)"
/mnt/c/Windows/System32/schtasks.exe /change /tn "Agenti - Postino" /disable 2>&1 | tr -d '\r' | head -2
echo
echo "### 2. Programmo lo sfratto tra 30 secondi (dopo che questo rapporto è partito):"
echo "    - termine del task in esecuzione (la finestra cmd si chiude)"
echo "    - pulizia di TUTTI i loop postino → il guardiano risuscita il SUO, invisibile, entro 60s"
nohup bash -c '
sleep 30
/mnt/c/Windows/System32/schtasks.exe /end /tn "Agenti - Postino" > /dev/null 2>&1
pkill -f "postino.sh --loo[p]" 2>/dev/null
' > /dev/null 2>&1 &
echo "sfratto armato ✓"
