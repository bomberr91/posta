#!/bin/bash
K=$(grep -oE "sk-mHof[A-Za-z0-9]+" ~/CHIAVI_LOCALI.md | head -1)
echo "## 💰 AGENTROUTER: CHI HA CANALE ADESSO? — $(date '+%H:%M')"
echo "### 1. Listino modelli (vestito codex)"
curl -s -m 30 "https://agentrouter.org/v1/models" \
  -H "Authorization: Bearer $K" \
  -H "User-Agent: codex_cli_rs/0.149.1" | python3 -c "
import json,sys
try:
    d = json.load(sys.stdin)
    ids = [m.get('id') for m in d.get('data', [])]
    print('modelli in listino:', len(ids))
    for i in ids[:30]: print(' ', i)
except Exception as e:
    print('listino non leggibile:', sys.stdin.read()[:200] if False else e)"
echo
sleep 6
for M in "claude-sonnet-4-5" "claude-haiku-4-5" "gpt-5.6" "glm-4.6"; do
  echo "### prova: $M"
  curl -s -m 60 -X POST "https://agentrouter.org/v1/messages" \
    -H "x-api-key: $K" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
    -H "User-Agent: claude-cli/2.0.14 (external, cli)" \
    -d "{\"model\":\"$M\",\"max_tokens\":15,\"messages\":[{\"role\":\"user\",\"content\":\"Reply exactly: CHANNEL OPEN\"}]}" | head -c 250
  echo; sleep 7
done
