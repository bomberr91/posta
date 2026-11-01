#!/bin/bash
echo "## 💰 AR PROCESSO 4 — chiave INTERA + cascata vera — $(date '+%H:%M')"
K=$(grep -oE "sk-mHof[A-Za-z0-9_-]{40,}" ~/CHIAVI_LOCALI.md | head -1)
echo "chiave: ${K:0:8}••••${K: -4} · ${#K} caratteri (attesi 51)"
[ ${#K} -lt 45 ] && { echo "❌ ancora moncherino — nel file c'è solo la versione spezzata"; exit 0; }
sleep 2
for M in "claude-opus-5" "claude-opus-4-8" "claude-sonnet-4-5-20250929" "gpt-5.6-sol" "deepseek-v4-flash"; do
  echo "### $M"
  curl -s -m 90 -X POST "https://agentrouter.org/v1/messages" \
    -H "x-api-key: $K" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
    -H "User-Agent: claude-cli/2.0.14 (external, cli)" \
    -d "{\"model\":\"$M\",\"max_tokens\":20,\"messages\":[{\"role\":\"user\",\"content\":\"Reply exactly: CHANNEL OPEN\"}]}" | head -c 300
  echo; sleep 8
done
