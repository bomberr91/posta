@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title OpenClaw
cd /d "%USERPROFILE%" 2>nul

REM ══════════════════════════════════════════════════════════════════════════
REM  APRI_OPENCLAW.bat — apre OpenClaw su Windows (doppio clic).
REM  Non installa niente: se OpenClaw non c'è, ti dice cosa fare.
REM ══════════════════════════════════════════════════════════════════════════

set "OC="
for /f "delims=" %%i in ('where openclaw 2^>nul') do if not defined OC set "OC=%%i"
if not defined OC if exist "%APPDATA%\npm\openclaw.cmd" set "OC=%APPDATA%\npm\openclaw.cmd"
if not defined OC for /d %%d in ("%LOCALAPPDATA%\Programs\openclaw*") do if exist "%%d\openclaw.exe" set "OC=%%d\openclaw.exe"

if defined OC goto APRI

set "HUB="
for /d %%d in ("%LOCALAPPDATA%\Programs\*OpenClaw*") do if exist "%%d" set "HUB=%%d"
if defined HUB goto APRI_HUB

cls
echo.
echo   OpenClaw non risulta installato su questo PC.
echo.
echo   Una volta sola: doppio clic su  INSTALLA_OPENCLAW.bat
echo   (sta nella stessa cartella di questo file, dentro ~/posta)
echo.
pause
exit /b 1

:APRI_HUB
echo   Non trovo il comando da terminale, ma c'è l'app grafica:
echo   %HUB%
echo   La apro...
for /f "delims=" %%e in ('dir /b "%HUB%\*.exe" 2^>nul') do (
  start "" "%HUB%\%%e"
  goto :eof
)
echo   Non ho trovato l'eseguibile dentro quella cartella: aprila a mano.
pause
exit /b 1

:APRI
echo   Avvio OpenClaw...  (%OC%)
echo   Quando lo chiudi, questa finestra si chiude da sola.
echo.
call "%OC%" %*
echo.
echo   OpenClaw è stato chiuso.
pause
exit /b 0
