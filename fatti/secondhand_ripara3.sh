#!/usr/bin/env bash
# secondhand_ripara3.sh — 4/11: chiudere il cerchio su Secondhand 0.4.3.
#
# FATTI (dal referto ripara2):
#   - 0.4.3 NON accetta un prompt come argomento ("Unrecognized argument(s)")
#   - MA `interpreter exec --skip-git-repo-check "<prompt>"` FUNZIONA ANCORA:
#     e' arrivata fino al CERVELLO, che ha risposto con la sua guardia:
#     "Guardia solo-gratis: 'gpt-4o' sembra un modello a pagamento.
#      Usa 'auto', 'gratis', 'veloce' o 'migliore'"
#     => il problema e' solo il MODELO: 0.4.3 non legge piu' la config vecchia
#        (~/.config/interpreter/config.toml) e parte da gpt-4o.
#   - il ritorno alla 0.0.x non e' praticabile (0.0.56 non e' piu' su PyPI e
#     la 0.0.297 non si compila su Python 3.12) => si va avanti con 0.4.3
#
# Cosa fa qui:
#   1) prova il comando exec con il modello esplicito (--model/-m auto)
#   2) se non basta, scopre dove 0.4.3 legge la config e la scrive come si deve
#   3) collaudo reale con un token univoco e stampa l'ESATTO comando che funziona
#      (serve per aggiornare il wrapper del ponte)
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

TOKEN="PIPPO42"
PROMPT="Rispondi esattamente con la parola $TOKEN e nient'altro."
PKG="$HOME/.local/lib/python3.12/site-packages/interpreter"
STAMP=$(date +%Y%m%d-%H%M%S)
BK="/tmp/sh_ripara3_$STAMP"
mkdir -p "$BK"

export OPENAI_API_KEY=sk-cervello
export OPENAI_BASE_URL=http://127.0.0.1:20129/v1
export OPENAI_HOST=http://127.0.0.1:20129

prova() {
  local etichetta="$1"; shift
  echo "--- $etichetta"
  timeout 180 "$@" > "$BK/prova.txt" 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ] && grep -qE "^[[:space:]]*$TOKEN[[:space:]]*$" "$BK/prova.txt"; then
    echo "    >>> FUNZIONA (exit 0, risposta $TOKEN)"
    return 0
  fi
  echo "    non funziona (exit $rc) — ultime righe:"
  tail -4 "$BK/prova.txt" | sed 's/^/      /'
  return 1
}

echo "### 1. IL MODELO SI PUO' DIRE DA LINEA DI COMANDO?"
echo "  versione: $(interpreter --version 2>&1 | head -1)"
OK=0
if [ "$OK" = "0" ]; then
  prova "exec --model auto" interpreter exec --skip-git-repo-check --model auto "$PROMPT" && OK=1
fi
if [ "$OK" = "0" ]; then
  prova "exec -m auto" interpreter exec -m auto --skip-git-repo-check "$PROMPT" && OK=1
fi
if [ "$OK" = "0" ]; then
  prova "exec con env MODEL" env MODEL=auto interpreter exec --skip-git-repo-check "$PROMPT" && OK=1
fi
if [ "$OK" = "0" ]; then
  prova "exec con env OPENAI_MODEL" env OPENAI_MODEL=auto interpreter exec --skip-git-repo-check "$PROMPT" && OK=1
fi
echo

if [ "$OK" = "0" ]; then
  echo "### 2. DOVE 0.4.3 LEGGE LA CONFIG (e come si chiama il file)"
  echo "--- file che parlano di config.toml:"
  grep -rln --include=*.py "config.toml" "$PKG" 2>/dev/null | head -6
  echo "--- righe sul caricamento (toml.load / config_path):"
  grep -rn --include=*.py -E "toml\.load|toml\.loads|config_path|CONFIG_PATH|user_config_dir" "$PKG" 2>/dev/null | head -20
  echo "--- chiavi usate per il modello e la base url:"
  grep -rn --include=*.py -E "\"model\"|'model'|api_base|\"provider\"" "$PKG/core/core.py" 2>/dev/null | head -12
  echo "--- provo a scrivere la config nuova in piu' posti (formati possibili)"
  for DEST in "$HOME/.config/open-interpreter/config.toml" "$HOME/.config/open-interpreter/oi.toml" "$HOME/.config/open-interpreter/interpreter.toml"; do
    mkdir -p "$(dirname "$DEST")"
    cat > "$DEST" << EOF
model = "auto"
provider = "openai"
api_key = "sk-cervello"
base_url = "http://127.0.0.1:20129/v1"
EOF
    cat >> "$DEST" << EOF

[llm]
model = "auto"
provider = "openai"
api_key = "sk-cervello"
base_url = "http://127.0.0.1:20129/v1"
EOF
    echo "--- scritta $DEST"
    if prova "exec con config in $DEST" interpreter exec --skip-git-repo-check "$PROMPT"; then OK=1; break; fi
  done
fi

echo
if [ "$OK" = "1" ]; then
  echo "### 3. RISULTATO: SECONDHAND (0.4.3) PARLA COL CERVELLO"
  echo "  chiave: OPENAI_API_KEY=sk-cervello"
  echo "  base: http://127.0.0.1:20129/v1"
  echo "  modello: auto (il cervello sceglie: gratis/veloce/migliore)"
  echo "  NOTA per il wrapper del ponte: usare la forma che ha funzionato sopra."
else
  echo "### 3. ANCORA NON FUNZIONA"
fi
echo
echo "--- ultime righe della prova:"
tail -12 "$BK/prova.txt" | sed 's/^/    /'
echo "FINE"
exit 0
