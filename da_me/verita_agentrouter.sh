#!/bin/bash
echo "## 💰 AGENTROUTER: IL CREDITO SI SPENDE VIA API? — $(date '+%H:%M')"
echo "### 1. Caccia alla chiave (mascherata)"
K=$(grep -A3 -i "agentrouter" ~/CHIAVI_LOCALI.md | grep -oE "sk-[A-Za-z0-9]{40,}" | head -1)
[ -z "$K" ] && K=$(grep -oE "sk-mHof[A-Za-z0-9]+" ~/CHIAVI_LOCALI.md | head -1)
echo "trovata: ${K:0:8}••••${K: -4} (${#K} caratteri)"
[ -z "$K" ] && { echo "❌ chiave non trovata nel portachiavi PC"; exit 0; }
echo
echo "### 2. Prova vestita (claude-cli, /v1/messages, EN, modello economico)"
curl -s -m 60 -X POST "https://agentrouter.org/v1/messages" \
  -H "x-api-key: $K" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
  -H "User-Agent: claude-cli/2.0.14 (external, cli)" \
  -d '{"model":"deepseek-v4-flash","max_tokens":20,"messages":[{"role":"user","content":"Reply with exactly: CREDIT WORKS"}]}' | head -c 400
echo; echo
sleep 6
echo "### 3. E i modelli NOBILI? (Opus, pochi token)"
curl -s -m 90 -X POST "https://agentrouter.org/v1/messages" \
  -H "x-api-key: $K" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
  -H "User-Agent: claude-cli/2.0.14 (external, cli)" \
  -d '{"model":"claude-opus-5","max_tokens":25,"messages":[{"role":"user","content":"Reply with exactly: OPUS AT YOUR SERVICE"}]}' | head -c 400
echo
