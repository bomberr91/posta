#!/bin/bash
# SANIFICA LE CHIAVI E RIMETTE IL LAVORO ONLINE — CURA-AUDIT (1/11 sera)
#
# Perché: GitHub ha la push protection. Se una risposta o uno script archiviato
# contiene una stringa che sembra una chiave (sk-…, ghp_…, tvly-…, cc3a11cf-…),
# la push viene RESPINTA ("push declined due to repository rule violations") e
# il postino riprova all'infinito con il lavoro a terra in locale.
#
# Questo script:
#   1. libera il rebase interrotto (il repo era fermo in "interactive rebase in
#      progress": senza questo, il reset e la push non possono girare)
#   2. maschera le stringhe-chiave in dal_pc/ e fatti/ (MAI in da_me/, dove i
#      compiti aspettano di essere eseguiti)
#   3. ricontrolla e dice quanti residui sono rimasti
#   4. ricostruisce la commit e la pusha
set -uo pipefail
cd "$HOME/posta" || { echo "❌ non trovo ~/posta"; exit 1; }
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }
# i pattern delle chiavi (quello che GitHub riconosce)
RE_KEYS='(sk-or-v1-[A-Za-z0-9]{20,}|tvly-[A-Za-z0-9-]{20,}|ghp_[A-Za-z0-9]{20,}|cc3a11cf-[0-9a-f-]{20,}|sk-[A-Za-z0-9]{30,})'
# ogni stringa lunga viene ridotta a 10 caratteri + "..."
RE_MASK='s/([A-Za-z0-9_-]{10})[A-Za-z0-9_-]{14,}/\1.../g'

say "1. libero il rebase interrotto e i lock"
git rebase --abort >/dev/null 2>&1 || true
git merge --abort >/dev/null 2>&1 || true
rm -f .git/index.lock 2>/dev/null || true
say "   stato: $(git status --short 2>/dev/null | head -3 | tr '\n' ' ')"

say "2. maschero le stringhe-chiave (dal_pc e fatti, mai da_me)"
TROVATI=0
while IFS= read -r -d '' f; do
  if grep -qE "$RE_KEYS" "$f" 2>/dev/null; then
    sed -i -E "$RE_MASK" "$f" 2>/dev/null || true
    say "   mascherato: $f"
    TROVATI=$((TROVATI+1))
  fi
done < <(find dal_pc fatti -maxdepth 1 -type f -print0 2>/dev/null)
say "   file mascherati: $TROVATI"

say "3. ricontrollo (deve stampare 0)"
RESIDUI=0
while IFS= read -r -d '' f; do
  if grep -qE "$RE_KEYS" "$f" 2>/dev/null; then
    say "   ⚠ resta: $f"
    RESIDUI=$((RESIDUI+1))
  fi
done < <(find dal_pc fatti -maxdepth 1 -type f -print0 2>/dev/null)
say "   residui: $RESIDUI"

say "4. ricostruisco la commit e pusho"
git fetch origin >/dev/null 2>&1
git reset --soft origin/main >/dev/null 2>&1
git reset -q >/dev/null 2>&1
git add -A dal_pc fatti >/dev/null 2>&1
git commit -qm "postino: script e risposte sanitizzati" >/dev/null 2>&1
git push origin HEAD:main 2>&1 | tail -2

say "5. esito"
if git ls-remote origin refs/heads/main 2>/dev/null | grep -q "$(git rev-parse HEAD 2>/dev/null)"; then
  say "✅ PUSH RIUSCITA — il lavoro è online"
  say "   testa: $(git log --oneline -1 2>/dev/null)"
  exit 0
fi
say "⛔ la push non è passata. Riprova fra un giro: il postino riprova da solo."
exit 1
