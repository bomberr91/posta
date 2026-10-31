#!/bin/bash
cd ~/posta
chmod +x lavori/deepopen_prova.sh
nohup bash lavori/deepopen_prova.sh > /dev/null 2>&1 &
echo "Prova DeepOpen avviata in sottofondo (pid $!). Scarica ~1GB: 20-60 minuti."
echo "A fine lavoro si committa da sola: dal_pc/deepopen_lavoro.log + deepopen_verdetto.md"
