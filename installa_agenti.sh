#!/usr/bin/env bash
# installa_agenti.sh — mette a posto TUTTI gli agenti in un colpo solo, senza domande.
#
# Perché esiste: non voglio che un agente manchi quando ti serve. Questo file:
#   · guarda chi c'è e chi manca
#   · installa SOLO i mancanti (chi c'è non lo tocca)
#   · mette in ogni agente il cervello comune (OmniRoute, formato OpenAI) tramite chiavi_env.sh
#   · alla fine ti stampa la tabella: chi è 🟢 pronto, chi è ⚠ da sistemare, chi manca
#
#   ./installa_agenti.sh                 installa tutto quello che manca
#   ./installa_agenti.sh gemini hermes   solo quelli che dici tu
#   ./installa_agenti.sh --prova         non installa: dice solo cosa farebbe
#   ./installa_agenti.sh --stato         solo la tabella (veloce)
set -u
QUI=$(cd "$(dirname "$0")" && pwd)
PROVA=0; SOLO=""
for a in "$@"; do
  case "$a" in
    --prova|-n) PROVA=1 ;;
    --stato) bash "$QUI/agenti_stato.sh"; exit 0 ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) SOLO="$SOLO $a" ;;
  esac
done
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
NPM22=$(ls "$HOME/.nvm/versions/node/v22"*/bin/npm 2>/dev/null | sort -V | tail -1)
[ -z "$NPM22" ] && NPM22=$(ls "$HOME/.nvm/versions/node/"*/bin/npm 2>/dev/null | sort -V | tail -1)
[ -z "$NPM22" ] && command -v npm >/dev/null 2>&1 && NPM22=$(command -v npm)
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$HOME/.hermes/hermes-agent/venv/bin:$HOME/bin:$PATH"
# shellcheck disable=SC1091
. "$QUI/chiavi_env.sh" 2>/dev/null || true

B="\033[36m"; G="\033[32m"; R="\033[31m"; Y="\033[33m"; O="\033[0m"
d(){ printf "  ${B}▸${O} %s\n" "$*"; }
ok(){ printf "  ${G}✓${O} %s\n" "$*"; }
ko(){ printf "  ${R}✗${O} %s\n" "$*"; }
at(){ printf "  ${Y}!${O} %s\n" "$*"; }
c_e(){ command -v "$1" >/dev/null 2>&1; }

vuole(){  # se ho chiesto agenti specifici, faccio solo quelli
  [ -z "$SOLO" ] && return 0
  case " $SOLO " in *" $1 "*) return 0 ;; esac
  return 1
}
esegui(){ if [ "$PROVA" = 1 ]; then d "[prova] $*"; return 1; fi; eval "$*"; }

echo "══════════════════════════════════════════════════════════"
echo " 🤖 AGENTI — tutti installati e pronti ($(date '+%d/%m %H:%M'))"
echo "══════════════════════════════════════════════════════════"
[ "$PROVA" = 1 ] && at "MODALITÀ PROVA: guardo soltanto"
d "cervello comune: ${OPENAI_BASE_URL:-—} (modello ${OPENAI_MODEL:-auto})"

# ── 1 · OpenCode ────────────────────────────────────────────────────────────
if vuole opencode; then
  if c_e opencode; then ok "OpenCode già presente ($(opencode --version 2>&1 | head -1))"
  else
    d "Installo OpenCode…"
    if esegui "curl -fsSL https://opencode.ai/install | bash >/dev/null 2>&1"; then
      export PATH="$HOME/.opencode/bin:$PATH"
      c_e opencode && ok "OpenCode installato" || ko "OpenCode: non installato (rete?)"
    fi
  fi
fi

# ── 2 · Goose ───────────────────────────────────────────────────────────────
if vuole goose; then
  if c_e goose; then ok "Goose già presente ($(goose --version 2>&1 | head -1))"
  else
    d "Installo Goose…"
    if esegui "curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash >/dev/null 2>&1"; then
      export PATH="$HOME/.local/bin:$PATH"
      c_e goose && ok "Goose installato" || ko "Goose: non installato"
    fi
  fi
fi

# ── 3 · Secondhand (OpenInterpreter) ────────────────────────────────────────
if vuole interpreter; then
  if c_e interpreter; then ok "Secondhand già presente"
  else
    d "Installo Secondhand…"
    if esegui "OPEN_INTERPRETER_NONINTERACTIVE=1 curl -fsSL https://www.openinterpreter.com/install | OPEN_INTERPRETER_NONINTERACTIVE=1 sh >/dev/null 2>&1"; then
      export PATH="$HOME/.local/bin:$PATH"
      c_e interpreter && ok "Secondhand installato" || at "Secondhand: non disponibile su WSL1 (si salta, non è un guasto)"
    fi
  fi
