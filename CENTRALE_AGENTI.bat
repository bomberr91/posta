@echo off
title Centrale Agenti H24 - FilippoPC
echo Avvio Centrale Agenti H24 su FilippoPC...

REM Se lanciato da Downloads, copia automaticamente CENTRALE_AGENTI.bat sul Desktop e pulisce le vecchie icone
for %%D in ("%USERPROFILE%\Desktop" "%USERPROFILE%\OneDrive\Desktop") do (
  if exist "%%~D" (
    copy /Y "%~f0" "%%~D\CENTRALE_AGENTI.bat" >nul 2>&1
    del /F /Q "%%~D\BROWSER_AGENTI.bat" "%%~D\SQUADRA_FUSION.bat" "%%~D\AGGIORNA_TUTTO_PC.bat" "%%~D\APRI_AGENTE.lnk" "%%~D\AVVIA_POSTINO.lnk" "%%~D\COMPITI.lnk" >nul 2>&1
  )
)

wsl.exe -d Ubuntu2 -u agenti -- bash -lc "bash ~/posta/avvio_centrale.sh"
echo.
echo La Centrale si e' chiusa. Premi un tasto per uscire...
pause >nul
