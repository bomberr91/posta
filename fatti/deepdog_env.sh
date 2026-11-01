#!/bin/bash
echo "## 🐕 RIEMPIO IL .env DI DEEP DOG — $(date '+%H:%M')"
ENV="/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog/.env"
OR=$(grep -A3 -i "openrouter" ~/CHIAVI_LOCALI.md | grep -oE "sk-or-[A-Za-z0-9_-]{30,}" | head -1)
TV=$(grep -oE "tvly-[A-Za-z0-9_-]{20,}" ~/CHIAVI_LOCALI.md | head -1)
echo "openrouter: ${OR:0:9}••• (${#OR} car) · tavily: ${TV:0:6}••• (${#TV} car)"
[ -f "$ENV" ] || { echo "❌ .env non trovato"; exit 0; }
python3 - "$ENV" "$OR" "$TV" << 'PYEOF'
import sys
p, orr, tv = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(p, encoding="utf-8", errors="replace").read()
if orr: s = s.replace("# OPENROUTER_API_KEY=", "OPENROUTER_API_KEY=" + orr).replace("OPENROUTER_API_KEY=\n", "OPENROUTER_API_KEY=%s\n" % orr)
if tv:  s = s.replace("# TAVILY_API_KEY=", "TAVILY_API_KEY=" + tv).replace("TAVILY_API_KEY=\n", "TAVILY_API_KEY=%s\n" % tv)
open(p, "w", encoding="utf-8").write(s)
import re
print("righe attive ora:", [r.split("=")[0] for r in s.splitlines() if re.match(r"^[A-Z_]+=.+", r)])
PYEOF
