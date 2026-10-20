#!/usr/bin/env bash
# verifica.sh — CONTROLLO SALUTE RAPIDO (sola lettura, ~2 secondi)
# Non installa niente e non tocca i tuoi file (al massimo rimette a 600 il portachiavi):
# guarda lo stato e dice verde/rosso. Serve per accorgersi
# subito di una rottura, senza rifare l'aggiornamento.
set -u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
V22BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
export PATH="$V22BIN:$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$PATH"

ROSSI=0; GIALLI=0; T0=$(date +%s)
ok(){   printf "  \033[32m✓\033[0m %-26s %s\n" "$1" "$2"; }
giu(){  printf "  \033[31m✗\033[0m %-26s %s\n" "$1" "$2"; ROSSI=$((ROSSI+1)); }
att(){  printf "  \033[33m·\033[0m %-26s %s\n" "$1" "$2"; GIALLI=$((GIALLI+1)); }
c_e(){  command -v "$1" >/dev/null 2>&1 && return 0
        local c; for c in "$HOME/.nvm/versions/node/"*/bin/"$1" "$HOME/.local/bin/$1" \
          "$HOME/.opencode/bin/$1" "$HOME/.hermes/hermes-agent/bin/$1" \
          "$HOME/.hermes/hermes-agent/venv/bin/$1" "$HOME/bin/$1"; do [ -x "$c" ] && return 0; done; return 1; }
ver(){  ( command -v "$1" >/dev/null 2>&1 && "$1" --version 2>&1 | head -1 ) \
        || ( ls "$HOME/.nvm/versions/node/"*/bin/"$1" 2>/dev/null | head -1 | xargs -r -I{} sh -c '{} --version 2>&1 | head -1' ) \
        || echo "?"; }
porta(){ (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3<&-; echo up; } || echo down; }

echo "══════════════════════════════════════════════════════════"
echo " 🩺 SALUTE DI FILIPPOPC — $(date '+%d/%m/%Y %H:%M')  (sola lettura)"
echo "══════════════════════════════════════════════════════════"

# ── 1 · PONTE
if [ -d "$HOME/posta/.git" ]; then
  cd "$HOME/posta" || exit 1
  H=$(git rev-parse --short HEAD 2>/dev/null || echo "?")
  D=$(git status --porcelain 2>/dev/null | wc -l)
  if [ "$D" -eq 0 ]; then ok "Ponte GitHub" "$H · pulito"; else att "Ponte GitHub" "$H · $D file modificati"; fi
else
  giu "Ponte GitHub" "~/posta non è un repo git"
fi

# ── 2 · SKILL
if [ -d "$HOME/.agents/skills" ]; then
  N=$(ls -1 "$HOME/.agents/skills" 2>/dev/null | wc -l)
  if [ "$N" -ge 26 ]; then ok "Skill" "$N attive (~/.agents/skills)"; else att "Skill" "solo $N: rifai FORZA=1 ./aggiorna_tutto.sh"; fi
else
  giu "Skill" "cartella ~/.agents/skills assente"
fi

# ── 3 · AGENTI
A_ok=""
for a in opencode goose interpreter hermes gemini; do
  if c_e "$a"; then A_ok="$A_ok $a"; else giu "Agente: $a" "NON trovato"; fi
done
[ -n "$A_ok" ] && ok "Agenti presenti" "$A_ok"
# openclaw merita un rigo suo (può stare in Ubuntu, con Bun, o su Windows)
QUI=$(cd "$(dirname "$0")" && pwd)
OC_TIPO=$(bash "$QUI/apri_openclaw.sh" --stato 2>/dev/null); OC_TIPO=${OC_TIPO:-no}
case "$OC_TIPO" in
  wsl)         ok   "OpenClaw (Ubuntu)"  "$(ver openclaw)" ;;
  bun)         ok   "OpenClaw (Bun)"     "$("$HOME/.bun/bin/openclaw" --version 2>&1 | head -1)" ;;
  windows-exe) ok   "OpenClaw (Windows)" "installato · si apre con [1]→[e]" ;;
  windows-app) att  "OpenClaw (Windows)" "c'è l'app grafica: aprila dal menu Start di Windows" ;;
  *)           giu  "OpenClaw"           "manca · doppio clic su INSTALLA_OPENCLAW.bat (o ./openclaw_fix.sh)" ;;
esac

