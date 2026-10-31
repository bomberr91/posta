#!/bin/bash
cd ~/posta
B=http://127.0.0.1:20129
echo "## COLLAUDO FASE 2·B3 SUL PC — $(date '+%H:%M')"
echo
echo "### 1. Versione"
curl -s -m 5 $B/portiere | grep -o "FASE 2·B3" | head -1 || echo "NON TROVATA!"
echo
echo "### 2. 'migliore' col motore vivo → deve viaggiare su auto/best-reasoning"
curl -s -m 120 -H Content-Type:application/json -d '{"model":"migliore","max_tokens":40,"messages":[{"role":"user","content":"Due parole: come stai?"}]}' $B/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model','?'),'→',(d.get('choices') or [{}])[0].get('message',{}).get('content','')[:60] or d.get('error',{}).get('message','')[:100])" 2>&1
grep '"rotta": "motore-mappato"' portiere_log.jsonl | tail -1
echo
echo "### 3. PRIMA SCOPERTA VERA DEL PORTACHIAVI (--scopri, zero token)"
timeout 600 python3 cervello.py --scopri 2>&1 | tail -25
echo
echo "### 4. Peso del catalogo"
ls -la portiere_catalogo.json 2>/dev/null
python3 -c "
import json
c = json.load(open('portiere_catalogo.json'))
print('provider nel catalogo:', len(c), '· modelli totali:', sum(len(v.get('modelli',[])) for v in c.values()))" 2>&1
