#!/usr/bin/env bash
# openclaw_stato.sh — dice in un colpo com'è messo OpenClaw, per la Centrale e per il Hub.
#   ./openclaw_stato.sh          testo leggibile
#   ./openclaw_stato.sh --json   una riga JSON (la usa la GUI)
set -u
QUI=$(cd "$(dirname "$0")" && pwd)
WINROOT="${WINROOT:-/mnt/c}"
PORT="${OPENCLAW_PORT:-18789}"

TIPO=$(bash "$QUI/apri_openclaw.sh" --stato 2>/dev/null); TIPO=${TIPO:-no}
DOVE=$(bash "$QUI/apri_openclaw.sh" --trova 2>/dev/null)

# comando eseguibile: su Windows è un .cmd, dentro Ubuntu è un binario
CMD=""
case "$TIPO" in
  wsl|bun) CMD=$(command -v openclaw 2>/dev/null || echo "$HOME/.bun/bin/openclaw") ;;
  windows-exe) CMD=$(bash "$QUI/apri_openclaw.sh" --trova 2>/dev/null | sed 's/^OpenClaw (installato su Windows): //') ;;
esac

VER=""
if [ -n "$CMD" ] && [ -x "$CMD" ]; then
  case "$CMD" in
    *.cmd|*.bat) VER=$( (cd "$WINROOT" 2>/dev/null; timeout 25 cmd.exe /c "$(wslpath -w "$CMD" 2>/dev/null || echo "$CMD")" --version 2>/dev/null) | tr -d '\r' | head -1) ;;
    *)           VER=$(timeout 25 "$CMD" --version 2>/dev/null | head -1) ;;
  esac
fi

# gateway: porta (in WSL1 il localhost è lo stesso di Windows)
PORTA_UP=0
(exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null && { exec 3<&-; PORTA_UP=1; }

# configurazione: c'è già? (la crea "openclaw onboard")
CFG=""; TOKEN=""
for f in "$WINROOT"/Users/*/.openclaw/openclaw.json "$HOME/.openclaw/openclaw.json"; do
  [ -f "$f" ] && { CFG="$f"; break; }
done
if [ -n "$CFG" ]; then
  TOKEN=$(grep -oE '"(token|authToken|apiKey)"[[:space:]]*:[[:space:]]*"[^"]{8,}"' "$CFG" 2>/dev/null | head -1 | sed -E 's/.*:[[:space:]]*"([^"]+)"/\1/')
fi

case "${1:-}" in
  --json)
    printf '{"tipo":"%s","dove":"%s","versione":"%s","porta":%s,"gateway":%s,"configurato":%s,"token":"%s","url":"http://127.0.0.1:%s","base_api":"http://127.0.0.1:%s/v1"}\n' \
      "$TIPO" "$DOVE" "$VER" "$PORT" "$PORTA_UP" "$([ -n "$CFG" ] && echo true || echo false)" "$TOKEN" "$PORT" "$PORT" ;;
  *)
    echo "OpenClaw: $([ "$TIPO" = no ] && echo 'NON installato' || echo "$TIPO")"
    [ -n "$VER" ] && echo "  versione:   $VER"
    [ -n "$DOVE" ] && echo "  dove:       $DOVE"
    echo "  gateway:    $([ "$PORTA_UP" = 1 ] && echo "acceso su :$PORT" || echo "spento (porta $PORT)")"
    echo "  configurato:$([ -n "$CFG" ] && echo " sì ($CFG)" || echo " no — manca «openclaw onboard»")"
    [ -n "$CFG" ] && echo "  interfaccia: http://localhost:$PORT   ·   API: http://localhost:$PORT/v1"
    ;;
esac
