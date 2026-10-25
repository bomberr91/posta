@echo off
rem ─────────────────────────────────────────────────────────────────────────
rem  AVVIA_RACCOGLI_LINK.bat
rem  Apre il raccoglitore di link: riquadro per le parole, numero di link,
rem  controllo se i siti sono online, e file pronti in posta\raccoglilink\Liste
rem ─────────────────────────────────────────────────────────────────────────
chcp 65001 >nul 2>&1
cd /d "%~dp0"
title Raccogli link

set "PY="
where python >nul 2>&1
if not errorlevel 1 set "PY=python"
if not defined PY (
  where py >nul 2>&1
  if not errorlevel 1 set "PY=py -3"
)
if not defined PY (
  where python3 >nul 2>&1
  if not errorlevel 1 set "PY=python3"
)

if defined PY goto :avvia
echo.
echo  Non trovo Python su questo PC.
echo.
echo  Serve una volta sola: installalo da https://www.python.org/downloads/windows/
echo  (durante l'installazione metti la spunta a "Add python.exe to PATH"),
echo  poi riapri questo file con doppio clic.
echo.
pause
exit /b 1

:avvia
echo  Avvio il raccoglitore...
%PY% "raccogli.py"
if errorlevel 1 (
  echo.
  echo  Qualcosa non ha funzionato. Provo dalla finestra nera, cosi' vedi il messaggio:
  echo.
  %PY% "raccogli.py" --cli
  pause
)
exit /b 0
