#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
chmod +x lavori/revisore.sh
nohup bash -c '
cd "'"$PWD"'" 2>/dev/null || cd ~/posta
for i in $(seq 1 30); do pgrep -f "opencode run" | grep -v $$ >/dev/null 2>&1 || break; sleep 15; done
bash lavori/revisore.sh 1 "1-16"
bash lavori/revisore.sh 2 "17-33"
bash lavori/revisore.sh 3 "34-48"
bash lavori/revisore.sh 4 "49-64"
' >> dal_pc/nohup_revisione.txt 2>&1 &
echo "SECONDA CONTROLLATA lanciata in catena seriale: $(date)"
