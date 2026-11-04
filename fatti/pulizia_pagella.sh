#!/usr/bin/env bash
# 4/11 notte - ARENA: pulizia dei FALSI ERRORI del portiere (via del capo:
# "sistema questa cosa di modo che non dia piu' il falso errore")
# Cosa fa:
#   1) backup di portiere_stato.json
#   2) toglie da castighi/pagella le voci dei provider che NON sono piu' nel
#      catalogo (i 5 falsi "✅ risolto 21/10 ...", piu' LongCat e NaraRouter
#      usciti dal roster) -> niente piu' castighi/punizioni su provider inesistenti
#   3) il portiere tiene lo stato in memoria: perche' la pulizia Stick,
#      si ferma SOLO il suo PID (mai taskkill di python.exe) e lo riavvia con
#      la STESSA riga di comando letta da /proc
#   4) se non torna, si ripristina il backup e si riavvia lo stesso comando
# NON tocca: il roster, il portachiavi, le chiavi.
set -u
REPO="$HOME/posta"
OUT="$REPO/dal_pc/pulizia_pagella.md"
mkdir -p "$REPO/dal_pc"
cd "$REPO" || { echo "non trovo $REPO" > "$OUT"; exit 1; }
TS=$(date +%Y%m%d-%H%M%S)

CMDLINE=""; PID=""
for p in $(pgrep -f "cervello.py" 2>/dev/null); do
  if [ "$p" != "$$" ]; then PID="$p"; break; fi
done
if [ -n "$PID" ] && [ -r "/proc/$PID/cmdline" ]; then
  CMDLINE=$(tr '\0' ' ' < "/proc/$PID/cmdline")
fi

{
  echo "# PULIZIA FALSI ERRORI DEL PORTIERE — $(date '+%d/%m/%Y %H:%M')"
  echo ""
  echo "PID del portiere: ${PID:-nessuno}"
  echo "riga di comando: ${CMDLINE:-non letta}"
  echo ""
} > "$OUT"

cp -f portiere_stato.json "portiere_stato.json.bak-$TS" 2>/dev/null && echo "backup: portiere_stato.json.bak-$TS" >> "$OUT"

# --- 1) fermo il portiere (solo il suo PID) ---
if [ -n "$PID" ]; then
  kill "$PID" 2>/dev/null
  for i in 1 2 3 4 5 6 7 8 9 10; do
    kill -0 "$PID" 2>/dev/null || break
    sleep 1
  done
  kill -0 "$PID" 2>/dev/null && { kill -9 "$PID" 2>/dev/null; sleep 1; }
  echo "portiere fermato (pid $PID)" >> "$OUT"
else
  echo "portiere non trovato fra i processi: pulisco lo stato e basta" >> "$OUT"
fi

# --- 2) pulizia dello stato ---
python3 - "$REPO" >> "$OUT" 2>&1 << 'PYEOF'
import json, os, sys
REPO = sys.argv[1]
lista = os.path.join(REPO, "portiere_lista.txt")
validi = set()
for r in open(lista, encoding="utf-8", errors="replace"):
    r = r.strip()
    if not r or r.startswith("#"):
        continue
    f = r.split("|")
    if len(f) >= 5 and f[3].strip():
        validi.add(f[0].strip())
path = os.path.join(REPO, "portiere_stato.json")
st = json.load(open(path, encoding="utf-8"))
pag = st.get("pagella", {}) or {}
cast = st.get("castighi", {}) or {}
out_pag = {k: v for k, v in pag.items() if k in validi}
out_cast = {}
for k, v in cast.items():
    pid = str(k).split("|")[0].strip()
    if pid in validi:
        out_cast[k] = v
tolti_p = sorted(set(pag) - set(out_pag))
tolti_c = sorted(set(cast) - set(out_cast))
st["pagella"] = out_pag
st["castighi"] = out_cast
tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(st, f, ensure_ascii=False, indent=1)
os.replace(tmp, path)
print("provider validi nel catalogo: %d" % len(validi))
print("voci di PAGELLA tolte: %d" % len(tolti_p))
for t in tolti_p:
    print("   - %s" % t[:90])
print("voci di CASTIGHI tolte: %d" % len(tolti_c))
for t in tolti_c:
    print("   - %s" % t[:90])
print("pagella rimasta: %d | castighi rimasti: %d" % (len(out_pag), len(out_cast)))
PYEOF

# --- 3) riavvio con la stessa riga di comando ---
if [ -n "$CMDLINE" ]; then
  ( cd "$REPO" && nohup $CMDLINE > /tmp/cervello.log 2>&1 & )
  echo "riavviato con: $CMDLINE" >> "$OUT"
else
  echo "nessuna riga di comando: NON riavvio (il portiere resta fermo: riavialo tu)" >> "$OUT"
fi

# --- 4) il portiere risponde? ---
python3 - >> "$OUT" 2>&1 << 'PYEOF'
import json, time, urllib.request
ok = False
for i in range(20):
    try:
        with urllib.request.urlopen("http://127.0.0.1:20129/v1/models", timeout=4) as r:
            d = json.loads(r.read().decode())
        n = len(d.get("data") or [])
        print("portiere RISPONDE: %d modelli in elenco" % n)
        ok = True
        break
    except Exception as e:
        time.sleep(2)
if not ok:
    print("portiere NON risponde dopo 40 s")
PYEOF

if grep -q "portiere RISPONDE" "$OUT"; then
  echo "" >> "$OUT"; echo "ESITO: OK — falsi errori spariscono, portiere vivo" >> "$OUT"
else
  # ripristino: backup + riavvio
  cp -f "portiere_stato.json.bak-$TS" portiere_stato.json 2>/dev/null
  if [ -n "$CMDLINE" ]; then ( cd "$REPO" && nohup $CMDLINE > /tmp/cervello.log 2>&1 & ); fi
  echo "" >> "$OUT"; echo "ESITO: FALLITO — stato ripristinato dal backup, riavvio rifatto" >> "$OUT"
fi
echo "--- pulizia_pagella: referto in dal_pc/pulizia_pagella.md ---"
