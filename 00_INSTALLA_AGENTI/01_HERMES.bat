@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title Installa Hermes - Agenti H24
color 0B
cd /d "%USERPROFILE%" >nul 2>&1

echo.
echo  ================================================================
echo    Hermes - installazione automatica su Ubuntu (WSL)
echo  ================================================================
echo.
echo    OpenClaw non viene toccato.
echo    Installo solo Hermes, usando il portachiavi e il cervello locale.
echo    Non serve aprire un terminale o inserire chiavi.
echo    L'installazione puo' richiedere alcuni minuti: non chiudere.
echo.
where wsl.exe >nul 2>&1
if errorlevel 1 goto NO_WSL

wsl.exe -d Ubuntu -u agenti -- bash -lc "cd ~/posta && bash ./installa_agenti.sh hermes"
set "ESITO=%ERRORLEVEL%"
if not "%ESITO%"=="0" goto ERRORE

echo.
echo  ================================================================
echo    Hermes risulta installato.
echo    Ora chiudi questa finestra e torna al menu della Centrale.
echo    Premi g per riavviare la GUI, poi scegli Hermes nella tendina.
echo  ================================================================
echo.
pause
exit /b 0

:NO_WSL
echo.
echo  WSL non trovato: non ho installato o modificato nulla.
echo  Controlla che Ubuntu sia presente come nella Centrale Agenti.
echo.
pause
exit /b 2

:ERRORE
echo.
echo  Hermes non e' stato installato: la finestra resta aperta.
echo  Guarda il messaggio sopra e mandami una foto: sistemo io il prossimo passo.
echo  Non e' stato toccato OpenClaw.
echo.
pause
exit /b %ESITO%
