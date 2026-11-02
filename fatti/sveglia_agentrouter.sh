#!/usr/bin/env bash
# sveglia_agentrouter.sh — WIDGET check-in AgentRouter: dalle 18:05 apre Chrome sul sito e insiste finche' non dici SI
set -u
POSTA_DIR="$HOME/posta"; OUT="$[CHIAVE-RIMOSSA].md"
TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
AG="[CHIAVE-RIMOSSA]"
STARTUP="[CHIAVE-RIMOSSA] Menu/Programs/Startup"
mkdir -p "$AG"
echo "# Widget check-in AgentRouter — $(date '+%d/%m %H:%M')" > "$OUT"
sed 's/$/\r/' "$[CHIAVE-RIMOSSA].ps1" > /tmp/wa.ps1
printf '\xEF\xBB\xBF' > "$AG/WIDGET_AGENTROUTER.ps1"; cat /tmp/wa.ps1 >> "$AG/WIDGET_AGENTROUTER.ps1"
echo "- scritto C:\\Users\\giopi\\AppData\\Local\\agenti\\WIDGET_AGENTROUTER.ps1" | tee -a "$OUT"
printf 'CreateObject("Wscript.Shell").Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\\Users\\giopi\\AppData\\Local\\agenti\\WIDGET_AGENTROUTER.ps1""", 0, False\r\n' > "$STARTUP/WIDGET_AGENTROUTER.vbs"
echo "- lanciatore in Esecuzione automatica (parte a ogni avvio di Windows)" | tee -a "$OUT"
/mnt/c/Windows/System32/cmd.exe /c start "" wscript.exe "C:\\Users\\giopi\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\WIDGET_AGENTROUTER.vbs" >/dev/null 2>&1
echo "- widget AVVIATO adesso (si fara' vivo alle 18:05)" | tee -a "$OUT"
cd "$POSTA_DIR" && git config user.name bomberr91 && git config user.email bomberr91@users.noreply.github.com
git add dal_pc/ >/dev/null 2>&1; git commit -qm "sveglia_agentrouter: esito" >/dev/null 2>&1 || true
[ -n "$TOKEN" ] && { git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1; git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; }
echo FINITO
