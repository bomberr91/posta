#!/usr/bin/env bash
# Sveglia LongCat: riaccede la sonda subito e controlla alle 19:00.
# Alle 19:00 mostra un riquadro sul PC e scrive il referto in dal_pc/.
# Girato dal postino sul PC.
set -u
H=$(date +%H); M=$(date +%M)
if [ "$H" -gt 19 ] || { [ "$H" -eq 19 ] && [ "$M" -ge 1 ]; }; then
  GIORNO="tomorrow"
else
  GIORNO="today"
fi
TARGET=$(date -d "$GIORNO 19:00" +%s)
NOW=$(date +%s)
echo "sveglia schedulata per $(date -d "@$TARGET" '+%d/%m %Y %H:%M') (tra $(( (TARGET - NOW) / 60 )) minuti)"

cat > "$HOME/.sveglia_longcat.sh" << 'EOF'
#!/usr/bin/env bash
TS=$(date '+%d/%m %Y %H:%M')
LOG="$HOME/sonda_longcat.log"
ULT=""
CAMPIONI=0
[ -f "$LOG" ] && { ULT=$(tail -1 "$LOG" | cut -c1-170); CAMPIONI=$(wc -l < "$LOG"); }
for d in "$HOME/posta" "$HOME/posta_ponte"; do
  if [ -f "$d/fatti/sonda_longcat.sh" ]; then
    bash "$d/fatti/sonda_longcat.sh" >/dev/null 2>&1
    break
  fi
done
TXT="Controllo LongCat delle $TS"
TXT="$TXT`n`nCampioni raccolti: $CAMPIONI"
TXT="$TXT`n`nUltimo campione:`n$ULT"
TXT="$TXT`n`nSe e' ancora 402, LongCat non si muove: lo togliamo dal roster."
printf '%s\n' "$TXT" > /mnt/c/Users/giopi/sveglia_longcat.txt
powershell.exe -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show((Get-Content -Raw C:\Users\giopi\sveglia_longcat.txt),'Sveglia LongCat - 19:00','OK','Information')" >/dev/null 2>&1
mkdir -p "$HOME/posta/dal_pc" 2>/dev/null
{
  echo "# Sveglia LongCat - $TS"
  echo
  echo "$TXT"
  echo
  echo "Referto generato sul PC dal postino."
} > "$HOME/posta/dal_pc/sveglia_longcat_1900.md" 2>/dev/null
EOF
chmod 700 "$HOME/.sveglia_longcat.sh"

cat > "$HOME/.sveglia_loop.sh" << 'EOF'
#!/usr/bin/env bash
TARGET="$1"
while [ "$(date +%s)" -lt "$TARGET" ]; do sleep 30; done
bash "$HOME/.sveglia_longcat.sh"
EOF
chmod 700 "$HOME/.sveglia_loop.sh"
setsid nohup "$HOME/.sveglia_loop.sh" "$TARGET" >/dev/null 2>&1 &
echo "sveglia avviata (pid $!)"

# intanto: riaccendo subito la sonda LongCat (il riavvio l'aveva uccisa)
for d in "$HOME/posta" "$HOME/posta_ponte"; do
  if [ -f "$d/fatti/sonda_longcat.sh" ]; then
    bash "$d/fatti/sonda_longcat.sh" 2>&1 | tail -4
    break
  fi
done
