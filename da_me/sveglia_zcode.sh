#!/usr/bin/env bash
# sveglia_zcode.sh — crea la sveglia Windows delle 12:00 per il riscatto ZCode
set -u
POSTA_DIR="$HOME/posta"; OUT="$POSTA_DIR/dal_pc/sveglia_zcode.md"
TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
SCH=/mnt/c/Windows/System32/schtasks.exe
WINDIR_AG="/mnt/c/Users/giopi/AppData/Local/agenti"
mkdir -p "$WINDIR_AG"
echo "# Sveglia ZCode 12:00 — $(date '+%d/%m %H:%M')" > "$OUT"
# popup senza finestra nera (VBS, ASCII, CRLF)
printf 'MsgBox "Apri ZCode e premi CLAIM (card in basso a sinistra)." & vbCrLf & "I token valgono dalle 16:00 alle 02:00.", 64, "ZCODE - RISCATTO (ore 12:00)"\r\n' > "$WINDIR_AG/SVEGLIA_ZCODE.vbs"
echo "- scritto C:\\Users\\giopi\\AppData\\Local\\agenti\\SVEGLIA_ZCODE.vbs" | tee -a "$OUT"
if "$SCH" /create /f /tn "Agenti - Riscatto ZCode" /tr "wscript.exe \"C:\Users\giopi\AppData\Local\agenti\SVEGLIA_ZCODE.vbs\"" /sc daily /st 12:00 >>"$OUT" 2>&1; then
  echo "- sveglia creata: ogni giorno alle 12:00" | tee -a "$OUT"
else
  echo "- ERRORE creazione sveglia (vedi sopra)" | tee -a "$OUT"
fi
echo '## Attivita esistenti (riscatto/sveglia/agenti)' >> "$OUT"; echo '```' >> "$OUT"
"$SCH" /query /fo csv 2>/dev/null | tr -d '\r' | grep -i -E 'riscat|sveglia|agenti|zcode|agentrouter' >> "$OUT" || echo "(niente trovato)" >> "$OUT"
echo '```' >> "$OUT"
cd "$POSTA_DIR" && git config user.name bomberr91 && git config user.email bomberr91@users.noreply.github.com
git add dal_pc/ >/dev/null 2>&1; git commit -qm "sveglia_zcode: esito" >/dev/null 2>&1 || true
[ -n "$TOKEN" ] && { git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1; git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; }
echo FINITO
