@echo off
rem A COSA SERVE: installa OpenCode CLI nativo Windows solo se manca; non configura o modifica altri agenti.
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title Installa OpenCode - Windows nativo
color 0B
pushd "%~dp0" >nul 2>&1

echo.
echo  ================================================================
echo    OpenCode CLI - controllo e installazione Windows
echo  ================================================================
echo.
echo    Controllo prima se OpenCode e' gia presente.
echo    Se c'e', non lo reinstallo e verifico solo la versione.
echo    Se manca, uso il pacchetto npm ufficiale opencode-ai.
echo    Non configuro login, provider, chiavi o altri agenti.
echo    OpenClaw resta escluso e intatto.
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 goto NO_POWERSHELL

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $present=Get-Command opencode -ErrorAction SilentlyContinue; if ($present) { Write-Host ('OpenCode gia presente: '+$present.Source); & $present.Source --version; if ($LASTEXITCODE -ne 0) { exit 4 }; exit 10 }; $npm=Get-Command npm -ErrorAction SilentlyContinue; if (-not $npm) { Write-Error 'Node.js e npm non sono disponibili nel PATH Windows. Nessuna installazione eseguita.'; exit 2 }; $prefix=(& $npm.Source prefix -g); if ($LASTEXITCODE -ne 0) { exit 3 }; $env:Path=($prefix.Trim()+';'+$env:Path); $present=Get-Command opencode -ErrorAction SilentlyContinue; if ($present) { Write-Host ('OpenCode gia presente nel percorso npm globale: '+$present.Source); & $present.Source --version; if ($LASTEXITCODE -ne 0) { exit 4 }; exit 10 }; Write-Host 'OpenCode non trovato. Installo il pacchetto ufficiale opencode-ai...'; & $npm.Source install -g opencode-ai; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; $installed=Get-Command opencode -ErrorAction SilentlyContinue; if (-not $installed) { Write-Error 'Installazione terminata ma il comando non e'' nel PATH. Apri una nuova finestra PowerShell.'; exit 5 }; Write-Host ('OpenCode installato: '+$installed.Source); & $installed.Source --version; if ($LASTEXITCODE -ne 0) { exit 6 }"
set "ESITO=%ERRORLEVEL%"
if "%ESITO%"=="10" goto GIA_PRESENTE
if not "%ESITO%"=="0" goto ERRORE

echo.
echo  ================================================================
echo    OpenCode CLI installato e versione verificata.
echo    Non ho configurato provider o login.
echo    Gli altri agenti e OpenClaw non sono stati toccati.
echo  ================================================================
echo.
pause
exit /b 0

:GIA_PRESENTE
echo.
echo OpenCode era gia installato: non ho reinstallato o cambiato la configurazione.
echo Gli altri agenti e OpenClaw non sono stati toccati.
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
echo OpenCode non e' stato verificato. Nessun altro agente e' stato modificato.
echo Manda una foto delle righe finali, senza chiavi o token.
echo.
pause
exit /b %ESITO%
