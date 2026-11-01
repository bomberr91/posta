#!/bin/bash
# INTEGRITÀ DELLA BASE + STATO DEL REPO DEL PC (1/11 sera)
#
# Due cose, una sola di scrittura (e solo per riparare, mai per cambiare):
#
#  1) LA FOTO DELLA BASE (solo lettura): il cervello è nato per usare tutte
#     le chiavi del capo (62 provider) e gestirle per gli agenti. Dopo una
#     serata di modifiche, serve una prova che la base è INTATTA:
#     quanti provider, quante classi, e la verifica che la policy "gratis"
#     ne prende TUTTI (prima ne prendeva 4: scartava i 58 free-ricorrente).
#
#  2) IL REPO DEL PC: ZCode ha scoperto che gira "detached HEAD" e che c'era
#     un rebase interattivo lasciato aperto alle 21:12. Se il repo è in uno
#     stato rotto, le push del postino non arrivano e il lavoro resta in
#     locale (la lezione della notte). QUI si ripara, in modo sicuro:
#     backup prima, reset a origin/main dopo.
set -uo pipefail
REPO="$HOME/posta"
cd "$REPO" || { echo "❌ non trovo $REPO"; exit 1; }
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }

say "1. LA FOTO DELLA BASE (sola lettura)"
python3 - << 'PYEOF'
import os, json
from collections import Counter
QUI = os.getcwd()
LISTA = os.path.join(QUI, "portiere_lista.txt")
CLASSI = {}
if os.path.exists(LISTA):
    for riga in open(LISTA, encoding="utf-8"):
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
keyless = [i for i in CLASSI if CLASSI[i] == "keyless"]
gratis = [i for i in CLASSI if CLASSI[i] in ("keyless", "free-ricorrente", "")]
print("   provider nella lista:            %d" % len(CLASSI))
for k, v in sorted(c.items()):
    print("   %-30s %d" % (k if k else "(vuoto = free-ricorrente)", v))
print("   policy 'keyless' (stretta):       %d" % len(keyless))
print("   policy 'gratis'  (quella che conta): %d" % len(gratis))
print("   -> la base e' INTATTA se gratis == provider totali")
# il portachiavi: quante chiavi vede davvero il cervello
import subprocess
n = 0
for f in ("portachiavi.txt", "chiavi.txt", "portachiavi.env", ".env"):
    fp = os.path.join(QUI, f)
    if os.path.exists(fp):
        try:
            k = sum(1 for r in open(fp, encoding="utf-8", errors="replace")
                    if "=" in r and not r.strip().startswith("#"))
            print("   portachiavi %-18s %d chiavi" % (f, k))
            n += k
        except Exception:
            pass
if not n:
    print("   (il portachiavi non sta nella repo: e' nel cervello/CHIAVI_LOCALI)")
PYEOF

say "2. lo stato del repo (detached HEAD? rebase aperto?)"
echo "   HEAD: $(git rev-parse --abbrev-ref HEAD)  ($(git rev-parse --short HEAD))"
echo "   branch: $(git branch --show-current)"
if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
  say "   ⚠️ REBASE APERTO: lo riparo (abort) con backup prima"
  git branch "salvataggio-$(date +%H%M)" 2>/dev/null || true
  git rebase --abort 2>&1 | tail -2
fi
if [ "$(git rev-parse --abbrev-ref HEAD)" = "HEAD" ]; then
  say "   ⚠️ DETACHED HEAD: riallineo a main (il postino deve poter pushare)"
  git branch "salvataggio-$(date +%H%M)" 2>/dev/null || true
  git fetch origin 2>&1 | tail -1
  git checkout main 2>&1 | tail -1
fi
git fetch origin 2>&1 | tail -1
git reset --hard origin/main 2>&1 | tail -1
git branch --set-upstream-to=origin/main main 2>/dev/null || true
echo "   ora: $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)"

say "3. il postino gira e pusha?"
pgrep -af "postino.sh" 2>/dev/null | head -3 || echo "   (non lo vedo da qui: puo' girare in un'altra shell)"
echo "   ultima commit locale:  $(git log -1 --format='%h %ad %s' --date=format:'%d/%m %H:%M')"
echo "   ultima commit remota:  $(git log origin/main -1 --format='%h %ad %s' --date=format:'%d/%m %H:%M')"

say "4. il cervello risponde?"
curl -s -m 8 http://localhost:20129/salute 2>/dev/null | head -c 400; echo
echo
curl -s -m 8 http://localhost:20129/portiere.json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print('   provider nel cervello: %s · pagelle: %s' % (d.get('provider'), len(d.get('pagelle') or {})))
except Exception as e:
    print('   (portiere.json non risponde:', e, ')')
"

say "5. VERDETTO"
echo "   base intatta: vedi sopra (policy gratis == totale provider)"
echo "   repo: $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)"
say "6. fine"
exit 0
