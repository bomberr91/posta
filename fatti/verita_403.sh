#!/bin/bash
echo "## IL 403 CONFESSA — $(date '+%H:%M')"
K=$(grep -oE "AIza[A-Za-z0-9_-]{30,}" ~/CHIAVI_LOCALI.md | head -1)
echo "### prova minima di testo (niente video) con la AIza:"
curl -s -m 30 -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$K" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"di ciao"}]}]}' | head -c 700
echo
