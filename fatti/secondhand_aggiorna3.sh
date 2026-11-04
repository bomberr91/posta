#!/usr/bin/env bash
# secondhand_aggiorna3.sh — 4/11: aggiornamento vero di Secondhand (3° giro).
#
# FATTI dei due tentativi precedenti:
#   - il pip di WSL rifiuta l'installazione (PEP 668: ambiente gestito):
#     "python3 -m pip install --upgrade open-interpreter" → exit 1
#     => serve --user --break-system-packages (l'interprete sta in
#        /home/agenti/.local/bin, installato --user)
#   - il pip di Windows non costruisce i metadata ("metadata-generation-failed")
#     e comunque l'app DESKTOP non e' un'installazione pip: sta in
#     AppData/Local/Programs/Open Interpreter e si aggiorna da se'.
#   - la WSL e' indietro: versione 0.0.56, su PyPI l'ultima e' 0.4.3
#
# Cosa fa qui:
#   1) raccoglie i fatti sull'app DESKTOP (come e' installata, come si aggiorna)
#   2) aggiorna la CLI WSL con --user --break-system-packages (tetto 900s)
#   3) se dopo l'aggiornamento il collaudo sul cervello fallisce:
#      RIPORTA la versione 0.0.56 e la config precedente => si torna come prima
#   4) collaudo reale finale
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

WIN_CFG=/mnt/c/Users/giopi/.openinterpreter/config.toml
WSL_CFG="$HOME/.config/interpreter/config.toml"
BASE="http://127.0.0.1:20129/v1"
STAMP=$(date +%Y%m%d-%H%M%S)

echo "### 1. L'APP DESKTOP WINDOWS: COME E' INSTALLATA E COME SI AGGIORNA"
APPDIR="/mnt/c/Users/giopi/AppData/Local/Programs/Open Interpreter"
echo "--- cartella dell'app:"
ls -1 "$APPDIR" 2>/dev/null | head -20
echo "--- eseguibili e file che dicono la versione:"
find "$APPDIR" -maxdepth 2 \( -name "*.exe" -o -name "app-update.yml" -o -name "*.asar" -o -name "*.json" \) 2>/dev/null | head -15
echo "--- configurazione dell'aggiornatore automatico (electron-updater):"
for f in "$APPDIR/resources/app-update.yml" "$APPDIR/resources/app.asar.unpacked/app-update.yml"; do
  [ -f "$f" ] && { echo "  $f:"; head -12 "$f"; }
done
echo "--- c'e' un aggiornamento gia' scaricato? (Squirrel/electron: cartella 'pending')"
ls -1d /mnt/c/Users/giopi/AppData/Local/*updater*/pending /mnt/c/Users/giopi/AppData/Local/*updater*/packages 2>/dev/null
ls -1 /mnt/c/Users/giopi/AppData/Local/ 2>/dev/null | grep -i "interpreter\|openinterp" | head
echo "--- installer scaricati:"
ls -1t /mnt/c/Users/giopi/Downloads 2>/dev/null | grep -i "interp\|open" | head -8
echo "--- la versione dentro l'app (prova su .exe/.asar, grezza):"
for f in "$APPDIR"/*.exe; do
  [ -f "$f" ] || continue
  echo "  file: $(basename "$f")"
  strings -a "$f" 2>/dev/null | grep -E "^(0\.[0-9]+\.[0-9]+)$" | sort -u | tail -5
done
echo

echo "### 2. AGGIORNAMENTO DELLA CLI WSL (era 0.0.56)"
echo "  versione prima: $(interpreter --version 2>&1 | head -1)"
cp "$WSL_CFG" "/tmp/sh_wsl_config_$STAMP.toml" 2>/dev/null && echo "  backup config WSL: /tmp/sh_wsl_config_$STAMP.toml"
timeout 900 python3 -m pip install --upgrade --user --break-system-packages open-interpreter > /tmp/sh_upd3.log 2>&1
echo "  exit pip: $?"
tail -8 /tmp/sh_upd3.log
echo "  versione dopo: $(interpreter --version 2>&1 | head -1)"
echo

echo "### 3. LA CONFIG PUNTA ANCORA AL CERVELLO?"
grep -n "base_url\|model_provider\|^model " "$WSL_CFG" 2>/dev/null | head -6
echo

echo "### 4. COLLAUDO (se fallisce, si torna alla 0.0.56)"
OUT=/tmp/sh_upd3_collaudo.log
cd "$REPO" || exit 1
OPENAI_API_KEY=sk-cervello timeout 240 interpreter exec --skip-git-repo-check \
  "Rispondi esattamente con la parola OK e nient'altro." > "$OUT" 2>&1
RC=$?
echo "--- exit: $RC"
grep -E "^(OK|provider:|model:)" "$OUT" | head -4
if [ "$RC" -ne 0 ] || ! grep -qi "^OK" "$OUT"; then
  echo "--- COLLAUDO FALLITO: ripristino la 0.0.56 e la config di prima"
  timeout 900 python3 -m pip install --user --break-system-packages "open-interpreter==0.0.56" > /tmp/sh_revert.log 2>&1
  echo "  exit revert: $? — versione: $(interpreter --version 2>&1 | head -1)"
  tail -4 /tmp/sh_revert.log
  cp "/tmp/sh_wsl_config_$STAMP.toml" "$WSL_CFG" 2>/dev/null && echo "  config WSL ripristinata"
  OPENAI_API_KEY=sk-cervello timeout 240 interpreter exec --skip-git-repo-check \
    "Rispondi esattamente con la parola OK e nient'altro." > /tmp/sh_revert_collaudo.log 2>&1
  echo "  collaudo dopo ripristino — exit: $?"
  grep -E "^(OK|provider:)" /tmp/sh_revert_collaudo.log | head -3
  echo "  VERDETTO: AGGIORNAMENTO RIFIUTATO, TORNATI ALLA VERSIONE PRECEDENTE (tutto come prima)"
else
  echo "  VERDETTO: AGGIORNATO E COLLAUDATO (OK dal cervello)"
fi
echo
echo "### 5. NOTE"
echo "L'app DESKTOP Windows si aggiorna dal suo meccanismo interno (vedi sezione 1):"
echo "se e' un aggiornatore electron/Squirrel, l'installazione e' gia' scaricata e"
echo "basta riavviare l'app; se invece va fatto a mano, la riga qui sopra dice il comando."
echo "FINE"
exit 0
