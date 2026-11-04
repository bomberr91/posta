#!/usr/bin/env bash
# goose_configura.sh — mette goose in piedi sul PC (WSL) con un provider free verificato.
#
# Perche' serve (4/11): ogni task ponte su `goose` finiva in 0 secondi con
#   "error: No provider configured. Run 'goose configure' first."
# cioe' goose c'e' ma non ha un modello. Qui gli diamo un provider free
# (OpenRouter, chiave gia' nel portachiavi) e gli facciamo una prova REALE.
#
# La chiave non viene mai stampata: si scrive nel config di goose (permessi 600)
# e nel referto si mostra mascherata.
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "non trovo il repo ($REPO)"; exit 1; }

echo "### 1. AMBIENTE"
echo "utente: $(whoami)  home: $HOME  repo: $REPO"
echo "commit: $(git log --oneline -1 2>/dev/null)"
echo

echo "### 2. GOOSE"
if ! command -v goose >/dev/null 2>&1; then
  echo "GOOSE NON INSTALLATO (command -v goose vuoto)"
  exit 1
fi
echo "percorso: $(command -v goose)"
goose --version 2>&1 | head -3
echo

echo "### 3. CHIAVE OPENROUTER (dal portachiavi, mai stampata)"
CHIAVE="$(python3 chiave_di.py "OpenRouter" 2>/dev/null | head -1)"
if [ -z "$CHIAVE" ] || [ "${CHIAVE:0:4}" = "(nes" ]; then
  echo "CHIAVE OPENROUTER NON TROVATA nel portachiavi"
  exit 1
fi
echo "chiave trovata: ${#CHIAVE} caratteri (non stampata)"
echo

echo "### 4. SCRIVO ~/.config/goose/config.yaml"
mkdir -p "$HOME/.config/goose"
if [ -f "$HOME/.config/goose/config.yaml" ]; then
  echo "config presente, ne faccio una copia di sicurezza:"
  cp -n "$HOME/.config/goose/config.yaml" "$HOME/.config/goose/config.yaml.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null
  echo "--- config attuale (mascherata) ---"
  sed -E 's/(API_KEY:).*/\1 ***/' "$HOME/.config/goose/config.yaml"
fi
cat > "$HOME/.config/goose/config.yaml" << EOF
GOOSE_PROVIDER: openrouter
GOOSE_MODEL: nvidia/nemotron-3-ultra-550b-a55b:free
OPENROUTER_API_KEY: $CHIAVE
EOF
chmod 600 "$HOME/.config/goose/config.yaml"
echo "scritto. --- config nuovo (mascherata) ---"
sed -E 's/(API_KEY:).*/\1 ***/' "$HOME/.config/goose/config.yaml"
echo

echo "### 5. PROVA REALE: goose run"
echo "(timeout 300 s; l'output integrale qui sotto)"
timeout 300 goose run -t "Rispondi esattamente con la parola OK e nient'altro." 2>&1 | tail -60
RC=${PIPESTATUS[0]}
echo "--- exit di goose: $RC"
echo

if [ "$RC" -ne 0 ]; then
  echo "### 5b. SECONDO TENTATIVO: modello di scorta + env espliciti"
  sed -i 's#^GOOSE_MODEL:.*#GOOSE_MODEL: google/gemma-4-31b-it:free#' "$HOME/.config/goose/config.yaml"
  export GOOSE_PROVIDER=openrouter
  export GOOSE_MODEL=google/gemma-4-31b-it:free
  export OPENROUTER_API_KEY="$CHIAVE"
  timeout 300 goose run -t "Rispondi esattamente con la parola OK e nient'altro." 2>&1 | tail -60
  RC=${PIPESTATUS[0]}
  echo "--- exit di goose (2o tentativo): $RC"
fi

echo
if [ "$RC" -eq 0 ]; then
  echo "VERDETTO: GOOSE CONFIGURATO E FUNZIONANTE (modello: $(grep '^GOOSE_MODEL:' "$HOME/.config/goose/config.yaml"))"
else
  echo "VERDETTO: GOOSE ANCORA NON FUNZIONANTE (exit $RC) — errore esatto qui sopra"
fi
exit "$RC"
