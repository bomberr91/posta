#!/bin/bash
# lancia l'analista del blocco 3 (idee 34-48) in background e libera subito il postino
cd "$(dirname "$0")/.." || exit 1
chmod +x lavori/analista.sh
nohup bash lavori/analista.sh 3 "34-48" freebuff >> dal_pc/nohup_blocco_3.txt 2>&1 &
echo "BLOCCO 3 (idee 34-48, motore freebuff) lanciato in background: $(date)"
echo "il verdetto arrivera' da solo in dal_pc/verdetto_blocco_3.md"
