@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title OpenClaw - configurazione iniziale
color 0B
cd /d "%USERPROFILE%" 2>nul

REM ══════════════════════════════════════════════════════════════════════════
REM  CONFIGURA_OPENCLAW.bat — le domande iniziali di OpenClaw, una volta sola.
REM  Trova da solo dove è installato openclaw e lo lancia con "call"
REM  (senza "call" Windows incastra i comandi e passa il nome del file
REM   come argomento a OpenClaw: è l'errore che hai visto).
REM ══════════════════════════════════════════════════════════════════════════

set "OC="
for /f "delims=" %%i in ('where openclaw.cmd 2^>nul') do if not defined OC set "OC=%%i"
if not defined OC for /f "delims=" %%i in ('where openclaw 2^>nul') do if not defined OC set "OC=%%i"
if not defined OC if exist "%APPDATA%\npm\openclaw.cmd" set "OC=%APPDATA%\npm\openclaw.cmd"
if not defined OC for /d %%d in ("%LOCALAPPDATA%\Programs\openclaw*") do if exist "%%d\openclaw.exe" set "OC=%%d\openclaw.exe"

if not defined OC goto NON_TROVATO

echo.
echo   Ho trovato OpenClaw qui:
echo      %OC%
echo.
echo   Parto con la configurazione iniziale.
echo   Rispondi alle domande (lingua, provider, canali).
echo   Se non sai una cosa, premi INVIO e la salti: si cambia dopo.
echo.
echo   ------------------------------------------------------------
echo.
call "%OC%" onboard
set "ESITO=%ERRORLEVEL%"
echo.
echo   ------------------------------------------------------------
if "%ESITO%"=="0" (
  echo   Configurazione terminata.
) else (
  echo   La configurazione si e' chiusa con codice %ESITO%.
  echo   Se non era voluto, rilancia questo file: riparte da dove serve.
)
echo.
echo   Adesso torna nella GUI della Centrale e premi "Accendi":
echo   da li' in avanti OpenClaw parte da solo col PC.
echo.
pause
exit /b %ESITO%

:NON_TROVATO
echo.
echo   Non trovo OpenClaw su questo PC.
echo.
echo   Una volta sola: doppio clic su INSTALLA_OPENCLAW.bat
echo   (sta nella cartella ~/posta, insieme a questo file).
echo.
pause
exit /b 1
