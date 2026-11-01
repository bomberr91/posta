#!/bin/bash
cd ~/posta
chmod +x lavori/cura_catena.sh
nohup bash lavori/cura_catena.sh > /dev/null 2>&1 &
echo "🚑 CURA in sottofondo (pid $!): 2 lotti + revisore, ~10-15 min"
