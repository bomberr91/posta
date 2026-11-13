#!/usr/bin/env bash
# battito.sh — l'agente dice cosa sta facendo (vocabolario: running blocked idle paused offline)
# uso: battito <agente> <stato> [nota]  — scrittura atomica in ~/posta/stato_agenti/<agente>.json
set -u
NOME="${1:-?}"; STATO="${2:-running}"; NOTA="${3:-}"
DIR="$HOME/posta/stato_agenti"; mkdir -p "$DIR"
TMP="$DIR/$NOME.json.tmp"
python3 - "$NOME" "$STATO" "$NOTA" "$TMP" <<'EOF'
import json, sys, time, os
nome, stato, nota, tmp = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
d = {"agente": nome, "stato": stato, "nota": nota,
     "ts": time.strftime("%Y-%m-%d %H:%M:%S"), "epoch": int(time.time())}
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(d, f, ensure_ascii=False, indent=1)
os.replace(tmp, os.path.join(os.path.dirname(tmp), nome + ".json"))
