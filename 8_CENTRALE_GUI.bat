@echo off
title Centrale GUI
powershell -WindowStyle Hidden -Command "Start-Process wsl.exe -ArgumentList '-d','Ubuntu','-u','agenti','--','bash','-lc','cd ~/posta; git fetch -q origin main 2>/dev/null; git reset -q --hard origin/main 2>/dev/null; pkill -f gui/server.py 2>/dev/null; exec python3 gui/server.py' -WindowStyle Hidden"
timeout /t 4 /nobreak >nul
start "" "http://localhost:20200"
