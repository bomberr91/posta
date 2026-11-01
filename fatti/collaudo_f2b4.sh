#!/bin/bash
cd ~/posta
B=http://127.0.0.1:20129
echo "## COLLAUDO FINALE FASE 2·B4 + IDEA 64 — $(date '+%H:%M')"
echo
echo "### 1. Versione"
curl -s -m 5 $B/portiere | grep -o "FASE 2·B4" | head -1 || echo "NON TROVATA!"
echo
echo "### 2. CACHE dal vivo (stessa domanda 2 volte)"
Q='{"model":"auto","max_tokens":30,"messages":[{"role":"user","content":"Quante zampe ha un ragno? Solo il numero."}]}'
curl -s -m 60 -H Content-Type:application/json -d "$Q" $B/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print('1ª:', d.get('model','?'))" 2>&1
sleep 2
curl -s -m 60 -H Content-Type:application/json -d "$Q" $B/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print('2ª:', d.get('model','?'), '← deve dire (cache)')" 2>&1
echo
echo "### 3. IDEA 64 — LA COMPRESSIONE RTK DEL MOTORE LAVORA?"
python3 << 'PYEOF'
import json, os, urllib.request
# prompt gonfio e ripetitivo: ~8000 caratteri = ~2000 token se NON compresso
zavorra = ("Il gatto dorme sul tappeto rosso del salotto grande. " * 150)
corpo = json.dumps({"model": "auto", "max_tokens": 20, "messages": [
    {"role": "user", "content": zavorra + " DOMANDA: di che colore e il tappeto? Una parola."}]}).encode()
req = urllib.request.Request("http://127.0.0.1:20128/v1/chat/completions", data=corpo,
    headers={"Content-Type": "application/json",
             "Authorization": "Bearer " + os.environ.get("OMNIROUTE_API_KEY", "")})
try:
    d = json.loads(urllib.request.urlopen(req, timeout=120).read().decode())
    u = d.get("usage") or {}
    stima = len(zavorra) // 4
    visti = u.get("prompt_tokens")
    print("caratteri zavorra:", len(zavorra), "→ stima SENZA compressione: ~%d token" % stima)
    print("prompt_tokens VISTI dal provider:", visti, "· modello:", d.get("model", "?"))
    if visti and visti < stima * 0.6:
        print("VERDETTO IDEA 64: ✅ COMPRESSIONE ATTIVA (risparmio ~%d%%)" % round(100 - 100 * visti / stima))
    elif visti:
        print("VERDETTO IDEA 64: ❌ compressione NON rilevata (token pieni)")
    else:
        print("VERDETTO IDEA 64: ⚠ usage non riportato dal provider — prova non conclusiva")
except Exception as e:
    print("prova fallita:", str(e)[:200])
PYEOF
echo
echo "### 4. Statistiche del Portiere"
python3 cervello.py --statistiche 2>&1 | head -20
