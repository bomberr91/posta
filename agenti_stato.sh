#!/usr/bin/env bash
# agenti_stato.sh — com'è messo OGNI agente: installato? con quale chiave? pronto a partire?
# Questo è il file che alimenta la scheda "🤖 Agenti" dell'interfaccia e il [7] della Centrale.
#
#   ./agenti_stato.sh            tabella leggibile
#   ./agenti_stato.sh --json     una riga JSON (per la GUI)
set -u
QUI=$(cd "$(dirname "$0")" && pwd)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
V22BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
export PATH="$V22BIN:$HOME/.bun/bin:$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$HOME/.hermes/hermes-agent/venv/bin:$HOME/bin:$PATH"
# shellcheck disable=SC1091
. "$QUI/chiavi_env.sh" 2>/dev/null || true

c_e(){ command -v "$1" >/dev/null 2>&1 && return 0
       local c; for c in "$HOME/.nvm/versions/node/"*/bin/"$1" "$HOME/.local/bin/$1" "$HOME/.bun/bin/$1" \
         "$HOME/.opencode/bin/$1" "$HOME/.hermes/hermes-agent/bin/$1" "$HOME/.hermes/hermes-agent/venv/bin/$1" \
         "$HOME/bin/$1"; do [ -x "$c" ] && return 0; done; return 1; }
ver(){ ( command -v "$1" >/dev/null 2>&1 && timeout 20 "$1" --version 2>&1 | head -1 ) \
       || (command -v "$1" >/dev/null 2>&1 && timeout 20 "$1" version 2>&1 | head -1) \
       || echo ""; }

# ogni agente: nome | binario | chiave necessaria | cosa gli serve
riga(){  # nome, bin, chiave_ok(0/1), nota, comando-per-aprirlo
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5"
}

json_pezzi=""
aggiungi(){
  local nome="$1" bin="$2" inst="$3" vers="$4" chiave="$5" nota="$6" apri="$7"
  json_pezzi="$json_pezzi{\"nome\":\"$nome\",\"bin\":\"$bin\",\"installato\":$inst,\"versione\":\"$vers\",\"chiave\":$chiave,\"pronto\":$([ "$inst" = true ] && { [ "$chiave" = true ] || [ -z "$nota" ]; } && echo true || echo false),\"nota\":\"$nota\",\"apri\":\"$apri\"},"
}

# ── 1 · OpenCode (Architetto & Codice)
if c_e opencode; then V=$(ver opencode); K=false; [ -n "${OPENCODE_API_KEY:-}" ] && K=true
  aggiungi "OpenCode" "opencode" true "$V" "$K" "$([ "$K" = true ] && echo '' || echo 'manca la chiave OpenCode Zen')" "opencode"
else aggiungi "OpenCode" "opencode" false "" false "da installare" "opencode"; fi

# ── 2 · Goose (Automazione)
if c_e goose; then V=$(ver goose); K=false; [ -n "${OPENAI_API_KEY:-}" ] && K=true
  aggiungi "Goose" "goose" true "$V" "$K" "$([ "$K" = true ] && echo '' || echo 'manca la chiave del cervello')" "goose session"
else aggiungi "Goose" "goose" false "" false "da installare" "goose session"; fi

# ── 3 · Secondhand / OpenInterpreter (Revisore)
if c_e interpreter; then aggiungi "Secondhand" "interpreter" true "$(ver interpreter)" true "" "interpreter"
else aggiungi "Secondhand" "interpreter" false "" false "da installare" "interpreter"; fi

# ── 4 · Hermes (Strategia e ricerca)
if c_e hermes || [ -d "$HOME/.hermes/hermes-agent" ]; then
  aggiungi "Hermes" "hermes" true "$(ver hermes)" true "" "hermes"
else aggiungi "Hermes" "hermes" false "" false "da installare" "hermes"; fi

# ── 5 · Gemini CLI (Google)
if c_e gemini; then V=$(ver gemini); K=false; [ -n "${GEMINI_API_KEY:-}" ] && K=true
  aggiungi "Gemini CLI" "gemini" true "$V" "$K" "$([ "$K" = true ] && echo '' || echo 'serve un accesso Google (una volta sola)')" "gemini"
