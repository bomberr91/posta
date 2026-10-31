#!/bin/bash
cd ~/posta
echo "## LISTA E CATALOGO DEL PORTIERE — $(date '+%H:%M')"
echo '```'
grep -v '^#' portiere_lista.txt | grep -v '^$' | cut -d'|' -f1,2,5 | head -70
echo '```'
echo
echo "### Dal catalogo scoperto: chi dichiara i modelli delle squadre 12/10"
python3 << 'PYEOF'
import json
cat = json.load(open('portiere_catalogo.json'))
cerca = ["gpt-oss-120b", "qwen3.8-27b", "nemotron-3-super", "codestral", "north-mini-code",
         "mistral-code", "glm-4.7-flash", "deepseek-v4-flash", "gemma-4-31b", "command-a-reasoning"]
for nome in cerca:
    chi = [pid for pid, v in cat.items() if any(nome in str(m).lower() for m in v.get("modelli", []))]
    print("  %-22s → %s" % (nome, ", ".join(chi[:6]) or "nessuno nel catalogo"))
PYEOF
