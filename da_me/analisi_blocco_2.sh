#!/bin/bash
# lancia l'analista del blocco 2 (idee 17-33) in background e libera subito il postino
cd "$(dirname "$0")/.." || exit 1
chmod +x lavori/analista.sh
nohup bash lavori/analista.sh 2 "17-33" goose >> dal_pc/nohup_blocco_2.txt 2>&1 &
echo "BLOCCO 2 (idee 17-33, motore goose) lanciato in background: $(date)"
echo "il verdetto arrivera' da solo in dal_pc/verdetto_blocco_2.md"
