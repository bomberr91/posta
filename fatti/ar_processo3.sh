#!/bin/bash
echo "## 💰 AR PROCESSO 3 — estrattore corretto — $(date '+%H:%M')"
K=$(grep -oE "sk-mHof[A-Za-z0-9_-]+" ~/CHIAVI_LOCALI.md | head -1)
echo "chiave: ${K:0:8}••••${K: -4} · ${#K} caratteri"
echo
echo "### A. riproduzione prova-auth (deepseek-v4-flash: atteso 'no channel' se auth ok)"
curl -s -m 60 -X POST "https://agentrouter.org/v1/messages" \
  -H "x-api-key: $K" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
  -H "User-Agent: claude-cli/2.0.14 (external, cli)" \
  -d '{"model":"deepseek-v4-flash","max_tokens":15,"messages":[{"role":"user","content":"Reply exactly: WORKS"}]}' | head -c 250
echo; sleep 7
echo "### B. listino (x-api-key + vestito claude)"
curl -s -m 30 "https://agentrouter.org/v1/models" \
  -H "x-api-key: $K" -H "anthropic-version: 2023-06-01" \
  -H "User-Agent: claude-cli/2.0.14 (external, cli)" | head -c 500
echo; sleep 7
for M in "claude-sonnet-4-5-20250929" "claude-opus-4-1" "gpt-5.6-sol"; do
  echo "### C. prova: $M"
  curl -s -m 90 -X POST "https://agentrouter.org/v1/messages" \
    -H "x-api-key: $K" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
    -H "User-Agent: claude-cli/2.0.14 (external, cli)" \
    -d "{\"model\":\"$M\",\"max_tokens\":15,\"messages\":[{\"role\":\"user\",\"content\":\"Reply exactly: CHANNEL OPEN\"}]}" | head -c 300
  echo; sleep 7
done
