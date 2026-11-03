#!/bin/bash
# stato_ponte.sh — quadro umano del ponte: demone, chi lavora, coda, processi.
cd ~/posta/lavori/ponte || exit 1
echo "== Ponte arena → agenti locali =="
if pgrep -f "poller.py" > /dev/null; then
  echo "demone: ATTIVO (pid $(pgrep -f 'poller.py' | head -1))"
else
  echo "demone: SPENTO  (riavvia: bash ~/posta/lavori/avvia_ponte.sh)"
fi
python3 - <<'PY'
import json, pathlib, datetime
p = pathlib.Path("_stato/ponte_stato.json")
s = json.loads(p.read_text()) if p.exists() else {}
ic = s.get("in_corso", [])
print(f"in esecuzione ora: {len(ic)}/{s.get('max_paralleli','?')}")
for t in ic:
    print(f"  - issue #{t['numero']} -> {t['target']} (dalle {t['dal']})")
PY
echo "processi agente vivi:"
pgrep -fa "goose run|opencode run|interpreter exec|hermes.exe|agy.exe|openclaw agent" 2>/dev/null | grep -v pgrep | head -5 || echo "  (nessuno)"
echo -n "coda GitHub (inbox): "
python3 -c "import sys; sys.path.insert(0,'.'); import poller; print(len(poller.issue_inbox()))" 2>/dev/null || echo "?"
echo "ultime consegne:"
ls -t ~/posta/consegne 2>/dev/null | head -3 || echo "  (nessuna)"
