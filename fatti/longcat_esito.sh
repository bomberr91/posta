#!/usr/bin/env bash
# Esito della sonda LongCat: quando rinnova la quota?
# Girato dal postino sul PC -> referto in dal_pc/longcat_esito.md
set -u
LOG="$HOME/sonda_longcat.log"

echo "=== LOG SONDA LONGCAT ($LOG) ==="
if [ ! -f "$LOG" ]; then
  echo "log assente"
else
  python3 - <<'PY'
import os, re
from collections import Counter
log = os.path.expanduser("~/sonda_longcat.log")
righe = [l.rstrip("\n") for l in open(log, encoding="utf-8", errors="replace") if l.strip()]
print("righe totali: %d" % len(righe))
if righe:
    print("prima: %s" % righe[0][:150])
    print("ultima: %s" % righe[-1][:150])
codici = Counter()
transizioni = []
prev = None
for l in righe:
    m = re.match(r"\s*([0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2})\s*\|\s*([A-Za-z0-9]+)\s*\|?\s*(.*)", l)
    if not m:
        continue
    ts, code, msg = m.group(1), m.group(2), m.group(3)
    codici[code] += 1
    if code != prev:
        transizioni.append((ts, code, msg[:120]))
        prev = code
print("campioni per esito: %s" % dict(codici))
print()
print("--- CAMBI DI ESITO (quando la quota e' tornata) ---")
if not transizioni:
    print("(nessun cambio: la quota non e' mai tornata nei campioni)")
for ts, code, msg in transizioni[:60]:
    print("%s  ->  %-8s %s" % (ts, code, msg))
PY
fi

echo
echo "=== LA SONDA E' ANCORA VIVA? ==="
if [ -f "$HOME/.sonda_longcat.pid" ] && kill -0 "$(cat "$HOME/.sonda_longcat.pid" 2>/dev/null)" 2>/dev/null; then
  echo "sonda VIVA (pid $(cat "$HOME/.sonda_longcat.pid"))"
else
  echo "sonda FERMA (l'ha uccisa il riavvio)"
fi

echo
echo "=== RIACCENDO LA SONDA ==="
for d in "$HOME/posta" "$HOME/posta_ponte"; do
  if [ -f "$d/fatti/sonda_longcat.sh" ]; then
    bash "$d/fatti/sonda_longcat.sh" 2>&1 | tail -6
    break
  fi
done

echo
echo "=== ORA ITALIANA ADESSO ==="
date '+%d/%m %Y %H:%M:%S %Z'
