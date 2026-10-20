#!/usr/bin/env bash
# aggiorna_tutto.sh — v2 (20/10/2026) · "SOLO LE NOVITÀ"
# ─────────────────────────────────────────────────────────────────────────────
# Prima: ogni [8] rifaceva TUTTO (skill, npm -g, OpenClaw con Node 24, ecc.) = minuti buttati.
# Adesso: ogni passo ha un TIMBRO in ~/.stato_aggiorna/. Se è già fatto → lo salta in un attimo.
#   · si rifà da solo se qualcosa è cambiato (es. skills_pack.tar.gz nuovo → reinstalla le skill)
#   · FORZA=1  → rifà tutto per davvero (riparazione completa)
#   · DRY=1    → mostra cosa farebbe, senza toccare niente
# Passo 1 (sincronizza il ponte) gira SEMPRE: è quello che porta le novità.
set -u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
V22BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
export PATH="$V22BIN:$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH"

FORZA="${FORZA:-0}"; DRY="${DRY:-0}"
ST="$HOME/.stato_aggiorna"; mkdir -p "$ST"
SALTATI=0; FATTI=0; DAFARE=0; NOVITA=""

ok()   { echo "  ✓ $*"; FATTI=$((FATTI+1)); NOVITA="$NOVITA\n  ✓ $*"; }
salto(){ echo "  · $* (già a posto, salto)"; SALTATI=$((SALTATI+1)); }
nota() { echo "  · $*"; }

# timbro <chiave> <impronta>: 0 = da fare, 1 = già fatto con la stessa impronta
timbro(){
  local k="$1" imp="${2:-statico}"
  [ "$FORZA" = "1" ] && return 0
  [ -f "$ST/$k" ] && [ "$(cat "$ST/$k" 2>/dev/null)" = "$imp" ] && return 1
  return 0
}
marca(){ printf '%s' "${2:-statico}" > "$ST/$1" 2>/dev/null || true; }
esegui(){ if [ "$DRY" = "1" ]; then nota "[DRY] eseguirei: $*"; DAFARE=$((DAFARE+1)); return 0; fi; "$@"; }

echo "=========================================================="
echo " 🚀 AGGIORNAMENTO FILIPPOPC — solo le novità ($(date '+%d/%m %H:%M'))"
[ "$FORZA" = "1" ] && echo "    ⚠ FORZA=1: rifaccio tutto"
[ "$DRY" = "1" ]   && echo "    ⚠ DRY=1: non tocco niente, solo simulazione"
echo "=========================================================="

# ── 1 · PONTE (sempre: è quello che porta le novità) ────────────────────────────
echo ""
echo "── 1/6 · Sincronizzo il ponte ~/posta..."
if [ -d "$HOME/posta/.git" ]; then
  cd "$HOME/posta" || exit 1
  TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
  [ -z "$TOKEN" ] && [ -f "$HOME/CHIAVI_LOCALI.md" ] && TOKEN="$(grep -oE 'ghp_[A-Za-z0-9]{30,}' "$HOME/CHIAVI_LOCALI.md" | head -1)"
  LOGIN=""; [ -s "$HOME/.posta_login" ] && LOGIN="$(tr -d '\r\n' < "$HOME/.posta_login")"
  [ -z "$LOGIN" ] && [ -s "$HOME/posta/.padrone" ] && LOGIN="$(tr -d '\r\n' < "$HOME/posta/.padrone")"
  PRIMA="$(git rev-parse --short HEAD 2>/dev/null || echo '?')"
  if [ "$DRY" != "1" ]; then
    if [ -n "$TOKEN" ] && [ -n "$LOGIN" ]; then
      git fetch -q origin main && git reset -q --hard origin/main || true
    else
      git pull -q || true
    fi
  fi
  DOPO="$(git rev-parse --short HEAD 2>/dev/null || echo '?')"
  [ "$PRIMA" = "$DOPO" ] && echo "  ✓ ponte già aggiornato ($DOPO)" || ok "ponte aggiornato: $PRIMA → $DOPO"
  chmod +x "$HOME/posta/postino.sh" "$HOME/posta/squadra.sh" "$HOME/posta/centrale.sh" 2>/dev/null || true