# ── 4 · NODE (il problema WSL1)
DEF=$(ls -d "$HOME/.nvm/versions/node/"* 2>/dev/null | sort -V | tail -1 | xargs -r basename)
N22=$(ls -d "$HOME/.nvm/versions/node/v22"* 2>/dev/null | sort -V | tail -1 | xargs -r basename)
N24=$(ls -d "$HOME/.nvm/versions/node/v2"[4-9]* 2>/dev/null | sort -V | tail -1 | xargs -r basename)
[ -n "$N22" ] && ok "Node v22 (Hub/Omni)" "$N22 · è quello che fa girare hub e agenti" \
              || giu "Node v22 (Hub/Omni)" "assente: rifai ./aggiorna_tutto.sh"

# Node di WINDOWS: è quello del Free LLM Hub (AVVIA_HUB.bat). OpenClaw su Windows usa il suo.
WR="${WINROOT:-/mnt/c}"
WINNODE=$(ls "$WR/Program Files/nodejs/node.exe" 2>/dev/null | head -1)
[ -z "$WINNODE" ] && WINNODE=$(ls "$WR/Program Files (x86)/nodejs/node.exe" 2>/dev/null | head -1)
if [ -n "$WINNODE" ]; then
  WV=$(timeout 3 "$WINNODE" -v 2>/dev/null | tr -d '\r')
  if [ -n "$WV" ]; then ok "Node Windows (Hub)" "$WV · serve al Free LLM Hub, si lascia stare"
  else att "Node Windows (Hub)" "trovato ma non risponde"; fi
fi
if [ -n "$N24" ]; then
  V24BIN=$(ls "$HOME/.nvm/versions/node/$N24/bin/node" 2>/dev/null)
  if "$V24BIN" -v >/dev/null 2>&1; then ok "Node $N24" "$("$V24BIN" -v) · gira"
  else att "Node $N24" "installato ma NON eseguibile su WSL1 (bug noto node#63735: usa Windows o Bun)"; fi
fi

# ── 5 · MOTORI E PORTE
[ "$(porta 20128)" = "up" ] && ok "OmniRoute (:20128)" "🟢 acceso" || att "OmniRoute (:20128)" "spento (si accende col [9])"
[ "$(porta 20200)" = "up" ] && ok "GUI Centrale (:20200)" "🟢 aperta" || att "GUI Centrale (:20200)" "chiusa (si apre col [g])"
[ "$(porta 9222)"  = "up" ] && ok "Browser agenti (:9222)" "🟢 acceso" || att "Browser agenti (:9222)" "spento (serve per il check-in)"

# ── 6 · CHECK-IN AGENTROUTER
D=$(date +%F); HH=$((10#$(date +%H%M)))
if [ -f "$HOME/.ar_checkin_$D" ]; then ok "Bonus AgentRouter" "fatto oggi alle $(cat "$HOME/.ar_checkin_$D" 2>/dev/null)"
elif [ "$HH" -ge 1805 ]; then att "Bonus AgentRouter" "finestra aperta e non ancora riscosso"
else att "Bonus AgentRouter" "si riscatta dalle 18:05 (ora $(date +%H:%M))"; fi
[ -f "$HOME/.ar_login_manuale" ] && giu "Login AgentRouter" "serve un login a mano: $(cat "$HOME/.ar_login_manuale" 2>/dev/null | cut -c1-60)"
T=$(cat "$HOME/.ar_checkin_try_$D" 2>/dev/null | tr -cd "0-9"); T=${T:-0}
[ "$T" -ge 3 ] && att "Tentativi oggi" "$T/3 (fermo fino a domani)"

# ── 7 · SICUREZZA E SPAZIO
if [ -f "$HOME/CHIAVI_LOCALI.md" ]; then
  P=$(stat -c '%a' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null)
  [ "$P" = "600" ] && ok "Portachiavi" "chmod 600" || { chmod 600 "$HOME/CHIAVI_LOCALI.md" 2>/dev/null; att "Portachiavi" "permessi erano $P → messi a 600"; }
fi
SP=$(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $4}')
ok "Spazio libero" "${SP:-?}"

# ── VERDETTO
T1=$(date +%s); DT=$((T1-T0))
echo "──────────────────────────────────────────────────────────"
if [ "$ROSSI" -eq 0 ] && [ "$GIALLI" -eq 0 ]; then
  echo " 🟢 TUTTO A POSTO ($DT s)"
elif [ "$ROSSI" -eq 0 ]; then
  echo " 🟡 $GIALLI cose da guardare, niente di rotto ($DT s)"
else
  echo " 🔴 $ROSSI PROBLEMI da sistemare · $GIALLI avvisi ($DT s)"
fi
echo "══════════════════════════════════════════════════════════"
[ "$ROSSI" -gt 0 ] && exit 1 || exit 0
