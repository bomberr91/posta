#!/usr/bin/env bash
# Toglie la popup di avvio (non serve piu') e riarma la sveglia LongCat delle 19:00
# (il riavvio l'aveva uccisa). Girato dal postino sul PC.
set -u
R=~/posta
[ -d "$R" ] || R=~/posta_ponte
WIN=/mnt/c/Users/giopi
STARTUP="$WIN/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"

echo "=== TOLGO LA POPUP ==="
rm -f "$STARTUP/BOOT_CHECK.vbs"
rm -rf "$WIN/BootCheck"
rm -f "$WIN/boot_check_last.txt"
echo "--- Startup ora ---"
ls -la "$STARTUP" | tr -d '\r'
echo "--- rimosse: BOOT_CHECK.vbs, cartella BootCheck, boot_check_last.txt ---"

echo
echo "=== RIARMO LONGCAT (sonda + sveglia 19:00) ==="
if [ -f "$R/da_me/sveglia_longcat_1900.sh" ]; then
  bash "$R/da_me/sveglia_longcat_1900.sh" 2>&1 | tail -8
elif [ -f "$R/fatti/sveglia_longcat_1900.sh" ]; then
  bash "$R/fatti/sveglia_longcat_1900.sh" 2>&1 | tail -8
else
  echo "script della sveglia non trovato nel repo"
fi

echo
echo "=== STATO ==="
date '+%d/%m %Y %H:%M:%S %Z'
for n in scorta_posta scorta_cervello scorta_motore omniroute; do
  printf "%-16s %s\n" "$n" "$(pgrep -fa "$n" 2>/dev/null | wc -l)"
done