fi

# ── 4 · Hermes ──────────────────────────────────────────────────────────────
if vuole hermes; then
  if c_e hermes || [ -d "$HOME/.hermes/hermes-agent" ]; then ok "Hermes già presente"
  else
    d "Installo Hermes (NousResearch)… può metterci 2-4 minuti"
    if esegui "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive --skip-browser --skip-computer-use >/dev/null 2>&1"; then
      export PATH="$HOME/.hermes/hermes-agent/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH"
      { c_e hermes || [ -d "$HOME/.hermes/hermes-agent" ]; } && ok "Hermes installato" || ko "Hermes: non installato"
    fi
  fi
fi

# ── 5 · Gemini CLI ──────────────────────────────────────────────────────────
if vuole gemini; then
  if c_e gemini; then ok "Gemini CLI già presente ($(gemini --version 2>&1 | head -1))"
  elif [ -z "$NPM22" ]; then ko "Gemini CLI: manca npm (Node): prima rifai [8]"
  else
    d "Installo Gemini CLI (npm, ~1 minuto)…"
    if esegui "\"$NPM22\" install -g @google/gemini-cli >/dev/null 2>&1"; then
      hash -r 2>/dev/null
      c_e gemini && ok "Gemini CLI installato ($(gemini --version 2>&1 | head -1))" || ko "Gemini CLI: non installato"
    fi
    [ -n "${GEMINI_API_KEY:-}" ] && ok "chiave Google trovata nel portachiavi" || at "Gemini: serve un accesso Google (si fa una volta: comando «gemini»)"
  fi
fi

# ── 6 · OpenClaw (vive su Windows) ──────────────────────────────────────────
if vuole openclaw || [ -z "$SOLO" ]; then
  TIPO=$(bash "$QUI/apri_openclaw.sh" --stato 2>/dev/null); TIPO=${TIPO:-no}
  if [ "$TIPO" = "no" ]; then
    at "OpenClaw: va installato da Windows → doppio clic su INSTALLA_OPENCLAW.bat (una volta sola)"
  else
    (exec 3<>/dev/tcp/127.0.0.1/18789) 2>/dev/null && { exec 3<&-; ok "OpenClaw acceso (gateway su :18789)"; } \
      || at "OpenClaw installato ma spento: apri la scheda e premi ▶ Accendi"
  fi
fi

# ── 7 · il cervello comune: OmniRoute ───────────────────────────────────────
if (exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null; then
  exec 3<&-; ok "OmniRoute acceso (:20128) — è il cervello che usano gli agenti"
else
  at "OmniRoute spento: gli agenti senza cervello non rispondono. Accendilo col [9] o dalla scheda 🤖 Agenti"
fi

# ── 8 · config: ogni agente puntato su OmniRoute ────────────────────────────
# Goose e gli altri compatibili OpenAI leggono queste variabili; le scrivo nel profilo
# così valgono anche quando apri un agente a mano da un terminale nuovo.
if [ "$PROVA" = 0 ]; then
  PROF="$HOME/.posta_agenti.env"
  {
    echo "# generato da installa_agenti.sh — chiavi lette da CHIAVI_LOCALI.md, mai scritte qui in chiaro"
    echo "export OPENAI_BASE_URL=\"${OPENAI_BASE_URL:-}\""
    echo "export OPENAI_API_BASE=\"${OPENAI_API_BASE:-}\""
    echo "export OPENAI_API_KEY=\"${OPENAI_API_KEY:-}\""
    echo "export OPENAI_MODEL=\"${OPENAI_MODEL:-auto}\""
    echo "export GOOSE_PROVIDER=\"${GOOSE_PROVIDER:-openai}\""
    echo "export GOOSE_MODEL=\"${OPENAI_MODEL:-auto}\""
  } > "$PROF" 2>/dev/null
  chmod 600 "$PROF" 2>/dev/null
  # lo collego al .bashrc una volta sola
  if [ -f "$PROF" ] && ! grep -q "posta_agenti.env" "$HOME/.bashrc" 2>/dev/null; then
    printf '\n# cervello comune degli agenti (OmniRoute)\n[ -f "$HOME/.posta_agenti.env" ] && . "$HOME/.posta_agenti.env"\n' >> "$HOME/.bashrc" 2>/dev/null
  fi
  ok "configurazione scritta in ~/.posta_agenti.env (chiavi in chiaro? no: rimanda a OmniRoute)"
fi

echo ""
bash "$QUI/agenti_stato.sh"
echo ""
echo "  Per aprirli: [1] nella Centrale, oppure la scheda 🤖 Agenti dell'interfaccia."
echo "══════════════════════════════════════════════════════════"
