#!/bin/bash
# CERVELLO SUL PC: pull → restart → collaudo (Arena, 01/11 sera)
#
# Perché questo job: il cervello del PC gira in memoria con il file VECCHIO.
# I fix sono sul remoto, ma un processo long-running non si aggiorna da solo:
# va UCCISO e RISUSCITATO col codice nuovo.
#
# Questa versione (1/11 sera, dopo il buco del file vuoto) fa anche:
#   - i 24 test offline
#   - la verifica che la policy "gratis" prende TUTTI i provider (62)
#   - se il guardiano non risuscita il cervello, lo avvia da solo
#
# Exit codes onesti: 0 = cervello sanato e collaudato, 1 = qualcosa non va.
set -uo pipefail

REPO="$HOME/posta"
cd "$REPO" || { echo "❌ non trovo $REPO"; exit 1; }

echo "### 1. COM'È ADESSO (prima del pull)"
echo "— commit in testa: $(git log --oneline -1 2>/dev/null)"
echo "— stato git: $(git rev-parse --abbrev-ref HEAD) $(git rev-parse --short HEAD 2>/dev/null)"
if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
  echo "⚠️ c'è un rebase aperto: lo chiudo (con backup)"
  git branch "salvataggio-$(date +%H%M)" 2>/dev/null || true
  git rebase --abort 2>&1 | tail -1
fi
echo

echo "### 2. PULL (il postino sincronizza comunque: io solo mi accerto)"
if [ "$(git rev-parse --abbrev-ref HEAD)" = "HEAD" ]; then
  echo "⚠️ detached HEAD: riallineo a main"
  git branch "salvataggio-$(date +%H%M)" 2>/dev/null || true
fi
git checkout main 2>&1 | tail -1
git fetch origin 2>&1 | tail -1
git reset --hard origin/main 2>&1 | tail -1
git branch --set-upstream-to=origin/main main 2>/dev/null || true
echo "— commit in testa adesso: $(git log --oneline -1 2>/dev/null)"
echo

echo "### 3. LA STRUTTURA È SANA? (se no, non ha senso riavviare)"
python3 - << 'PYEOF'
import sys
sys.argv = ["cervello.py"]
try:
    import importlib.util, os
    spec = importlib.util.spec_from_file_location("c", "cervello.py")
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    NOME = getattr(m, "NOME", "?")
    print("   NOME del cervello: %s" % NOME)
except SystemExit:
    print("   (il modulo ha fatto sys.exit: normale in --autoprova)")
except Exception as e:
    print("   ⚠️ import: %s" % e)
PYEOF
python3 cervello.py --autoprova
RC=$?
if [ "$RC" -ne 0 ]; then
  echo "❌ il cervello è ANCORA rotto dopo il pull: non lo riavvio (sarebbe inutile)"
  exit 1
fi
echo "   ✓ struttura sana (autoprova superata)"
echo

echo "### 3b. I 24 TEST OFFLINE"
python3 -m unittest tests.test_cervello_offline 2>&1 | tail -5
echo

echo "### 3c. LA POLICY 'gratis' (deve prendere TUTTI i provider)"
python3 - << 'PYEOF'
from collections import Counter
CLASSI = {}
for riga in open("portiere_lista.txt", encoding="utf-8"):
    riga = riga.rstrip("\n")
    if not riga.strip() or riga.lstrip().startswith("#"):
        continue
    p = riga.split("|")
    if len(p) < 3:
        continue
    nome = p[2].strip()
    classe = (p[7].strip() if len(p) > 7 else "") or \
             ("keyless" if nome == "SENZA" else "free-ricorrente")
    CLASSI[p[0].strip()] = classe
c = Counter(CLASSI.values())
gratis = [i for i in CLASSI if CLASSI[i] in ("keyless", "free-ricorrente", "")]
for k, v in sorted(c.items()):
    print("   %-24s %d" % (k if k else "(vuoto = free-ricorrente)", v))
print("   totale provider: %d · policy gratis ne prende: %d" % (len(CLASSI), len(gratis)))
print("   ✓ base intatta" if len(gratis) == len(CLASSI) else "   ⚠️ la base NON torna")
PYEOF
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
  echo "⚠️ il guardiano non l'ha risuscitato: lo avvio io"
  nohup python3 cervello.py > /tmp/cervello.log 2>&1 &
  for i in $(seq 1 24); do
    sleep 5
    if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
      TORNATO=1; echo "   ✓ risorto dopo ~$((i*5))s (avviato da me)"; break
    fi
  done
fi
if [ "$TORNATO" -ne 1 ]; then
  echo "❌ il cervello NON è tornato in ~4 minuti"
  echo "   → guarda /tmp/cervello.log e il log del guardiano"
  exit 1
fi
sleep 3
echo

echo "### 6. /salute (il mio endpoint: dice anche se la struttura è pulita)"
curl -fsS -m 20 http://127.0.0.1:20129/salute | head -c 600; echo
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
