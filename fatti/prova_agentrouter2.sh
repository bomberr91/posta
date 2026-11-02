#!/usr/bin/env bash
# prova_agentrouter2.sh — AgentRouter: catalogo + modelli, uno alla volta.
#
# PERCHÉ (2/11 14:30): la strada che funziona è POST /v1/messages con
# x-api-key e UA claude-cli (la richiesta torna dal backend vero: 503 «no
# available channel for model deepseek-v4-flash in group default» → la CHIAVE
# è valida, era il modello senza canale in quel momento). Con /v1/chat/completions
# la connessione resta appesa (WAF) e /messages senza /v1 restituisce la pagina
# web. Ora serve: (a) il catalogo vero, (b) il primo modello che risponde.
#
# ATTENZIONE: il WAF Aliyun risponde HTTP 200 con una PAGINA HTML. Quindi
# l'esito si decide sul CORPO (c'è "aliyun_waf" o "<!doctype" → bloccato),
# mai sul solo codice HTTP.
#
# NB dal vault: «niente raffiche» → 4 secondi tra una richiesta e l'altra.
#
# Uso:  bash ~/posta/fatti/prova_agentrouter2.sh
set -uo pipefail
REPO="$HOME/posta"
K=$(python3 "$REPO/chiave_di.py" AgentRouter 2>/dev/null)
if [ -z "$K" ]; then echo "✗ chiave AgentRouter non trovata nel portachiavi"; exit 1; fi
UA_CLAUDE="claude-cli/2.0.14 (external, cli)"
UA_CODEX="codex_cli_rs/0.149.1"

# bloccato? il WAF risponde 200 + HTML
bloccato(){ grep -qi 'aliyun_waf\|<!doctype html\|<html' "$1" 2>/dev/null; }

echo "== 1. catalogo con x-api-key (claude-cli) =="
code=$(curl -s -m 30 -o /tmp/ar_models.json -w '%{http_code}' \
  -A "$UA_CLAUDE" -H "x-api-key: $K" https://agentrouter.org/v1/models 2>/dev/null)
if bloccato /tmp/ar_models.json; then
  echo "   HTTP $code ma è la pagina del WAF (bloccato da questo IP)"
elif [ "$code" = "200" ]; then
  python3 - << 'PY'
import json
try:
    d = json.load(open("/tmp/ar_models.json", encoding="utf-8", errors="replace"))
except Exception as e:
    print("   (catalogo non leggibile)", e); raise SystemExit
voci = d.get("data") if isinstance(d, dict) else None
if not voci and isinstance(d, dict):
    for k in ("models", "result", "items"):
        if isinstance(d.get(k), list):
            voci = d[k]; break
ids = [x.get("id") if isinstance(x, dict) else x for x in (voci or [])]
print(f"   modelli nel catalogo: {len(ids)}")
for i in ids[:60]:
    print("     -", i)
PY
else
  echo "   HTTP $code"; head -c 200 /tmp/ar_models.json 2>/dev/null; echo
fi
echo

echo "== 2. modelli su /v1/messages (x-api-key, domanda in inglese) =="
TROVATO=""
for M in deepseek-v4-flash deepseek-v4-pro claude-haiku-4.5 claude-sonnet-4.6 \
         claude-3-5-haiku-latest gpt-5.6-sol gpt-5.1 qwen3.8-27b glm-5.2-flash kimi-k2.6; do
  code=$(curl -s -m 30 -o /tmp/ar_m.json -w '%{http_code}' \
    -A "$UA_CLAUDE" -H "x-api-key: $K" -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$M\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with only OK\"}],\"max_tokens\":64}" \
    https://agentrouter.org/v1/messages 2>/dev/null)
  if bloccato /tmp/ar_m.json; then
    echo "   · $M -> HTTP $code ma pagina WAF (bloccato da questo IP)"
    sleep 4; continue
  fi
  risposta=$(head -c 150 /tmp/ar_m.json 2>/dev/null | tr '\n' ' ')
  case "$code" in
    200) echo "   ✓ $M -> HTTP 200"; echo "     $risposta"; TROVATO="$M"; break ;;
    401|403) echo "   ✗ $M -> HTTP $code (chiave rifiutata)"; break ;;
    *) echo "   · $M -> HTTP $code"; echo "     $risposta" ;;
  esac
  sleep 4
done
[ -n "$TROVATO" ] && echo "   MODELO CHE RISPONDE: $TROVATO"
echo

echo "== 3. /v1/responses con UA codex (per i modelli GPT) =="
for M in gpt-5.6-sol gpt-5.1 deepseek-v4-flash; do
  code=$(curl -s -m 30 -o /tmp/ar_r.json -w '%{http_code}' \
    -A "$UA_CODEX" -H "originator: codex_cli_rs" -H "Authorization: Bearer $K" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$M\",\"input\":\"Reply with only OK\",\"max_output_tokens\":64}" \
    https://agentrouter.org/v1/responses 2>/dev/null)
  if bloccato /tmp/ar_r.json; then
    echo "   · $M -> HTTP $code ma pagina WAF"; sleep 4; continue
  fi
  risposta=$(head -c 150 /tmp/ar_r.json 2>/dev/null | tr '\n' ' ')
  case "$code" in
    200) echo "   ✓ $M -> HTTP 200"; echo "     $risposta"; break ;;
    *) echo "   · $M -> HTTP $code"; echo "     $risposta" ;;
  esac
  sleep 4
done
