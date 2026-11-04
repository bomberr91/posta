#!/usr/bin/env bash
# assegnazioni_verifica_pc.sh — collaudo del libro mastro SUL PC (dove vive il portachiavi).
#
# Esegue il verificatore `lavori/assegnazioni_vedi.py` con il portachiavi vero
# e riporta l'output: chi usa quale chiave, quali chiavi sono libere, quali
# conflitti restano. Nessuna chiave viene stampata (il verificatore non lo fa).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

git pull --rebase --autostash 2>&1 | tail -2
echo "commit: $(git log --oneline -1 2>/dev/null)"
echo "libro mastro: $(ls -la lavori/assegnazioni_provider.tsv 2>/dev/null | awk '{print $5" byte"}')"
echo "portachiavi: $(ls -la "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | awk '{print $5" byte"}')"
echo

python3 lavori/assegnazioni_vedi.py --vault "$HOME/CHIAVI_LOCALI.md"
RC=$?
echo
echo "(il verificatore esce con $RC: 1 = ci sono conflitti da sistemare, 0 = tutto pulito)"
exit 0
