#!/usr/bin/env bash
# Risolve i KO dell'avvio: motore OmniRoute (20128) e Gateway OpenClaw (18789).
# Girato dal postino sul PC -> referto in dal_pc/risolvi_ko_avvio.md
set -u
R=~/posta
[ -d "$R" ] || R=~/posta_ponte
WIN=/mnt/c/Users/giopi

echo "=== 1. PROCESSI ==="
for n in scorta_cervello scorta_motore scorta_posta cervello omniroute postino openclaw; do
  printf "%-16s %s\n" "$n" "$(pgrep -fa "$n" 2>/dev/null | wc -l)"
  pgrep -fa "$n" 2>/dev/null | head -2 | sed 's/^/    /'
done

echo
echo "=== 2. LOG ==="
for f in /tmp/scorta_motore.log /tmp/scorta_cervello.log /tmp/postino.log /tmp/omniroute_avvio.log; do
  echo "--- $f"
  [ -f "$f" ] && tail -12 "$f" || echo "(assente)"
done

echo
echo "=== 3. MECCANISMO DI AVVIO ==="
STARTUP="$WIN/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
ls -la "$STARTUP" 2>/dev/null | tr -d '\r'
for f in "$STARTUP"/*.vbs; do
  [ -f "$f" ] || continue
  echo "--- $(basename "$f")"
  tr -d '\r' < "$f"
  echo
done
echo "--- ACCENDI_OMNIROUTE.bat (Desktop) ---"
cat "$WIN/Desktop/ACCENDI_OMNIROUTE.bat" 2>/dev/null | tr -d '\r' || echo "(assente)"
echo "--- script con sleep 60 (la regola dei 60 secondi) ---"
grep -rn -e "sleep 60" -e "sleep 61" -e "sleep 90" "$R"/lavori/*.sh "$R"/fatti/*.sh 2>/dev/null | head -12
echo "--- lock git ---"
ls -la "$R/.git/index.lock" 2>/dev/null || echo "(nessun lock)"

echo
echo "=== 4. LOG OPENCLAW (ultimi errori) ==="
grep -i -e error -e fail -e exit -e lock \
  "$WIN/AppData/Local/Temp/openclaw/openclaw-2026-11-03.log" 2>/dev/null | tail -10 | cut -c1-240
echo "--- lock di stato OpenClaw ---"
ls -la "$WIN/AppData/Local/openclaw/locks/openclaw-state-owners/" 2>/dev/null | tr -d '\r' || echo "(nessuna cartella)"

echo
echo "=== 5. RIPARO ==="
if [ -f "$R/.git/index.lock" ] && ! pgrep -x git >/dev/null 2>&1; then
  rm -f "$R/.git/index.lock"
  echo "lock git orfano rimosso"
fi

if pgrep -f scorta_motore >/dev/null 2>&1; then
  echo "guardiano del motore: gia' attivo"
else
  nohup bash "$R/lavori/scorta_motore.sh" >/dev/null 2>&1 &
  echo "guardiano del motore riavviato (pid $!)"
fi

if (exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null; then
  echo "motore: gia' vivo"
else
  echo "motore MUTO: lancio OmniRoute in background"
  ( export NVM_DIR="$HOME/.nvm"
    . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1
    export OMNIROUTE_SERVER_HOST=127.0.0.1
    setsid nohup omniroute >/tmp/omniroute_avvio.log 2>&1 & ) &
  sleep 5
fi

if (exec 3<>/dev/tcp/127.0.0.1/18789) 2>/dev/null; then
  echo "gateway: gia' in ascolto"
else
  echo "Gateway MUTO: lo lancio in background"
  cmd.exe /c start "" "C:\Users\giopi\.openclaw\gateway.cmd" >/dev/null 2>&1 || true
fi

echo
echo "=== 6. VERIFICA DOPO 100 secondi ==="
sleep 100
python3 - <<'PY'
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
echo "=== 7. PROCESSI DOPO IL RIPARO ==="
for n in scorta_motore omniroute openclaw; do
  printf "%-16s %s\n" "$n" "$(pgrep -fa "$n" 2>/dev/null | wc -l)"
  pgrep -fa "$n" 2>/dev/null | head -2 | sed 's/^/    /'
done
