#!/bin/bash
# revisore.sh <N> <RANGE> — seconda controllata del blocco N
N="$1"; RANGE="$2"
cd "$(dirname "$0")/.." || exit 1
OUT="dal_pc/revisione_blocco_${N}.md"
LOG="dal_pc/log_revisione_${N}.txt"
echo "avvio revisione $(date)" > "$LOG"

PROMPT="Sei il REVISORE INDIPENDENTE, un agente DIVERSO dall'analista. Il tuo mestiere e' CONTESTARE: trova gli errori nel verdetto, non ripeterlo.
Hai: le REGOLE VINCOLANTI, il QUADERNO (64 idee) e il VERDETTO dell'analista sulle idee ${RANGE}.
Per OGNI idea del blocco controlla: 1) il verdetto rispetta DAVVERO tutte le regole? 2) la FASE e' giusta o troppo ottimista? 3) SFORZO e RISCHIO sono realistici per un cervello.py in Python puro su Windows+WSL1? 4) l'analista ha promosso SICURA qualcosa che merita DECIDE-IL-CAPO o PARCHEGGIO (o viceversa)?
FORMATO RISPOSTA:
## DISACCORDI (solo le idee dove correggi l'analista)
### Idea <n> - <titolo>
- VERDETTO ANALISTA: ... -> VERDETTO REVISORE: ...
- PERCHE': 1-2 righe, cita la regola se violata
## CONFERME: elenco dei numeri idea dove l'analista ha ragione
## TABELLA FINALE RIVISTA: | n | verdetto finale | fase |
Sii severo ma onesto: se l'analista ha fatto bene, conferma e basta. NON inventare idee nuove.

=== REGOLE VINCOLANTI ===
$(cat missione/REGOLE_VINCOLANTI.md)

=== VERDETTO DELL'ANALISTA (blocco ${N}) ===
$(cat dal_pc/verdetto_blocco_${N}.md)

=== QUADERNO (64 idee, per riscontro) ===
$(cat missione/CERVELLO_MACCHINA_PERFETTA.md)"

RIS="$(opencode run -m cervello/auto "$PROMPT" 2>>"$LOG")"
{ echo "# REVISIONE BLOCCO ${N} (idee ${RANGE})"
  echo "- fine: $(date)"
  echo ""
  echo "$RIS"
  [ -z "$RIS" ] && echo "ERRORE: revisore muto — vedi log_revisione_${N}.txt"
} > "$OUT"
for i in 1 2 3 4 5; do
  git add dal_pc >/dev/null 2>&1; git commit -m "revisione blocco ${N}" >/dev/null 2>&1
  git pull --rebase >/dev/null 2>&1 && git push >/dev/null 2>&1 && break; sleep $((RANDOM%20+5))
done
