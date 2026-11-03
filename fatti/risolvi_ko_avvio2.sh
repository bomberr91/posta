#!/usr/bin/env bash
# Secondo intervento sui KO di avvio:
#  A) OmniRoute: il ready timeout di 60s e' troppo corto (qui il cold start ne
#     mette 2-3 minuti) => il motore si arrende prima di legare la porta 20128.
#  B) Gateway OpenClaw: un'istanza zombie tiene lo "state directory" e rifiuta
#     le nuove => si ferma tutto, si toglie il lock e si avvia UNA istanza pulita.
#  C) il .vbs di avvio del Gateway aspetta 90 secondi (stessa regola dei 60 dei
#     guardiani WSL) perche' al login il PC non e' ancora pronto.
set -u
R=~/posta
[ -d "$R" ] || R=~/posta_ponte
WIN=/mnt/c/Users/giopi
STARTUP="$WIN/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"

echo "=== A. OMNIROUTE: finestra di attesa piu' generosa ==="
for f in "$R/lavori/scorta_motore.sh" \
         "$R/fatti/accendi_omniroute_e_rilancia.sh" \
         "$R/fatti/accendi_omniroute_2.sh" \
         "$WIN/Desktop/ACCENDI_OMNIROUTE.bat"; do
  [ -f "$f" ] || continue
  if grep -q "OMNIROUTE_READY_TIMEOUT_MS" "$f"; then
    echo "--- $f : gia' impostato"
  else
    sed -i 's|OMNIROUTE_SERVER_HOST=127.0.0.1|OMNIROUTE_SERVER_HOST=127.0.0.1 OMNIROUTE_READY_TIMEOUT_MS=180000|' "$f"
    echo "--- $f : corretto"
  fi
  grep -n "omniroute" "$f" | head -3
done

echo
echo "=== B. RIAVVIO DEL MOTORE CON LA NUOVA IMPOSTAZIONE ==="
PAT="scorta_""motore.sh"
pkill -f "$PAT" >/dev/null 2>&1 || true
PAT2="node.*""omniroute"
pkill -f "$PAT2" >/dev/null 2>&1 || true
sleep 3
rm -f /tmp/omni.lk
nohup bash "$R/lavori/scorta_motore.sh" >/dev/null 2>&1 &
echo "guardiano del motore riavviato (pid $!) con timeout 180s"

echo
echo "=== C. GATEWAY: via alle istanze zombie e lock ==="
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { \$_.Name -eq 'node.exe' -and \$_.CommandLine -like '*openclaw*' -and \$_.ProcessId -ne \$PID } | ForEach-Object { Write-Host ('ucciso ' + \$_.ProcessId); Stop-Process -Id \$_.ProcessId -Force }" 2>&1 | tr -d '\r'
sleep 3
LOCKS="$WIN/AppData/Local/openclaw/locks/openclaw-state-owners"
echo "--- lock di stato prima ---"
ls -la "$LOCKS" 2>/dev/null | tr -d '\r' || echo "(nessuna cartella)"
rm -f "$LOCKS"/*.lock 2>/dev/null || true
echo "--- lock rimossi ---"

echo
echo "=== D. IL .vbs DI AVVIO ASPETTA 90 SECONDI ==="
cat > "$STARTUP/OpenClaw Gateway.vbs" << 'VBS'
' OpenClaw Gateway - aspetta 90 secondi (stessa regola dei 60 dei guardiani WSL):
' al login il PC non e' ancora pronto e il Gateway si impianta sul lock di stato.
Set shell = CreateObject("WScript.Shell")
shell.Environment("Process")("OPENCLAW_WINDOWS_TASK_HIDDEN_LAUNCHER") = "wscript"
WScript.Quit shell.Run("cmd.exe /c ""timeout /t 90 /nobreak >nul & C:\Users\giopi\.openclaw\gateway.cmd""", 0, True)
VBS
ls -la "$STARTUP" | tr -d '\r'

echo
echo "=== E. AVVIO DI UN'ISTANZA PULITA DEL GATEWAY ==="
cmd.exe /c start "" "C:\Users\giopi\.openclaw\gateway.cmd" >/dev/null 2>&1 || true
echo "lanciato (il Gateway mette 1-2 minuti a salire)"

echo
echo "=== F. VERIFICA DOPO 150 SECONDI ==="
sleep 150
python3 - << 'PY'
import socket
for p, n in ((20128, "motore OmniRoute"), (20129, "cervello"), (18789, "Gateway OpenClaw")):
    s = socket.socket()
    s.settimeout(2)
    try:
        s.connect(("127.0.0.1", p))
        print("  VIVO  %-16s %d" % (n, p))
    except Exception:
        print("  KO    %-16s %d" % (n, p))
    finally:
        s.close()
PY

echo
echo "=== G. PROCESSI ==="
for n in scorta_motore omniroute postino cervello; do
  printf "%-16s %s\n" "$n" "$(pgrep -fa "$n" 2>/dev/null | wc -l)"
done
echo "--- ultimo pezzo di /tmp/scorta_motore.log ---"
tail -12 /tmp/scorta_motore.log 2>/dev/null
