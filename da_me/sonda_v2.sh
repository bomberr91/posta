#!/bin/bash
cd ~/posta
echo "## SONDA v2 (User-Agent civile + keyless bussati) — $(date '+%H:%M')"
timeout 400 python3 cervello.py --sonda 2>&1
