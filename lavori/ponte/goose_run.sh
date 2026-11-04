#!/usr/bin/env bash
# goose_run.sh — lancia goose con la chiave OpenRouter presa dal portachiavi.
#
# Perche' serve (4/11): goose 1.55 NON legge la chiave da config.yaml ("Configuration
# value not found: OPENROUTER_API_KEY ... check your system keychain"), e la WSL
# non ha un keyring. Quindi qui la chiave si legge dal portachiavi e si passa per
# environment. La chiave non viene mai stampata.
#
# Uso: bash goose_run.sh "<compito>"
set -uo pipefail

REPO="/home/agenti/posta"
[ -d "$REPO" ] || REPO="$HOME/posta"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

COMPITO="${1:-}"
if [ -z "$COMPITO" ]; then echo "compito mancante"; exit 2; fi

CHIAVE="$(python3 "$REPO/chiave_di.py" "OpenRouter" 2>/dev/null | head -1)"
if [ -z "$CHIAVE" ]; then
  echo "chiave OpenRouter non trovata nel portachiavi"
  exit 3
fi

export OPENROUTER_API_KEY="$CHIAVE"
export GOOSE_PROVIDER=openrouter
export GOOSE_MODEL="${GOOSE_MODEL:-nvidia/nemotron-3-ultra-550b-a55b:free}"
export GOOSE_MAX_TOKENS="${GOOSE_MAX_TOKENS:-8192}"

GOOSE_BIN="$(command -v goose 2>/dev/null || echo /home/agenti/.local/bin/goose)"
echo "[goose_run] provider=$GOOSE_PROVIDER model=$GOOSE_MODEL bin=$GOOSE_BIN"
exec "$GOOSE_BIN" run -t "$COMPITO"
