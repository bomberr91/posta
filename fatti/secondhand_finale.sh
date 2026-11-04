#!/usr/bin/env bash
# secondhand_finale.sh — 4/11: chiudere Secondhand (0.4.3) sul cervello.
#
# FATTI (dal referto profilo):
#   - il profilo di 0.4.3 e' ~/.config/open-interpreter/profiles/default.yaml
#     (YAML), e il campo giusto per la base URL e' "api_base" (non "base_url")
#   - scrivendo llm.model: auto la chiamata E' passata (il cervello non ha
#     piu' respinto gpt-4o): ora pero' l'interpreter chiede "y/n" per eseguire
#     il codice e, senza terminale, muore con EOFError
#   => nel profilo vanno messi auto_run: True e safe_mode: "off"
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
export OPENAI_HOST=http://127.0.0.1:20129
BK=/tmp/sh_fin_$(date +%H%M%S); mkdir -p "$BK"

echo "### 1. SCRIVO IL PROFILO (cervello, senza richieste di conferma)"
[ -f "$P" ] && cp "$P" "$BK/default.yaml.bak" && echo "  backup: $BK/default.yaml.bak"
cat > "$P" << 'EOF'
# OPEN INTERPRETER CONFIGURATION FILE
# 4/11: Secondhand parla col CERVELLO LOCALE (20129) con la chiave fissa del
# portone: nessuna chiave provider in giro.

llm:
  model: "auto"
  temperature: 0
  api_key: "sk-cervello"
  api_base: "http://127.0.0.1:20129/v1"

computer:
  import_computer_api: True

auto_run: True
safe_mode: "off"

version: 0.2.5  # Profile version (do not modify)
EOF
echo "  scritto: $P"
echo

echo "### 2. COLLAUDO REALE"
timeout 240 interpreter exec --skip-git-repo-check "$PROMPT" > "$BK/prova.txt" 2>&1
RC=$?
echo "  exit: $RC"
if [ "$RC" -eq 0 ] && grep -qE "^[[:space:]]*$TOKEN[[:space:]]*$" "$BK/prova.txt"; then
  echo "  >>> FUNZIONA (risposta $TOKEN dal cervello)"
  echo "  prime righe:"; head -12 "$BK/prova.txt" | sed 's/^/    /'
  echo "VERDETTO: SECONDHAND PRONTO"
else
  echo "  non funziona (exit $RC) — ultime righe:"
  tail -8 "$BK/prova.txt" | sed 's/^/    /'
  echo "VERDETTO: ANCORA NON PRONTO"
fi
echo
echo "### 3. LA STESSA COSA PER L'APP WINDOWS (profilo 0.4.x)"
WP=/mnt/c/Users/giopi/.config/open-interpreter/profiles/default.yaml
if [ -f "$WP" ]; then
  cp "$WP" "$BK/default_windows.yaml.bak" && echo "  backup: $BK/default_windows.yaml.bak"
else
  mkdir -p "$(dirname "$WP")"
fi
sed -e 's|api_base: .*|api_base: "http://127.0.0.1:20129/v1"|' \
    -e 's|model: .*|model: "auto"|' \
    -e 's|# api_key:.*|  api_key: "sk-cervello"|' \
    "$P" > "$WP" 2>/dev/null
echo "  scritto: $WP"
echo
echo "FINE"
exit 0