else
  nota "~/posta non è un repo git: salto la sincronizzazione"
fi

# ── 2 · SKILL (solo se il pacchetto è cambiato) ────────────────────────────────
echo ""
echo "── 2/6 · Skill (26 pacchetti A+B+C+D)..."
PACK="$HOME/posta/skills_pack.tar.gz"
if [ -f "$PACK" ]; then
  IMP="$(md5sum "$PACK" 2>/dev/null | cut -d' ' -f1)"
  N_SKILL=$(ls -1 "$HOME/.agents/skills" 2>/dev/null | wc -l)
  if timbro skills "$IMP"; then
    esegui tar -xzf "$PACK" -C "$HOME"
    esegui mkdir -p "$HOME/.claude/skills" "$HOME/.hermes/skills"
    esegui bash -c "cp -rf \"$HOME/.agents/skills/\"* \"$HOME/.claude/skills/\" 2>/dev/null || true"
    esegui bash -c "cp -rf \"$HOME/.agents/skills/\"* \"$HOME/.hermes/skills/\" 2>/dev/null || true"
    if [ "$DRY" = "1" ]; then
      nota "[DRY] installerei/aggiornerei le skill dal pacchetto nuovo"
    else
      date -Is > "$HOME/.skills_v2_installed"; marca skills "$IMP"
      ok "Skill installate/aggiornate ($(ls -1 "$HOME/.agents/skills" 2>/dev/null | wc -l) attive) — pacchetto nuovo"
    fi
  else
    salto "Skill: $N_SKILL attive · pacchetto identico a quello già installato"
  fi
else
  nota "skills_pack.tar.gz non trovato nel ponte"
fi

# ── 3 · STRUMENTI BROWSER/WEB (solo se mancano) ───────────────────────────────
echo ""
echo "── 3/6 · Strumenti Browser & Web (agent-browser + firecrawl-cli)..."
NPM22=$(ls "$HOME/.nvm/versions/node/v22"*/bin/npm 2>/dev/null | sort -V | tail -1)
[ -z "$NPM22" ] && command -v npm >/dev/null 2>&1 && NPM22=$(command -v npm)
if command -v agent-browser >/dev/null 2>&1 && command -v firecrawl-cli >/dev/null 2>&1; then
  salto "agent-browser $(agent-browser --version 2>&1 | head -1) + firecrawl-cli già presenti"
elif [ -n "$NPM22" ]; then
  esegui "$NPM22" i -g agent-browser firecrawl-cli >/dev/null 2>&1 \
    && { marca browser_tools; ok "agent-browser + firecrawl-cli installati"; } \
    || nota "npm install parziale (non blocca nulla)"
else
  nota "npm non trovato: salto"
fi

# default nvm SEMPRE su v22 (su WSL1 il 24 non parte) — costa un istante
V22DIR=$(ls -d "$HOME/.nvm/versions/node/v22"* 2>/dev/null | sort -V | tail -1)
if [ -n "$V22DIR" ] && [ -s "$NVM_DIR/nvm.sh" ] && [ "$DRY" != "1" ]; then
  . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 && nvm alias default "$(basename "$V22DIR")" >/dev/null 2>&1 || true
fi

# ── 4 · SECONDHAND ────────────────────────────────────────────────────────────
echo ""
echo "── 4/6 · Secondhand (OpenInterpreter Rust)..."
if command -v interpreter >/dev/null 2>&1; then
  salto "Secondhand $(interpreter --version 2>&1 | head -1)"
