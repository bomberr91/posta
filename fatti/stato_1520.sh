#!/usr/bin/env bash
# misura di stato rapida (sola lettura) — il postino la gira sul PC
set -u
echo "Data: $(date '+%d/%m/%Y %H:%M:%S')  |  acceso da: $(uptime -p 2>/dev/null | sed 's/up //')"
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
for n in scorta_posta scorta_cervello scorta_motore "postino.sh --loop" omniroute sonda_longcat_loop sveglia_loop; do
  printf "  %-22s %s\n" "$n" "$(pgrep -fc "$n" 2>/dev/null || echo 0)"
done
echo "  ultimo campione LongCat: $(tail -1 "$HOME/sonda_longcat.log" 2>/dev/null | cut -c1-120)"
