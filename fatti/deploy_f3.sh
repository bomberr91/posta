#!/bin/bash
cd ~/posta
echo "## DEPLOY FASE 3 + RESURREZIONE — $(date '+%H:%M')"
pkill -f '^python3 cervello\.py$' && echo "vecchio ucciso" || echo "non girava"
for i in $(seq 1 15); do sleep 5; (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && { echo "risorto dopo ~$((i*5))s"; break; }; done
sleep 2
echo
echo "### Targa (deve dire FASE 3)"
curl -s -m 5 http://127.0.0.1:20129/portiere | grep -o "FASE 3" | head -1 || echo "NON TROVATA"
echo
echo "### Moduli gemelli caricati? (ping di prova + log)"
curl -s -m 10 -H Content-Type:application/json -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' http://127.0.0.1:20129/v1/chat/completions | python3 -c "import json,sys; print(json.load(sys.stdin).get('model','?'))"
python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('c','cervello.py')
c = importlib.util.module_from_spec(spec); spec.loader.exec_module(c)
print('F3_OK =', c.F3_OK)"
echo
echo "### Sentinella: primo battito (baseline)"
sleep 1
python3 -c "
import json
d = json.load(open('portiere_stato.json'))
print('sentinella:', d.get('sentinella', 'non ancora battuta (parte col primo traffico)'))" 2>/dev/null
