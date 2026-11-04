#!/usr/bin/env bash
# poller_fix_compito.sh — 4/11: riavvia il poller perche' carichi il fix di parse_campo.
#
# Il fix (nel repo, gia' pushato): prima parse_campo tagliava il compito al PRIMO
# a capo, perche' la regex "in linea" si mangiava anche il newline. Risultato:
# l'agente riceveva solo "Esegui questo comando:" senza il comando e rispondeva
# "dimmi il comando" (vedi issue #18 e #19). Ora il campo arriva intero.
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

echo "### 1. PULL"
git pull --rebase --autostash >/tmp/pollerfix_pull.log 2>&1
echo "exit pull: $?"
tail -3 /tmp/pollerfix_pull.log
echo "commit in testa: $(git log --oneline -1 2>/dev/null)"
echo "fix presente nel file: $(grep -c 'il campo e' "$REPO/lavori/ponte/poller.py" 2>/dev/null)"
echo

echo "### 2. RIAVVIO DEL POLLER"
cd "$REPO/lavori/ponte" || exit 1
if pgrep -f 'python3 poller[.]py' >/dev/null 2>&1; then
  pkill -f 'python3 poller[.]py'
  sleep 3
  echo "poller fermato"
else
  echo "poller non era in giro"
fi
rm -f _stato/poller.lock
nohup python3 poller.py >> poller.log 2>&1 &
sleep 12
if pgrep -f 'python3 poller[.]py' >/dev/null 2>&1; then
  echo "poller riavviato (pid $(pgrep -f 'python3 poller[.]py' | head -1))"
else
  echo "ATTENZIONE: il poller non riparte"
  tail -20 poller.log
fi
echo
echo "### 3. COLLAUDO DEL PARSER (offline, sul file appena scaricato)"
python3 - << 'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("poller", "poller.py")
m = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(m)
except SystemExit:
    pass
body = "target: opencode\ncompito:\nprima riga\nseconda riga\n\nfine"
print("   multi-riga ->", repr(m.parse_campo(body, "compito", "contesto")))
body2 = "target: opencode\ncompito: solo una riga\ncontesto: altro"
print("   una riga   ->", repr(m.parse_campo(body2, "compito", "contesto")))
PY
echo
echo "FINE"
exit 0
