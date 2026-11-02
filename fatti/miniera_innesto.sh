#!/bin/bash
echo "## ⛏️ INNESTO DELLE 7 — $(date '+%H:%M')"
cd ~/miniera
SORG=$(find . -type d -name "skills" -path "*.claude*" | head -1)
echo "sorgente: $SORG"
SETTE="check-tests learn-agent-skills learn-mcp reviewable [CHIAVE-RIMOSSA] [CHIAVE-RIMOSSA] [CHIAVE-RIMOSSA]"
for NIDO in ~/.claude/skills ~/.agents/skills ~/.config/opencode/skills; do
  PRIMA=$(ls "$NIDO" | wc -l)
  for S in $SETTE; do
    [ -d "$SORG/$S" ] && cp -r "$SORG/$S" "$NIDO/" 2>/dev/null
  done
  echo "  $NIDO: $PRIMA → $(ls "$NIDO" | wc -l) voci"
done
echo
echo "### benign: caccia col nome largo"
find . -iname "*benign*" | head -5
B=$(find . -iname "*benign*" -name "*.md" | head -1)
[ -n "$B" ] && head -20 "$B"
echo
echo "### collaudo: opencode vede e usa una skill?"
export PATH="$HOME/.opencode/bin:$PATH"
while pgrep -f "opencode ru[n]" > /dev/null; do sleep 30; done
timeout 420 opencode run -m cervello/auto "Usa la skill check-tests (e' nelle tue skills installate): applicala a questo caso finto e dimmi in 3 righe cosa farebbe: 'progetto con 2 test, uno senza output salvato'. Se NON riesci a trovare o usare la skill, scrivi esattamente SKILL NON TROVATA." 2>&1 | tail -6
