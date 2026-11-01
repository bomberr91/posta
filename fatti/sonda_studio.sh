#!/bin/bash
K=$(grep "^GEMINI_STUDIO=" ~/CHIAVI_LOCALI.md | cut -d= -f2)
echo "## SONDA GEMINI_STUDIO — $(date '+%H:%M') · chiave ${#K} caratteri"
[ -z "$K" ] && { echo "❌ chiave assente dal portachiavi"; exit 0; }
echo "### stile ?key="
curl -s -m 30 -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$K" -H "Content-Type: application/json" -d '{"contents":[{"parts":[{"text":"Rispondi solo: occhi aperti"}]}]}' | head -c 250
echo; echo "### stile x-goog-api-key"
curl -s -m 30 -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent" -H "Content-Type: application/json" -H "x-goog-api-key: $K" -d '{"contents":[{"parts":[{"text":"Rispondi solo: occhi aperti"}]}]}' | head -c 250
echo
