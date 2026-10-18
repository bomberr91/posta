@echo off
title Squadra Fusion (3 Agenti in Sincronia)
wsl.exe -d Ubuntu -u agenti -- bash -lc "~/posta/squadra.sh"
echo.
pause
