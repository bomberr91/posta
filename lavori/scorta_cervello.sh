#!/bin/bash
sleep 15
while true; do
  flock -n /tmp/cervello.lk bash -c 'cd ~/posta; python3 cervello.py'
  sleep 60
done
