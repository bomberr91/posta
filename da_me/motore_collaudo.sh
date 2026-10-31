#!/bin/bash
cd ~/posta
K="sk-be311327ce941004-4df42c-cf76ba39"
M=http://127.0.0.1:20128
echo "## COLLAUDO MOTORE NUOVO (3.8.52) — $(date '+%H:%M')"
echo
echo "### 1. Porta 20128"
(exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null && echo "🟢 vivo" || { echo "🔴 SPENTO — mi fermo qui"; exit 0; }
echo
echo "### 2. Catalogo modelli (quanti ne espone)"
curl -s -m 20 -H "Authorization: Bearer $K" $M/v1/models | python3 -c "
import json,sys
try:
    d = json.load(sys.stdin)
    print('modelli esposti:', len(d.get('data',[])))
    print('primi 5:', [m.get('id','?') for m in d.get('data',[])[:5]])
except Exception as e:
    print('risposta non-JSON o vuota:', e)" 2>&1
echo
echo "### 3. Prova vera dal PORTIERE (auto → deve passare dal motore)"
curl -s -m 120 -H Content-Type:application/json -d '{"model":"auto","max_tokens":30,"messages":[{"role":"user","content":"Scrivi solo: motore nuovo funzionante"}]}' http://127.0.0.1:20129/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model','?'),'→',(d.get('choices') or [{}])[0].get('message',{}).get('content','')[:70] or d.get('error',{}).get('message','')[:120])" 2>&1
echo
echo "### 4. Il Portiere che dice? (/cervello)"
curl -s -m 10 http://127.0.0.1:20129/cervello | python3 -c "import json,sys; d=json.load(sys.stdin); print('motore:', d.get('motore'), '· adesso risponde:', d.get('adesso'))" 2>&1
