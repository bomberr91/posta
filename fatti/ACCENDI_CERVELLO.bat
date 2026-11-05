@echo off
setlocal EnableExtensions
title CERVELLO acceso (porta 20129) - NON CHIUDERE, puoi ridurla a icona
color 0A

REM ============================================================
REM  ACCENDI_CERVELLO.bat - 30/10/2026
REM  Accende il Portiere (cervello.py, porta 20129) dalla
REM  cartella posta dentro WSL. Da lanciare PRIMA di aprire
REM  gli agenti. Se e' gia' acceso non fa niente (anti-doppione).
REM  IMPORTANTE: finche' lavori con gli agenti questa finestra
REM  deve restare aperta (ridotta a icona va benissimo).
REM ============================================================

REM --- gia' acceso? ---
curl -s -o nul -m 2 http://127.0.0.1:20129/v1/models
if %ERRORLEVEL%==0 goto GIA_ACCESO

echo.
echo   Accendo il cervello (porta 20129)...
echo   Lascia questa finestra aperta: puoi ridurla a icona.
echo   Per spegnerlo: chiudi questa finestra.
echo.
wsl bash -lc "cd ~/posta && python3 cervello.py"

echo.
echo   Il cervello si e' spento (o non e' riuscito a partire).
echo   Se qui sopra c'e' un errore, copialo in chat.
echo.
pause
exit /b 0

:GIA_ACCESO
echo.
echo   Il cervello e' GIA' acceso sulla porta 20129.
echo   Non serve fare altro: puoi aprire gli agenti.
echo.
pause
exit /b 0
