#!/bin/bash
cd ~/posta
echo "## KILO: I DUE PREGIATI, CON CALMA — $(date '+%H:%M')"
python3 << 'PYEOF'
import json, time, urllib.request
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) cervello/2.1"}
URL = "https://kilo.ai/api/openrouter/v1/chat/completions"
for m in ("nvidia/nemotron-3.5-lightning:free", "cohere/north-mini-code:free"):
    corpo = json.dumps({"model": m, "max_tokens": 30, "messages": [{"role": "user", "content": "Rispondi solo: kilo funziona"}]}).encode()
    try:
        d = json.loads(urllib.request.urlopen(urllib.request.Request(URL, data=corpo, headers=UA), timeout=60).read().decode())
        testo = (d.get("choices") or [{}])[0].get("message", {}).get("content", "")
        print(("✅ " if testo else "🟡 vuoto ") + m + " → " + (testo[:60].replace("\n", " ") if testo else ""))
    except Exception as e:
        print("❌", m, "→", str(e)[:100])
    time.sleep(20)
PYEOF
