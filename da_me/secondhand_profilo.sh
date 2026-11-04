#!/usr/bin/env bash
# secondhand_profilo.sh — 4/11: il profilo di 0.4.3 e' un YAML:
#   ~/.config/open-interpreter/profiles/default.yaml
# (l'ho trovato grazie all'ls -R). Il modello e' gia' li' dentro, non nel TOML.
#
# Qui: (1) si mostra il profilo attuale (mascherato), (2) si mostra il codice
# che lo carica, (3) si provano due strutture YAML e si tiene la prima che
# fa rispondere OK il cervello.
#
# Niente pipe verso tail.
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

TOKEN="PIPPO42"
PROMPT="Rispondi esattamente con la parola $TOKEN e nient'altro."
P="$HOME/.config/open-interpreter/profiles/default.yaml"
export OPENAI_API_KEY=sk-cervello
export OPENAI_BASE_URL=http://127.0.0.1:20129/v1
BK=/tmp/sh_prof_$(date +%H%M%S); mkdir -p "$BK"

maschera() {
  sed -E 's/(api_key|apiKey|secret|token)([[:space:]]*:[[:space:]]*).*/\1\2«presente»/I' "$1"
}

echo "### 1. IL PROFILO ATTUALE (mascherato)"
[ -f "$P" ] && { echo "--- $P"; maschera "$P"; } || echo "  assente: $P"
echo
echo "### 2. COME VIENE LETTO (codice)"
sed -n '200,260p' "$HOME/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/profiles.py" 2>/dev/null | head -40
echo

prova() {
  local etichetta="$1"; shift
  echo "--- $etichetta"
  timeout 180 interpreter exec --skip-git-repo-check "$PROMPT" > "$BK/prova.txt" 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ] && grep -qE "^[[:space:]]*$TOKEN[[:space:]]*$" "$BK/prova.txt"; then
    echo "    >>> FUNZIONA (risposta $TOKEN)"
    return 0
  fi
  echo "    non funziona (exit $rc):"
  tail -3 "$BK/prova.txt" | sed 's/^/      /'
  return 1
}

echo "### 3. PROVA STRUTTURA A (llm: {...})"
[ -f "$P" ] && cp "$P" "$BK/default.yaml.bak"
cat > "$P" << 'EOF'
llm:
  model: auto
  provider: openai
  api_key: sk-cervello
  base_url: http://127.0.0.1:20129/v1
EOF
echo "--- profilo scritto:"; maschera "$P" | sed 's/^/    /'
OK=0
prova "struttura A" && OK=1

if [ "$OK" = "0" ]; then
  echo "### 4. PROVA STRUTTURA B (chiavi in piano)"
  cat > "$P" << 'EOF'
model: auto
provider: openai
api_key: sk-cervello
base_url: http://127.0.0.1:20129/v1
EOF
  echo "--- profilo scritto:"; maschera "$P" | sed 's/^/    /'
  prova "struttura B" && OK=1
fi

if [ "$OK" = "0" ]; then
  echo "### 5. PROVA STRUTTURA C (llm.model + modello, con env)"
  cat > "$P" << 'EOF'
llm:
  model: auto
EOF
  prova "struttura C" && OK=1
fi

echo
if [ "$OK" = "1" ]; then
  echo "VERDETTO: SECONDHAND PRONTO (profilo sistemato, risposta $TOKEN dal cervello)"
  echo "  profilo: $P"
  echo "  backup: $BK/default.yaml.bak"
else
  echo "VERDETTO: ANCORA NON PRONTO"
  [ -f "$BK/default.yaml.bak" ] && cp "$BK/default.yaml.bak" "$P" && echo "  profilo originale ripristinato"
fi
echo "FINE"
exit 0
