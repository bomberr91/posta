@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title Installa Hermes - Windows nativo
color 0B
pushd "%~dp0" >nul 2>&1

rem Hermes nativo Windows e' la via ufficiale per evitare il Node Linux che
rem fallisce nel WSL attuale. Nessun comando o file di OpenClaw viene toccato.
set "INSTALLER=%TEMP%\hermes-install-%RANDOM%-%RANDOM%.ps1"
set "HERMES_INSTALLER_PATH=%INSTALLER%"

echo.
echo  ================================================================
echo    Hermes Agent - installazione ufficiale Windows
echo  ================================================================
echo.
echo    Installo solo Hermes, in Windows nativo.
echo    OpenClaw non viene reinstallato, modificato o rimosso.
echo    Browser e computer-use opzionali sono esclusi per ora.
echo    Non inserire chiavi: questa fase non configura il modello.
echo    Attendi il completamento; puo' richiedere alcuni minuti.
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 goto NO_POWERSHELL

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri 'https://hermes-agent.nousresearch.com/install.ps1' -OutFile $env:HERMES_INSTALLER_PATH; if ((Get-Content -LiteralPath $env:HERMES_INSTALLER_PATH -TotalCount 1) -notmatch '^# Hermes Agent bootstrap:') { throw 'Il file scaricato non corrisponde al formato ufficiale Hermes.' }"
if errorlevel 1 goto DOWNLOAD_ERROR

echo Avvio l'installer ufficiale Hermes (solo Windows)...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%" -NonInteractive -SkipBrowser -SkipComputerUse -Verbose
set "ESITO=%ERRORLEVEL%"
if not "%ESITO%"=="0" goto INSTALL_ERROR

rem Ricarica il PATH utente aggiornato dall'installer e verifica il comando.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$machine=[Environment]::GetEnvironmentVariable('Path','Machine'); $user=[Environment]::GetEnvironmentVariable('Path','User'); $env:Path=$machine+';'+$user; $cmd=Get-Command hermes -ErrorAction SilentlyContinue; if (-not $cmd) { Write-Error 'Installazione completata ma hermes non compare nel PATH utente.'; exit 1 }; & $cmd.Source --version; if ($LASTEXITCODE -ne 0) { exit 1 }"
set "ESITO=%ERRORLEVEL%"
del /q "%INSTALLER%" >nul 2>&1
if not "%ESITO%"=="0" goto VERIFY_ERROR

echo.
echo  ================================================================
echo    Hermes Windows installato e comando verificato.
echo    OpenClaw non e' stato toccato.
echo    Prossimo passo: collegare Hermes nativo alla Centrale.
echo  ================================================================
echo.
pause
exit /b 0

:NO_POWERSHELL
echo PowerShell non trovato: non ho installato o modificato nulla.
echo.
pause
exit /b 2

:DOWNLOAD_ERROR
del /q "%INSTALLER%" >nul 2>&1
echo Download o verifica dell'installer ufficiale non riusciti.
echo Nessuna installazione e' stata avviata. Controlla la connessione e riprova.
echo.
pause
exit /b 3

:INSTALL_ERROR
del /q "%INSTALLER%" >nul 2>&1
echo L'installer ufficiale ha segnalato un errore. Hermes non e' verificato.
echo Invia una foto del messaggio e il log, senza chiavi o token.
echo Log Hermes: %LOCALAPPDATA%\hermes\logs\install.log
echo.
pause
exit /b %ESITO%

:VERIFY_ERROR
echo Hermes non e' stato trovato o non ha superato il controllo versione.
echo Non rilanciare l'installer WSL: mandami l'output di questa schermata.
echo OpenClaw non e' stato toccato.
echo.
pause
exit /b %ESITO%
