#!/bin/bash
echo "## CONTA POSTINI DOPO LO SFRATTO — $(date '+%H:%M')"
ps aux | grep "postino.sh --loo[p]" | grep -v grep | awk '{print " ", $2, $7, substr($0, index($0,$11), 50)}'
N=$(ps aux | grep -c "postino.sh --loo[p]")
echo "→ loop attivi: $N (atteso: 2 righe = 1 postino vero + il suo flock)"
echo
echo "stato task:"; /mnt/c/Windows/System32/schtasks.exe /query /tn "Agenti - Postino" /fo list 2>/dev/null | tr -d '\r' | grep -E "Stato|Status" | head -2
