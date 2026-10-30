#!/bin/bash
# operaio generico: analista.sh <N> <RANGE> <MOTORE>
N="$1"; RANGE="$2"; AG="$3"
cd "$(dirname "$0")/.." || exit 1
OUT="dal_pc/verdetto_blocco_${N}.md"
LOG="dal_pc/log_blocco_${N}.txt"
echo "avvio $(date) motore richiesto: $AG" > "$LOG"

PROMPT="Sei l'ANALISTA del blocco ${N} di un team. Il capo ha raccolto 64 idee per migliorare il nostro router locale cervello.py (il Portiere, porta 20129: Python puro, semplice, gira su Windows+WSL1, utente principiante; smista gli agenti sui modelli gratuiti e custodisce le chiavi).
COMPITO: esamina SOLO le idee numero ${RANGE} del QUADERNO in fondo. Per OGNUNA compila ESATTAMENTE questo modulo:

### Idea <numero> - <titolo breve>
- VERDETTO: SICURA | DECIDE-IL-CAPO | PARCHEGGIO | SCARTO
- FASE: F1(subito) | F2 | F3 | CACCIA | -
- SFORZO: S|M|L  RISCHIO: basso|medio|alto
- MOTIVO: 1-2 righe concrete
- (solo se PARCHEGGIO) CONDIZIONE-SBLOCCO: cosa deve succedere per riaprirla
- (solo se conflitto) REGOLA VIOLATA: numero e nome della regola

CRITERI: SICURA solo se rispetta TUTTE le regole vincolanti, aiuta il focus (risparmio token / rotazione chiavi / affidabilita') e si scrive dentro cervello.py senza stravolgerlo. Le idee di caccia-token (registrarsi a un provider gratuito) = SICURA con FASE CACCIA (compito umano, non codice). Chiudi con una tabella riassuntiva | n | verdetto | fase | e i conteggi per verdetto.
NON riassumere le altre idee. NON inventare idee nuove. Qualita' batte tempo: ragiona su ogni idea.

=== REGOLE VINCOLANTI ===
$(cat missione/REGOLE_VINCOLANTI.md)

=== QUADERNO (64 idee) ===
$(cat missione/CERVELLO_MACCHINA_PERFETTA.md)"

run_goose(){ command -v goose >/dev/null 2>&1 && goose run -t "$PROMPT" 2>>"$LOG"; }
run_freebuff(){
  export NVM_DIR="/home/agenti/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
  [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1
  command -v freebuff >/dev/null 2>&1 || return 1
  ( cd /mnt/c/Users/giopi/Documents/AgentWorkspace && freebuff run "$PROMPT" 2>>"$OLDPWD/$LOG" )
}
run_opencode(){ opencode run -m cervello/auto "$PROMPT" 2>>"$LOG"; }

RIS=""; MOT=""
case "$AG" in
  goose)    RIS="$(run_goose)"    && [ -n "$RIS" ] && MOT="goose";;
  freebuff) RIS="$(run_freebuff)" && [ -n "$RIS" ] && MOT="freebuff";;
esac
if [ -z "$RIS" ]; then RIS="$(run_opencode)"; [ -n "$RIS" ] && MOT="opencode(cervello/auto) [riserva]"; fi

{ echo "# VERDETTO BLOCCO ${N} (idee ${RANGE})"
  echo "- motore: ${MOT:-NESSUNO}"
  echo "- fine: $(date)"
  echo ""
  echo "$RIS"
  [ -z "$RIS" ] && echo "ERRORE: nessun motore ha prodotto output — vedi log_blocco_${N}.txt"
} > "$OUT"

for i in 1 2 3 4 5 6; do
  git add dal_pc/ >/dev/null 2>&1
  git commit -m "verdetto blocco ${N} (${MOT:-errore})" >/dev/null 2>&1
  git pull --rebase >/dev/null 2>&1 && git push >/dev/null 2>&1 && break
  sleep $((RANDOM % 25 + 5))
done
