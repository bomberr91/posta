#!/bin/bash
# diagnostica_cervello.sh — perché il motore (20128) non risponde e chi deve
# tenere d'occhio il cervello. Letto dal PC (WSL) dal postino.
# Non scrive file: parla solo con lo stdout, così il referto arriva in
# dal_pc/diagnostica_cervello.md

echo "## Porte in ascolto (20128 motore, 20129 portiere, 18789 gateway, 18800 browser)"
if command -v ss >/dev/null 2>&1; then
  ss -ltnp 2>/dev/null | grep -E ":20128|:20129|:18789|:18800" || echo "nessuna delle 4 porte in ascolto"
else
  netstat -ltnp 2>/dev/null | grep -E ":20128|:20129|:18789|:18800" || echo "ss/netstat non disponibili"
fi

echo ""
echo "## Processi: cervello, motore, guardiani"
for pat in "scorta_cervello" "scorta_motore" "cervello.py" "omni" "omniroute" "postino"; do
  trovati=$(ps -ef 2>/dev/null | grep -F "$pat" | grep -v grep | sed -E 's/^[^ ]+ +[0-9]+ +[0-9]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[0-9:]+ +[0-9:]+ +//' | cut -c1-140)
  if [ -n "$trovati" ]; then
    echo "- [$pat]"
    echo "$trovati" | sed 's/^/    /'
  else
    echo "- [$pat]: nessun processo"
  fi
done

echo ""
echo "## Log dei guardiani"
for L in /tmp/scorta_cervello.log /tmp/scorta_motore.log /tmp/scorta_posta.log; do
  if [ -f "$L" ]; then
    echo "- $L (ultime 5 righe)"
    tail -n 5 "$L" 2>/dev/null | cut -c1-200 | sed 's/^/    /'
  else
    echo "- $L: ASSENTE"
  fi
done

echo ""
echo "## Il portiere vede il motore?"
python3 - <<'PY'
import urllib.request, json
try:
    d = json.loads(urllib.request.urlopen("http://127.0.0.1:20129/salute", timeout=5).read().decode())
    print("- /salute:", json.dumps(d)[:400])
except Exception as e:
    print("- /salute: non risponde", type(e).__name__)
for porta in (20128,):
    for path in ("/v1/models", "/salute", "/"):
        try:
            urllib.request.urlopen("http://127.0.0.1:%d%s" % (porta, path), timeout=4).read()
            print(f"- {porta}{path}: RISPONDE")
        except Exception as e:
            print(f"- {porta}{path}: {type(e).__name__}")
PY

echo ""
echo "## Il motore si accende con [9] in centrale.sh?"
if [ -f "$HOME/posta/centrale.sh" ]; then
  grep -n -e "20128" -e "OmniRoute" "$HOME/posta/centrale.sh" 2>/dev/null | head -6 | sed 's/^/    /'
fi

echo ""
echo "## Ultime richieste al portiere"
tail -n 5 "$HOME/posta/portiere_log.jsonl" 2>/dev/null | cut -c1-240
