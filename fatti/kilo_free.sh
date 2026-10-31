#!/bin/bash
cd ~/posta
echo "## KILO: I MODELLI :free SULLA PORTA NUOVA — $(date '+%H:%M')"
python3 << 'PYEOF'
import json, urllib.request
cat = json.load(open("portiere_catalogo.json")).get("kilo", {}).get("modelli", [])
liberi = [m for m in cat if ":free" in m.lower()]
print("modelli :free nel catalogo kilo:", len(liberi))
print("primi 8:", liberi[:8])
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) cervello/2.1"}
URL = "https://kilo.ai/api/openrouter/v1/chat/completions"
for m in liberi[:4]:
    corpo = json.dumps({"model": m, "max_tokens": 25, "messages": [{"role": "user", "content": "Rispondi solo: kilo funziona"}]}).encode()
    try:
        d = json.loads(urllib.request.urlopen(urllib.request.Request(URL, data=corpo, headers=UA), timeout=45).read().decode())
        testo = (d.get("choices") or [{}])[0].get("message", {}).get("content", "")
        if testo:
            print("✅ RISPONDE:", m, "→", testo[:60].replace("\n", " "))
            break
        print("🟡 vuoto:", m)
    except Exception as e:
        print("❌", m, "→", str(e)[:100])
PYEOF
