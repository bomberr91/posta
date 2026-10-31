#!/bin/bash
cd ~/posta
echo "## GITHUB MODELS: VIVO O MORTO? — $(date '+%H:%M')"
K=$(python3 chiave_di.py "github" 2>/dev/null || python3 chiave_di.py "githubmodels" 2>/dev/null)
URL=$(grep '^githubmodels|' portiere_lista.txt | cut -d'|' -f4)
echo "endpoint: $URL"
curl -s -m 30 -X POST "$URL/chat/completions" -H "Authorization: Bearer $K" -H "Content-Type: application/json" -H "User-Agent: Mozilla/5.0 cervello/2.1" -d '{"model":"openai/gpt-4o-mini","max_tokens":10,"messages":[{"role":"user","content":"ping"}]}' | head -c 300
echo
