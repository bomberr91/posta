#!/usr/bin/env bash
# Prova Reddit per gli agenti: ricerca + lettura integrale delle discussioni.
# Nessuna credenziale: si usano i feed .rss pubblici di Reddit.
# Uso: bash ~/posta/fatti/prova_reddit_agente.sh [domanda] [quante] [righe]
set -u
cd ~/posta || exit 1
DOMANDA="${1:-free llm api rate limit}"
QUANTE="${2:-2}"
RIGHE="${3:-120}"
python3 fatti/reddit_leggi.py --q "$DOMANDA" --max "$QUANTE" --commenti --max-righe "$RIGHE"
