#!/bin/bash
sleep 25
while true; do
  flock -n /tmp/omni.lk bash -c '. ~/.nvm/nvm.sh; OMNIROUTE_SERVER_HOST=127.0.0.1 omniroute'
  sleep 120
done
