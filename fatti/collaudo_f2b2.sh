#!/bin/bash
cd ~/posta
B=http://127.0.0.1:20129
echo "## COLLAUDO FASE 2·B2 SUL PC — $(date '+%H:%M')"
echo
echo "### 1. Versione (deve dire FASE 2·B2)"
curl -s -m 5 $B/portiere | grep -o "FASE 2·B2" | head -1 || echo "NON TROVATA!"
echo
echo "### 2. Casella 'riserva oggi'"
curl -s -m 5 $B/portiere | grep -o "riserva oggi" | head -1 || echo "MANCA!"
echo
echo "### 3. Politica GRATIS dal vivo (dritta in riserva, nutre la pagella)"
curl -s -m 90 -H Content-Type:application/json -d '{"model":"gratis","max_tokens":40,"messages":[{"role":"user","content":"Di che colore e il cielo? Rispondi in 3 parole."}]}' $B/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model','?'),'→',(d.get('choices') or [{}])[0].get('message',{}).get('content','')[:80] or d.get('error',{}).get('message','')[:120])" 2>&1
sleep 3
curl -s -m 90 -H Content-Type:application/json -d '{"model":"gratis","max_tokens":40,"messages":[{"role":"user","content":"Conta da 1 a 3."}]}' $B/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model','?'),'→',(d.get('choices') or [{}])[0].get('message',{}).get('content','')[:80] or d.get('error',{}).get('message','')[:120])" 2>&1
sleep 4
echo
echo "### 4. Pagella, velocità e consumi NUTRITI"
python3 -c "
import json
try:
    d = json.load(open('portiere_stato.json'))
    for pid, p in d.get('pagella',{}).items():
        print('  pagella %s: %dok/%dko' % (pid, p.get('ok',0), p.get('ko',0)) + (' · ~%dms' % p['ms_ewma'] if p.get('ms_ewma') is not None else ''))
    for pid, u in d.get('uso',{}).items():
        print('  uso %s: %d richieste · %d token (%s)' % (pid, u.get('n',0), u.get('token',0), u.get('giorno','')))
    print('  agenti censiti:', len(d.get('agenti',{})))
    print('  castighi attivi:', len(d.get('castighi',{})))
except FileNotFoundError:
    print('  stato ancora vuoto')" 2>&1
echo
echo "### 5. Glass-box: ultime 6"
tail -6 portiere_log.jsonl 2>/dev/null
