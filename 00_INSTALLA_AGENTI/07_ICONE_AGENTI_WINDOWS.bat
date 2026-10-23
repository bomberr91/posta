@echo off
rem A COSA SERVE: crea/aggiorna le icone Desktop per Hermes, OpenCode,
rem Secondhand e Antigravity usando i loghi inclusi. Goose e OpenClaw restano intatti.
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title Crea icone agenti - Windows
color 0B
set "AGENT_ICONS_SOURCE=%~dp0icone_agenti"

echo.
echo  ================================================================
echo    Icone Desktop agenti Windows
echo  ================================================================
echo.
echo    Creo o aggiorno Hermes, OpenCode, Secondhand e Antigravity.
echo    Uso i loghi inclusi; non installo, configuro o avvio agenti.
echo    L'icona Goose resta com'e'. OpenClaw non viene toccato.
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 goto NO_POWERSHELL

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $src=$env:AGENT_ICONS_SOURCE; $names=@('hermes.ico','opencode.ico','secondhand.ico','antigravity.ico'); foreach ($n in $names) { if (-not (Test-Path (Join-Path $src $n))) { throw ('File icona mancante: '+$n) } }; $iconHome=Join-Path $env:LOCALAPPDATA 'AgentiDesktop\icone'; New-Item -ItemType Directory -Path $iconHome -Force | Out-Null; foreach ($n in $names) { Copy-Item -LiteralPath (Join-Path $src $n) -Destination (Join-Path $iconHome $n) -Force }; $machine=[Environment]::GetEnvironmentVariable('Path','Machine'); $user=[Environment]::GetEnvironmentVariable('Path','User'); $env:Path=$machine+';'+$user+';'+$env:Path; $desktop=[Environment]::GetFolderPath('Desktop'); $shell=New-Object -ComObject WScript.Shell; function New-AgentShortcut([string]$name,[string]$target,[string]$arguments,[string]$icon) { $s=$shell.CreateShortcut((Join-Path $desktop ($name+'.lnk'))); $s.TargetPath=$target; if ($arguments) { $s.Arguments=$arguments }; $s.WorkingDirectory=$env:USERPROFILE; $s.IconLocation=$icon; $s.Description=$name; $s.Save(); Write-Host ('Creato/aggiornato: '+$name) }; $hermes=Join-Path $env:LOCALAPPDATA 'hermes\bin\hermes.exe'; if (-not (Test-Path $hermes)) { $h=Get-Command hermes -ErrorAction SilentlyContinue; if ($h -and $h.Source) { $hermes=$h.Source } }; if (Test-Path $hermes) { New-AgentShortcut 'Hermes' $hermes '' (Join-Path $iconHome 'hermes.ico') } else { Write-Host 'Hermes: non trovato, icona saltata.' }; $oc=Get-Command opencode -ErrorAction SilentlyContinue; if (-not $oc) { $ocPath=Join-Path $env:APPDATA 'npm\opencode.cmd'; if (Test-Path $ocPath) { $oc=[pscustomobject]@{Source=$ocPath} } }; if ($oc) { New-AgentShortcut 'OpenCode' (Join-Path $PSHOME 'powershell.exe') '-NoLogo -NoExit -Command opencode' (Join-Path $iconHome 'opencode.ico') } else { Write-Host 'OpenCode: non trovato, icona saltata.' }; $oi=Join-Path $env:LOCALAPPDATA 'Programs\Open Interpreter\bin\interpreter.exe'; if (-not (Test-Path $oi)) { $i=Get-Command interpreter -ErrorAction SilentlyContinue; if ($i -and $i.Source) { $oi=$i.Source } }; if (Test-Path $oi) { New-AgentShortcut 'Secondhand' $oi '' (Join-Path $iconHome 'secondhand.ico') } else { Write-Host 'Secondhand: non trovato, icona saltata.' }; $agy=Join-Path $env:LOCALAPPDATA 'agy\bin\agy.exe'; if (Test-Path $agy) { New-AgentShortcut 'Antigravity CLI' $agy '' (Join-Path $iconHome 'antigravity.ico') } else { Write-Host 'Antigravity CLI: non trovato, icona saltata.' }"
set "ESITO=%ERRORLEVEL%"
if not "%ESITO%"=="0" goto ERRORE

echo.
echo  ================================================================
echo    Icone pronte. Se non si aggiornano subito, premi F5 sul Desktop.
echo    Goose e OpenClaw non sono stati modificati.
echo  ================================================================
echo.
pause
exit /b 0

:NO_POWERSHELL
echo PowerShell non trovato. Nessuna icona modificata.
echo.
pause
exit /b 2

:ERRORE
echo.
echo Non sono riuscito a completare tutte le icone.
echo Nessun agente e' stato installato o avviato.
echo Inviami una foto delle righe finali.
echo.
pause
exit /b %ESITO%
