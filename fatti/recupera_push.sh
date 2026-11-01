#!/bin/bash
# RECUPERA LA PUSH DEL POSTINO — CURA-AUDIT (1/11 sera)
#
# Il problema: GitHub rifiuta la push con "push declined due to repository rule
# violations". Non è una regola del repo (l'API dice: nessuna ruleset, nessuna
# branch protection, tutti i merge consentiti) → è il CONTENUTO della commit:
# c'è dentro un file che GitHub non accetta (nome con caratteri vietati, o
# file troppo grande, o percorso strano). Finché quel file c'è, la push non
# passa e il lavoro resta in locale per sempre.
#
# Cosa fa questo script:
#   1. mette al sicuro tutto quello che il postino ha prodotto
#   2. individua i nomi di file che GitHub rifiuta (con gli escape, per vederli
#      davvero: il terminale e le chat possono "abbellirli" e mentire)
#   3. riallinea l'albero al remoto e ricostruisce la commit da zero
#   4. rimette i file con il nome valido
#   5. prova la push; se GitHub la rifiuta ancora, SCA il file colpevole uno
#      per uno (lo esclude e riprova) e dice qual è
set -uo pipefail
REPO="$HOME/posta"
cd "$REPO" || { echo "❌ non trovo $REPO"; exit 1; }
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }
# caratteri che GitHub non accetta in un nome di file
RE_SOLO='[<>:"|?*\\]'

TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
LOGIN=""; [ -s "$HOME/.posta_login" ] && LOGIN="$(tr -d '\r\n' < "$HOME/.posta_login")"
REMOTE="origin"
[ -n "$TOKEN" ] && [ -n "$LOGIN" ] && REMOTE="https://x-access-token:$TOKEN@github.com/$LOGIN/posta.git"

say "1. metto al sicuro i file del postino"
rm -rf /tmp/recupero 2>/dev/null || true
mkdir -p /tmp/recupero
for d in dal_pc fatti da_me; do
  [ -d "$d" ] || continue
  mkdir -p "/tmp/recupero/$d"
  find "$d" -maxdepth 1 -type f -print0 2>/dev/null | while IFS= read -r -d '' f; do
    cp -p -- "$f" "/tmp/recupero/$f" 2>/dev/null || true
  done
done
say "   salvati $(find /tmp/recupero -type f 2>/dev/null | wc -l) file"

say "2. i nomi sospetti (con escape: il terminale abbellisce e mente)"
SOSPETTI=0
while IFS= read -r -d '' f; do
  if printf '%s' "${f#/tmp/recupero/}" | grep -qE "$RE_SOLO"; then
    echo "   ⛔ $(printf '%s' "$f" | cat -v)"
    SOSPETTI=$((SOSPETTI+1))
  fi
done < <(find /tmp/recupero -type f -print0 2>/dev/null)
say "   nomi sospetti: $SOSPETTI"

say "3. riallineo l'albero al remoto e rifaccio la commit da zero"
git fetch origin >/dev/null 2>&1
git reset --hard origin/main >/dev/null 2>&1
git clean -fdq dal_pc fatti da_me >/dev/null 2>&1

say "4. rimetto i file con il nome valido"
RIMESSI=0; SCARTATI=0
for d in dal_pc fatti da_me; do
  [ -d "/tmp/recupero/$d" ] || continue
  for f in "/tmp/recupero/$d"/*; do
    [ -f "$f" ] || continue
    n="$d/$(basename "$f")"
    if printf '%s' "$n" | grep -qE "$RE_SOLO"; then
      say "   ⛔ scartato (nome vietato): $(printf '%s' "$n" | cat -v)"
      SCARTATI=$((SCARTATI+1)); continue
    fi
    if cp -p -- "$f" "$n" 2>/dev/null; then RIMESSI=$((RIMESSI+1)); fi
  done
done
say "   rimessi: $RIMESSI · scartati: $SCARTATI"

say "5. commit e push"
git add -A dal_pc fatti da_me >/dev/null 2>&1
git commit -qm "postino recupero $(date '+%d/%m %H:%M')" >/dev/null 2>&1
if git push "$REMOTE" HEAD:main 2>&1 | tail -3; then
  if git ls-remote "$REMOTE" refs/heads/main 2>/dev/null | grep -q "$(git rev-parse HEAD)"; then
    say "✅ PUSH RIUSCITA — la catena è chiusa"
    exit 0
  fi
fi

say "6. prova decisive: push su un RAMO DI PROVA (se passa, il problema è di main)"
if git push "$REMOTE" HEAD:refs/heads/prova-push >/dev/null 2>&1; then
  say "   ✅ il ramo di prova È passato → il problema riguarda main, non i file"
  say "      (regole/protection su main, invisibili all'API: si risolve dalla scheda Rules del repo)"
  say "      fin qui i file sono recuperati: per pubblicarli serve sbloccare main."
  exit 0
fi
say "   il ramo di prova è stato rifiutato ANCHE lui → è il contenuto: cerco il colpevole"

say "7. GitHub rifiuta ancora: cerco il file colpevole uno per uno"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  git reset --soft HEAD~1 >/dev/null 2>&1
  git reset -q -- "$f" >/dev/null 2>&1
  git commit -qm "postino recupero (bisect)" >/dev/null 2>&1
  if git push "$REMOTE" HEAD:main >/dev/null 2>&1; then
    say "✅ PUSH RIUSCITA. Il colpevole era: $(printf '%s' "$f" | cat -v)"
    say "   (quel file resta fuori dal commit; se ti serve, rinominalo e rimmettilo)"
    exit 0
  fi
  say "   …non era $f, proseguo"
done < <(git show --pretty=format: --name-only HEAD 2>/dev/null)

say "⛔ non sono riuscito a isolare il colpevole. I file in commit sono:"
git show --pretty=format: --name-only HEAD 2>/dev/null | cat -v
exit 1
