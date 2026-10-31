#!/bin/bash
cd ~/posta
chmod +x lavori/setaccio_vena.sh
nohup bash lavori/setaccio_vena.sh > /dev/null 2>&1 &
echo "Setaccio avviato in sottofondo (pid $!): sonda ~10 min, poi schede quando DeepOpen libera l'operaio."
