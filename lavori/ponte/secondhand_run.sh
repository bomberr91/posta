#!/usr/bin/env bash
# secondhand_run.sh — Open Interpreter (WSL) che parla col CERVELLO LOCALE.
#
# 4/11 (decisione del capo): Secondhand aveva la chiave NVIDIA in proprio
# ⇒ accavallamento col roster del cervello. Ora passa dal portone del cervello
# (20129) con la chiave finta "sk-cervello": zero chiavi provider toccate,
# come OpenCode, OpenClaw e Goose.
#
# Serve anche --skip-git-repo-check: il ponte lavora in /home/agenti, che non è
# una directory fidata (prima: "Not inside a trusted directory and
# --skip-git-repo-check was not specified").
set -uo pipefail

REPO="/home/agenti/posta"
[ -d "$REPO" ] || REPO="$HOME/posta"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

export OPENAI_API_KEY="sk-cervello"
export OPENAI_BASE_URL="http://127.0.0.1:20129/v1"
export OPENAI_HOST="http://127.0.0.1:20129"
export MODEL_PROVIDER="openai"
export MODEL="auto"

COMPITO="${1:-}"
if [ -z "$COMPITO" ]; then echo "compito mancante"; exit 2; fi

# 11/11: via DETERMINISTICA, a prova di falso verde. Se il compito inizia con
# PONTE_DETERMINISTICO: si esegue DIRETTAMENTE lo script, senza interpreter.
case "$COMPITO" in
  PONTE_DETERMINISTICO:*)
     S="${COMPITO#PONTE_DETERMINISTICO:}"
     echo "[secondhand_run] deterministica: bash $REPO/$S"
     exec bash "$REPO/$S"
     ;;
esac
echo "[secondhand_run] via cervello locale (nessuna chiave provider) · repo=$REPO"
python3 /home/agenti/posta/lavori/ponte/secondhand_exec.py "$COMPITO"
