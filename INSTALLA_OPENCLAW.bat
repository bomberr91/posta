@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title OpenClaw - installazione automatica su Windows
color 0B
cd /d "%USERPROFILE%" 2>nul

REM ══════════════════════════════════════════════════════════════════════════
REM  INSTALLA_OPENCLAW.bat — mette OpenClaw su Windows in automatico.
REM  Perché su Windows e non dentro Ubuntu(WSL1): OpenClaw dalla v2026.9.3
REM  vuole Node >= 24.16, e quei Node NON partono su WSL1 (Exec format error,
REM  nodejs/node#63735). Su Windows invece Node 24/26 gira benissimo e
REM  l'installer se lo porta dietro da solo.
REM  Non serve essere amministratore. Non tocca Ubuntu né il ponte ~/posta.
REM  Ogni cosa viene scritta nel log: %USERPROFILE%\openclaw_install.log
REM ══════════════════════════════════════════════════════════════════════════

set "LOG=%USERPROFILE%\openclaw_install.log"
set "ARCH=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"
if /i "%PROCESSOR_ARCHITEW6432%"=="ARM64" set "ARCH=arm64"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -Command"
set "URLHUB=https://github.com/openclaw/openclaw-windows-node/releases/latest/download/OpenClawCompanion-Setup-%ARCH%.exe"
set "FILEHUB=%USERPROFILE%\Downloads\OpenClawCompanion-Setup-%ARCH%.exe"

REM ── Il Node di WINDOWS (è quello che fa girare il Free LLM Hub): NON lo tocchiamo.
set "NODEWIN="
for /f "delims=" %%p in ('where node 2^>nul') do if not defined NODEWIN set "NODEWIN=%%p"
if not defined NODEWIN if exist "%ProgramFiles%\nodejs\node.exe" set "NODEWIN=%ProgramFiles%\nodejs\node.exe"
set "NODEWINV="
if defined NODEWIN for /f "delims=" %%v in ('"%NODEWIN%" -v 2^>nul') do set "NODEWINV=%%v"

>>"%LOG%" echo.
>>"%LOG%" echo ===================== avvio %DATE% %TIME% =====================
>>"%LOG%" echo architettura: %ARCH%  utente: %USERNAME%
>>"%LOG%" echo node windows: %NODEWIN% %NODEWINV%

:MENU
cls
echo.
echo  ======================================================================
echo    OpenClaw  -  installazione automatica   (tuo Windows: %ARCH%)
echo  ======================================================================
echo.
echo    Hai Node 24 su Ubuntu? Non c'entra: dentro WSL1 non parte.
echo    Qui lo installiamo SU WINDOWS, dove funziona davvero.
echo.
if defined NODEWINV echo    Il tuo Node di Windows: %NODEWINV%  -  lo usa il Free LLM Hub, NON lo tocchiamo
echo.
echo    [1]  TUTTO AUTOMATICO   (consigliato: prova, controlla, e se serve
echo                            passa alla versione grafica)
echo    [2]  Solo la versione da terminale  (comando "openclaw" su Windows)
echo    [3]  Solo la versione grafica       (app con icona nel tray e chat)
echo    [4]  Controlla cosa c'è già        (non installa niente)
echo    [0]  Esci
echo.
set "SCELTA="
set /p "SCELTA=   Scegli un numero e premi INVIO: "
if not defined SCELTA goto MENU
if "%SCELTA%"=="1" goto TUTTO
if "%SCELTA%"=="2" goto SOLO_CLI
if "%SCELTA%"=="3" goto SOLO_HUB
if "%SCELTA%"=="4" goto CONTROLLA
if "%SCELTA%"=="0" goto ESCI
goto MENU

REM ══════════════════════════════════════════════════════════════════════
:CONTROLLA
cls
echo.
echo  --------------------------------------------------------------
echo    COSA C'E' GIA' SU QUESTO PC
echo  --------------------------------------------------------------
call :TROVA_CLI
if defined TROVATO (
  echo    [OK] versione da terminale: %TROVATO%
) else (
  echo    [--] versione da terminale: non installata
)
call :TROVA_HUB
if defined HUB (
  echo    [OK] app grafica:           %HUB%
) else (
  echo    [--] app grafica:           non installata
)
echo.
if defined NODEWINV echo    Node di Windows:            %NODEWINV%  -  Free LLM Hub: ok, resta cosi'
if not defined NODEWINV echo    Node di Windows:            assente - l'installer di OpenClaw se lo mette lui
echo    Windows: %OS%   architettura: %ARCH%
echo    Log di tutte le prove: %LOG%
echo.
echo  --------------------------------------------------------------
pause
goto MENU

REM ══════════════════════════════════════════════════════════════════════
:TUTTO
cls
echo.
echo  ======================================================================
echo    1/3  Controllo cosa c'è già...
echo  ======================================================================
call :TROVA_CLI
if defined TROVATO goto GIA_PRONTO
echo.
echo  ======================================================================
echo    2/3  Installo la versione da terminale (Node se lo porta lui)
echo  ======================================================================
echo    Ci vogliono 2-5 minuti, la finestra lavora da sola. Non chiuderla.
echo.
call :INSTALLA_CLI
if not errorlevel 1 goto CLI_FATTO
echo.
echo    La versione da terminale non è andata (è scritto tutto nel log).
echo.
echo  ======================================================================
echo    3/3  Provo la versione GRAFICA (app con tray e chat)
echo  ======================================================================
echo    È la strada consigliata da OpenClaw per Windows.
echo.
call :INSTALLA_HUB
if not errorlevel 1 goto HUB_FATTO
goto FALLITO

:CLI_FATTO
cls
echo.
echo  ======================================================================
echo    FATTO: OpenClaw è installato su Windows
echo  ======================================================================
call :TROVA_CLI
echo    Comando: %TROVATO%
echo.
echo    Come lo usi da qui in avanti:
echo      - Dal menu Start di Windows: cerca "OpenClaw"
echo      - Dalla Centrale Ubuntu: [1] poi [e]  (ora funziona)
echo      - Da solo, doppio clic su APRI_OPENCLAW.bat
echo.
echo    Adesso faccio il PRIMO AVVIO in una finestra a parte.
echo    Se compare la domanda:
echo         Update NodeJS: Y/N [N]:
echo    rispondi   Y   e premi INVIO.
echo    Cosi' OpenClaw si mette un Node SUO (privato) e il tuo Node %NODEWINV%
echo    del Free LLM Hub resta esattamente com'e'.
echo.
start "OpenClaw - primo avvio" cmd /k "openclaw --version"
echo    (se invece non chiede niente e stampa un numero di versione: era gia' a posto)
echo.
echo    Poi, quando vuoi, la configurazione iniziale:
echo      openclaw onboard
echo.
goto FINE_OK

:HUB_FATTO
cls
echo.
echo  ======================================================================
echo    FATTO: l'app grafica di OpenClaw è stata scaricata
echo  ======================================================================
echo    Si è aperta la finestra di installazione: premi Avanti fino alla fine
echo    (non serve essere amministratore).
echo.
echo    Poi: cerca "OpenClaw Companion" nel menu Start e aprile.
echo    Al primo avvio scegli  "Set up locally"  e lascia fare a lei.
echo.
goto FINE_OK

:GIA_PRONTO
cls
echo.
echo  ======================================================================
echo    Non c'è niente da installare: OpenClaw c'è già
echo  ======================================================================
echo    %TROVATO%
echo.
echo    Se vuoi controllare che stia bene, apri il Prompt dei comandi e scrivi:
echo       openclaw --version
echo       openclaw doctor
echo.
goto FINE_OK

:FALLITO
cls
echo.
echo  ======================================================================
echo    Non ci sono riuscito da solo
echo  ======================================================================
echo    Non è un problema: mandami il file del log, lo sistemo io.
echo.
echo       %LOG%
echo.
echo    (dalla Centrale Ubuntu lo trovi in:  /mnt/c/Users/%USERNAME%/openclaw_install.log)
echo.
goto FINE_OK

:FINE_OK
echo.
echo  --------------------------------------------------------------
echo    Log completo: %LOG%
echo  --------------------------------------------------------------
echo.
pause
goto MENU

REM ══════════════════════════════════════════════════════════════════════
:SOLO_CLI
cls
echo.
call :INSTALLA_CLI
if errorlevel 1 goto FALLITO_CLI
call :TROVA_CLI
echo.
echo    [OK] Installato: %TROVATO%
echo.
pause
goto MENU
:FALLITO_CLI
echo.
echo    [--] Installazione non riuscita. Log: %LOG%
echo.
pause
goto MENU

:SOLO_HUB
cls
echo.
call :INSTALLA_HUB
if errorlevel 1 goto FALLITO_HUB
echo.
pause
goto MENU
:FALLITO_HUB
echo.
echo    [--] Download/avvio non riuscito. Log: %LOG%
echo.
pause
goto MENU

:ESCI
endlocal
exit /b 0

REM ══════════════════════════════════════════════════════════════════════
REM  SOTTOPROGRAMMI
REM ══════════════════════════════════════════════════════════════════════

:TROVA_CLI
set "TROVATO="
for /f "delims=" %%i in ('where openclaw 2^>nul') do if not defined TROVATO set "TROVATO=%%i"
if defined TROVATO goto :eof
if exist "%APPDATA%\npm\openclaw.cmd" set "TROVATO=%APPDATA%\npm\openclaw.cmd"
if defined TROVATO goto :eof
for /d %%d in ("%LOCALAPPDATA%\Programs\openclaw*") do if exist "%%d\openclaw.exe" set "TROVATO=%%d\openclaw.exe"
goto :eof

:TROVA_HUB
set "HUB="
for /d %%d in ("%LOCALAPPDATA%\Programs\*OpenClaw*") do if exist "%%d" set "HUB=%%d"
if defined HUB goto :eof
for /d %%d in ("%PROGRAMFILES%\*OpenClaw*") do if exist "%%d" set "HUB=%%d"
goto :eof

:INSTALLA_CLI
>>"%LOG%" echo --- installazione CLI Windows ---
echo    Sto scaricando ed eseguendo l'installer ufficiale (Node compreso)...
echo    (la finestra può sembrare ferma: sta scaricando)
%PS% "& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -NoOnboard" >>"%LOG%" 2>&1
if errorlevel 1 (
  echo    primo tentativo non riuscito, riprovo in modo semplice...
  %PS% "iwr -useb https://openclaw.ai/install.ps1 | iex" >>"%LOG%" 2>&1
)
call :TROVA_CLI
if defined TROVATO (
  echo    [OK] trovato: %TROVATO%
  for /f "delims=" %%v in ('call openclaw --version 2^>nul') do echo    versione: %%v
  exit /b 0
)
echo    [--] non trovato dopo l'installazione
exit /b 1

:INSTALLA_HUB
>>"%LOG%" echo --- app grafica Windows Hub ---
echo    Scarico l'app (circa 40-120 MB): %URLHUB%
%PS% "$u='%URLHUB%'; $o='%FILEHUB%'; New-Item -ItemType Directory -Force -Path ($env:USERPROFILE+'\Downloads') | Out-Null; iwr -useb $u -OutFile $o; $s=(Get-AuthenticodeSignature $o).Status; Write-Host ('   scaricato: '+$o); Write-Host ('   firma: '+$s)" >>"%LOG%" 2>&1
if not exist "%FILEHUB%" (
  echo    [--] download non riuscito
  exit /b 1
)
for %%f in ("%FILEHUB%") do echo    scaricato: %%~nxf  -  %%~zf byte
echo    Avvio l'installazione...
start "" "%FILEHUB%"
exit /b 0
