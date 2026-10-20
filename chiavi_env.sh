#!/usr/bin/env bash
# chiavi_env.sh — UN SOLO POSTO dove si prendono le chiavi dal portachiavi.
# Lo usano: centrale.sh, la GUI, installa_agenti.sh, aggiorna_tutto.sh, lo stato agenti.
# Regola: le chiavi NON si scrivono mai dentro i file del ponte, si leggono da ~/CHIAVI_LOCALI.md.
#         Questo file stampa solo comandi "export", non salva niente.
#
#   . ./chiavi_env.sh          (dentro un altro script: esporta tutto nel proprio ambiente)
#   ./chiavi_env.sh --elenco   (mostra QUALI chiavi sono state trovate, senza mostrarle)
set -u
KF="${CHIAVI_FILE:-$HOME/CHIAVI_LOCALI.md}"

t() { [ -f "$KF" ] || return 1; }

# estrae la prima chiave che corrisponde a un nome di provider + un formato
chiave_di(){  # $1 = nome/riga, $2 = regex della chiave
  t || return 1
  grep -iE "$1" "$KF" 2>/dev/null | grep -oE "$2" 2>/dev/null | head -1
}

# ── le chiavi che servono agli agenti ─────────────────────────────────────────
OC_KEY=$(chiave_di 'opencode' 'oc_sk_[A-Za-z0-9_-]+')                # OpenCode Zen
GQ_KEY=$(chiave_di 'groq' 'gsk_[A-Za-z0-9_-]+')                      # Groq
GM_KEY=$(chiave_di 'Google AI Studio' 'AQ\.[A-Za-z0-9_.-]{20,}')     # Google AI Studio (nuovo formato)
[ -z "${GM_KEY:-}" ] && GM_KEY=$(chiave_di 'Google AI Studio|gemini' 'AIza[A-Za-z0-9_-]{30,}')
OM_KEY=$(chiave_di '^[[:space:]]*[-*].*[Oo]mniroute|omniroute' 'sk-[A-Za-z0-9-]{16,}')  # OmniRoute (centralino locale)
AN_KEY=$(chiave_di 'agentrouter' 'sk-[A-Za-z0-9]{30,}')              # AgentRouter
AR_KEY="$AN_KEY"

# OmniRoute parla il formato OpenAI: se c'è, TUTTI gli agenti possono usarlo come cervello
OMNI_URL="http://127.0.0.1:20128/v1"
# Portiere (cervello.py, porta 20129): se è acceso, gli agenti parlano con lui.
# Lui passa la richiesta al motore e, se il motore è caduto, alle chiavi di riserva.
CERVELLO_URL="http://127.0.0.1:20129/v1"
if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
  exec 3<&- 2>/dev/null || true
  OPENAI_BASE_URL="$CERVELLO_URL"
else
  OPENAI_BASE_URL="$OMNI_URL"
fi

export OPENCODE_API_KEY="${OC_KEY:-}"
export GROQ_API_KEY="${GQ_KEY:-}"
# Gemini CLI avvisa se ci sono TUTTE E DUE: ne imposto una sola (GEMINI_API_KEY)
export GEMINI_API_KEY="${GM_KEY:-}"
unset GOOGLE_API_KEY 2>/dev/null || true
export AGENTROUTER_API_KEY="${AR_KEY:-}"

export OPENAI_BASE_URL
export OPENAI_API_BASE="$OPENAI_BASE_URL"
export OPENAI_API_KEY="${OM_KEY:-sk-omniroute}"
export OPENAI_MODEL="${OPENAI_MODEL:-auto}"
export OMNIROUTE_API_KEY="${OM_KEY:-sk-omniroute}"

# ---- Goose: stesso cervello di tutti, senza dover fare "goose configure" a mano ----
# Goose vuole HOST senza /v1 e il percorso a parte; la chiave la legge dall'ambiente.
export OPENAI_HOST="${OPENAI_HOST:-${OPENAI_BASE_URL%/v1}}"
export OPENAI_BASE_PATH="${OPENAI_BASE_PATH:-v1/chat/completions}"
export GOOSE_PROVIDER="${GOOSE_PROVIDER:-openai}"
export GOOSE_MODEL="${GOOSE_MODEL:-${OPENAI_MODEL:-auto}}"

if [ "${1:-}" = "--elenco" ]; then
  printf '  %-22s %s\n' "OpenCode Zen"   "$([ -n "${OC_KEY:-}" ] && echo '✓ trovata' || echo '— assente')"
  printf '  %-22s %s\n' "Groq"           "$([ -n "${GQ_KEY:-}" ] && echo '✓ trovata' || echo '— assente')"
  printf '  %-22s %s\n' "Google AI Studio" "$([ -n "${GM_KEY:-}" ] && echo '✓ trovata' || echo '— assente')"
  printf '  %-22s %s\n' "OmniRoute"      "$([ -n "${OM_KEY:-}" ] && echo '✓ trovata' || echo '— assente (il motore usa la sua)')"
  printf '  %-22s %s\n' "AgentRouter"    "$([ -n "${AR_KEY:-}" ] && echo '✓ trovata' || echo '— assente')"
  echo "  cervello di default per gli agenti: $OPENAI_BASE_URL  (modello: $OPENAI_MODEL)"
  echo "  riserva se il motore cade: portiere 20129 ($([ -f "$HOME/.posta_appello.json" ] && echo 'appello pronto' || echo 'appello non ancora fatto'))"
fi
