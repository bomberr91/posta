@echo off
rem A COSA SERVE: crea solo la scorciatoia Desktop per avviare OpenClaw.
rem Riusa il launcher esistente apri_openclaw.sh tramite WSL Ubuntu / utente agenti.
rem Non installa, aggiorna, configura o modifica OpenClaw.
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title Crea icona OpenClaw - Windows
color 0B
set "OPENCLAW_ICON_SOURCE=%~dp0icone_agenti\openclaw.ico"

echo.
echo  ================================================================
echo    Crea l'icona OpenClaw sul Desktop
echo  ================================================================
echo.
echo    Creo solo il collegamento, con il logo ufficiale.
echo    Al clic usera' il launcher gia' presente nella Centrale.
echo    Non installo, configuro o avvio OpenClaw adesso.
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 goto NO_POWERSHELL

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $source=$env:OPENCLAW_ICON_SOURCE; if (-not (Test-Path -LiteralPath $source)) { Write-Error 'Icona OpenClaw non trovata nella cartella dell''installatore.'; exit 2 }; $wsl=Join-Path $env:WINDIR 'System32\wsl.exe'; if (-not (Test-Path $wsl)) { Write-Error 'WSL non trovato. Nessun collegamento creato.'; exit 3 }; $iconHome=Join-Path $env:LOCALAPPDATA 'AgentiDesktop\icone'; New-Item -ItemType Directory -Path $iconHome -Force | Out-Null; $icon=Join-Path $iconHome 'openclaw.ico'; Copy-Item -LiteralPath $source -Destination $icon -Force; $desktop=[Environment]::GetFolderPath('Desktop'); $shell=New-Object -ComObject WScript.Shell; $s=$shell.CreateShortcut((Join-Path $desktop 'OpenClaw.lnk')); $s.TargetPath=$wsl; $s.Arguments=('-d Ubuntu -u agenti -- bash -lc '+[char]34+'cd ~/posta && bash ./apri_openclaw.sh'+[char]34); $s.WorkingDirectory=$env:USERPROFILE; $s.IconLocation=$icon; $s.Description='Avvia OpenClaw tramite il launcher della Centrale'; $s.Save(); Write-Host 'Icona OpenClaw creata sul Desktop.'"
set "ESITO=%ERRORLEVEL%"
if not "%ESITO%"=="0" goto ERRORE

echo.
echo  ================================================================
echo    Icona OpenClaw creata. Al clic, il launcher avviera' OpenClaw.
echo    Nessuna installazione o configurazione e' stata modificata.
echo  ================================================================
echo.
pause
exit /b 0

:NO_POWERSHELL
echo PowerShell non trovato. Nessuna modifica eseguita.
echo.
pause
exit /b 2

:ERRORE
echo.
echo Non sono riuscito a creare l'icona OpenClaw.
echo Nessun dato o programma OpenClaw e' stato modificato.
echo Inviami una foto delle righe finali.
echo.
pause
exit /b %ESITO%
