#!/bin/bash
# METTE IL CRUSCOTTO v2 NEL REPO (CURA-AUDIT, 1/11 sera)
#
# Perché: cruscotto.html sta solo sul PC, FUORI dal versionamento. Se il PC
# muore, il cruscotto muore con lui — e non si sa nemmeno quale versione
# era. In più le correzioni al parser (pagelle reali in %, castighi con
# countdown) finirebbero perdute al primo ripristino.
#
# Il repo è PUBBLICO: prima di copiare il file lo scanno per stringhe-chiave
# e, se ce ne fossero, le maschero (l'originale resta in /tmp).
set -uo pipefail
SRC="[CHIAVE-RIMOSSA].html"
REPO="$HOME/posta"
cd "$REPO" || { echo "❌ non trovo $REPO"; exit 1; }
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }

say "1. il cruscotto esiste?"
if [ ! -f "$SRC" ]; then
  echo "❌ non trovo $SRC"
  echo "   (se il file è altrove, dimmi il percorso e lo prendo)"
  exit 1
fi
echo "   $SRC — $(wc -c < "$SRC") byte"

say "2. scansione stringhe-chiave (il repo è pubblico)"
CHIAVI=$(grep -oE '(sk-or-v1-[A-Za-z0-9]{20,}|tvly-[A-Za-z0-9-]{20,}|ghp_[A-Za-z0-9]{20,}|cc3a11cf-[0-9a-f-]{20,}|sk-[A-Za-z0-9]{30,}|oc_sk_[A-Za-z0-9_-]{20,})' "$SRC" 2>/dev/null | sort -u | wc -l)
say "   chiavi trovate: $CHIAVI"
if [ "$CHIAVI" -gt 0 ]; then
  cp -p "$SRC" /tmp/cruscotto_originale.html
  sed -i -E 's/([A-Za-z0-9_-]{10})[A-Za-z0-9_-]{14,}/\1.../g' "$SRC"
  say "   mascherate (l'originale intatto è in /tmp/cruscotto_originale.html)"
else
  say "   ✓ nessuna chiave: il file si copia così com'è"
fi

say "3. lo metto nel repo (gui/ è già la casa degli altri cruscotti)"
mkdir -p gui
cp -p "$SRC" gui/cruscotto.html
echo "   gui/cruscotto.html — $(wc -c < gui/cruscotto.html) byte"

say "4. commit e push"
git add gui/cruscotto.html
git commit -qm "📊 cruscotto v2: pannello lavoro di oggi, badge sentinella, mini-plancia, parser delle pagelle e dei castighi (1/11 sera)" >/dev/null 2>&1
git push origin HEAD:main 2>&1 | tail -2

say "5. esito"
if git ls-remote origin refs/heads/main 2>/dev/null | grep -q "$(git rev-parse HEAD 2>/dev/null)"; then
  say "✅ cruscotto v2 nel repo e online — da ora è versionato"
  exit 0
fi
say "⛔ la push non è passata (il postino riprova al giro dopo)"
exit 1
