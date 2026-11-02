#!/usr/bin/env bash
# setup_tavily.sh — collega Tavily agli agenti del PC.
#
# Cosa fa (seguendo tavily.com/agent-setup/SKILL.md):
#   1. cerca nel portachiavi le chiavi tavily-dev, le prova e tiene la prima che
#      risponde davvero (il probe stampa codice HTTP e corpo, cosi' si capisce)
#   2. se nessuna risponde passa in modalita' SENZA chiave: Tavily search ed
#      extract funzionano lo stesso (gratuiti, solo limitati)
#   3. installa la CLI tvly, autentica e installa le skill globali per Claude Code
#   4. copia le skill anche nella cartella delle skill di OpenCode
#   5. verifica: tvly auth --json + una ricerca vera
#
# NESSUNA CHIAVE IN QUESTO FILE: si legge dal portachiavi del PC.
set -u
LOG=/tmp/setup_tavily.log
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
export PATH="$HOME/.local/bin:$PATH"

V="$HOME/CHIAVI_LOCALI.md"
if [ ! -f "$V" ]; then
  say "portachiavi non trovato: $V"
  exit 1
fi
say "portachiavi: $V ($(wc -l < "$V") righe)"

# 1) le chiavi: una prova per ciascuna, con codice e corpo
GOOD=""
for K in $(grep -oE "tvly-dev-[A-Za-z0-9_-]{20,}" "$V" | sort -u); do
  R=$(curl -s --max-time 25 -w "\n__CODE__%{http_code}" -X POST https://api.tavily.com/v1/search \
      -H "Authorization: Bearer $K" -H "Content-Type: application/json" \
      -d '{"query":"probe","max_results":1}' 2>/dev/null)
  CODE=$(printf '%s' "$R" | sed -n 's/.*__CODE__//p')
  CORPO=$(printf '%s' "$R" | sed 's/__CODE__.*//' | head -c 180 | tr '\n' ' ')
  say "chiave ${K:0:12}... -> HTTP ${CODE:-000} | ${CORPO}"
  case "$R" in
    *'"results"'*|*'"answer"'*|*'"query"'*) GOOD="$K"; say "chiave tavily valida (${#K} caratteri)"; break ;;
  esac
done
KEYLESS=0
if [ -z "$GOOD" ]; then
  say "nessuna chiave risponde: passo alla modalita' SENZA chiave (search ed extract gratis, limitati)"
  KEYLESS=1
fi
say "raggiungibilita api.tavily.com: $(curl -s -o /dev/null -w '%{http_code}' --max-time 15 -X POST https://api.tavily.com/v1/search -H 'Content-Type: application/json' -d '{"query":"probe","max_results":1}' 2>/dev/null)"

# 2) CLI
if ! command -v tvly >/dev/null 2>&1; then
  say "installo la CLI tvly"
  curl -fsSL https://cli.tavily.com/install.sh | bash >/dev/null 2>&1
  export PATH="$HOME/.local/bin:$PATH"
fi
say "tvly: $(command -v tvly || echo mancante) $(tvly --version 2>/dev/null | head -1)"

# 3) autenticazione + skill per Claude Code
say "autentico e installo le skill"
if [ "$KEYLESS" = "1" ]; then
  tvly init --skip-auth --agent claude-code --yes >/tmp/tvly_init.log 2>&1 \
    || npx -y skills add tavily-ai/skills --skill '*' --agent claude-code --global --yes >>/tmp/tvly_init.log 2>&1
else
  tvly init --api-key "$GOOD" --agent claude-code --yes >/tmp/tvly_init.log 2>&1 \
    || npx -y skills add tavily-ai/skills --skill '*' --agent claude-code --global --yes >>/tmp/tvly_init.log 2>&1
fi

# 4) le skill anche per OpenCode
if [ -d "$HOME/.claude/skills" ] && [ -d "$HOME/.config/opencode/skills" ]; then
  for S in "$HOME"/.claude/skills/tavily-*; do
    [ -d "$S" ] || continue
    N=$(basename "$S")
    rm -rf "$HOME/.config/opencode/skills/$N"
    cp -r "$S" "$HOME/.config/opencode/skills/$N" && say "skill copiata per OpenCode: $N"
  done
fi

# 5) verifica
say "verifica auth: $(tvly auth --json 2>/dev/null | head -1)"
if tvly search "Tavily Search API" --json >/tmp/tvly_search.json 2>/dev/null \
   && grep -q '"results"' /tmp/tvly_search.json; then
  say "RICERCA VERA OK"
else
  say "la ricerca non ha risposto: guardo /tmp/tvly_search.json"
  head -c 300 /tmp/tvly_search.json 2>/dev/null
  echo
fi
ls "$HOME/.claude/skills" 2>/dev/null | grep -i tavily | sed 's/^/  skill claude: /'
ls "$HOME/.config/opencode/skills" 2>/dev/null | grep -i tavily | sed 's/^/  skill opencode: /'
say "tavily pronto (modalita' $( [ "$KEYLESS" = "1" ] && echo senza-chiave || echo con-chiave ))"
exit 0
