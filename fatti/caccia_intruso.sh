#!/bin/bash
echo "## CACCIA ALL'INTRUSO CMD — $(date '+%H:%M')"
echo "### 1. Quanti postini girano? (se >1 = GUAIO doppi-job)"
ps aux | grep "postino.sh --loo[p]" | grep -v grep
N=$(ps aux | grep -c "postino.sh --loo[p]")
echo "→ conteggio loop postino: $N"
echo
echo "### 2. Avvii automatici nel REGISTRO di Windows"
/mnt/c/Windows/System32/reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2>/dev/null | tr -d '\r' | grep -v "^$" | tail -n +2
echo
echo "### 3. Utilità di pianificazione (voci sospette)"
[CHIAVE-RIMOSSA].exe /query /fo csv 2>/dev/null | tr -d '\r' | grep -iE "post|wsl|agent|omni|cervell" | head -5 || echo "  niente di sospetto"
echo
echo "### 4. Esecuzione automatica COMUNE (tutti gli utenti)"
ls "[CHIAVE-RIMOSSA] Menu/Programs/StartUp/" 2>/dev/null || echo "  vuota"
echo
echo "### 5. Chi è il terminale predefinito? (bizza Win11)"
/mnt/c/Windows/System32/reg.exe query "HKCU\Console\%%startup" /v DelegationConsole 2>/dev/null | tr -d '\r' | tail -2 || echo "  non leggibile"
