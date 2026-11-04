#!/bin/bash
# DEEP DOG RICERCA — il cane richiamabile dagli agenti (1/11 sera)
#
# Il Deep Dog (Windows, porta 8765) fa ricerche con fonti e scrive i report
# nella cartella outputs/. Prima gli agenti potevano solo LEGGERE i report
# vecchi: non potevano chiederne uno nuovo. Il capo l'ha regalato agli agenti
# in locale, quindi deve essere SEMPRE richiamabile da loro.
#
#   bash lavori/deepdog_ricerca.sh "la domanda"
#
# Fa: controlla che il cane sia vivo → gli passa la domanda → aspetta il
# report → lo copia in dal_pc/deepdog_reports/ (il postino lo pubblica) →
# dice dove sta il file e cosa ha risposto.
set -uo pipefail
PORT="${DEEPDOG_PORT:-8765}"
# --- helper HTTP: nella WSL del PC il `curl` NON esiste -> python3 (4/11) ---
http_get() {
  python3 - "$1" << 'PYGET'
import sys, urllib.request
try:
    with urllib.request.urlopen(sys.argv[1], timeout=8) as r:
        sys.stdout.write(r.read().decode("utf-8", "replace"))
except Exception:
    sys.exit(1)
PYGET
}

http_post() {
  python3 - "$1" "$2" << 'PYPOST'
import sys, urllib.request
try:
    req = urllib.request.Request(sys.argv[1], data=sys.argv[2].encode("utf-8"),
                                 headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=25) as r:
        sys.stdout.write(r.read().decode("utf-8", "replace"))
except Exception:
    sys.exit(1)
PYPOST
}

PORT="${DEEPDOG_PORT:-8765}"
DD_OUT="/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog/outputs"
cd "$HOME/posta" || exit 1
mkdir -p dal_pc/deepdog_reports

DOMANDA="${1:-}"
if [ -z "$DOMANDA" ]; then
  echo "uso: bash lavori/deepdog_ricerca.sh \"la domanda\""
  exit 1
fi
T0=$(date +%s)

# 1. il cane è vivo? SE NON LO È, LO AVVIO IO (il capo non deve fare niente
#    sul PC: il cane è un regalo per gli agenti, e gli agenti lo avviano)
if ! http_get "http://127.0.0.1:$PORT/api/status" >/dev/null 2>&1; then
  echo "il cane non gira: lo avvio io"
  BAT='C:\Users\giopi\Documents\AgentWorkspace\deepdog\Avvia Deep Dog Web.bat'
  cmd.exe /c start "" "$BAT" >/dev/null 2>&1
  for i in $(seq 1 30); do
    sleep 4
    if http_get "http://127.0.0.1:$PORT/api/status" >/dev/null 2>&1; then
      echo "cane avviato e vivo (~$((i*4))s)"
      break
    fi
  done
  if ! http_get "http://127.0.0.1:$PORT/api/status" >/dev/null 2>&1; then
    echo "non sono riuscito ad avviarlo. Prova: doppio click su 'Avvia Deep Dog Web.bat'"
    echo "oppure guarda se il venv esiste: /mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog/.venv"
    exit 1
  fi
else
  echo "cane vivo (porta $PORT)"
fi

# 2. la domanda
echo "domanda: $DOMANDA"
PILLO=$(python3 -c 'import json,sys; print(json.dumps({"prompt": sys.argv[1]}))' "$DOMANDA" 2>/dev/null)
if [ -z "$PILLO" ]; then echo "non riesco a preparare la domanda"; exit 1; fi
if ! http_post "http://127.0.0.1:$PORT/api/start" "$PILLO" >/dev/null 2>&1; then
  echo "il cane ha rifiutato la domanda"; exit 1
fi
echo "domanda mandata, aspetto il report (max 10 minuti)..."

# 3. aspetto che finisca
FINITO=""
ST=""
for i in $(seq 1 120); do
  sleep 5
  ST=$(http_get "http://127.0.0.1:$PORT/api/status" 2>/dev/null)
  S=$(printf '%s' "$ST" | python3 -c "import json,sys
try: print(json.load(sys.stdin).get('status','?'))
except Exception: print('?')" 2>/dev/null)
  case "$S" in
    done|failed|completed) FINITO="$S"; break ;;
  esac
done
if [ -z "$FINITO" ]; then
  echo "il cane non ha finito in tempo (10 minuti). Guarda la finestra: http://localhost:$PORT"
  exit 1
fi
echo "stato: $FINITO"

# 4. il report
STAMP=$(date '+%Y-%m-%d_%H-%M-%S')
NOME="deepdog_ricerca_${STAMP}.md"
ERRORE=$(printf '%s' "$ST" | python3 -c "import json,sys
try: print((json.load(sys.stdin).get('error') or '').strip())
except Exception: print('')" 2>/dev/null)

# 4a. il file vero del cane (c'è dentro anche le fonti)
ULTIMO=""
for f in $(ls -t "$DD_OUT"/*.md 2>/dev/null | head -3); do
  MT=$(stat -c %Y "$f" 2>/dev/null || echo 0)
  if [ "$MT" -ge "$T0" ]; then ULTIMO="$f"; break; fi
done
if [ -n "$ULTIMO" ]; then
  cp "$ULTIMO" "dal_pc/deepdog_reports/$NOME" 2>/dev/null \
    && echo "report: dal_pc/deepdog_reports/$NOME  (dal file del cane: $(basename "$ULTIMO"))"
else
  printf '%s' "$ST" | python3 -c "import json,sys
try:
    d=json.load(sys.stdin); print(d.get('report') or '(il cane non ha scritto un report)')
except Exception:
    print('(status non leggibile)')" > "dal_pc/deepdog_reports/$NOME" 2>/dev/null
  echo "report: dal_pc/deepdog_reports/$NOME  (dal testo dello stato)"
fi
if [ -n "$ERRORE" ]; then
  echo "errore del cane: $ERRORE" | head -c 400; echo
fi
echo "--- estratto:"
head -30 "dal_pc/deepdog_reports/$NOME" 2>/dev/null | sed 's/^/   /'
echo
echo "il postino pubblica i report in dal_pc/deepdog_reports/ -> gli agenti li ritrovano nel repo"
[ "$FINITO" = "failed" ] && exit 1
exit 0
