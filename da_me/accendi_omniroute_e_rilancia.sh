#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
R=dal_pc/accendi_omniroute.md
export NVM_DIR="/home/agenti/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1
vivo(){ curl -s -m 4 http://127.0.0.1:20128/v1/models -H "Authorization: Bearer sk-be311327ce941004-4df42c-cf76ba39" | grep -q data; }
{
echo "# ACCENSIONE OMNIROUTE $(date)"
if vivo; then echo "gia' acceso, niente da fare"
else
  for cmd in "omniroute start" "omniroute serve" "omniroute"; do
    echo "provo: $cmd"
    nohup $cmd >> dal_pc/omni_start.log 2>&1 &
    sleep 25
    if vivo; then echo "ACCESO con: $cmd (pid $!)"; break; fi
    kill $! 2>/dev/null
  done
fi
if vivo; then
  echo "VERIFICA: :20128 risponde ✓ — rilancio la catena completa dei 4 blocchi"
  chmod +x lavori/catena_completa.sh lavori/analista.sh
  nohup bash lavori/catena_completa.sh >> dal_pc/nohup_catena.txt 2>&1 &
else
  echo "FALLITO: :20128 non risponde — ultime righe del log:"
  tail -5 dal_pc/omni_start.log 2>/dev/null
fi
} > "$R" 2>&1
git add dal_pc >/dev/null 2>&1; git commit -m "accensione omniroute + rilancio" >/dev/null 2>&1
git pull --rebase >/dev/null 2>&1; git push >/dev/null 2>&1
echo "fatto, vedi $R"
