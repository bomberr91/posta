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
NVM22BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
export PATH="$NVM22BIN:$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$HOME/.hermes/hermes-agent/venv/bin:$HOME/bin:$PATH"
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

# Goose va puntato al MOTORE una volta sola (altrimenti chiede un login e non risponde)
if vuole goose && c_e goose; then
  GC="$HOME/.config/goose/config.yaml"
  mkdir -p "$(dirname "$GC")"
  if ! grep -q "127.0.0.1:20128" "$GC" 2>/dev/null; then
    if [ -f "$GC" ]; then cp "$GC" "$GC.prima_del_motore" 2>/dev/null || true; fi
    cat > "$GC" <<'YAML'
# scritto da installa_agenti.sh — Goose parla con OmniRoute (il cervello comune)
GOOSE_PROVIDER: openai
GOOSE_MODEL: auto
OPENAI_HOST: http://127.0.0.1:20128
OPENAI_BASE_PATH: v1/chat/completions
GOOSE_MODE: auto
GOOSE_TELEMETRY_ENABLED: false
YAML
    ok "Goose puntato al motore (config.yaml)"
  else
    ok "Goose già puntato al motore"
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
HERMES_INSTALL_FAILED=0
if vuole hermes; then
  if c_e hermes; then ok "Hermes già presente ($(hermes --version 2>&1 | head -1))"
  else
    d "Installo Hermes (NousResearch)… può metterci alcuni minuti"
    if [ "$PROVA" = "1" ]; then
      d "[prova] scaricherei lo script ufficiale Hermes e lo eseguirei con --non-interactive --skip-browser --skip-computer-use"
    else
      HERMES_SETUP_TMP=$(mktemp "${TMPDIR:-/tmp}/hermes-install.XXXXXX.sh") || HERMES_SETUP_TMP=""
      if [ -z "$HERMES_SETUP_TMP" ]; then
        ko "Hermes: non riesco a creare il file temporaneo per l'installer"
        HERMES_INSTALL_FAILED=1
      elif ! curl --fail --location --silent --show-error --retry 2 \
              --output "$HERMES_SETUP_TMP" https://hermes-agent.nousresearch.com/install.sh; then
        ko "Hermes: non riesco a scaricare l'installer ufficiale; controlla la connessione e riprova"
        HERMES_INSTALL_FAILED=1
        rm -f "$HERMES_SETUP_TMP"
      elif ! head -n 1 "$HERMES_SETUP_TMP" | grep -q '^#!/usr/bin/env bash'; then
        ko "Hermes: il server non ha restituito lo script atteso; non l'ho eseguito"
        HERMES_INSTALL_FAILED=1
        rm -f "$HERMES_SETUP_TMP"
      else
        # output visibile: nessun install fallito nascosto nel BAT
        bash "$HERMES_SETUP_TMP" --non-interactive --skip-browser --skip-computer-use --verbose
        HERMES_RC=$?
        rm -f "$HERMES_SETUP_TMP"
        export PATH="$HOME/.hermes/hermes-agent/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH"
        if [ "$HERMES_RC" -eq 0 ] && c_e hermes; then
          ok "Hermes installato ($(hermes --version 2>&1 | head -1))"
        else
          ko "Hermes: installer fermato (codice $HERMES_RC) o comando non trovato"
          HERMES_INSTALL_FAILED=1
          echo "  Log completo: $HOME/.hermes/logs/install.log"
          if [ -f "$HOME/.hermes/logs/install.log" ]; then
            echo "  Ultime righe del log:"
            tail -n 25 "$HOME/.hermes/logs/install.log" | sed 's/^/    /'
          fi
        fi
      fi
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
# Se richiesto un agente specifico, restituisco un errore vero quando non c'è:
# il suo .bat può così restare aperto e mostrare il fallimento, mai «successo» a vuoto.
if vuole hermes && [ -n "$SOLO" ] && [ "$PROVA" = 0 ]; then
  if [ "$HERMES_INSTALL_FAILED" = "1" ] || ! c_e hermes; then
    exit 1
  fi
fi
