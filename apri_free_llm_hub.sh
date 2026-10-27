#!/usr/bin/env bash
# Avvia la copia standalone del Free LLM Hub dal commit upstream 1277fef.
set -u
HUB_REVISION="1277fefc33ecd6b6fdd1db2e0568713bbd941b3a"
HUB_PORT="${FREE_LLM_HUB_PORT:-3000}"
HUB_DIR="${FREE_LLM_HUB_DIR:-$HOME/posta/free-llm-hub}"
HUB_URL="http://localhost:$HUB_PORT/"

if [ ! -f "$HUB_DIR/dev.js" ] || [ ! -f "$HUB_DIR/index.html" ] || [ ! -f "$HUB_DIR/SOURCE_COMMIT" ]; then
  echo "❌ Free LLM Hub 1277fef non trovato in $HUB_DIR"
  exit 1
fi
if [ "$(tr -d '\r\n' < "$HUB_DIR/SOURCE_COMMIT")" != "$HUB_REVISION" ]; then
  echo "❌ La copia in $HUB_DIR non corrisponde al commit Free LLM Hub 1277fef."
  exit 1
fi
HUB_NODE="$HOME/.nvm/versions/node/v22.22.2/bin/node"
if [ ! -x "$HUB_NODE" ]; then HUB_NODE="$(command -v node || true)"; fi
if [ -z "$HUB_NODE" ]; then
  echo "❌ Node.js non trovato: non posso avviare Free LLM Hub."
  exit 1
fi
if ! command -v curl >/dev/null 2>&1 || ! command -v sha256sum >/dev/null 2>&1; then
  echo "❌ Servono curl e sha256sum per verificare la versione del Hub."
  exit 1
fi

EXPECTED_SHA="$(sha256sum "$HUB_DIR/index.html" | awk '{print $1}')"
live_sha() { curl -fsS --max-time 2 "$HUB_URL" 2>/dev/null | sha256sum | awk '{print $1}'; }
port_open() { (exec 3<>"/dev/tcp/127.0.0.1/$HUB_PORT") 2>/dev/null; }

# Chiude solo un vecchio dev.js del Free LLM Hub lanciato da una delle sue cartelle note.
stop_old_hub_processes() {
  local proc pid cmd cwd found=0
  for proc in /proc/[0-9]*; do
    [ -r "$proc/cmdline" ] || continue
    pid="${proc##*/}"
    cmd="$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null || true)"
    [[ "$cmd" == *node*dev.js* ]] || continue
    cwd="$(readlink -f "$proc/cwd" 2>/dev/null || true)"
    if [[ "$cwd" == "$HUB_DIR" || "$cwd" == "$HOME/free-llm-hub" ]]; then
      kill -TERM "$pid" 2>/dev/null || true
      found=1
    fi
  done
  return "$found"
}

# Evita che la vecchia GUI integrata resti come seconda schermata.
pkill -f "$HOME/posta/gui/server.py" 2>/dev/null || true
LIVE_SHA="$(live_sha)"
if [ "$LIVE_SHA" != "$EXPECTED_SHA" ] && port_open; then
  stop_old_hub_processes || true
  for _ in {1..20}; do
    LIVE_SHA="$(live_sha)"
    [ "$LIVE_SHA" = "$EXPECTED_SHA" ] && break
    port_open || break
    sleep 0.25
  done
  LIVE_SHA="$(live_sha)"
  if [ "$LIVE_SHA" != "$EXPECTED_SHA" ] && port_open; then
    echo "❌ La porta $HUB_PORT è occupata da un servizio non riconosciuto; non apro una schermata vecchia o doppia."
    exit 1
  fi
fi

LIVE_SHA="$(live_sha)"
if [ "$LIVE_SHA" != "$EXPECTED_SHA" ]; then
  if port_open; then
    echo "❌ La porta $HUB_PORT non serve la versione richiesta; non apro il browser."
    exit 1
  fi
  (cd "$HUB_DIR" && nohup env PORT="$HUB_PORT" "$HUB_NODE" dev.js >/tmp/free-llm-hub.log 2>&1 </dev/null &)
  HUB_PRONTO=0
  for _ in {1..20}; do
    LIVE_SHA="$(live_sha)"
    if [ "$LIVE_SHA" = "$EXPECTED_SHA" ]; then HUB_PRONTO=1; break; fi
    sleep 0.25
  done
  if [ "$HUB_PRONTO" -ne 1 ]; then
    echo "❌ Free LLM Hub 1277fef non si è avviato. Controlla /tmp/free-llm-hub.log."
    exit 1
  fi
fi

if [ "${FREE_LLM_HUB_NO_OPEN:-0}" != "1" ]; then
  cmd.exe /c start "" "$HUB_URL" 2>/dev/null || echo "Apri nel browser: $HUB_URL"
fi
echo "🌐 Free LLM Hub verificato — commit 1277fef — $HUB_URL"
