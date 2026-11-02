#!/bin/bash
# CERCA — ricerca web per gli agenti, SENZA il cane (1/11 sera)
#
# QUANDO USARE CHE COSA (le chiavi sono tutte nel portachiavi, ~/CHIAVI_LOCALI.md):
#
#   · CERCA (questo script) → domanda secca: vuoi link + due righe di risposta.
#     Usa Exa (trova bene) + Tavily (risponde già pulito) insieme.
#     È la via veloce: 2-4 secondi, niente report, niente finestre.
#
#   · DEEP DOG (lavori/deepdog_ricerca.sh) → ricerca SERIA: report con fonti,
#     e ci mette dentro gli agenti PubMed, SEC (e Reddit quando lo sblocchi).
#     Quando ti serve DOCUMENTARE, non basta un link. Si avvia da solo.
#
#   · SKILL build-with-exa → per COSTRUIRE con l'API Exa (è già installata nei
#     nidi degli agenti). Non per cercare: per fare.
#
#   · FIRECRAWL → per LEGGERE il contenuto di una pagina (ce l'hai nel portachiavi).
#   · LINKUP → contesto più ampio quando Exa/Tavily non bastano.
#
# USO: bash lavori/cerca.sh "la domanda" [quanti risultati]
# ESEMPIO: bash lavori/cerca.sh "come si fa una API OpenAI-compatible" 5
set -uo pipefail

DOMANDA="${1:-}"
N="${2:-5}"
CHIAVI="${CHIAVI_FILE:-$HOME/CHIAVI_LOCALI.md}"
if [ -z "$DOMANDA" ]; then
  echo "uso: bash lavori/cerca.sh \"la domanda\" [quanti risultati]"
  exit 1
fi
if [ ! -f "$CHIAVI" ]; then
  echo "non trovo il portachiavi ($CHIAVI): nessuna chiave da usare"
  exit 1
fi

# le chiavi si prendono dal portachiavi, MAI hardcoded
EXA=$(grep -iE "^[[:space:]]*([0-9]+[.)])?[[:space:]]*-?[[:space:]]*\**Exa\b" "$CHIAVI" 2>/dev/null \
      | grep -oE "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}" | head -1)
TAVILY=$(grep -iE "^[[:space:]]*([0-9]+[.)])?[[:space:]]*-?[[:space:]]*\**Tavily\b" "$CHIAVI" 2>/dev/null \
      | grep -oE "tvly-[A-Za-z0-9_-]{20,}" | head -1)

if [ -z "$EXA" ] && [ -z "$TAVILY" ]; then
  echo "nel portachiavi non c'e' nessuna chiave di ricerca (Exa/Tavily): niente da fare"
  exit 1
fi
echo "motori: $([ -n "$EXA" ] && printf 'exa ')$([ -n "$TAVILY" ] && printf 'tavily')" >/dev/null

# ── Exa: trova bene (titoli, link, estratti) ───────────────────────────────
RIS_EXA=""
if [ -n "$EXA" ]; then
  BODY=$(python3 -c 'import json,sys; print(json.dumps({"query":sys.argv[1],"numResults":int(sys.argv[2]),"contents":{"text":{"maxCharacters":1200}}}))' "$DOMANDA" "$N" 2>/dev/null)
  RIS_EXA=$(curl -s -m 25 -X POST "https://api.exa.ai/search" \
      -H "x-api-key: $EXA" -H "Content-Type: application/json" -d "$BODY" 2>/dev/null)
fi

# ── Tavily: risponde già pulito ───────────────────────────────────────────
RIS_TAV=""
if [ -n "$TAVILY" ]; then
  BODY=$(python3 -c 'import json,sys; print(json.dumps({"query":sys.argv[1],"max_results":int(sys.argv[2]),"include_answer":True}))' "$DOMANDA" "$N" 2>/dev/null)
  RIS_TAV=$(curl -s -m 25 -X POST "https://api.tavily.com/search" \
      -H "Authorization: Bearer $TAVILY" -H "Content-Type: application/json" -d "$BODY" 2>/dev/null)
fi

# ── l'output: prima la risposta di Tavily, poi i risultati di Exa ─────────
python3 - "$RIS_TAV" "$RIS_EXA" "$N" << 'PYEOF'
import json, sys
tav, exa, n = sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 5
def carica(t):
    try:
        return json.loads(t)
    except Exception:
        return {}
T, E = carica(tav), carica(exa)
if not T and not E:
    print("nessun motore ha risposto (Exa e Tavily entrambi muti o le chiavi non sono piu' valide)")
    sys.exit(1)
risposta = (T.get("answer") or "").strip()
if risposta:
    print("RISPOSTA (Tavily):")
    print(" ", risposta.replace("\n", " ")[:1200])
    print()
visti = set()
n_out = 0
for r in (T.get("results") or []) + (E.get("results") or []):
    url = (r.get("url") or "").strip()
    if not url or url in visti:
        continue
    visti.add(url)
    titolo = (r.get("title") or "(senza titolo)").strip()
    testo = (r.get("content") or r.get("text") or r.get("snippet") or "").strip()
    testo = " ".join(testo.split())[:400]
    print("%d. %s" % (n_out + 1, titolo))
    print("   %s" % url)
    if testo:
        print("   %s" % testo)
    n_out += 1
    if n_out >= n:
        break
if not n_out:
    print("nessun risultato")
PYEOF
RC=$?
[ "$RC" -eq 0 ] || exit 1
exit 0
