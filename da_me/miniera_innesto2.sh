#!/bin/bash
echo "## ⛏️ INNESTO round 2 (cerca-ovunque) — $(date '+%H:%M')"
cd ~/miniera
SETTE="check-tests learn-agent-skills learn-mcp reviewable skill-invocation-router skill-release-gate skill-safety-reviewer"
for S in $SETTE; do
  D=$(find . -type d -name "$S" -not -path "*/node_modules/*" | head -1)
  if [ -n "$D" ]; then
    for NIDO in ~/.claude/skills ~/.agents/skills ~/.config/opencode/skills; do
      cp -rn "$D" "$NIDO/" 2>/dev/null
    done
    echo "  ✓ $S (da $D)"
  else
    echo "  ✗ $S NON TROVATA nella miniera!"
  fi
done
echo
echo "### Verifica finale: le 7 nei 3 nidi"
for NIDO in ~/.claude/skills ~/.agents/skills ~/.config/opencode/skills; do
  OK=0
  for S in $SETTE; do [ -d "$NIDO/$S" ] && OK=$((OK+1)); done
  echo "  $NIDO: $OK/7 presenti · totale $(ls "$NIDO" | wc -l) voci"
done
