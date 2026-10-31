#!/bin/bash
# Catena F3: due operai in fila + un revisore, tutto in locale via cervello/auto
cd ~/posta
export PATH="$HOME/.opencode/bin:$PATH"
D=~/posta/dal_pc; mkdir -p "$D"
SPEC=$(cat missione/DOSSIER_F3.md)
echo "## CATENA F3 PARTITA — $(date '+%H:%M')"
for MOD in 1 2; do
  NOME=$([ $MOD = 1 ] && echo compressione || echo per_agente)
  echo "— operaio modulo $MOD ($NOME) al lavoro $(date '+%H:%M') —"
  timeout 900 opencode run -m cervello/auto "Sei un programmatore Python meticoloso. Scrivi il MODULO $MOD richiesto dal dossier qui sotto, rispettando OGNI regola. Rispondi SOLO col blocco di codice.

$SPEC" > "$D/f3_${NOME}.md" 2>&1
  echo "  scritto dal_pc/f3_${NOME}.md ($(wc -c < "$D/f3_${NOME}.md") byte)"
done
echo "— revisore al lavoro $(date '+%H:%M') —"
timeout 900 opencode run -m cervello/auto "Sei un revisore severo. Qui sotto trovi il dossier con le specifiche e poi i due moduli scritti da un collega. Per ciascuno: elenca gli errori veri (bug, specifiche ignorate, casi non gestiti), ignora lo stile. Chiudi con verdetto PROMOSSO o BOCCIATO per ciascun modulo e, se bocciato, la correzione precisa.

=== DOSSIER ===
$SPEC

=== MODULO 1 ===
$(cat "$D/f3_compressione.md")

=== MODULO 2 ===
$(cat "$D/f3_per_agente.md")" > "$D/f3_revisione.md" 2>&1
echo "  scritto dal_pc/f3_revisione.md"
echo "## CATENA F3 FINITA — $(date '+%H:%M')"
