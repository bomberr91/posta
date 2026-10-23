@echo off
rem A COSA SERVE: installa Antigravity CLI ufficiale per Windows se manca.
rem Verifica versione, crea un'icona sul Desktop; non apre l'agente o il login.
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title Installa Antigravity CLI
color 0B
set "INSTALLER=%TEMP%\agy-install-%RANDOM%-%RANDOM%.ps1"
set "AGY_INSTALLER_PATH=%INSTALLER%"

echo.
echo  ================================================================
echo    Antigravity CLI - installer ufficiale Google per Windows
echo  ================================================================
echo.
echo    Scarico l'installer ufficiale e ne verifico l'impronta.
echo    Installer e programma sono scaricati da Google; il programma
echo    viene verificato dall'installer con checksum SHA-512.
echo    Creo un'icona sul Desktop, ma NON avvio l'agente.
echo    Non configuro account, login, provider o chiavi.
echo    Aggiungo al PATH utente solo la cartella di Antigravity CLI.
echo    Gli altri agenti e le loro configurazioni restano intatti.
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 goto NO_POWERSHELL

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; function New-AgyShortcut([string]$p) { if (-not $p.ToLowerInvariant().EndsWith('.exe')) { return }; $d=[Environment]::GetFolderPath('Desktop'); $w=New-Object -ComObject WScript.Shell; $s=$w.CreateShortcut((Join-Path $d 'Antigravity CLI.lnk')); $s.TargetPath=$p; $s.WorkingDirectory=$env:USERPROFILE; $s.IconLocation=$p+',0'; $s.Save() }; $existing=Get-Command agy -ErrorAction SilentlyContinue; if ($existing) { Write-Host ('Antigravity CLI gia presente: '+$existing.Source); & $existing.Source --version; if ($LASTEXITCODE -ne 0) { exit 4 }; New-AgyShortcut $existing.Source; exit 10 }; $bin=Join-Path $env:LOCALAPPDATA 'agy\bin'; $exe=Join-Path $bin 'agy.exe'; if (Test-Path $bin) { if (Test-Path $exe) { & $exe --version; if ($LASTEXITCODE -ne 0) { exit 4 }; New-AgyShortcut $exe; exit 10 }; Write-Host 'La cartella di Antigravity CLI esiste ma agy.exe non c''e. Mi fermo senza modificarla.'; exit 11 }; $data=Join-Path $env:USERPROFILE '.gemini\antigravity-cli'; if (Test-Path $data) { Write-Host 'Ho trovato dati Antigravity CLI gia presenti. Mi fermo per non modificarli.'; exit 11 }; try { Invoke-WebRequest -UseBasicParsing -Uri 'https://antigravity.google/cli/install.ps1' -OutFile $env:AGY_INSTALLER_PATH; $scriptHash=(Get-FileHash -LiteralPath $env:AGY_INSTALLER_PATH -Algorithm SHA256).Hash.ToLowerInvariant(); if ($scriptHash -ne '51c2cb4fada22ce0228da71b9506370383d6544bfebcec85fe7616a52b805344') { throw 'L''impronta dell''installer ufficiale non corrisponde. Installazione annullata.' }; if ((Get-Content -LiteralPath $env:AGY_INSTALLER_PATH -Raw) -notmatch 'antigravity-cli-auto-updater-974169037036\.us-central1\.run\.app') { throw 'Il contenuto scaricato non corrisponde all''installer Antigravity verificato.' } } catch { Remove-Item -LiteralPath $env:AGY_INSTALLER_PATH -Force -ErrorAction SilentlyContinue; Write-Error $_; exit 3 }"
set "ESITO=%ERRORLEVEL%"
if "%ESITO%"=="10" goto GIA_PRESENTE
if "%ESITO%"=="11" goto CARTELLA_ESISTENTE
if not "%ESITO%"=="0" goto DOWNLOAD_ERROR

echo Avvio l'installer ufficiale. Non avvio agy e non apro il login.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%"
set "ESITO=%ERRORLEVEL%"
del /q "%INSTALLER%" >nul 2>&1
if not "%ESITO%"=="0" goto INSTALL_ERROR

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $bin=Join-Path $env:LOCALAPPDATA 'agy\bin'; $exe=Join-Path $bin 'agy.exe'; if (-not (Test-Path $exe)) { Write-Error 'Installazione terminata ma agy.exe non trovato.'; exit 5 }; $m=[Environment]::GetEnvironmentVariable('Path','Machine'); $u=[Environment]::GetEnvironmentVariable('Path','User'); $parts=@($u -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ne $bin.TrimEnd('\') }); if (-not ($u -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -eq $bin.TrimEnd('\') })) { $u=(@($parts)+$bin) -join ';'; [Environment]::SetEnvironmentVariable('Path',$u,'User') }; $env:Path=$m+';'+$u; & $exe --version; if ($LASTEXITCODE -ne 0) { exit 6 }; $d=[Environment]::GetFolderPath('Desktop'); $w=New-Object -ComObject WScript.Shell; $s=$w.CreateShortcut((Join-Path $d 'Antigravity CLI.lnk')); $s.TargetPath=$exe; $s.WorkingDirectory=$env:USERPROFILE; $s.IconLocation=$exe+',0'; $s.Save()"
set "ESITO=%ERRORLEVEL%"
if not "%ESITO%"=="0" goto VERIFY_ERROR

echo.
echo  ================================================================
echo    Antigravity CLI installato e versione verificata.
echo    Icona creata: Antigravity CLI sul Desktop.
echo    NON ho avviato l'agente o il login; nessun provider configurato.
echo    Chiudi e riapri PowerShell per aggiornare il PATH.
echo  ================================================================
echo.
pause
exit /b 0

:GIA_PRESENTE
del /q "%INSTALLER%" >nul 2>&1
echo.
echo Antigravity CLI era gia presente e verificato; non l'ho reinstallato.
echo Se possibile, ho creato solo l'icona Antigravity CLI.
echo.
pause
exit /b 0

:CARTELLA_ESISTENTE
del /q "%INSTALLER%" >nul 2>&1
echo.
echo Ho trovato una cartella o dati Antigravity CLI gia esistenti.
echo Non ho modificato nulla. Mandami una foto di questo messaggio.
echo.
pause
exit /b 11

:NO_POWERSHELL
echo PowerShell non trovato. Nessuna modifica eseguita.
echo.
pause
exit /b 2

:DOWNLOAD_ERROR
del /q "%INSTALLER%" >nul 2>&1
echo.
echo Download/verifica dell'installer non riusciti. Nessuna installazione avviata.
echo Controlla la connessione e mandami le righe finali.
echo.
pause
exit /b %ESITO%

:INSTALL_ERROR
echo.
echo L'installer ufficiale ha segnalato un errore. Agente non verificato.
echo Inviami una foto delle righe finali, senza chiavi o password.
echo.
pause
exit /b %ESITO%

:VERIFY_ERROR
echo.
echo Il comando non ha superato il controllo o l'icona non e' stata creata.
echo Inviami una foto delle righe finali. Non rilanciare l'installer.
echo.
pause
exit /b %ESITO%
