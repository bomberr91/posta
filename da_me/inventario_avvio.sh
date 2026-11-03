#!/usr/bin/env bash
# Inventario: cosa si avvia davvero quando accendi il PC.
# Girato dal postino sul PC -> referto in dal_pc/inventario_avvio.md
set -u
W=/mnt/c/Users/giopi
STARTUP="$W/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"

echo "=== 1. CARTELLA STARTUP (Windows) ==="
ls -la "$STARTUP" 2>/dev/null | tr -d '\r'
for f in "$STARTUP"/*.vbs "$STARTUP"/*.cmd "$STARTUP"/*.bat; do
  [ -f "$f" ] || continue
  echo "--- $(basename "$f") ---"
  tr -d '\r' < "$f"
  echo
done

echo
echo "=== 2. TASKS PIANIFICATE DI WINDOWS ==="
schtasks.exe /Query /FO CSV 2>/dev/null | tr -d '\r' | head -80

echo
echo "=== 3. AVVIO AUTOMATICO DA REGISTRO ==="
echo "--- HKCU Run ---"
reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2>/dev/null | tr -d '\r'
echo "--- HKLM Run ---"
reg.exe query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" 2>/dev/null | tr -d '\r'

echo
echo "=== 4. PROCESSI NOSTRI IN WSL ==="
for nome in scorta_cervello scorta_motore scorta_posta cervello omniroute postino magpie openclaw; do
  n=$(pgrep -fa "$nome" 2>/dev/null | wc -l)
  echo "== $nome : $n"
  pgrep -fa "$nome" 2>/dev/null | head -3
done

echo
echo "=== 5. SONDE SULLE PORTE (vero, non 'ss') ==="
python3 - <<'PY'
import socket
for porta, nome in ((20128, "motore OmniRoute"), (20129, "cervello/portiere"),
                    (18789, "Gateway OpenClaw (Windows)"), (18800, "browser isolato")):
    s = socket.socket()
    s.settimeout(2)
    try:
        s.connect(("127.0.0.1", porta))
        print("  VIVO   %s porta %d" % (nome, porta))
    except Exception as e:
        print("  spento %s porta %d (%s)" % (nome, porta, type(e).__name__))
    finally:
        s.close()
PY

echo
echo "=== 6. REGOLA DEI 60 SECONDI: dove e' codificata ==="
ls -la ~/posta/lavori/ 2>/dev/null | head -20
grep -rn -e "60" -e "sleep" ~/posta/lavori/*.sh 2>/dev/null | head -12

echo
echo "=== 7. SCRIPT DI AVVIO NEL REPO ==="
ls -la ~/posta/fatti/riavvia_guardiani.sh ~/posta/fatti/accendi_omniroute_e_rilancia.sh 2>/dev/null
