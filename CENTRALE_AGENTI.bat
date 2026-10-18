@echo off
title Centrale Agenti H24 - FilippoPC
wsl.exe -d Ubuntu -u agenti -- bash -lc "cd ~/posta && git pull -q 2>/dev/null; bash ~/posta/centrale.sh"
