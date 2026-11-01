#!/bin/bash
cd ~/posta
pkill -f '^python3 cervello\.py$' && echo "resurrezione col json ricco..."
for i in $(seq 1 15); do sleep 5; (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && { echo "risorto ~$((i*5))s"; break; }; done
curl -s -m 10 http://127.0.0.1:20129/portiere.json | python3 -c "
import json,sys
d = json.load(sys.stdin)
print('campi nuovi:', [k for k in ('pagelle','castighi','uso_oggi','sentinella_avviso') if k in d])
print('pagelle presenti:', len(d.get('pagelle', {})), '· castighi attivi:', len(d.get('castighi', {})))"
