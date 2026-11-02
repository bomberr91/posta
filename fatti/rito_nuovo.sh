#!/bin/bash
# RITO NUOVO + COLLAUDO INTERRUTTORE — CURA-AUDIT v5 (1/11 sera):
# il rito adesso collauda per davvero e può dire FALLITO.
set -uo pipefail
cd ~/posta || exit 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=fatti/collaudo_cervello.sh
. "$DIR/fatti/collaudo_cervello.sh"

echo "## RITO NUOVO + COLLAUDO INTERRUTTORE — $(date '+%H:%M')"
echo
echo "### 1. Ammazzo il cervello vecchio (il guardiano lo risusciterà col codice nuovo)"
pkill -f '^python3 cervello\.py$' && echo "ucciso" || echo "non girava"
echo "aspetto il guardiano (max 75s)..."
attendi || { echo "❌ il cervello non è tornato: il rito si ferma qui"; exit 1; }
sleep 2
echo
echo "### 1b. COLLAUDO (prima di fare altro: se il cervello è rotto, tutto il resto è inutile)"
collaudo || { echo "❌ il cervello è rotto: il rito si ferma qui"; exit 1; }
echo
echo "### 2. Interruttore SPENTO (file assente) → motore usato"
rm -f SOLO_CERVELLO.txt
curl -fsS -m 30 "$CERVELLO_URL/cervello" | python3 -c "import json,sys; d=json.load(sys.stdin); print('  interruttore:', d.get('interruttore_solo_cervello'), '· motore:', d.get('motore'), '· adesso:', d.get('adesso'))" || { echo "❌ /cervello non risponde"; exit 1; }
echo
echo "### 3. ACCENDO l'interruttore (creo SOLO_CERVELLO.txt) → motore ignorato"
echo "il capo comanda" > SOLO_CERVELLO.txt
curl -fsS -m 30 "$CERVELLO_URL/cervello" | python3 -c "import json,sys; d=json.load(sys.stdin); print('  interruttore:', d.get('interruttore_solo_cervello'), '· motore:', d.get('motore'), '· adesso:', d.get('adesso'))" || { echo "❌ /cervello non risponde"; exit 1; }
curl -fsS -m 240 -H 'Content-Type: application/json' \
  -d '{"model":"auto","max_tokens":30,"messages":[{"role":"user","content":"OmniRoute e acceso ma io ti ignoro. Chi risponde? Breve."}]}' \
  "$[CHIAVE-RIMOSSA]" | python3 -c "import json,sys; d=json.load(sys.stdin); print('  richiesta auto →', d.get('model','?'))" || { echo "❌ la richiesta auto non è passata"; exit 1; }
echo
echo "### 4. RISPONGO l'interruttore (torna il motore)"
rm -f SOLO_CERVELLO.txt
curl -fsS -m 30 "$CERVELLO_URL/cervello" | python3 -c "import json,sys; d=json.load(sys.stdin); print('  interruttore:', d.get('interruttore_solo_cervello'), '· motore:', d.get('motore'), '· adesso:', d.get('adesso'))" || { echo "❌ /cervello non risponde"; exit 1; }
echo
echo "✅ RITO NUOVO RIUSCITO"
