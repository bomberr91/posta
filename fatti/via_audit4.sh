#!/bin/bash
cd ~/posta
chmod +x lavori/audit_catena.sh
nohup bash lavori/audit_catena.sh > /dev/null 2>&1 &
echo "audit v4 lanciato (pid $!) — telaio-miniera, file su disco, niente inline"
