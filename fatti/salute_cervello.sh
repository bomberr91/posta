#!/bin/bash
# salute_cervello.sh — stato dei servizi locali, letto dal PC (WSL).
# Il postino esegue questo file e mette il suo stdout in dal_pc/salute_cervello.md
# Non scrive file: parla solo con lo stdout, cosi' il rapporto arriva dove deve.

echo "## Cervello e portiere"
python3 - <<'PY'
import urllib.request
for nome, url in [("portiere 20129", "http://127.0.0.1:20129/salute"),
                  ("motore   20128", "http://127.0.0.1:20128/v1/models")]:
    try:
        r = urllib.request.urlopen(url, timeout=5).read().decode(errors="replace")
        print(f"- {nome}: RISPONDE {r[:300]}")
    except Exception as e:
        print(f"- {nome}: NON RISPONDE ({type(e).__name__})")
PY

echo ""
echo "## Processi di guardia (guardiano, sentinella, scorer)"
ps -ef 2>/dev/null | grep -E "guardiano|sentinella|scorca_cervello|postino" | grep -v grep \
  | sed -E 's/^[^ ]+ +[0-9]+ +[0-9]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[0-9:]+ +[0-9:]+ +//' \
  | cut -c1-160 | head -8

echo ""
echo "## Ultime 3 richieste nel portiere_log.jsonl"
tail -n 3 ~/posta/portiere_log.jsonl 2>/dev/null | cut -c1-300

echo ""
echo "## Browser isolato OpenClaw (CDP 18800)"
python3 - <<'PY'
import urllib.request
try:
    r = urllib.request.urlopen("http://127.0.0.1:18800/json/version", timeout=4).read().decode(errors="replace")
    print("- CDP 18800: RISPONDE", r[:200])
except Exception as e:
    print(f"- CDP 18800: non risponde ({type(e).__name__}) -> browser OpenClaw da riavviare")
PY
