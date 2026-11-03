#!/usr/bin/env bash
# gateway_diag.sh — il Gateway OpenClaw (18789) non ascolta: perche'?
# SOLO LETTURA: nessun kill, nessuna modifica.
set -u
WIN=/mnt/c/Users/giopi
OC="$WIN/.openclaw"
LOCKS="$WIN/AppData/Local/openclaw/locks/openclaw-state-owners"

echo "Data: $(date '+%d/%m/%Y %H:%M:%S')"
echo "Acceso da: $(uptime -p 2>/dev/null || uptime)"
echo

echo "## Porte"
python3 - << 'PY'
import socket
for p, n in ((20128, "motore OmniRoute"), (20129, "cervello"), (18789, "Gateway OpenClaw"), (18800, "browser agenti")):
    s = socket.socket(); s.settimeout(2)
    try:
        s.connect(("127.0.0.1", p)); print("  VIVO  %-16s %d" % (n, p))
    except Exception:
        print("  KO    %-16s %d" % (n, p))
    finally:
        s.close()
PY
echo

echo "## Processi node.exe con openclaw (Windows)"
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { \$_.Name -eq 'node.exe' } | Select-Object ProcessId,CreationDate,CommandLine | Format-List" 2>&1 | tr -d '\r' | head -40
echo

echo "## Lock dello state directory"
ls -la "$LOCKS" 2>/dev/null | tr -d '\r' || echo "(cartella assente)"
echo

echo "## Startup: cosa c'è"
ls -la "$WIN/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/" 2>/dev/null | tr -d '\r'
echo
echo "--- 'OpenClaw Gateway.vbs' ---"
cat "$WIN/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/OpenClaw Gateway.vbs" 2>/dev/null | tr -d '\r'
echo
echo "--- gateway.cmd (prime righe) ---"
head -25 "$OC/gateway.cmd" 2>/dev/null | tr -d '\r'
echo

echo "## Log OpenClaw: i piu' recenti (Windows)"
find "$OC" -maxdepth 3 -name '*.log' -mmin -240 2>/dev/null | while IFS= read -r f; do
  echo "--- $f ($(stat -c %y "$f" 2>/dev/null | cut -c1-19)) ---"
  tail -25 "$f" | tr -d '\r'
  echo
done
echo "## Log OpenClaw: i piu' recenti (WSL)"
find "$HOME/.openclaw" -maxdepth 3 -name '*.log' -mmin -240 2>/dev/null | head -5 | while IFS= read -r f; do
  echo "--- $f ($(stat -c %y "$f" 2>/dev/null | cut -c1-19)) ---"
  tail -15 "$f" | tr -d '\r'
  echo
done
echo "## Fine"
