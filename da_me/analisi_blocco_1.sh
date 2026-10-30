#!/bin/bash
# lancia l'analista del blocco 1 (idee 1-16) in background e libera subito il postino
cd "$(dirname "$0")/.." || exit 1
chmod +x lavori/analista.sh
nohup bash lavori/analista.sh 1 "1-16" opencode >> dal_pc/nohup_blocco_1.txt 2>&1 &
echo "BLOCCO 1 (idee 1-16, motore opencode) lanciato in background: $(date)"
echo "il verdetto arrivera' da solo in dal_pc/verdetto_blocco_1.md"
