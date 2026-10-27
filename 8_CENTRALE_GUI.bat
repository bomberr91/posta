@echo off
title Free LLM Hub 1277fef
powershell -WindowStyle Hidden -Command "Start-Process wsl.exe -ArgumentList '-d','Ubuntu','-u','agenti','--','bash','-lc','exec bash ~/posta/apri_free_llm_hub.sh' -WindowStyle Hidden"
