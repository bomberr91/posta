#!/usr/bin/env bash
# avvia_sonda_longcat.sh — mette in piedi la sonda che scopre a che ora
# LongCat rinnova la quota giornaliera (l'orario non e' nei docs).
# Lo script esce subito: il campione resta vivo in background sul PC.
set -u
DIR="$HOME/posta"
[ -d "$DIR" ] || DIR="$HOME/posta_ponte"
cd "$DIR" || { echo "non trovo il clone"; exit 1; }
bash fatti/sonda_longcat.sh
