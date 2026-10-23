@echo off
rem A COSA SERVE: installa Open Interpreter nativo Windows (CLI Secondhand) se manca.
rem Verifica il comando, crea un'icona sul Desktop e non configura provider o login.
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title Installa Secondhand - Open Interpreter
color 0B
set "INSTALLER=%TEMP%\open-interpreter-install-%RANDOM%-%RANDOM%.ps1"
set "OI_INSTALLER_PATH=%INSTALLER%"
set "OPEN_INTERPRETER_NONINTERACTIVE=1"

echo.
echo  ================================================================
echo    Secondhand - Open Interpreter, CLI Windows ufficiale
echo  ================================================================
echo.
echo    Scarico l'installer ufficiale e verifico la sua impronta.
echo    Il programma richiede circa 261 MB di download; verra' verificato.
echo    Creo un'icona sul Desktop, ma non avvio l'agente.
echo    Non configuro login, provider o chiavi.
echo    Aggiungo solo la cartella del programma al PATH del tuo utente.
echo    OpenCode, Goose, Hermes, OpenClaw e la Centrale restano intatti.
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 goto NO_POWERSHELL

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; function New-InterpreterShortcut([string]$p) { if (-not $p.ToLowerInvariant().EndsWith('.exe')) { return }; $d=[Environment]::GetFolderPath('Desktop'); $w=New-Object -ComObject WScript.Shell; $s=$w.CreateShortcut((Join-Path $d 'Secondhand.lnk')); $s.TargetPath=$p; $s.WorkingDirectory=$env:USERPROFILE; $s.IconLocation=$p+',0'; $s.Save() }; $existing=Get-Command interpreter -ErrorAction SilentlyContinue; if ($existing) { Write-Host ('Open Interpreter gia presente: '+$existing.Source); & $existing.Source --version; if ($LASTEXITCODE -ne 0) { exit 4 }; New-InterpreterShortcut $existing.Source; exit 10 }; $bin=Join-Path $env:LOCALAPPDATA 'Programs\Open Interpreter\bin'; $exe=Join-Path $bin 'interpreter.exe'; if (Test-Path $bin) { if (Test-Path $exe) { & $exe --version; if ($LASTEXITCODE -ne 0) { exit 4 }; New-InterpreterShortcut $exe; exit 10 }; Write-Host 'La cartella di installazione Open Interpreter esiste ma il comando non c''e. Mi fermo senza modificarla.'; exit 11 }; $oiHome=Join-Path $env:USERPROFILE '.openinterpreter'; if (Test-Path $oiHome) { Write-Host 'Esistono gia dati Open Interpreter. Mi fermo per non modificarli.'; exit 11 }; try { Invoke-WebRequest -UseBasicParsing -Uri 'https://www.openinterpreter.com/install.ps1' -OutFile $env:OI_INSTALLER_PATH; $scriptHash=(Get-FileHash -LiteralPath $env:OI_INSTALLER_PATH -Algorithm SHA256).Hash.ToLowerInvariant(); if ($scriptHash -ne '121a14add92ff5a08051b43bf907a75cbc7f7c2d71ba7ba6b5535dc017b1c2ad') { throw 'L''impronta dell''installer ufficiale non corrisponde. Installazione annullata.' }; if ((Get-Content -LiteralPath $env:OI_INSTALLER_PATH -Raw) -notmatch 'openinterpreter/openinterpreter') { throw 'Il contenuto scaricato non corrisponde al progetto Open Interpreter.' } } catch { Remove-Item -LiteralPath $env:OI_INSTALLER_PATH -Force -ErrorAction SilentlyContinue; Write-Error $_; exit 3 }"
set "ESITO=%ERRORLEVEL%"
if "%ESITO%"=="10" goto GIA_PRESENTE
if "%ESITO%"=="11" goto CARTELLA_ESISTENTE
if not "%ESITO%"=="0" goto DOWNLOAD_ERROR

echo Avvio l'installer ufficiale Open Interpreter; nessuna configurazione modello verra' aperta.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%"
set "ESITO=%ERRORLEVEL%"
del /q "%INSTALLER%" >nul 2>&1
if not "%ESITO%"=="0" goto INSTALL_ERROR

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $m=[Environment]::GetEnvironmentVariable('Path','Machine'); $u=[Environment]::GetEnvironmentVariable('Path','User'); $env:Path=$m+';'+$u; $exe=Join-Path $env:LOCALAPPDATA 'Programs\Open Interpreter\bin\interpreter.exe'; if (-not (Test-Path $exe)) { Write-Error 'Installazione terminata ma interpreter.exe non trovato.'; exit 5 }; & $exe --version; if ($LASTEXITCODE -ne 0) { exit 6 }; $d=[Environment]::GetFolderPath('Desktop'); $w=New-Object -ComObject WScript.Shell; $s=$w.CreateShortcut((Join-Path $d 'Secondhand.lnk')); $s.TargetPath=$exe; $s.WorkingDirectory=$env:USERPROFILE; $s.IconLocation=$exe+',0'; $s.Save()"
set "ESITO=%ERRORLEVEL%"
if not "%ESITO%"=="0" goto VERIFY_ERROR

echo.
echo  ================================================================
echo    Open Interpreter installato e versione verificata.
echo    Ho creato l'icona Secondhand sul Desktop; non ho avviato l'agente.
echo    Non ho configurato il provider.
echo  ================================================================
echo.
pause
exit /b 0

:GIA_PRESENTE
del /q "%INSTALLER%" >nul 2>&1
echo.
echo Open Interpreter era gia presente e verificato; non l'ho reinstallato.
echo Se possibile, ho creato solo l'icona Secondhand.
echo.
pause
exit /b 0

:CARTELLA_ESISTENTE
del /q "%INSTALLER%" >nul 2>&1
echo.
echo Ho trovato dati o una cartella Open Interpreter esistente.
echo Non ho modificato nulla. Inviami una foto di questo messaggio.
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
echo Controlla la connessione e inviami le righe finali.
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
