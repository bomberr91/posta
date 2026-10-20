#!/usr/bin/env bash
# squadra.sh — Lancia il nuovo motore SQUADRA FUSION 2.0 (Regista Intelligente + Barra 0%->100% + Qualità > Tempo)
export PATH="$HOME/.nvm/versions/node/v22.22.2/bin:$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$PATH"
python3 "$HOME/posta/fusion_engine.py" "$@"
