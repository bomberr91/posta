@echo off
title Centrale Posta - Router Hub
powershell -WindowStyle Hidden -Command "Start-Process wsl.exe -ArgumentList '-d','Ubuntu','-u','agenti','--','bash','-lc','exec python3 ~/posta/gui/server.py' -WindowStyle Hidden"
timeout /t 4 /nobreak >nul
start "" "http://localhost:20200"
