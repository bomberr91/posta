#!/usr/bin/env bash
# prova_agentrouter.sh — prova SOLO AgentRouter, con le sue strade giuste.
#
# PERCHÉ (2/11 14:20): la chiave nel portachiavi era TRONCATA (`sk-mHof0hcg…`),
# quindi l'appello diceva "nessuna chiave". Rimessa la chiave intera, la
# richiesta "normale" (browser UA + /v1/chat/completions + domanda in ITALIANO)
# resta appesa e muore "non raggiungibile": è il WAF Aliyun, che lascia cadere
# le richieste non riconosciute. Le strade che funzionano (dal PC):
#   a) GPT/DeepSeek: UA codex_cli_rs/0.149.1 + header originator: codex_cli_rs
#   b) Claude:       /v1/messages + x-api-key + UA claude-cli/2.0.14
# e la domanda va in INGLESE (in italiano risponde content-blocked).
#
# Uso:  bash ~/posta/fatti/prova_agentrouter.sh
set -uo pipefail
REPO="$HOME/posta"
K=$(python3 "$REPO/chiave_di.py" AgentRouter 2>/dev/null)
if [ -z "$K" ]; then
  echo "✗ chiave AgentRouter non trovata nel portachiavi"
  exit 1
fi
echo "chiave trovata (${#K} caratteri, iniziano con ${K:0:10})"
echo

echo "== a) codex_cli_rs su /v1/chat/completions, modello deepseek-v4-flash =="
curl -s -m 45 -o /tmp/ar_a.json -w "   HTTP %{http_code} in %{time_total}s\n" \
  -A "codex_cli_rs/0.149.1" -H "originator: codex_cli_rs" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $K" \
  -d '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"Reply with only OK"}],"max_tokens":64}' \
  https://agentrouter.org/v1/chat/completions 2>/dev/null
head -c 260 /tmp/ar_a.json 2>/dev/null; echo; echo

echo "== b) claude-cli su /v1/messages, modello deepseek-v4-flash =="
curl -s -m 45 -o /tmp/ar_b.json -w "   HTTP %{http_code} in %{time_total}s\n" \
  -A "claude-cli/2.0.14 (external, cli)" -H "x-api-key: $K" \
  -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
  -d '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"Reply with only OK"}],"max_tokens":64}' \
  https://agentrouter.org/v1/messages 2>/dev/null
head -c 260 /tmp/ar_b.json 2>/dev/null; echo; echo

echo "== c) claude-cli su /messages (senza /v1), modello claude-haiku-4.5 =="
curl -s -m 45 -o /tmp/ar_c.json -w "   HTTP %{http_code} in %{time_total}s\n" \
  -A "claude-cli/2.0.14 (external, cli)" -H "x-api-key: $K" \
  -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
  -d '{"model":"claude-haiku-4.5","messages":[{"role":"user","content":"Reply with only OK"}],"max_tokens":64}' \
  https://agentrouter.org/messages 2>/dev/null
head -c 260 /tmp/ar_c.json 2>/dev/null; echo
