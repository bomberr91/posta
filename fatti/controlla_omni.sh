#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
R=dal_pc/controlla_omni.md
vivo(){ curl -s -m 4 http://127.0.0.1:20128/v1/models -H "Authorization: Bearer sk-be311327ce941004-4df42c-cf76ba39" | grep -q data; }
{
echo "# CONTROLLO OMNIROUTE $(date)"
echo "## processo vivo?"; pgrep -af "omniroute" | head -5; pgrep -af "node" | head -5
echo "## porte in ascolto (2012x):"; (ss -tln 2>/dev/null || netstat -tln 2>/dev/null) | grep -E "2012[0-9]" 
echo "## risponde?"
if vivo; then
  echo "SI' ✓ :20128 VIVO — LANCIO LA CATENA DEI 4 BLOCCHI"
  chmod +x lavori/catena_completa.sh lavori/analista.sh
  nohup bash lavori/catena_completa.sh >> dal_pc/nohup_catena.txt 2>&1 &
else
  echo "no — coda log:"; tail -15 dal_pc/omni_start.log | tr -d '\033'
fi
} > "$R" 2>&1
git add dal_pc >/dev/null 2>&1; git commit -m "controllo omni" >/dev/null 2>&1
git pull --rebase >/dev/null 2>&1; git push >/dev/null 2>&1
echo fatto
