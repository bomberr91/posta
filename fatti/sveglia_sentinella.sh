#!/bin/bash
cd ~/posta
echo "## SVEGLIA SENTINELLA (battito forzato) — $(date '+%H:%M')"
python3 -c "
import json
d = json.load(open('portiere_stato.json'))
d.setdefault('sentinella', {})['controllo'] = 0
json.dump(d, open('portiere_stato.json','w'))
print('orologio azzerato')"
pkill -f '^python3 cervello\.py$' && echo "cervello ucciso (rilegge lo stato alla resurrezione)"
for i in $(seq 1 15); do sleep 5; (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && { echo "risorto ~$((i*5))s"; break; }; done
sleep 2
# CURA-AUDIT v5: uccidere il cervello e poi NON verificare = lasciare il PC
# morto senza dirlo. Il collaudo condiviso dice NO se non è tornato.
bash fatti/collaudo_cervello.sh || { echo "❌ il cervello NON è tornato (o non risponde)"; exit 1; }
sleep 8
echo "### I due occhi"
python3 -c "
import json
st = json.load(open('portiere_stato.json')).get('sentinella', {})
v = st.get('visti', {})
for r, p in v.items(): print(' 👁', r, '→ baseline push', p)
print('occhi attivi:', len(v), '· avviso:', st.get('avviso', 'nessuno (baseline, giusto cosi)'))" \
  || { echo "❌ lo stato della sentinella non si legge"; exit 1; }
echo "✅ SVEGLIA RIUSCITA"
