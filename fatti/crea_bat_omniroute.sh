#!/bin/bash
# Crea ACCENDI_OMNIROUTE.bat sul Desktop (finestra dedicata, bind sicuro)
DEST="[CHIAVE-RIMOSSA].bat"
printf '@echo off\r\ntitle OmniRoute - NON CHIUDERE QUESTA FINESTRA (riducila a icona)\r\necho Avvio OmniRoute sulla porta 20128 (il primo avvio impiega anche 2-3 minuti)...\r\nwsl bash -lc ". ~/.nvm/nvm.sh; export OMNIROUTE_SERVER_HOST=127.0.0.1; omniroute"\r\npause\r\n' > "$DEST"
ls -la "$DEST" && echo "BAT creato sul Desktop"
echo
echo "Versione OmniRoute attualmente installata:"
bash -lc ". ~/.nvm/nvm.sh >/dev/null 2>&1; omniroute --version 2>/dev/null || npm ls -g omniroute 2>/dev/null | grep omniroute || echo 'non rilevabile da qui'"
echo
echo "Il motore 20128 adesso e':"
(exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null && echo "VIVO" || echo "SPENTO"
