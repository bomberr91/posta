@echo off
title Browser degli Agenti (porta 9222 - profilo isolato)
set PROFILE_DIR=C:\AgentiH24\BrowserProfile
if not exist "%PROFILE_DIR%" mkdir "%PROFILE_DIR%"

set CHROME=""
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set CHROME="C:\Program Files\Google\Chrome\Application\chrome.exe"
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set CHROME="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
if %CHROME%=="" if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" set CHROME="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if %CHROME%=="" if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" set CHROME="C:\Program Files\Microsoft\Edge\Application\msedge.exe"

echo Avvio il Browser degli Agenti (profilo separato in %PROFILE_DIR%, porta 9222)...
echo Qui puoi fare login nei siti che vuoi far usare agli agenti senza toccare il tuo browser personale.
start "" %CHROME% --remote-debugging-port=9222 --user-data-dir="%PROFILE_DIR%" --no-first-run --no-default-browser-check https://www.google.com
