#!/usr/bin/env bash
# prova_navyai.sh — prova mirata di NavyAI (una sola richiesta per modello).
# La chiave si legge dal portachiavi: nessuna chiave in questo file.
set -u
cd "$HOME/posta" 2>/dev/null || cd "$(dirname "$0")/.." || exit 1
K=$(python3 chiave_di.py "NavyAI" 2>/dev/null)
if [ -z "$K" ]; then echo "NavyAI: nessuna chiave nel portachiavi"; exit 1; fi
echo "NavyAI: chiave trovata (${#K} caratteri)"
for M in "schizogpt" "gpt-6.1-sol" "gpt-6-astra" "gpt-5.6-sol"; do
  BODY=$(curl -s -m 40 -w "\n%{http_code}" -A "Mozilla/5.0" \
    -H "Authorization: Bearer $K" -H "Content-Type: application/json" \
    -d "{\"model\":\"$M\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with the single word OK\"}],\"max_tokens\":64}" \
    https://api.navy/v1/chat/completions 2>/dev/null)
  CODE=$(printf '%s' "$BODY" | tail -1)
  RIS=$(printf '%s' "$BODY" | grep -oE '"content":"[^"]{0,40}' | head -1)
  ERR=$(printf '%s' "$BODY" | grep -oE '"message":"[^"]{0,80}' | head -1)
  echo "  $M -> HTTP $CODE ${RIS:-${ERR:-}}"
done
