#!/bin/bash
cd ~/posta
echo "## DEPLOY SENTINELLA 2 OCCHI — $(date '+%H:%M')"
pkill -f '^python3 cervello\.py$' && echo "ucciso" || echo "non girava"
for i in $(seq 1 15); do sleep 5; (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && { echo "risorto ~$((i*5))s"; break; }; done
sleep 2
curl -s -m 10 -H Content-Type:application/json -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' http://127.0.0.1:20129/v1/chat/completions > /dev/null
sleep 3
echo "### Stato sentinella (deve avere 2 repo in 'visti')"
python3 -c "
import json
st = json.load(open('portiere_stato.json')).get('sentinella', {})
print('visti:', json.dumps(st.get('visti', {}), indent=1))
print('avviso attivo:', st.get('avviso', 'nessuno (normale: baseline)'))"
