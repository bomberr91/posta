#!/usr/bin/env bash
# Avvia il Free LLM Hub standalone (sorgente 1277fef) su una porta dedicata.
set -u
HUB_REVISION="1277fef"
HUB_PORT="${FREE_LLM_HUB_PORT:-12777}"
HUB_DIR="${FREE_LLM_HUB_DIR:-$HOME/posta/free-llm-hub}"
if [ -z "${FREE_LLM_HUB_DIR:-}" ] && [ ! -f "$HUB_DIR/dev.js" ] && [ -f "$HOME/free-llm-hub/dev.js" ]; then
  HUB_DIR="$HOME/free-llm-hub"
fi
HUB_NODE="$HOME/.nvm/versions/node/v22.22.2/bin/node"
if [ ! -x "$HUB_NODE" ]; then
  HUB_NODE="$(command -v node || true)"
fi
HUB_URL="http://localhost:$HUB_PORT/"
HUB_MARKER="name=\"posta-free-llm-hub-source\" content=\"$HUB_REVISION\""
if [ ! -f "$HUB_DIR/dev.js" ]; then
  echo "❌ Free LLM Hub aggiornato non trovato: $HUB_DIR/dev.js"
  exit 1
elif [ -z "$HUB_NODE" ]; then
  echo "❌ Node.js non trovato: non posso avviare Free LLM Hub."
  exit 1
elif ! command -v curl >/dev/null 2>&1; then
  echo "❌ curl non è installato: non posso verificare il Free LLM Hub."
  exit 1
fi
HUB_HTML="$(curl -fsS --max-time 2 "$HUB_URL" 2>/dev/null || true)"
if [[ "$HUB_HTML" == *"$HUB_MARKER"* ]]; then
  HUB_PRONTO=1
elif (exec 3<>"/dev/tcp/127.0.0.1/$HUB_PORT") 2>/dev/null; then
  echo "❌ La porta $HUB_PORT è occupata da un'altra versione/servizio. Non apro l'hub vecchio."
  exit 1
else
  (cd "$HUB_DIR" && nohup env PORT="$HUB_PORT" "$HUB_NODE" dev.js >/tmp/free-llm-hub.log 2>&1 </dev/null &)
  HUB_PRONTO=0
  for _ in {1..20}; do
    HUB_HTML="$(curl -fsS --max-time 2 "$HUB_URL" 2>/dev/null || true)"
    if [[ "$HUB_HTML" == *"$HUB_MARKER"* ]]; then HUB_PRONTO=1; break; fi
    sleep 1
  done
  if [ "$HUB_PRONTO" -ne 1 ]; then
    echo "❌ Free LLM Hub 1277fef non pronto. Controlla /tmp/free-llm-hub.log."
    exit 1
  fi
fi
if [ "${FREE_LLM_HUB_NO_OPEN:-0}" != "1" ]; then
  cmd.exe /c start "" "$HUB_URL" 2>/dev/null || echo "Apri nel browser: $HUB_URL"
fi
echo "🌐 Free LLM Hub aggiornato (sorgente $HUB_REVISION): $HUB_URL"
