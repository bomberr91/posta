#!/bin/bash
# Collaudo FASE 1 dal vivo sul PC
cd ~/posta
B=http://127.0.0.1:20129
echo "## COLLAUDO FASE 1 SUL PC — $(date '+%H:%M')"
echo
echo "### 1. Versione in esecuzione (deve dire FASE 1)"
curl -s -m 5 $B/portiere | grep -o "FASE 1" | head -1 || echo "NON trovata la scritta FASE 1!"
echo
echo "### 2. Politiche in /v1/models (devono esserci auto/gratis/veloce/migliore)"
curl -s -m 10 $B/v1/models | python3 -c "import json,sys; d=json.load(sys.stdin); print([m['id'] for m in d['data'][:6]])" 2>&1
echo
echo "### 3. Ping risposto in casa (deve dire cervello/locale, 0 token)"
curl -s -m 10 -H Content-Type:application/json -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' $B/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model'),'→',d['choices'][0]['message']['content'])" 2>&1
echo
echo "### 4. Guardia solo-gratis (gpt-5 deve essere rifiutato)"
curl -s -m 10 -H Content-Type:application/json -d '{"model":"gpt-5","messages":[{"role":"user","content":"x"}]}' $B/v1/chat/completions | head -c 150
echo; echo
echo "### 5. Sonda credenziali (zero token)"
timeout 300 python3 cervello.py --sonda 2>&1
echo
echo "### 6. Glass-box: ultime righe del log"
tail -5 portiere_log.jsonl 2>/dev/null || echo "(log ancora vuoto: normale se nessuna richiesta vera è passata)"
