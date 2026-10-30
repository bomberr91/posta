#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
chmod +x lavori/seriale.sh lavori/analista.sh
nohup bash lavori/seriale.sh >> dal_pc/nohup_seriale.txt 2>&1 &
echo "CATENA SERIALE lanciata: aspetta il blocco 1, poi fa 2->3->4 uno alla volta. $(date)"
