#!/bin/bash
echo "## AUTONOMIA ALL'AVVIO — $(date '+%H:%M')"
STARTUP="[CHIAVE-RIMOSSA] Menu/Programs/Startup"
DESK="/mnt/c/Users/giopi/Desktop"
ARCHIVIO="[CHIAVE-RIMOSSA]"
echo
echo "### 1. Cosa c'era già in Esecuzione automatica"
ls -la "$STARTUP" 2>/dev/null | tail -n +2
echo
echo "### 2. Creo AGENTI_INVISIBILI.vbs (postino + cervello + OmniRoute, guardiani infiniti)"
cat > /tmp/agenti.vbs << 'VEOF'
' AGENTI INVISIBILI - avvia postino, cervello e OmniRoute SENZA finestre.
' Ogni riga e' un guardiano infinito: se il processo muore, lo rilancia da solo.
Set sh = CreateObject("WScript.Shell")
sh.Run "wsl.exe bash -lc ""sleep 15; while true; do flock -n /tmp/postino.lk bash -c 'cd ~/posta; git pull -q; bash postino.sh --loop'; sleep 60; done""", 0, False
sh.Run "wsl.exe bash -lc ""sleep 15; while true; do flock -n /tmp/cervello.lk bash -c 'cd ~/posta; python3 cervello.py'; sleep 60; done""", 0, False
sh.Run "wsl.exe bash -lc ""sleep 25; while true; do flock -n /tmp/omni.lk bash -c '. ~/.nvm/nvm.sh; OMNIROUTE_SERVER_HOST=127.0.0.1 omniroute'; sleep 120; done""", 0, False
VEOF
sed 's/$/\r/' /tmp/agenti.vbs > "$STARTUP/AGENTI_INVISIBILI.vbs" && echo "✓ creato in Esecuzione automatica"
echo
echo "### 3. Vecchi lanciatori del postino da togliere (se ci sono)"
mkdir -p "$ARCHIVIO"
for f in "$STARTUP"/*ostino* "$STARTUP"/*OSTINO*; do
  [ -f "$f" ] && mv "$f" "$ARCHIVIO/" && echo "archiviato: $(basename "$f")"
done
echo "(i WIDGET_* non si toccano)"
echo
echo "### 4. Pulizia bat dal Desktop → archiviati in AgentWorkspace/vecchi_bat"
for f in "$DESK/ACCENDI_CERVELLO.bat" "$DESK/ACCENDI_OMNIROUTE.bat" "$DESK/PUNTA_OPENCLAW_CERVELLO.bat" "[CHIAVE-RIMOSSA].bat"; do
  [ -f "$f" ] && mv "$f" "$ARCHIVIO/" && echo "archiviato: $(basename "$f")"
done
echo
echo "### 5. Com'è rimasto il Desktop (solo .bat e .lnk)"
ls "$DESK" | grep -Ei '\.(bat|lnk|vbs)$' || echo "(pulito)"
