#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
R=dal_pc/accendi_omniroute_2.md
export NVM_DIR="/home/agenti/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1
vivo(){ curl -s -m 4 http://127.0.0.1:20128/v1/models -H "Authorization: Bearer sk-be311327ce941004-4df42c-cf76ba39" | grep -q data; }
{
echo "# ACCENSIONE OMNIROUTE tentativo 2 — $(date)"
if vivo; then echo "gia' acceso"
else
  echo "avvio: OMNIROUTE_SERVER_HOST=127.0.0.1 omniroute (solo localhost, regola sicurezza)"
  OMNIROUTE_SERVER_HOST=127.0.0.1 nohup omniroute >> dal_pc/omni_start.log 2>&1 &
  echo "pid: $! — aspetto fino a 2 minuti SENZA toccarlo"
  for i in $(seq 1 24); do sleep 5; vivo && break; done
fi
if vivo; then
  echo "ACCESO ✓ :20128 risponde — rilancio la catena completa dei 4 blocchi"
  chmod +x lavori/catena_completa.sh lavori/analista.sh
  nohup bash lavori/catena_completa.sh >> dal_pc/nohup_catena.txt 2>&1 &
else
  echo "ANCORA GIU' — coda del log di avvio:"; tail -10 dal_pc/omni_start.log | tr -d '\033'
fi
} > "$R" 2>&1
git add dal_pc >/dev/null 2>&1; git commit -m "accensione omniroute 2" >/dev/null 2>&1
git pull --rebase >/dev/null 2>&1; git push >/dev/null 2>&1
echo fatto
