#!/usr/bin/env bash
# secondhand_ok.sh — 4/11: verifica finale di Secondhand (il capo ha fatto
# l'aggiornamento lui). Solo un controllo: la config e' quella del cervello e
# l'interpreter risponde?
#
# La pista del tentativo precedente: il flag globale va PRIMA del sottocomando
# ("interpreter --model auto exec ..."), non dopo.
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

TOKEN="PIPPO42"
PROMPT="Rispondi esattamente con la parola $TOKEN e nient'altro."
export OPENAI_API_KEY=sk-cervello
export OPENAI_BASE_URL=http://127.0.0.1:20129/v1
export OPENAI_HOST=http://127.0.0.1:20129
BK=/tmp/sh_ok_$(date +%H%M%S); mkdir -p "$BK"

echo "### 1. CONFIG (quello che c'e' adesso)"
for f in "$HOME/.openinterpreter/config.toml" "$HOME/.config/open-interpreter/config.toml" "$HOME/.config/interpreter/config.toml" "/mnt/c/Users/giopi/.openinterpreter/config.toml"; do
  echo "--- $f"
  [ -f "$f" ] || { echo "    assente"; continue; }
  grep -E "^\s*(model|model_provider|base_url|env_key|api_key|name|wire_api|sandbox_mode|approval_policy)\s*=" "$f" | sed 's/api_key = .*/api_key = «presente»/' | sed 's/^/    /'
done
echo

echo "### 2. VERSIONE"
echo "  $(interpreter --version 2>&1 | head -1)"
echo

prova() {
  local etichetta="$1"; shift
  echo "--- $etichetta"
  timeout 180 "$@" > "$BK/prova.txt" 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ] && grep -qE "^[[:space:]]*$TOKEN[[:space:]]*$" "$BK/prova.txt"; then
    echo "    >>> FUNZIONA (risposta $TOKEN)"
    return 0
  fi
  echo "    non funziona (exit $rc):"
  tail -3 "$BK/prova.txt" | sed 's/^/      /'
  return 1
}

echo "### 3. COLLAUDO (3 forme, si ferma alla prima che va)"
OK=0
if [ "$OK" = "0" ]; then
  prova "flag prima del sottocomando" interpreter --model auto exec --skip-git-repo-check "$PROMPT" && OK=1
fi
if [ "$OK" = "0" ]; then
  prova "flag prima, senza skip" interpreter --model auto exec "$PROMPT" && OK=1
fi
if [ "$OK" = "0" ]; then
  prova "config nuova + exec" interpreter exec --skip-git-repo-check "$PROMPT" && OK=1
fi
echo
if [ "$OK" = "1" ]; then
  echo "VERDETTO: SECONDHAND PRONTO (parla col cervello, modello auto)"
else
  echo "VERDETTO: SECONDHAND NON PRONTO — la richiesta esce con il modello sbagliato (gpt-4o)"
fi
echo "FINE"
exit 0
