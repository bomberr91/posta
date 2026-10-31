#!/bin/bash
cd ~/posta
B=http://127.0.0.1:20129
echo "## COLLAUDO FASE 2·B1 SUL PC — $(date '+%H:%M')"
echo
echo "### 1. Versione (deve dire FASE 2·B1)"
curl -s -m 5 $B/portiere | grep -o "FASE 2·B1" | head -1 || echo "NON TROVATA!"
echo
echo "### 2. Ping in casa (0 token)"
curl -s -m 10 -H Content-Type:application/json -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' $B/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model'))" 2>&1
echo
echo "### 3. Una richiesta vera piccola (nutre la pagella)"
curl -s -m 120 -H Content-Type:application/json -d '{"model":"auto","max_tokens":30,"messages":[{"role":"user","content":"Rispondi con una parola sola: pronto"}]}' $B/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model'),'→',(d.get('choices') or [{}])[0].get('message',{}).get('content','')[:60])" 2>&1
echo
echo "### 4. Pagella e velocità osservate"
python3 -c "
import json
try:
    d = json.load(open('portiere_stato.json'))
    print('castighi attivi:', len(d.get('castighi',{})))
    for pid, p in list(d.get('pagella',{}).items())[:8]:
        print('  %s: %dok/%dko' % (pid, p.get('ok',0), p.get('ko',0)) + (' · ~%dms' % p['ms_ewma'] if p.get('ms_ewma') is not None else ''))
except FileNotFoundError:
    print('stato non ancora creato (normale: nessuna richiesta di riserva ancora)')" 2>&1
echo
echo "### 5. Glass-box: ultime 5 righe"
tail -5 portiere_log.jsonl 2>/dev/null || echo "(vuoto)"
