#!/bin/bash
cd ~/posta
pkill -f '^python3 cervello\.py$' && echo "ucciso, il guardiano risuscita col CORS"
for i in $(seq 1 15); do sleep 5; (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && { echo "risorto ~$((i*5))s"; break; }; done
curl -s -D - -o /dev/null --max-time 5 http://127.0.0.1:20129/cervello 2>/dev/null | grep -i "access-control" && echo "✓ CORS attivo" || echo "✗ niente header"
