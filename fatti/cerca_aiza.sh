#!/bin/bash
echo "## CACCIA ALLA CHIAVE AIza — $(date '+%H:%M')"
echo "### nel portachiavi / CHIAVI_LOCALI del PC (mascherate)"
for F in ~/CHIAVI_LOCALI.md ~/posta/CHIAVI_LOCALI.md ~/.portachiavi* ~/posta/portachiavi*; do
  [ -f "$F" ] && grep -oE "AIza[A-Za-z0-9_-]{30,}" "$F" 2>/dev/null | sed 's/^\(AIza......\).*\(....\)$/\1••••\2/' | sort -u | head -3 && echo "   (trovate in: $F)"
done
echo "### nel DB di OmniRoute (solo presenza, mai la chiave)"
grep -rl "AIza" ~/.omniroute* ~/.config/omniroute* 2>/dev/null | head -2 || echo "   non leggibile/assente"
echo "### quante AIza distinte in totale (tutti i posti sopra)"
cat ~/CHIAVI_LOCALI.md ~/posta/CHIAVI_LOCALI.md 2>/dev/null | grep -oE "AIza[A-Za-z0-9_-]{30,}" | sort -u | wc -l
