#!/usr/bin/env bash
# Installa la popup di stato all'avvio del PC (Windows) e la collauda subito.
# Girato dal postino sul PC: il referto finisce in dal_pc/installa_popup_avvio.md
set -u
WIN=/mnt/c/Users/giopi
REPO=~/posta
DEST="$WIN/BootCheck"
STARTUP="$WIN/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"

mkdir -p "$DEST" || exit 1
cp "$REPO/fatti/boot_check.ps1" "$DEST/boot_check.ps1" || exit 1

cat > "$DEST/BOOT_CHECK.vbs" <<'VBS'
Set shell = CreateObject("WScript.Shell")
WScript.Quit shell.Run("powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Users\giopi\BootCheck\boot_check.ps1""", 0, True)
VBS

cp "$DEST/BOOT_CHECK.vbs" "$STARTUP/BOOT_CHECK.vbs" || exit 1

echo "=== installato ==="
ls -la "$DEST"
echo "--- startup ---"
ls -la "$STARTUP" | grep -i -e boot_check -e openclaw

echo
echo "=== collaudo immediato (senza attesa, senza riquadro) ==="
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\giopi\BootCheck\boot_check.ps1" -NoPopup -Fast 2>&1 | tr -d '\r'

echo
echo "=== referto salvato in ==="
echo "$WIN/boot_check_last.txt"
cat "$WIN/boot_check_last.txt" 2>/dev/null | tr -d '\r' || echo "(non trovato)"
