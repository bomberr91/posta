#!/bin/bash
cd ~/posta
chmod +x lavori/miniera_catena.sh
nohup bash lavori/miniera_catena.sh > /dev/null 2>&1 &
echo "⛏️ CATENA MINIERA AVVIATA (pid $!): 4 operai + revisore, guardia anti-collisione attiva."
echo "Si committa blocco per blocco. Stima: 30-60 min totali."
