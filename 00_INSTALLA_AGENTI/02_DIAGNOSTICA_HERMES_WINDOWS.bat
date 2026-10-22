@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title Verifica Hermes Windows
color 0B
pushd "%~dp0" >nul 2>&1

echo.
echo  ================================================================
echo    Diagnostica Hermes - sola lettura, nessuna installazione
echo  ================================================================
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 goto NO_POWERSHELL

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$machine=[Environment]::GetEnvironmentVariable('Path','Machine'); $user=[Environment]::GetEnvironmentVariable('Path','User'); $env:Path=$machine+';'+$user; $cmd=Get-Command hermes -ErrorAction SilentlyContinue; if ($cmd) { Write-Host ('COMANDO: '+$cmd.Source); & $cmd.Source --version; Write-Host ('CODICE VERSIONE: '+$LASTEXITCODE) } else { Write-Host 'COMANDO HERMES: non trovato nel PATH Windows' }; $home=Join-Path $env:LOCALAPPDATA 'hermes'; $repo=Join-Path $home 'hermes-agent'; $marker=Join-Path $repo '.hermes-bootstrap-complete'; Write-Host ('CARTELLA HERMES: '+$home); Write-Host ('CHECKOUT: '+(Test-Path -LiteralPath $repo)); Write-Host ('INSTALLAZIONE COMPLETA: '+(Test-Path -LiteralPath $marker)); $log=Join-Path $home 'logs\install.log'; if (Test-Path -LiteralPath $log) { Write-Host ('LOG: '+$log); Write-Host '--- ULTIME 35 RIGHE LOG ---'; Get-Content -LiteralPath $log -Tail 35 } else { Write-Host ('LOG INSTALLER: non trovato ('+$log+')') }"
set "ESITO=%ERRORLEVEL%"
echo.
echo Fine controllo. Manda una foto di questa schermata senza chiavi o token.
echo.
pause
exit /b %ESITO%

:NO_POWERSHELL
echo PowerShell non trovato. Nessuna modifica eseguita.
echo.
pause
exit /b 2
