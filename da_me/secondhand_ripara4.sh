#!/usr/bin/env bash
# secondhand_ripara4.sh — 4/11: Secondhand 0.4.3 sul cervello (config nuova).
#
# LA PUNTA (documentazione ufficiale 0.4.x):
#   - la config utente sta in ~/.openinterpreter/config.toml (NON in
#     ~/.config/interpreter/config.toml, che era quella della 0.0.x)
#   - chiavi: model, model_provider, sandbox_mode, approval_policy
#   - provider personalizzato:
#       [model_providers.cervello]
#       name = "Cervello"
#       base_url = "http://127.0.0.1:20129/v1"
#       env_key = "OPENAI_API_KEY"
#       wire_api = "chat"
#   - esecuzione non interattiva: `interpreter exec "<prompt>"`
#   - c'è anche `interpreter update` (l'installer ufficiale)
#
# Il problema di prima era solo questo: 0.4.3 partiva da gpt-4o (che il
# cervello rifiuta, regola "solo gratis") perche' non leggeva la config vecchia.
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

TOKEN="PIPPO42"
PROMPT="Rispondi esattamente con la parola $TOKEN e nient'altro."
STAMP=$(date +%Y%m%d-%H%M%S)
BK="/tmp/sh_ripara4_$STAMP"
mkdir -p "$BK"

export OPENAI_API_KEY=sk-cervello
export OPENAI_BASE_URL=http://127.0.0.1:20129/v1
export OPENAI_HOST=http://127.0.0.1:20129

echo "### 1. CONFIG UTENTE NUOVA (WSL): ~/.openinterpreter/config.toml"
mkdir -p "$HOME/.openinterpreter"
[ -f "$HOME/.openinterpreter/config.toml" ] && cp "$HOME/.openinterpreter/config.toml" "$BK/config_utente_precedente.toml"
cat > "$HOME/.openinterpreter/config.toml" << 'EOF'
model = "auto"
model_provider = "cervello"
approval_policy = "never"
sandbox_mode = "workspace-write"
web_search = "cached"

[model_providers.cervello]
name = "Cervello"
base_url = "http://127.0.0.1:20129/v1"
env_key = "OPENAI_API_KEY"
wire_api = "chat"
EOF
echo "  scritta: $HOME/.openinterpreter/config.toml"
echo "  backup del precedente: $BK/config_utente_precedente.toml"
echo

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

echo "### 2. COLLAUDO (varianti di comando, si ferma alla prima che va)"
OK=0
if [ "$OK" = "0" ]; then
  prova "exec --skip-git-repo-check" interpreter exec --skip-git-repo-check "$PROMPT" && OK=1
fi
if [ "$OK" = "0" ]; then
  prova "exec" interpreter exec "$PROMPT" && OK=1
fi
if [ "$OK" = "0" ]; then
  prova "exec con -c model=auto" interpreter exec -c model='"auto"' "$PROMPT" && OK=1
fi
echo

if [ "$OK" = "1" ]; then
  echo "### 3. OK: 0.4.3 PARLA COL CERVELLO"
  echo "  comando: interpreter exec --skip-git-repo-check \"<compito>\""
  echo "  chiave: OPENAI_API_KEY=sk-cervello   base: http://127.0.0.1:20129/v1   modello: auto"
else
  echo "### 3. ANCORA NON VA — ultime righe:"
  tail -14 "$BK/prova.txt" | sed 's/^/    /'
fi
echo

echo "### 4. CONFIG NUOVA ANCHE PER L'APP WINDOWS"
WIN_CFG=/mnt/c/Users/giopi/.openinterpreter/config.toml
if [ -f "$WIN_CFG" ]; then
  cp "$WIN_CFG" "$BK/config_windows_precedente.toml" && echo "  backup: $BK/config_windows_precedente.toml"
else
  echo "  (non c'era: $WIN_CFG)"
fi
cat > "$WIN_CFG" << 'EOF'
model = "auto"
model_provider = "cervello"
approval_policy = "never"
sandbox_mode = "danger-full-access"

[model_providers.cervello]
name = "Cervello"
base_url = "http://127.0.0.1:20129/v1"
env_key = "OPENAI_API_KEY"
wire_api = "chat"
EOF
echo "  scritta: $WIN_CFG (formato 0.4.x)"
echo "  la variabile OPENAI_API_KEY=sk-cervello e' gia' impostata per Windows (setx)"
echo
echo "### 5. VERSIONE"
echo "  $(interpreter --version 2>&1 | head -1)"
echo "  (ultima release PyPI: 0.4.3)"
echo "FINE"
exit 0
