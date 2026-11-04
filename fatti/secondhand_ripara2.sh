#!/usr/bin/env bash
# secondhand_ripara2.sh — 4/11: Secondhand dopo l'upgrade a 0.4.3 (riscrittura).
#
# FATTI (dal referto ripara):
#   - 0.4.3 NON ha piu' il sottocomando "exec": e' una CLI da terminale che
#     chiede "OpenAI API key" se non la trova. Con la sola env OPENAI_API_KEY
#     passa oltre, ma la chiamata litellm va a buon fine solo se la base URL
#     arriva dalla CLI (--api_base), non da OPENAI_BASE_URL.
#   - 0.4.3 NON legge piu' ~/.config/interpreter/config.toml: la sua cartella
#     e' platformdirs.user_config_dir("open-interpreter") => ~/.config/open-interpreter
#   - il ripiego a 0.0.56 fallisce: 0.0.56 non e' piu' su PyPI (pip lo scarta)
#
# Cosa fa qui, in ordine:
#   A) prova la CLI NUOVA (0.4.3) con varie combinazioni di flag/env
#   B) se nessuna funziona: ripristina la 0.0.56 dalla CACHE DI PIP
#      (la ruota originale e' li' dentro) => torna esattamente com'era prima
#   C) in ogni caso scrive la config nel posto GIUSTO per la versione che
#      resta e fa il collaudo reale con un token univoco (niente falsi verdi)
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

TOKEN="PIPPO42"
PROMPT="Rispondi esattamente con la parola $TOKEN e nient'altro."
WSL_CFG_OLD="$HOME/.config/interpreter/config.toml"
WSL_CFG_NEW="$HOME/.config/open-interpreter/config.toml"
STAMP=$(date +%Y%m%d-%H%M%S)
BK="/tmp/sh_ripara2_$STAMP"
mkdir -p "$BK"
[ -f "$WSL_CFG_OLD" ] && cp "$WSL_CFG_OLD" "$BK/config_old.toml"

echo "### 0. CONFIG NUOVA NEL POSTO GIUSTO (per 0.4.3)"
mkdir -p "$(dirname "$WSL_CFG_NEW")"
cat > "$WSL_CFG_NEW" << EOF
[llm]
provider = "openai"
model = "auto"
api_key = "sk-cervello"
base_url = "http://127.0.0.1:20129/v1"
EOF
echo "  scritta: $WSL_CFG_NEW"
echo "  (per 0.0.56 invece vale $WSL_CFG_OLD)"
echo

prova() {
  # $1 = etichetta, $2.. = comando
  local etichetta="$1"; shift
  echo "--- $etichetta"
  timeout 180 "$@" > "$BK/prova.txt" 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ] && grep -qE "^[[:space:]]*$TOKEN[[:space:]]*$" "$BK/prova.txt"; then
    echo "    >>> FUNZIONA (exit 0, risposta $TOKEN)"
    return 0
  fi
  echo "    non funziona (exit $rc) — ultime righe:"
  tail -5 "$BK/prova.txt" | sed 's/^/      /'
  return 1
}

echo "### 1. LA CLI NUOVA (0.4.3)"
echo "  versione: $(interpreter --version 2>&1 | head -1)"
export OPENAI_API_KEY=sk-cervello
export OPENAI_BASE_URL=http://127.0.0.1:20129/v1
OK=0
if [ "$OK" = "0" ]; then
  prova "0.4.3 con --api_base e --model" interpreter -y --api_base http://127.0.0.1:20129/v1 --model auto "$PROMPT" && OK=1
fi
if [ "$OK" = "0" ]; then
  prova "0.4.3 con --api_base, modello openai/auto" interpreter -y --api_base http://127.0.0.1:20129/v1 --model openai/auto "$PROMPT" && OK=1
fi
if [ "$OK" = "0" ]; then
  prova "0.4.3 con solo env" interpreter -y "$PROMPT" && OK=1
fi
if [ "$OK" = "0" ]; then
  prova "0.4.3 con --api_base e modello gpt-4o" interpreter -y --api_base http://127.0.0.1:20129/v1 --model gpt-4o "$PROMPT" && OK=1
fi
echo

if [ "$OK" = "1" ]; then
  echo "### 2. RISULTATO: 0.4.3 FUNZIONA COL CERVELLO"
  echo "  invocazione: interpreter -y --api_base http://127.0.0.1:20129/v1 --model auto \"<compito>\""
  echo "  chiave: OPENAI_API_KEY=sk-cervello (finta, e' la chiave del portone)"
  echo "FINE"
  exit 0
fi

echo "### 2. LA NUOVA NON VA: RIPRISTINO LA 0.0.56 DALLA CACHE DI PIP"
echo "--- ruote in cache:"
find "$HOME/.cache/pip" -name "open_interpreter-0.0.56*" 2>/dev/null | head -5
RUOTA=$(find "$HOME/.cache/pip" -name "open_interpreter-0.0.56*.whl" 2>/dev/null | head -1)
if [ -n "$RUOTA" ]; then
  cp "$RUOTA" "$BK/"
  timeout 600 python3 -m pip install --user --break-system-packages --no-deps "$BK/$(basename "$RUOTA")" > "$BK/revert.log" 2>&1
  echo "  exit pip: $?"
  tail -4 "$BK/revert.log"
else
  echo "  ruota 0.0.56 NON trovata in cache: cerco un'altra 0.0.x installabile"
  timeout 600 python3 -m pip install --user --break-system-packages --ignore-requires-python "open-interpreter==0.0.297" > "$BK/revert2.log" 2>&1
  echo "  exit pip: $?"
  tail -4 "$BK/revert2.log"
fi
echo "  versione: $(interpreter --version 2>&1 | head -1)"
[ -f "$BK/config_old.toml" ] && cp "$BK/config_old.toml" "$WSL_CFG_OLD" && echo "  config vecchia ripristinata"
echo "--- collaudo col comando VECCHIO (exec):"
timeout 240 interpreter exec --skip-git-repo-check "$PROMPT" > "$BK/collaudo.txt" 2>&1
RC=$?
echo "  exit: $RC"
grep -E "^[[:space:]]*$TOKEN[[:space:]]*$" "$BK/collaudo.txt" | head -2
tail -4 "$BK/collaudo.txt" | sed 's/^/    /'
if [ "$RC" -eq 0 ] && grep -qE "^[[:space:]]*$TOKEN[[:space:]]*$" "$BK/collaudo.txt"; then
  echo "  VERDETTO: RIPRISTINATA LA VERSIONE PRECEDENTE, COLLAUDATA (risposta $TOKEN)"
else
  echo "  VERDETTO: ANCORA ROTTO — vedi $BK/collaudo.txt"
fi
echo "FINE"
exit 0
