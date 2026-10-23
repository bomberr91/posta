@echo off
rem A COSA SERVE: scarica Goose Desktop ufficiale per Windows e crea un'icona sul Desktop.
rem Non avvia l'app e non configura provider, login o chiavi.
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title Installa Goose Desktop - Windows
color 0B

echo.
echo  ================================================================
echo    Goose Desktop - installazione ufficiale Windows
echo  ================================================================
echo.
echo    Scarico Goose Desktop v1.55.0 (circa 246 MB).
echo    Verifico il file con l'impronta ufficiale SHA-256.
echo    Creo un'icona sul Desktop, ma non avvio l'app.
echo    Non configuro login, provider o chiavi.
echo    Non modifico OpenCode, Hermes, OpenClaw o la Centrale.
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 goto NO_POWERSHELL

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { Write-Error 'Questo pacchetto ufficiale richiede Windows x64.'; exit 2 }; $appDir=Join-Path $env:LOCALAPPDATA 'Programs\Goose'; $existing=Get-Command goose -ErrorAction SilentlyContinue; if ($existing) { Write-Host ('Goose CLI gia presente: '+$existing.Source); exit 10 }; if (Test-Path $appDir) { $old=Get-ChildItem -LiteralPath $appDir -Recurse -File -Filter 'Goose.exe' -ErrorAction SilentlyContinue | Select-Object -First 1; if ($old) { Write-Host ('Goose Desktop gia presente: '+$old.FullName); exit 10 }; Write-Error 'La cartella Goose esiste ma non contiene l''app attesa. Mi fermo senza modificarla.'; exit 11 }; $zip=Join-Path $env:TEMP 'Goose-win32-x64-v1.55.0.zip'; $stage=Join-Path $env:TEMP ('goose-stage-'+[guid]::NewGuid().ToString('N')); try { Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/aaif-goose/goose/releases/download/v1.55.0/Goose-win32-x64.zip' -OutFile $zip; $actual=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant(); if ($actual -ne '4a10e547730832afc2fb13d1c3c4e60b0332ce3e49fd3793cb04259206054c0c') { throw 'Verifica SHA-256 non riuscita: archivio eliminato, installazione annullata.' }; Expand-Archive -LiteralPath $zip -DestinationPath $stage -Force; $exe=Get-ChildItem -LiteralPath $stage -Recurse -File -Filter 'Goose.exe' -ErrorAction SilentlyContinue | Select-Object -First 1; if (-not $exe) { throw 'Goose.exe non trovato nell''archivio ufficiale.' }; New-Item -ItemType Directory -Path $appDir -Force | Out-Null; Copy-Item -Path (Join-Path $stage '*') -Destination $appDir -Recurse -Force; $installed=Get-ChildItem -LiteralPath $appDir -Recurse -File -Filter 'Goose.exe' -ErrorAction SilentlyContinue | Select-Object -First 1; if (-not $installed) { throw 'Copia completata ma Goose.exe non trovato.' }; $desktop=[Environment]::GetFolderPath('Desktop'); $shell=New-Object -ComObject WScript.Shell; $shortcut=$shell.CreateShortcut((Join-Path $desktop 'Goose.lnk')); $shortcut.TargetPath=$installed.FullName; $shortcut.WorkingDirectory=$installed.DirectoryName; $shortcut.IconLocation=$installed.FullName+',0'; $shortcut.Save(); Write-Host ('GOOSE_OK|'+$installed.FullName) } catch { Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue; Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue; Write-Error $_; exit 3 }; Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue; Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue"
set "ESITO=%ERRORLEVEL%"
if "%ESITO%"=="10" goto GIA_PRESENTE
if "%ESITO%"=="11" goto CARTELLA_ANOMALA
if not "%ESITO%"=="0" goto ERRORE

echo.
echo  ================================================================
echo    Goose Desktop v1.55.0 installato.
echo    Ho creato l'icona Goose sul Desktop; non ho avviato l'app.
echo    Il provider verra' configurato in un secondo momento.
echo  ================================================================
echo.
pause
exit /b 0

:GIA_PRESENTE
echo.
echo Goose risulta gia presente. Non ho reinstallato o modificato nulla.
echo.
pause
exit /b 0

:CARTELLA_ANOMALA
echo.
echo Ho trovato una cartella Goose incompleta; non l'ho modificata.
echo Inviami una foto di questa schermata prima di procedere.
echo.
pause
exit /b 11

:NO_POWERSHELL
echo PowerShell non trovato. Nessuna modifica eseguita.
echo.
pause
exit /b 2

:ERRORE
echo.
echo Goose Desktop non e' stato installato o verificato.
echo Inviami una foto delle righe finali; non inserire chiavi o password.
echo.
pause
exit /b %ESITO%
