#!/bin/bash
cd ~/posta
echo "## KILO: PROVA FINALE CON BUDGET VERO + RITO AUTO — $(date '+%H:%M')"
pkill -f '^python3 cervello\.py$' && echo "cervello ucciso, il guardiano lo risuscita..."
for i in $(seq 1 15); do sleep 5; (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && { echo "risorto (~$((i*5))s)"; break; }; done
# CURA-AUDIT v5: dopo aver ucciso il cervello, VERIFICARE che è tornato.
# Senza questo, uno script può lasciare il PC morto e dire "tutto bene".
bash fatti/collaudo_cervello.sh || { echo "❌ il cervello NON è tornato (o non risponde)"; exit 1; }
echo
echo "### 1. Kilo diretto, max_tokens 1200 (budget da adulti)"
python3 << 'PYEOF'
import json, urllib.request
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) cervello/2.1"}
corpo = json.dumps({"model": "nvidia/nemotron-3.5-lightning:free", "max_tokens": 1200,
                    "messages": [{"role": "user", "content": "Di che colore e il cielo sereno? Una parola."}]}).encode()
try:
    d = json.loads(urllib.request.urlopen(urllib.request.Request(
        "https://kilo.ai/api/openrouter/v1/chat/completions", data=corpo, headers=UA), timeout=90).read().decode())
    m = (d.get("choices") or [{}])[0].get("message", {})
    print("content:", (m.get("content") or "(vuoto)")[:80])
except Exception as e:
    print("errore:", str(e)[:120])
PYEOF
echo
echo "### 2. Via PORTIERE col catalogo (pin del modello, deve trovare kilo da solo)"
curl -s -m 120 -H Content-Type:application/json -d '{"model":"nvidia/nemotron-3.5-lightning:free","messages":[{"role":"user","content":"Due piu due? Solo il numero."}]}' http://127.0.0.1:20129/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model','?'),'→',(d.get('choices') or [{}])[0].get('message',{}).get('content','')[:60] or d.get('error',{}).get('message','')[:100])"
