#!/bin/bash
cd ~/posta
echo "## GITHUB MODELS, SECONDA AUTOPSIA — $(date '+%H:%M')"
K=$(python3 chiave_di.py "github" 2>/dev/null)
[ -z "$K" ] && K=$(python3 chiave_di.py "githubmodels" 2>/dev/null)
echo "chiave trovata: ${#K} caratteri"
URL=$(grep '^githubmodels|' portiere_lista.txt | cut -d'|' -f4)
echo "endpoint lista: $URL"
echo
echo "### POST chat/completions (codice + corpo)"
curl -s -m 30 -w "\n[HTTP %{http_code}]\n" -X POST "$URL/chat/completions" -H "Authorization: Bearer $K" -H "Content-Type: application/json" -H "User-Agent: Mozilla/5.0 cervello/2.1" -d '{"model":"openai/gpt-4o-mini","max_tokens":10,"messages":[{"role":"user","content":"Rispondi: vivo"}]}' | head -c 500
echo
echo "### GET /models (codice)"
curl -s -o /dev/null -w "[HTTP %{http_code}]\n" -m 20 "$URL/models" -H "Authorization: Bearer $K"
