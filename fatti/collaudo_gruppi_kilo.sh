#!/bin/bash
cd ~/posta
B=http://127.0.0.1:20129
echo "## COLLAUDO GRUPPI + KILO — $(date '+%H:%M')"
echo
echo "### 1. Il cervello ha mangiato i gruppi da solo? (/v1/models)"
curl -s -m 15 $B/v1/models | python3 -c "import json,sys; print([m['id'] for m in json.load(sys.stdin)['data'] if m.get('owned_by')=='cervello-gruppo'])"
echo
echo "### 2. Gruppo 'forte' alla prova"
curl -s -m 120 -H Content-Type:application/json -d '{"model":"forte","max_tokens":30,"messages":[{"role":"user","content":"Dimmi solo: squadra forte presente"}]}' $B/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model','?'),'→',(d.get('choices') or [{}])[0].get('message',{}).get('content','')[:60] or d.get('error',{}).get('message','')[:100])"
echo
echo "### 3. KILO DIRETTO (lavoro n.3): il keyless dei 384 modelli parla in chat?"
python3 << 'PYEOF'
import json, urllib.request
url = ""
for r in open("portiere_lista.txt"):
    p = r.split("|")
    if p[0].strip() == "kilo":
        url = p[3].strip().rstrip("/")
        break
print("endpoint:", url or "NON TROVATO")
cat = json.load(open("portiere_catalogo.json")).get("kilo", {}).get("modelli", [])
candidati = [m for m in cat if any(x in m.lower() for x in ("gemma", "llama", "qwen", "gpt-oss"))][:3] or cat[:3]
print("candidati dal catalogo:", candidati)
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) cervello/2.1"}
for m in candidati:
    corpo = json.dumps({"model": m, "max_tokens": 30, "messages": [{"role": "user", "content": "Rispondi solo: kilo funziona"}]}).encode()
    try:
        d = json.loads(urllib.request.urlopen(urllib.request.Request(url + "/chat/completions", data=corpo, headers=UA), timeout=45).read().decode())
        testo = (d.get("choices") or [{}])[0].get("message", {}).get("content", "")
        if testo:
            print("✅ KILO RISPONDE con", m, "→", testo[:60].replace("\n", " "))
            break
        print("🟡", m, "→ 200 ma vuoto")
    except Exception as e:
        print("❌", m, "→", str(e)[:90])
PYEOF
echo
echo "### 4. Rinfresco appello (cosi i keyless buoni entrano in squadra)"
timeout 300 bash appello_chiavi.sh --svelto > /dev/null 2>&1
sleep 2
curl -s -m 10 $B/cervello | python3 -c "import json,sys; d=json.load(sys.stdin); print('riserve pronte ora:', d.get('risponde'))"
echo
echo "### 5. Politica gratis dopo il rinfresco"
curl -s -m 120 -H Content-Type:application/json -d '{"model":"gratis","max_tokens":30,"messages":[{"role":"user","content":"Capitale Italia? Una parola."}]}' $B/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model','?'),'→',(d.get('choices') or [{}])[0].get('message',{}).get('content','')[:50] or d.get('error',{}).get('message','')[:100])"
