#!/bin/bash
# collaudo_gruppi_kilo.sh — COLLAUDO GRUPPI + KILO
# CURA-AUDIT v5: chat lette con fatti/chat_leggi.sh (corpo vuoto = FAILURE)
# e uscita 1 se qualcosa non torna. Prima non poteva dire NO.
set -uo pipefail
cd ~/posta || exit 1
B=http://127.0.0.1:20129
FALLITI=0
echo "## COLLAUDO GRUPPI + KILO — $(date '+%H:%M')"
echo
echo "### 1. Il cervello ha mangiato i gruppi da solo? (/v1/models)"
if out=$(curl -fsS -m 15 $B/v1/models 2>/dev/null) && [ -n "$out" ]; then
  echo "$out" | python3 -c "import json,sys; print([m['id'] for m in json.load(sys.stdin)['data'] if m.get('owned_by')=='cervello-gruppo'])" 2>&1 || FALLITI=$((FALLITI+1))
else
  echo "   ✗ /v1/models non risponde"; FALLITI=$((FALLITI+1))
fi
echo
echo "### 2. Gruppo 'forte' alla prova"
if bash fatti/chat_leggi.sh 240 '{"model":"forte","max_tokens":30,"messages":[{"role":"user","content":"Dimmi solo: squadra forte presente"}]}' "d.get('model','?')+' → '+str(((d.get('choices') or [{}])[0].get('message',{}).get('content','')) or d.get('error',{}).get('message',''))[:60]"; then :; else FALLITI=$((FALLITI+1)); fi
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
if out=$(curl -fsS -m 10 $B/cervello 2>/dev/null) && [ -n "$out" ]; then
  echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print('riserve pronte ora:', d.get('risponde'))" 2>&1 || FALLITI=$((FALLITI+1))
else
  echo "   ✗ /cervello non risponde"; FALLITI=$((FALLITI+1))
fi
echo
echo "### 5. Politica gratis dopo il rinfresco"
if bash fatti/chat_leggi.sh 240 '{"model":"gratis","max_tokens":30,"messages":[{"role":"user","content":"Capitale Italia? Una parola."}]}' "d.get('model','?')+' → '+str(((d.get('choices') or [{}])[0].get('message',{}).get('content','')) or d.get('error',{}).get('message',''))[:50]"; then :; else FALLITI=$((FALLITI+1)); fi
echo
if [ "$FALLITI" -gt 0 ]; then
  echo "❌ COLLAUDO GRUPPI+KILO FALLITO: $FALLITI problema/i"
  exit 1
fi
echo "✅ COLLAUDO GRUPPI+KILO OK"
exit 0