else
  esegui bash -c "OPEN_INTERPRETER_NONINTERACTIVE=1 curl -fsSL https://www.openinterpreter.com/install | OPEN_INTERPRETER_NONINTERACTIVE=1 sh >/dev/null 2>&1 || true"
  export PATH="$HOME/.local/bin:$PATH"
  command -v interpreter >/dev/null 2>&1 && ok "Secondhand installato" || nota "Secondhand: non compatibile WSL1 (salto)"
fi

# ── 5 · HERMES ────────────────────────────────────────────────────────────────
echo ""
echo "── 5/6 · Hermes Agent (NousResearch)..."
if command -v hermes >/dev/null 2>&1 || [ -x "$HOME/.hermes/hermes-agent/venv/bin/hermes" ]; then
  salto "Hermes già installato"
else
  esegui bash -c "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive --skip-browser --skip-computer-use >/dev/null 2>&1 || true"
  { command -v hermes >/dev/null 2>&1 || [ -d "$HOME/.hermes/hermes-agent" ]; } && ok "Hermes installato" || nota "Hermes: installazione saltata"
fi

# ── 6 · OPENCLAW (richiede Node ≥24: su WSL1 non parte → un tentativo ogni 7 giorni) ──
echo ""
echo "── 6/6 · OpenClaw..."
if command -v openclaw >/dev/null 2>&1; then
  salto "OpenClaw $(openclaw --version 2>&1 | head -1)"
else
  ULTIMO="$ST/openclaw_ultimo_tentativo"
  TENTA=1
  if [ -f "$ULTIMO" ] && [ "$FORZA" != "1" ]; then
    T0=$(date -r "$ULTIMO" +%s 2>/dev/null || echo 0)
    G=$(( ( $(date +%s) - T0 ) / 86400 ))
    [ "$G" -lt 7 ] && TENTA=0
  fi
  if [ "$TENTA" = "0" ]; then
    salto "OpenClaw: tentato $G giorni fa, riprovo tra $((7-G)) giorni (serve Node ≥24, non disponibile su WSL1)"
  elif [ "$DRY" = "1" ]; then
    nota "[DRY] tenterei l'installazione di OpenClaw"
  else
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh \
      | OPENCLAW_NO_ONBOARD=1 OPENCLAW_NO_PROMPT=1 bash -s -- --runtime node --no-onboard --no-prompt >/dev/null 2>&1 || true
    date -Is > "$ULTIMO"
    if command -v openclaw >/dev/null 2>&1; then
      ok "OpenClaw installato: $(openclaw --version 2>&1 | head -1)"
    else
      nota "OpenClaw: serve Node ≥24 (su WSL1 non parte) → prossimo tentativo tra 7 giorni"
    fi
  fi
fi

# ── Extra: innesti Scaglione 1 + skill di marketing (con timbro) ──────────────
if [ -f "$HOME/posta/da_me/scaglione1_applica_innesti.sh" ] && [ ! -f "$HOME/.scaglione1_innesti_done" ] && [ "$DRY" != "1" ]; then
  bash "$HOME/posta/da_me/scaglione1_applica_innesti.sh" && touch "$HOME/.scaglione1_innesti_done" && ok "Innesti Scaglione 1 applicati"
fi
if [ ! -d "$HOME/.agents/skills/taste-skill" ] && [ "$DRY" != "1" ]; then
  git clone --depth 1 -q https://github.com/leonxlnx/taste-skill.git /tmp/ts_sk 2>/dev/null \
    && cp -r /tmp/ts_sk "$HOME/.agents/skills/taste-skill" && rm -rf /tmp/ts_sk && ok "Skill taste-skill aggiunta"
fi
if [ ! -d "$HOME/.agents/skills/marketingskills" ] && [ "$DRY" != "1" ]; then
  git clone --depth 1 -q https://github.com/coreyhaines31/marketingskills.git /tmp/mk_sk 2>/dev/null \
    && cp -r /tmp/mk_sk "$HOME/.agents/skills/marketingskills" && rm -rf /tmp/mk_sk && ok "Skill marketingskills aggiunta"
fi

