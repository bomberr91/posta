#!/bin/bash
# lancia l'analista del blocco 4 (idee 49-64) in background e libera subito il postino
cd "$(dirname "$0")/.." || exit 1
chmod +x lavori/analista.sh
nohup bash lavori/analista.sh 4 "49-64" opencode >> dal_pc/nohup_blocco_4.txt 2>&1 &
echo "BLOCCO 4 (idee 49-64, motore opencode) lanciato in background: $(date)"
echo "il verdetto arrivera' da solo in dal_pc/verdetto_blocco_4.md"
