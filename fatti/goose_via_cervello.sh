#!/usr/bin/env bash
# goose_via_cervello.sh — prova goose CONTRO il cervello locale (nessuna chiave provider).
#
# Motivo (4/11): il wrapper di goose usava la chiave OpenRouter, che e' anche
# nel roster del cervello (quota 15/min e 45/giorno): due strumenti sulla stessa
# chiave = accavallamento. Il cervello (20129) e' gia' il nostro allocatore:
# se goose gli parla, non tocca nessuna chiave provider e non compete con
# l'appello.
#
# Prova le due forme di endpoint (con e senza /v1) e riporta quale funziona.
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || exit 1
GOOSE_BIN="$(command -v goose 2>/dev/null || echo /home/agenti/.local/bin/goose)"

echo "### 0. IL CERVELLO E' VIVO?"
if command -v curl >/dev/null 2>&1; then
  curl -fsS -m 15 http://127.0.0.1:20129/salute | head -c 300; echo
else
  python3 - << 'PY'
import urllib.request
try:
    print(urllib.request.urlopen("http://127.0.0.1:20129/salute", timeout=15).read().decode()[:300])
except Exception as e:
    print("salute non raggiungibile:", str(e)[:150])
PY
fi
echo "--- modelli esposti dal cervello"
python3 - << 'PY'
import urllib.request, json
try:
    d = json.loads(urllib.request.urlopen("http://127.0.0.1:20129/v1/models", timeout=15).read().decode())
    print("   " + ", ".join(m.get("id", "?") for m in d.get("data", [])[:12]))
except Exception as e:
    print("   non raggiungibile:", str(e)[:150])
PY
echo

prova() {
  local etichetta="$1"; shift
  echo "### PROVA: $etichetta"
  echo "    env: $*"
  ( export "$@" ; timeout 300 "$GOOSE_BIN" run -t "Rispondi esattamente con la parola OK e nient'altro." 2>&1 | tail -25 )
  local rc=${PIPESTATUS[0]}
  echo "--- exit: $rc"
  echo
  return $rc
}

RC=1
prova "A: OPENAI_HOST senza /v1" \
  GOOSE_PROVIDER=openai GOOSE_MODEL=auto \
  OPENAI_HOST=http://127.0.0.1:20129 OPENAI_BASE_URL=http://127.0.0.1:20129/v1 \
  OPENAI_API_KEY=sk-cervello && RC=0

if [ "$RC" -ne 0 ]; then
  RC=1
  prova "B: OPENAI_HOST con /v1" \
    GOOSE_PROVIDER=openai GOOSE_MODEL=auto \
    OPENAI_HOST=http://127.0.0.1:20129/v1 OPENAI_BASE_URL=http://127.0.0.1:20129/v1 \
    OPENAI_API_KEY=sk-cervello && RC=0
fi

if [ "$RC" -ne 0 ]; then
  RC=1
  prova "C: modello policy 'gratis'" \
    GOOSE_PROVIDER=openai GOOSE_MODEL=gratis \
    OPENAI_HOST=http://127.0.0.1:20129 OPENAI_BASE_URL=http://127.0.0.1:20129/v1 \
    OPENAI_API_KEY=sk-cervello && RC=0
fi

echo "### VERDETTO"
if [ "$RC" -eq 0 ]; then
  echo "GOOSE PARLA COL CERVELLO: si puo' togliere la chiave OpenRouter dal wrapper (zero accavallamento)"
else
  echo "GOOSE NON PARLA COL CERVELLO (exit $RC): per ora il wrapper resta su OpenRouter e la conflitto va dichiarato nel libro mastro"
fi
exit "$RC"
