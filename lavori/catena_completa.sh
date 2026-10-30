#!/bin/bash
# rifa' TUTTI e 4 i blocchi in fila, col motore acceso
cd "$(dirname "$0")/.." || exit 1
for i in $(seq 1 30); do pgrep -f "opencode run" >/dev/null 2>&1 || break; sleep 20; done
bash lavori/analista.sh 1 "1-16"  opencode
bash lavori/analista.sh 2 "17-33" opencode
bash lavori/analista.sh 3 "34-48" opencode
bash lavori/analista.sh 4 "49-64" opencode
