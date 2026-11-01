#!/bin/bash
cd ~/posta
echo "## BLINDATURA GUARDIANI v2 — $(date '+%H:%M')"
echo "### 1. Postino rinato? (se leggi questo: sì ✓) · conteggio loop:"
ps aux | grep -c "postino.sh --loo[p]"
echo "### 2. Task vecchio davvero disattivato?"
/mnt/c/Windows/System32/schtasks.exe /query /tn "Agenti - Postino" /fo list 2>/dev/null | tr -d '\r' | grep -iE "stato|status" | head -1
echo "### 3. Riscrivo AGENTI_INVISIBILI.vbs → ora chiama le scorte (nomi innocui)"
chmod +x lavori/scorta_*.sh
cat > /tmp/agenti.vbs << 'VEOF'
' AGENTI INVISIBILI v2 - scorte con nomi innocui (anti self-match)
Set sh = CreateObject("WScript.Shell")
sh.Run "wsl.exe bash -lc ""bash ~/posta/lavori/scorta_posta.sh""", 0, False
sh.Run "wsl.exe bash -lc ""bash ~/posta/lavori/scorta_cervello.sh""", 0, False
sh.Run "wsl.exe bash -lc ""bash ~/posta/lavori/scorta_motore.sh""", 0, False
VEOF
sed 's/$/\r/' /tmp/agenti.vbs > "/mnt/c/Users/giopi/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/AGENTI_INVISIBILI.vbs"
echo "✓ VBS v2 scritto (attivo dal prossimo boot; gli attuali restano validi fino ad allora)"
