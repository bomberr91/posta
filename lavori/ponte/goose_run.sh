#!/usr/bin/env bash
# goose_run.sh — lancia goose CONTRO IL CERVELLO LOCALE (nessuna chiave provider).
#
# Perche' (4/11): la prima versione di questo wrapper usava la chiave
# OpenRouter, ma OpenRouter e' ANCHE nel roster del cervello (quota 15/min,
# 45/giorno): due strumenti sulla stessa chiave = accavallamento.
# Il cervello (porta 20129) e' gia' il nostro allocatore: goose gli parla con
# la chiave finta "sk-cervello" e non tocca nessuna chiave provider.
# Test reale sul PC (4/11): "goose is ready" -> "OK", exit 0.
#
# Se il cervello non risponde, goose esce con un messaggio chiaro: non si
# ripiega su una chiave provider in silenzio (consumerebbe quota di altri).
set -uo pipefail

REPO="/home/agenti/posta"
[ -d "$REPO" ] || REPO="$HOME/posta"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

COMPITO="${1:-}"
if [ -z "$COMPITO" ]; then echo "compito mancante"; exit 2; fi

if ! python3 - << 'PY'
import urllib.request, sys
try:
    urllib.request.urlopen("http://127.0.0.1:20129/salute", timeout=10).read()
except Exception as e:
    print("cervello non raggiungibile su 127.0.0.1:20129 (%s)" % str(e)[:120])
    sys.exit(1)
PY
then
  echo "goose non parte: il cervello locale non risponde (niente fallback su chiavi provider)"
  exit 4
fi

export GOOSE_PROVIDER=openai
export GOOSE_MODEL="${GOOSE_MODEL:-auto}"
export OPENAI_HOST=http://127.0.0.1:20129
export OPENAI_BASE_URL=http://127.0.0.1:20129/v1
export OPENAI_API_KEY=sk-cervello

GOOSE_BIN="$(command -v goose 2>/dev/null || echo /home/agenti/.local/bin/goose)"
echo "[goose_run] via cervello locale (nessuna chiave provider) · modello=$GOOSE_MODEL · bin=$GOOSE_BIN"
exec "$GOOSE_BIN" run -t "$COMPITO"
