#!/bin/bash
echo "## 💰 AGENTROUTER: PROCESSO A TUTTE LE CHIAVI — $(date '+%H:%M')"
echo "### candidate nel portachiavi (sezione agentrouter ± 10 righe)"
CANDS=$(grep -B2 -A10 -i "agentrouter" ~/CHIAVI_LOCALI.md | grep -oE "sk-[A-Za-z0-9_-]{35,}" | sort -u)
echo "$CANDS" | sed 's/^\(sk-......\).*\(....\)$/  \1••••\2/'
N=0
for K in $CANDS; do
  N=$((N+1)); [ $N -gt 4 ] && break
  echo
  echo "### prova chiave $N (${K:0:8}••••${K: -4}, ${#K} car)"
  curl -s -m 60 -X POST "https://agentrouter.org/v1/messages" \
    -H "x-api-key: $K" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
    -H "User-Agent: claude-cli/2.0.14 (external, cli)" \
    -d '{"model":"deepseek-v4-flash","max_tokens":15,"messages":[{"role":"user","content":"Reply exactly: WORKS"}]}' | head -c 300
  echo
  sleep 6
done
