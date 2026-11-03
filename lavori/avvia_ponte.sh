#!/bin/bash
# avvia_ponte.sh — fa partire il poller del ponte (una sola istanza: il lock protegge).
# Chiamato dalla Startup (PONTE_ARENA.vbs) e riutilizzabile a mano.
sleep 45  # regola dei 60 secondi: i servizi falliscono se partono all'istante
cd ~/posta/lavori/ponte || exit 1
if [ -e _stato/poller.lock ]; then
  echo "ponte gia' attivo"
  exit 0
fi
nohup python3 poller.py >> poller.log 2>&1 &
echo "ponte avviato (pid $!)"