# ── Desktop: un'unica icona (istantaneo) ─────────────────────────────────────
for d in /mnt/c/Users/*/Desktop /mnt/c/Users/*/OneDrive*/Desktop; do
  if [ -d "$d" ]; then
    cp -f "$HOME/posta/CENTRALE_AGENTI.bat" "$d/CENTRALE_AGENTI.bat" 2>/dev/null || true
    cp -f "$HOME/posta/8_CENTRALE_GUI.bat" "$d/CENTRALE_GUI.bat" 2>/dev/null || true
    rm -f "$d/BROWSER_AGENTI.bat" "$d/SQUADRA_FUSION.bat" "$d/APRI_AGENTE.lnk" "$d/AVVIA_POSTINO.lnk" "$d/COMPITI.lnk" "$d/AGGIORNA_TUTTO_PC.bat" 2>/dev/null || true
  fi
done
chmod +x "$HOME/posta/centrale.sh" "$HOME/posta/leggi_video.py" "$HOME/posta/squadra.sh" "$HOME/posta/postino.sh" 2>/dev/null || true

# ── Rapporto sul ponte (solo se c'è qualcosa di nuovo) ──────────────────────
mkdir -p "$HOME/posta/fatti" "$HOME/posta/dal_pc" 2>/dev/null || true
if [ "$FATTI" -gt 0 ] && [ "$DRY" != "1" ]; then
  {
    echo "# ✅ Aggiornamento FilippoPC — $(date '+%d/%m/%Y %H:%M')"
    echo ""
    echo "## Novità applicate in questo giro ($FATTI)"
    printf '%b\n' "$NOVITA"
    echo ""
    echo "## Saltati perché già a posto: $SALTATI"
    echo ""
    echo "- Skill: $(ls -1 "$HOME/.agents/skills" 2>/dev/null | wc -l)"
    echo "- OpenCode: $(opencode --version 2>&1 | head -1)"
    echo "- Goose: $(goose --version 2>&1 | head -1)"
    echo "- Secondhand: $(interpreter --version 2>&1 | head -1 || echo non presente)"
    echo "- Hermes: $(command -v hermes >/dev/null 2>&1 && hermes --version 2>&1 | head -1 || echo 'presente ma fuori PATH')"
    echo "- OpenClaw: $(command -v openclaw >/dev/null 2>&1 && openclaw --version 2>&1 | head -1 || echo 'non installato (Node 24 su WSL1)')"
  } > "$HOME/posta/dal_pc/stato_aggiornamento.md"
  cd "$HOME/posta" || exit 0
  git add -A >/dev/null 2>&1 || true
  git diff --cached --quiet || git commit -qm "aggiornamento $(date '+%d/%m %H:%M') · $FATTI novità" >/dev/null 2>&1 || true
  [ -n "${TOKEN:-}" ] && [ -n "${LOGIN:-}" ] && git push -q "https://x-access-token:$TOKEN@github.com/$LOGIN/posta.git" HEAD:main >/dev/null 2>&1 || true
fi

# ── Riavvio del postino (istantaneo) ─────────────────────────────────────────
if [ "$DRY" != "1" ]; then
  pkill -f 'postino.sh' 2>/dev/null || true
  sleep 0.3
  nohup "$HOME/posta/postino.sh" --loop >/dev/null 2>&1 &
fi

echo ""
echo "=========================================================="
if [ "$DRY" = "1" ]; then
  echo " 🔎 SIMULAZIONE: avrei fatto $DAFARE passi · $SALTATI già a posto"
elif [ "$FATTI" -eq 0 ]; then
  echo " ✅ NIENTE DA FARE: tutto già a posto ($SALTATI controlli saltati in un lampo)"
else
  echo " 🎉 FATTO: $FATTI novità applicate · $SALTATI passi saltati (erano già a posto)"
fi
echo " Per rifare tutto da zero:  FORZA=1 bash ~/posta/aggiorna_tutto.sh"
echo "=========================================================="
