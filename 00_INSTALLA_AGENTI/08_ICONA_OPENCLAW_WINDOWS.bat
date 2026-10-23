@echo off
rem A COSA SERVE: crea solo una scorciatoia Desktop verso OpenClaw installato su Windows.
rem Non usa WSL e non installa, aggiorna o modifica OpenClaw.
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title Crea icona OpenClaw Windows
color 0B
set "OPENCLAW_ICON_SOURCE=%~dp0icone_agenti\openclaw.ico"

echo.
echo  ================================================================
echo    Crea l'icona OpenClaw Windows sul Desktop
echo  ================================================================
echo.
echo    Cerco il comando OpenClaw gia' installato su Windows.
echo    Creo un collegamento con il logo ufficiale.
echo    Non uso WSL e non modifico installazione, configurazione o dati.
echo    Non avvio OpenClaw durante questa operazione.
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 goto NO_POWERSHELL

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $source=$env:OPENCLAW_ICON_SOURCE; if (-not (Test-Path -LiteralPath $source)) { Write-Error 'Icona OpenClaw non trovata nella cartella dell''installatore.'; exit 2 }; $machine=[Environment]::GetEnvironmentVariable('Path','Machine'); $user=[Environment]::GetEnvironmentVariable('Path','User'); $env:Path=$machine+';'+$user+';'+$env:Path; $target=$null; $app=Get-Command openclaw -CommandType Application -ErrorAction SilentlyContinue; if ($app -and $app.Source) { $target=$app.Source }; if (-not $target) { $candidate=Join-Path $env:APPDATA 'npm\openclaw.cmd'; if (Test-Path $candidate) { $target=$candidate } }; if (-not $target) { $candidate=Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Programs\openclaw*\openclaw.exe') -File -ErrorAction SilentlyContinue | Select-Object -First 1; if ($candidate) { $target=$candidate.FullName } }; if (-not $target) { Write-Error 'Non trovo il comando OpenClaw nativo Windows. Nessun collegamento creato; WSL non verra'' usato.'; exit 4 }; $iconHome=Join-Path $env:LOCALAPPDATA 'AgentiDesktop\icone'; New-Item -ItemType Directory -Path $iconHome -Force | Out-Null; $icon=Join-Path $iconHome 'openclaw.ico'; Copy-Item -LiteralPath $source -Destination $icon -Force; $desktop=[Environment]::GetFolderPath('Desktop'); $shell=New-Object -ComObject WScript.Shell; $s=$shell.CreateShortcut((Join-Path $desktop 'OpenClaw.lnk')); if ([IO.Path]::GetExtension($target).ToLowerInvariant() -in @('.cmd','.bat','.ps1')) { $ps=Join-Path $PSHOME 'powershell.exe'; $q=[string][char]39; $escaped=$target.Replace($q,$q+$q); $command='& '+$q+$escaped+$q; $s.TargetPath=$ps; $s.Arguments=('-NoLogo -NoExit -Command '+[char]34+$command+[char]34) } else { $s.TargetPath=$target }; $s.WorkingDirectory=$env:USERPROFILE; $s.IconLocation=$icon; $s.Description='Avvia OpenClaw installato su Windows'; $s.Save(); Write-Host ('Icona OpenClaw creata per: '+$target)"
set "ESITO=%ERRORLEVEL%"
if not "%ESITO%"=="0" goto ERRORE

echo.
echo  ================================================================
echo    Icona OpenClaw Windows creata sul Desktop.
echo    Non ho avviato o modificato l'agente.
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
echo Non sono riuscito a creare l'icona OpenClaw Windows.
echo Non ho usato WSL e non ho modificato OpenClaw.
echo Mandami una foto delle righe finali.
echo.
pause
exit /b %ESITO%
