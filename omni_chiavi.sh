#!/usr/bin/env bash
# omni_chiavi.sh — innesta le NOSTRE chiavi API nei provider "free" di OmniRoute + rapporto sul ponte
set -u
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
V22BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
[ -n "$V22BIN" ] && export PATH="$V22BIN:$PATH"
# OmniRoute, quando parte, apre la sua Dashboard nel browser (2 avvii = 2 schede).
# Gli metto davanti un "apri browser" finto: la scheda la apre la GUI solo se la chiedi tu.
ND=/tmp/omni_senza_schede; mkdir -p "$ND"
for n in xdg-open wslview sensible-browser open; do
  [ -x "$ND/$n" ] || { printf '#!/bin/sh\nexit 0\n' > "$ND/$n"; chmod +x "$ND/$n"; }
done
export PATH="$ND:$PATH"
OMNI=$(command -v omniroute || echo "$V22BIN/omniroute")
[ -x "$OMNI" ] || { echo "  ❌ omniroute non trovato"; exit 0; }
K="$HOME/CHIAVI_LOCALI.md"
[ -f "$K" ] || { echo "  ❌ ~/CHIAVI_LOCALI.md non trovato"; exit 0; }

# il database si scrive SOLO a motore spento (lezione "locking protocol")
echo "== Spengo il motore per sbloccare il database (lo riaccendo io alla fine)..."
pkill -x omniroute 2>/dev/null; pkill -f "bin/omniroute" 2>/dev/null; sleep 4

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
  echo "## Test di tutte le connessioni (a motore spento)"
  TESTOUT=$(timeout 180 "$OMNI" providers test-all </dev/null 2>&1 | noansi)
  echo "$TESTOUT" | head -40
  TOTL=$(timeout 60 "$OMNI" providers list </dev/null 2>&1 | noansi | grep -ciE "kiro|opencode|pollinations|longcat|cloudflare|qwen|qoder|ddg|duck|felo|groq|gemini|mistral|cohere|openrouter|nvidia|agentrouter" || true)
  OKL=$(echo "$TESTOUT" | grep -ciE "✓|success|passed|\bok\b" || true)
  NST=$(echo "$TESTOUT" | grep -ciE "not supported" || true)
  echo
  echo "## 📊 LINEE: $OKL/$TOTL superano il test ($NST non testabili dal CLI, non per forza rotte)"
  echo
  echo "## Riaccensione motore + domanda di prova"
  nohup "$OMNI" >/tmp/omniroute.log 2>&1 &
  sleep 15
  OKEY=$(grep -E '^omniroute ' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | grep -oE 'sk-[A-Za-z0-9-]+' | head -1)
  if [ -n "$OKEY" ]; then
    curl -s --max-time 90 http://localhost:20128/v1/chat/completions -H "Authorization: Bearer $OKEY" -H "Content-Type: application/json" -d '{"model":"auto","messages":[{"role":"user","content":"Rispondi solo con la parola: OK"}],"max_tokens":20}' | head -c 1200
    echo
    MJ=$(curl -s --max-time 20 http://localhost:20128/v1/models -H "Authorization: Bearer $OKEY" 2>/dev/null)
    NM=$(echo "$MJ" | grep -o '"id"' | wc -l)
    NL=$(echo "$MJ" | grep -oE '"owned_by":"[^"]*"' | sort -u | wc -l)
    echo "## 📊 A MOTORE ACCESO: $NM modelli usabili su $NL linee vive"
    echo
  fi
} > "$R" 2>&1

echo "== Spedisco il rapporto sul ponte..."
cd "$HOME/posta" || exit 0
git add -A >/dev/null 2>&1; git commit -qm "rapporto innesto chiavi omniroute" >/dev/null 2>&1 || true
TOK=$(grep -oE 'ghp_[A-Za-z0-9]+' "$K" 2>/dev/null | head -1)
git push -q origin main >/dev/null 2>&1 || { [ -n "$TOK" ] && git push -q "https://x-access-token:$TOK@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; } || true
echo "✅ FATTO! Chiavi innestate dove trovate. Rapporto sul ponte."
