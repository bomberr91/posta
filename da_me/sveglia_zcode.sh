#!/usr/bin/env bash
# sveglia_zcode.sh v2 — WIDGET riscatto ZCode: avvio con Windows, insiste ogni 20 min finche' non dici SI
set -u
POSTA_DIR="$HOME/posta"; OUT="$POSTA_DIR/dal_pc/sveglia_zcode.md"
TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
SCH=/mnt/c/Windows/System32/schtasks.exe
AG="/mnt/c/Users/giopi/AppData/Local/agenti"
STARTUP="/mnt/c/Users/giopi/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
mkdir -p "$AG"
echo "# Widget riscatto ZCode — $(date '+%d/%m %H:%M')" > "$OUT"
# pulizia versione precedente (sveglia semplice)
"$SCH" /delete /f /tn "Agenti - Riscatto ZCode" >/dev/null 2>&1 && echo "- vecchia sveglia 12:00 rimossa" >> "$OUT"
rm -f "$AG/SVEGLIA_ZCODE.vbs"
# scrivo il PS1 (BOM + CRLF, ASCII)
sed 's/$/\r/' "$POSTA_DIR/strumenti/widget_zcode_src.ps1" > /tmp/w.ps1 2>/dev/null || exit_err=1
printf '\xEF\xBB\xBF' > "$AG/WIDGET_ZCODE.ps1"; cat /tmp/w.ps1 >> "$AG/WIDGET_ZCODE.ps1"
echo "- scritto C:\\Users\\giopi\\AppData\\Local\\agenti\\WIDGET_ZCODE.ps1" | tee -a "$OUT"
# lanciatore invisibile nella cartella Esecuzione automatica
printf 'CreateObject("Wscript.Shell").Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\\Users\\giopi\\AppData\\Local\\agenti\\WIDGET_ZCODE.ps1""", 0, False\r\n' > "$STARTUP/WIDGET_ZCODE.vbs"
echo "- lanciatore messo in Esecuzione automatica (parte a ogni avvio di Windows)" | tee -a "$OUT"
# avvio subito, staccato dalla finestra
/mnt/c/Windows/System32/cmd.exe /c start "" wscript.exe "C:\\Users\\giopi\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\WIDGET_ZCODE.vbs" >/dev/null 2>&1
echo "- widget AVVIATO adesso" | tee -a "$OUT"
cd "$POSTA_DIR" && git config user.name bomberr91 && git config user.email bomberr91@users.noreply.github.com
git add dal_pc/ >/dev/null 2>&1; git commit -qm "sveglia_zcode v2: esito" >/dev/null 2>&1 || true
[ -n "$TOKEN" ] && { git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1; git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; }
echo FINITO
