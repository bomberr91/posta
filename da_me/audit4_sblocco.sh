#!/bin/bash
echo "## 🔓 CHI BLOCCA LA CATENA? — $(date '+%H:%M')"
echo "### cosa combacia con 'opencode run' (la guardia della catena)"
pgrep -af "opencode ru[n]" || echo "  NIENTE combacia → la catena non è in attesa, è DENTRO una chiamata"
echo
echo "### tutti i processi opencode"
pgrep -af "opencod[e]" | head -6 || echo "  nessun opencode vivo"
echo
echo "### se c'è un fantasma che combacia ma non lavora, lo elimino"
for PID in $(pgrep -f "opencode ru[n]"); do
  ETA=$(ps -o etimes= -p $PID 2>/dev/null | tr -d " ")
  if [ -n "$ETA" ] && [ "$ETA" -gt 1200 ]; then
    kill $PID && echo "  ucciso fantasma pid $PID (vivo da ${ETA}s)"
  else
    echo "  pid $PID vivo da ${ETA}s: lo lascio (giovane)"
  fi
done
echo "(la catena riparte da sola al prossimo giro della sua guardia)"
