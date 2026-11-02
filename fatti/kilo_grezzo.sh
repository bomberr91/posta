#!/bin/bash
echo "## KILO: LA RISPOSTA GREZZA — $(date '+%H:%M')"
python3 << 'PYEOF'
import json, urllib.request
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) cervello/2.1"}
URL = "https://kilo.ai/api/openrouter/v1/chat/completions"
corpo = json.dumps({"model": "nvidia/nemotron-3.5-lightning:free", "max_tokens": 60,
                    "messages": [{"role": "user", "content": "Di che colore e il cielo? Una parola."}]}).encode()
try:
    grezzo = urllib.request.urlopen(urllib.request.Request(URL, data=corpo, headers=UA), timeout=60).read().decode()
    print("PRIMI 600 CARATTERI GREZZI:")
    print(grezzo[:600])
except Exception as e:
    print("errore:", str(e)[:150])
PYEOF
