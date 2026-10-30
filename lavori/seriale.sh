#!/bin/bash
# catena seriale: aspetta il blocco 1, poi 2->3->4 con opencode (uno alla volta, WSL1)
cd "$(dirname "$0")/.." || exit 1
# sonda freebuff per il futuro (non blocca)
export NVM_DIR="/home/agenti/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1
{ freebuff --help 2>&1 | head -60; echo "=== run --help ==="; freebuff run --help 2>&1 | head -40; } > dal_pc/freebuff_help.txt
# aspetta che l'opencode del blocco 1 finisca (max 30 min)
for i in $(seq 1 90); do pgrep -f "opencode run" >/dev/null 2>&1 || break; sleep 20; done
bash lavori/analista.sh 2 "17-33" opencode
bash lavori/analista.sh 3 "34-48" opencode
bash lavori/analista.sh 4 "49-64" opencode
for i in 1 2 3 4 5; do
  git add dal_pc >/dev/null 2>&1; git commit -m "catena seriale completata" >/dev/null 2>&1
  git pull --rebase >/dev/null 2>&1 && git push >/dev/null 2>&1 && break; sleep 10
done
