#!/usr/bin/env bash
# squadra.sh — Lancia una SQUADRA FUSION da 3 Agenti in sincronia (parallelo) + Sintesi del Capo
set -u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$PATH"
if [ -f "$HOME/CHIAVI_LOCALI.md" ]; then
  OC_KEY=$(grep -oE 'oc_sk_[A-Za-z0-9_-]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
  [ -n "$OC_KEY" ] && export OPENCODE_API_KEY="$OC_KEY"
  GQ_KEY=$(grep -i "Groq" "$HOME/CHIAVI_LOCALI.md" | grep -oE 'gsk_[A-Za-z0-9_-]+' 2>/dev/null | head -1)
  [ -n "$GQ_KEY" ] && export GROQ_API_KEY="$GQ_KEY"
fi
pgrep -f 'magpie serve' >/dev/null 2>&1 || (nohup magpie serve >/dev/null 2>&1 & sleep 1)

TASK="${1:-}"
OUT_FILE="${2:-}"
if [ -z "$TASK" ]; then
  echo "=========================================================="
  echo "   SQUADRA FUSION — 3 AGENTI IN SINCRONIA SU FILIPPOPC"
  echo "=========================================================="
  read -r -p "Scrivi il compito per la squadra e premi INVIO: " TASK
  [ -z "$TASK" ] && exit 0
fi

STAMP="$(date '+%Y%m%d_%H%M%S')"
WORK="/tmp/squadra_$STAMP"
mkdir -p "$WORK" "$HOME/posta/dal_pc"
[ -z "$OUT_FILE" ] && OUT_FILE="$HOME/posta/dal_pc/squadra_$STAMP.md"

echo ""
echo "[1/2] Lancio i 3 Agenti in SINCRONIA (parallelo)..."
echo "  -> Agente 1 (Esploratore & Fatti)"
echo "  -> Agente 2 (Costruttore & Codice)"
echo "  -> Agente 3 (Critico & Alternative Costo Zero)"

# Agente 1: Esploratore (Goose o OpenCode modello 1)
(
  cd "$WORK"
  P1="RUOLO: Agente 1 (Esploratore Tecnico). Analizza questo compito concentrandoti su fatti verificabili, strumenti esistenti, link e dati concreti. Sii sintetico in italiano. COMPITO: $TASK"
  if command -v opencode >/dev/null 2>&1; then
    timeout 600 opencode run -m opencode/deepseek-v4.1-flash-free "$P1" > "$WORK/a1.md" 2>&1 \
      || timeout 600 opencode run -m opencode/big-pickle "$P1" > "$WORK/a1.md" 2>&1
  fi
) &
PID1=$!

# Agente 2: Costruttore (OpenCode modello 2)
(
  cd "$WORK"
  P2="RUOLO: Agente 2 (Architetto & Costruttore). Analizza questo compito concentrandoti su come realizzarlo in pratica passo-passo, comandi/codice pronti e architettura a costo zero. Sii sintetico in italiano. COMPITO: $TASK"
  if command -v opencode >/dev/null 2>&1; then
    timeout 600 opencode run -m opencode/big-pickle "$P2" > "$WORK/a2.md" 2>&1 \
      || timeout 600 opencode run "$P2" > "$WORK/a2.md" 2>&1
  fi
) &
PID2=$!

# Agente 3: Specialista / Critico (Secondhand interpreter / Groq / OpenCode modello 3)
(
  cd "$WORK"
  P3="RUOLO: Agente 3 (Critico & Ottimizzatore). Trova i colli di bottiglia, i rischi, i trucchi per risparmiare tempo/soldi e le alternative migliori per questo compito. Sii sintetico in italiano. COMPITO: $TASK"
  if [ -n "${GROQ_API_KEY:-}" ]; then
    python3 - "$P3" "$WORK/a3.md" <<'PYEOF'
import os, sys, json, urllib.request
prompt, out_p = sys.argv[1], sys.argv[2]
req = urllib.request.Request(
    "https://api.groq.com/openai/v1/chat/completions",
    data=json.dumps({"model":"llama-3.3-70b-versatile","messages":[{"role":"user","content":prompt}]}).encode("utf-8"),
    headers={"Authorization": f"Bearer {os.environ['GROQ_API_KEY']}", "Content-Type":"application/json", "User-Agent":"SquadraFusion/1.0"}
)
try:
    with urllib.request.urlopen(req, timeout=120) as r:
        d = json.loads(r.read().decode("utf-8"))
        open(out_p, "w", encoding="utf-8").write(d["choices"][0]["message"]["content"])
except Exception as e:
    open(out_p, "w", encoding="utf-8").write(f"Errore Agente 3: {e}")
PYEOF
  elif command -v opencode >/dev/null 2>&1; then
    timeout 600 opencode run "$P3" > "$WORK/a3.md" 2>&1
  fi
) &
PID3=$!

wait $PID1 $PID2 $PID3
echo "  ✓ Tutti e 3 gli agenti hanno terminato in sincronia!"

echo "[2/2] Il Capo fonde i 3 risultati nel verdetto finale..."
COMBINED="$WORK/combined.txt"
{
  echo "COMPITO ORIGINALE: $TASK"
  echo ""
  echo "=== REPORT AGENTE 1 (ESPLORATORE) ==="
  cat "$WORK/a1.md" 2>/dev/null || true
  echo ""
  echo "=== REPORT AGENTE 2 (COSTRUTTORE) ==="
  cat "$WORK/a2.md" 2>/dev/null || true
  echo ""
  echo "=== REPORT AGENTE 3 (CRITICO & OTTIMIZZATORE) ==="
  cat "$WORK/a3.md" 2>/dev/null || true
} > "$COMBINED"

{
  echo "# 🔥 Risposta Squadra Fusion (3 Agenti in Sincronia)"
  echo "_$(date '+%d/%m/%Y %H:%M') · $(hostname)_"
  echo ""
  echo "**Compito:** $TASK"
  echo ""
  echo "## 👑 Verdetto Unificato del Capo"
} > "$OUT_FILE"

FUSE_PROMPT="Sei il Capo della Squadra Fusion. Qui sotto trovi i 3 report prodotti in parallelo dai tuoi 3 agenti (Esploratore, Costruttore, Critico). Fondili in un'unica risposta chiara, ordinata, senza ripetizioni e subito azionabile in italiano:

$(cat "$COMBINED")"
timeout 600 opencode run -m opencode/big-pickle "$FUSE_PROMPT" >> "$OUT_FILE" 2>&1 \
  || timeout 600 opencode run "$FUSE_PROMPT" >> "$OUT_FILE" 2>&1

{
  echo ""
  echo "<details><summary>📂 Mostrare i 3 report grezzi dei singoli agenti</summary>"
  echo ""
  cat "$COMBINED"
  echo "</details>"
} >> "$OUT_FILE"

rm -rf "$WORK"
echo ""
echo "=========================================================="
echo " ✓ COMPLETATO! Risultato salvato in: $OUT_FILE"
echo "=========================================================="
cat "$OUT_FILE"
