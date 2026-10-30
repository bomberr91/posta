#!/usr/bin/env bash
# link_freebuff.sh — scarica il logo e crea il collegamento Freebuff sul Desktop
set -u
POSTA_DIR="$HOME/posta"; OUT="$POSTA_DIR/dal_pc/link_freebuff.md"
TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
AG="/mnt/c/Users/giopi/AppData/Local/agenti"; mkdir -p "$AG"
echo "# Collegamento Desktop Freebuff — $(date '+%d/%m %H:%M')" > "$OUT"
curl -sL -m 20 -o "$AG/freebuff.ico" "https://freebuff.com/favicon.ico" && echo "- logo scaricato in AppData\\Local\\agenti\\freebuff.ico" | tee -a "$OUT"
sed 's/$/\r/' "$POSTA_DIR/strumenti/crea_link_freebuff_src.ps1" > /tmp/cl.ps1
printf '\xEF\xBB\xBF' > "$AG/crea_link_freebuff.ps1"; cat /tmp/cl.ps1 >> "$AG/crea_link_freebuff.ps1"
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\giopi\\AppData\\Local\\agenti\\crea_link_freebuff.ps1" >>"$OUT" 2>&1
grep -q LINK_CREATO "$OUT" && echo "- collegamento Freebuff.lnk creato sul Desktop (con logo)" | tee -a "$OUT" || echo "- ERRORE creazione link (vedi report)" | tee -a "$OUT"
cd "$POSTA_DIR" && git config user.name bomberr91 && git config user.email bomberr91@users.noreply.github.com
git add dal_pc/ >/dev/null 2>&1; git commit -qm "link_freebuff: esito" >/dev/null 2>&1 || true
[ -n "$TOKEN" ] && { git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1; git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; }
echo FINITO
