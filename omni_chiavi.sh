#!/usr/bin/env bash
# omni_chiavi.sh — innesta le NOSTRE chiavi API nei provider "free" di OmniRoute + rapporto sul ponte
set -u
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
V22BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
[ -n "$V22BIN" ] && export PATH="$V22BIN:$PATH"
OMNI=$(command -v omniroute || echo "$V22BIN/omniroute")
[ -x "$OMNI" ] || { echo "  ❌ omniroute non trovato"; exit 0; }
K="$HOME/CHIAVI_LOCALI.md"
[ -f "$K" ] || { echo "  ❌ ~/CHIAVI_LOCALI.md non trovato"; exit 0; }

# il comando 'providers add' passa dal server attivo: accendi il motore se spento
if ! pgrep -f omniroute >/dev/null 2>&1; then
  echo "== Accendo il motore..."
  nohup "$OMNI" >/tmp/omniroute.log 2>&1 &
  sleep 12
fi

D="$HOME/posta/dal_pc"; mkdir -p "$D"
R="$D/omni_chiavi_report.md"
noansi(){ sed -e 's/\x1b\[[0-9;]*[A-Za-z]//g'; }

# cerca_chiave <etichetta-riga> <pattern-chiave>
cerca(){ grep -iE "$1" "$K" 2>/dev/null | grep -oE "$2" | head -1; }

{
  echo "# 🔑 Rapporto innesto chiavi in OmniRoute — $(date '+%d/%m/%Y %H:%M')"
  echo
  # provider_id | riga da cercare | pattern chiave
  while IFS=';' read -r PID RIGA PAT; do
    [ -z "$PID" ] && continue
    KEY=$(cerca "$RIGA" "$PAT")
    if [ -z "$KEY" ]; then echo "- $PID: · nessuna chiave nel portachiavi (salto)"; continue; fi
    if timeout 60 "$OMNI" providers list </dev/null 2>&1 | noansi | grep -qiE "[[:space:]]$PID[[:space:]]"; then
      ROT=$(timeout 90 "$OMNI" providers rotate "$PID" --api-key "$KEY" </dev/null 2>&1 | noansi | tail -2 | tr '\n' ' ')
      if echo "$ROT" | grep -qiE "success|rotat|updated|saved"; then echo "- $PID: 🔄 chiave aggiornata ($ROT)"; continue; fi
      printf 'y\n' | timeout 60 "$OMNI" providers remove "$PID" >/dev/null 2>&1 || true
    fi
    OUT=$(timeout 90 "$OMNI" providers add "$PID" --api-key "$KEY" </dev/null 2>&1 | noansi | tail -2 | tr '\n' ' ')
    if echo "$OUT" | grep -qiE "success|added|saved|creat|configur"; then
      echo "- $PID: ✅ INNESTATO ($OUT)"
    else
      OUT2=$(timeout 90 "$OMNI" setup --non-interactive --add-provider --provider "$PID" --api-key "$KEY" </dev/null 2>&1 | noansi | tail -2 | tr '\n' ' ')
      echo "- $PID: ① ${OUT:-nulla} ② ${OUT2:-nulla}"
    fi
  done << 'MAPPA'
groq;groq;gsk_[A-Za-z0-9_-]+
gemini;gemini|google ai;AQ\.[A-Za-z0-9_-]+
mistral;mistral;mstrl_[A-Za-z0-9_-]+
cohere;cohere;[A-Za-z0-9]{40}
openrouter;openrouter;sk-or-[A-Za-z0-9_-]+
nvidia;nvidia;nvapi-[A-Za-z0-9_-]+
agentrouter;^agentrouter ;sk-[A-Za-z0-9]{30,}
MAPPA
  echo
  echo "## Connessioni configurate adesso"
  timeout 60 "$OMNI" providers list </dev/null 2>&1 | noansi | head -40
  echo
  echo "## Test di tutte le connessioni"
  timeout 180 "$OMNI" providers test-all </dev/null 2>&1 | noansi | head -40
} > "$R" 2>&1

echo "== Spedisco il rapporto sul ponte..."
cd "$HOME/posta" || exit 0
git add -A >/dev/null 2>&1; git commit -qm "rapporto innesto chiavi omniroute" >/dev/null 2>&1 || true
TOK=$(grep -oE 'ghp_[A-Za-z0-9]+' "$K" 2>/dev/null | head -1)
git push -q origin main >/dev/null 2>&1 || { [ -n "$TOK" ] && git push -q "https://x-access-token:$TOK@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; } || true
echo "✅ FATTO! Chiavi innestate dove trovate. Rapporto sul ponte."
