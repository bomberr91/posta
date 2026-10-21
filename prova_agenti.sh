#!/usr/bin/env bash
# prova_agenti.sh — non basta che siano installati: gli faccio una domanda e guardo chi risponde.
#
# Per ogni agente: versione + una domanda vera ("rispondi solo con OK").
# Se un agente non ha un modo automatico per fargli una domanda, lo dice invece di inventare.
#
#   ./prova_agenti.sh            prova tutti (può volerci 1-3 minuti)
#   ./prova_agenti.sh --svelto   solo versione e cervello (10 secondi)
set -u
QUI=$(cd "$(dirname "$0")" && pwd)
SVELTO=0
[ "${1:-}" = "--svelto" ] && SVELTO=1
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
V22BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
export PATH="$V22BIN:$HOME/.bun/bin:$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$HOME/.hermes/hermes-agent/venv/bin:$HOME/bin:$PATH"
# shellcheck disable=SC1091
. "$QUI/chiavi_env.sh" 2>/dev/null || true

G="\033[32m"; R="\033[31m"; Y="\033[33m"; B="\033[36m"; O="\033[0m"
ok(){ printf "  ${G}✓${O} %-12s %s\n" "$1" "$2"; }
ko(){ printf "  ${R}✗${O} %-12s %s\n" "$1" "$2"; }
at(){ printf "  ${Y}?${O} %-12s %s\n" "$1" "$2"; }
c_e(){ command -v "$1" >/dev/null 2>&1; }
DOMANDA="Rispondi soltanto con la parola OK, nient'altro."

# prova a fargli una domanda: primo argomento = comando completo
chiedi(){  # $1 etichetta, resto = comando
  local etichetta="$1"; shift
  local out
  out=$(timeout 60 "$@" 2>&1 | tr -d '\r' | tail -5)
  if printf '%s' "$out" | grep -qiE "\bOK\b"; then
    ok "$etichetta" "risponde"
  elif [ -z "$out" ]; then
    at "$etichetta" "nessuna risposta: gli manca la configurazione (una volta sola: «goose configure»)"
  else
    at "$etichetta" "risposta strana: $(printf '%s' "$out" | head -1 | cut -c1-60)"
  fi
}

echo "══════════════════════════════════════════════════════════"
echo " 🧪 PROVA AGENTI — chi risponde davvero ($(date '+%d/%m %H:%M'))"
echo "══════════════════════════════════════════════════════════"

# ── 0 · il cervello comune: se è spento, nessuno risponde
MOTORE=0
(exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null && { exec 3<&-; MOTORE=1; }
if [ "$MOTORE" = 1 ]; then
  MODS=0
  for K in "${OMNIROUTE_API_KEY:-}" "${OPENAI_API_KEY:-}" ""; do
    MODS=$(curl -s -m 10 ${K:+-H "Authorization: Bearer $K"} http://127.0.0.1:20128/v1/models | grep -o '"id"' | wc -l)
    [ "${MODS:-0}" -gt 0 ] && break
  done
  if [ "${MODS:-0}" -gt 0 ]; then
    ok "OmniRoute" "🟢 acceso · $MODS modelli disponibili"
  else
    at "OmniRoute" "🟢 acceso ma 0 modelli: attiva i provider free col [9] → f (senza modelli gli agenti non rispondono)"
  fi
else
  ko "OmniRoute" "🔴 spento: senza di lui gli agenti non hanno cervello (accendilo col [9])"
fi

# ── 1 · versioni (sempre)
for a in opencode goose interpreter hermes gemini; do
  if c_e "$a" || { [ "$a" = hermes ] && [ -d "$HOME/.hermes/hermes-agent" ]; }; then
    V=$(timeout 20 "$a" --version 2>&1 | head -1 | tr -d '\r')
    [ -z "$V" ] && V=$(timeout 20 "$a" version 2>&1 | head -1 | tr -d '\r')
    [ -n "$V" ] && ok "$a" "installato · $V" || at "$a" "installato (versione non dichiarata)"
  else
    ko "$a" "non installato"
  fi
done

if [ "$SVELTO" = 0 ] && [ "$MOTORE" = 1 ]; then
  echo ""
  echo " ── domanda vera a chi sa rispondere da solo ──"
  # OpenCode
  if c_e opencode; then
    chiedi "OpenCode" opencode run "$DOMANDA"
  fi
  # Goose
  if c_e goose; then
    chiedi "Goose" goose run -t "$DOMANDA"
  fi
  # Gemini CLI (con la chiave Google del portachiavi)
  if c_e gemini; then
    chiedi "Gemini" gemini -p "$DOMANDA"
  fi
  # Secondhand: il binario Rust non ha un "una domanda e via" affidabile
  c_e interpreter && at "Secondhand" "installato: si prova aprendolo (non ha un modo automatico sicuro)"
  # Hermes: binario OPPURE cartella (spesso vive solo in ~/.hermes)
  { c_e hermes || [ -d "$HOME/.hermes/hermes-agent" ]; } && at "Hermes" "installato (in ~/.hermes): si prova aprendolo"
  # OpenClaw: sta su Windows, il segnale vero è il gateway
  if [ "$(bash "$QUI/apri_openclaw.sh" --stato 2>/dev/null || echo no)" != "no" ]; then
    if (exec 3<>/dev/tcp/127.0.0.1/18789) 2>/dev/null; then
      exec 3<&-; ok "OpenClaw" "gateway acceso su :18789"
    else
      at "OpenClaw" "installato ma spento: premi Accendi nella scheda"
    fi
  else
    ko "OpenClaw" "non installato (va su Windows)"
  fi
fi

echo ""
echo "  Nota: un agente può essere installato e NON rispondere se il motore è spento"
echo "  o se al primo avvio chiede un login (Gemini una volta sola)."
echo "──────────────────────────────────────────────────────────"
