#!/bin/bash
cd ~/posta
pkill -f '^python3 cervello\.py$' && echo "resurrezione con la cura..."
for i in $(seq 1 15); do sleep 5; (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null && { echo "risorto ~$((i*5))s"; break; }; done
curl -s -m 10 http://127.0.0.1:20129/portiere | grep -o "FASE 3" | head -1
curl -s -m 10 -H Content-Type:application/json -d '{"model":"gemini-2.5-pro","messages":[{"role":"user","content":"x"}]}' http://127.0.0.1:20129/v1/chat/completions | head -c 120
echo
curl -s -m 15 -H Content-Type:application/json -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' http://127.0.0.1:20129/v1/chat/completions | python3 -c "import json,sys; print(json.load(sys.stdin).get('model','?'))"
