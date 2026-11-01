#!/bin/bash
cd ~/posta
pkill -f '^python3 cervello\.py$' && echo "resurrezione con gli occhi-pagina..."
for i in $(seq 1 15); do sleep 5; (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && { echo "risorto ~$((i*5))s"; break; }; done
python3 -c "
import json
d = json.load(open('portiere_stato.json'))
d.setdefault('sentinella', {})['controllo'] = 0
json.dump(d, open('portiere_stato.json','w'))" 2>/dev/null
pkill -f '^python3 cervello\.py$'; for i in $(seq 1 15); do sleep 5; (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && break; done
curl -s -m 20 -H Content-Type:application/json -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' http://127.0.0.1:20129/v1/chat/completions > /dev/null
sleep 8
python3 -c "
import json
st = json.load(open('portiere_stato.json')).get('sentinella', {})
occhi = st.get('visti', {})
for k in sorted(occhi): print(' 👁', k, '→', occhi[k])
print('avviso:', st.get('avviso', 'nessuno (baseline presa)'))"