else aggiungi "Gemini CLI" "gemini" false "" false "da installare" "gemini"; fi

# ── 6 · OpenClaw (lavora sul PC): sta su Windows
OC=$(bash "$QUI/apri_openclaw.sh" --stato 2>/dev/null); OC=${OC:-no}
if [ "$OC" != "no" ]; then
  GWO=0; (exec 3<>"/dev/tcp/127.0.0.1/18789") 2>/dev/null && { exec 3<&-; GWO=1; }
  aggiungi "OpenClaw" "openclaw" true "$(bash "$QUI/openclaw_stato.sh" --json 2>/dev/null | sed -E 's/.*"versione":"([^"]*)".*/\1/')" "$([ "$GWO" = 1 ] && echo true || echo false)" \
    "$([ "$GWO" = 1 ] && echo '' || echo 'gateway spento: apri dalla scheda e premi Accendi')" "apri_openclaw.sh"
else aggiungi "OpenClaw" "openclaw" false "" false "da installare (su Windows)" "INSTALLA_OPENCLAW.bat"; fi

# ── 7 · OmniRoute (il motore di tutti: non è un agente ma serve a tutti)
GWM=0; (exec 3<>"/dev/tcp/127.0.0.1/20128") 2>/dev/null && { exec 3<&-; GWM=1; }
OMNI_INST=false; { c_e omniroute || ls "$HOME"/.nvm/versions/node/*/bin/omniroute >/dev/null 2>&1; } && OMNI_INST=true
aggiungi "OmniRoute" "omniroute" "$OMNI_INST" "" true \
  "$([ "$GWM" = 1 ] && echo '' || { [ "$OMNI_INST" = true ] && echo 'installato ma spento: accendilo col [9] o dalla scheda' || echo 'da installare col [9]'; })" "omniroute"

case "${1:-}" in
  --json) printf '{"agenti":[%s],"chiavi":{"opencode":%s,"groq":%s,"google":%s,"omniroute":%s},"cervello":"%s"}\n' \
            "${json_pezzi%,}" \
            "$([ -n "${OPENCODE_API_KEY:-}" ] && echo true || echo false)" \
            "$([ -n "${GROQ_API_KEY:-}" ] && echo true || echo false)" \
            "$([ -n "${GEMINI_API_KEY:-}" ] && echo true || echo false)" \
            "$([ -n "${OMNIROUTE_API_KEY:-}" ] && echo true || echo false)" \
            "${OPENAI_BASE_URL:-}";;
  *)
    echo "─────────────── 🤖 AGENTI ───────────────"
    printf '  %-12s %-10s %-7s %s\n' "AGENTE" "STATO" "CHIAVE" "NOTE"
    IFS='},'
    echo "$json_pezzi" | tr '}' '\n' | while IFS= read -r blocco; do
      [ -z "$blocco" ] && continue
      nome=$(echo "$blocco" | sed -nE 's/.*"nome":"([^"]*)".*/\1/p')
      inst=$(echo "$blocco" | sed -nE 's/.*"installato":(true|false).*/\1/p')
      str=$(echo "$blocco" | sed -nE 's/.*"pronto":(true|false).*/\1/p')
      chi=$(echo "$blocco" | sed -nE 's/.*"chiave":(true|false).*/\1/p')
      nota=$(echo "$blocco" | sed -nE 's/.*"nota":"([^"]*)".*/\1/p')
      [ -z "$nome" ] && continue
      if [ "$inst" = true ]; then st="✓ installato"; else st="✗ manca"; fi
      [ "$inst" = true ] && [ "$str" != true ] && st="⚠ da sistemare"
      [ "$inst" = true ] && [ "$str" = true ] && st="🟢 pronto"
      ch="$([ "$chi" = true ] && echo 'sì' || echo 'no')"
      printf '  %-12s %-14s %-7s %s\n' "$nome" "$st" "$ch" "$nota"
    done
    echo "─────────────────────────────────────────"
    echo "  cervello per gli agenti: ${OPENAI_BASE_URL:-—}  (modello ${OPENAI_MODEL:-auto})"
    ;;
esac
