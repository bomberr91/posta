#!/bin/bash
# CERVELLO SUL PC: pull → restart → collaudo (Arena, 01/11 sera)
#
# Perché questo job: il cervello del PC gira in memoria con il file ROTTO
# (quello che l'agente morto aveva pushato). Il mio fix è sul remoto, ma un
# processo long-running non si aggiorna da solo: va UCCISO e RISUSCITATO.
# Il guardiano (scorta_posta.sh / sveglia_sentinella.sh) lo fa risorgere dal
# file aggiornato.
#
# Exit codes onesti: 0 = cervello sanato e collaudato, 1 = qualcosa non va.
set -uo pipefail

REPO="$HOME/posta"
cd "$REPO" || { echo "❌ non trovo $REPO"; exit 1; }

echo "### 1. COM'È ADESSO (prima del pull)"
echo "— commit in testa: $(git log --oneline -1 2>/dev/null)"
echo "— NOME del cervello:"
grep -n 'NOME = "Portiere"' cervello.py | head -2 || echo "   (NOME NON TROVATO: il file è quello rotto)"
echo "— dove sta _sessione (4 spazi = metodo della classe = bene; 8 = annidato = rotto):"
grep -n 'def _sessione' cervello.py | head -3 || echo "   (_sessione non c'è)"
echo

echo "### 2. PULL (il postino sincronizza comunque: io solo mi accerto)"
git pull --rebase --autostash origin main 2>&1 | tail -3
echo "— commit in testa adesso: $(git log --oneline -1 2>/dev/null)"
echo

echo "### 3. LA STRUTTURA È SANA? (se no, non ha senso riavviare)"
python3 cervello.py --autoprova
RC=$?
if [ "$RC" -ne 0 ]; then
  echo "❌ il cervello è ANCORA rotto dopo il pull: non lo riavvio (sarebbe inutile)"
  exit 1
fi
echo "   ✓ struttura sana (autoprova superata)"
echo

echo "### 4. AMMAZZO il cervello vecchio (il guardiano lo risuscita col codice nuovo)"
pkill -f '^python3 cervello\.py$' && echo "   ucciso (pattern esatto)" || echo "   non girava con quel nome"
sleep 4
if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
  echo "   ⚠️ la porta 20129 è ancora aperta: provo col pattern più largo"
  pkill -f 'cervello\.py' && echo "   ucciso (pattern largo)" || echo "   non c'è niente da uccidere"
  sleep 3
fi
echo

echo "### 5. ASPETTO CHE TORNI (max 150s)"
TORNATO=0
for i in $(seq 1 30); do
  sleep 5
  if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
    TORNATO=1; echo "   ✓ risorto dopo ~$((i*5))s"; break
  fi
done
if [ "$TORNATO" -ne 1 ]; then
  echo "❌ il cervello NON è tornato in 150s: il guardiano non lo ha risuscitato"
  echo "   → controlla che scorta_posta.sh (guardiano) sia vivo, poi:"
  echo "     cd ~/posta && nohup python3 cervello.py > /tmp/cervello.log 2>&1 &"
  exit 1
fi
sleep 3
echo

echo "### 6. /salute (il mio endpoint: dice anche se la struttura è pulita)"
curl -fsS -m 20 http://127.0.0.1:20129/salute | head -c 500; echo
echo

echo "### 7. COLLAUDO (chat reale, può dire NO)"
bash fatti/collaudo_cervello.sh
RC=$?
if [ "$RC" -ne 0 ]; then
  echo
  echo "❌ il cervello è VIVO ma il collaudo è FALLITO (exit $RC)"
  echo "   (leggere sopra il motivo: provider/crediti/timeout — NON è il file rotto)"
  exit 1
fi
echo
echo "✅ CERVELLO SANO: pull fatto, processo riavviato col codice nuovo, collaudo superato"
exit 0
