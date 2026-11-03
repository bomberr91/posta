# Risposta a «gateway_diag»

_03/11/2026 16:17 · FilippoPC_

Data: 03/11/2026 16:17:26
Acceso da: up 31 minutes

## Porte
  VIVO  motore OmniRoute 20128
  VIVO  cervello         20129
  VIVO  Gateway OpenClaw 18789
  KO    browser agenti   18800

## Processi node.exe con openclaw (Windows)


ProcessId    : 1912
CreationDate : 03/11/2026 15:48:03
CommandLine  : "C:\Program Files\nodejs\node.exe"  --max-old-space-size=8141 
               C:\Users\giopi\AppData\Roaming\npm\node_modules\openclaw\dist\index.js gateway --port 18789 
               --task-supervisor 

ProcessId    : 7900
CreationDate : 03/11/2026 15:50:41
CommandLine  : "C:\Program Files\nodejs\node.exe" 
               C:\Users\giopi\AppData\Roaming\npm\node_modules\openclaw\dist\process\spawn-broker\worker.js

ProcessId    : 10008
CreationDate : 03/11/2026 15:52:35
CommandLine  : "C:\Program Files\nodejs\node.exe" C:\Users\giopi\AppData\Roaming\npm\node_modules\openclaw\dist\process
               \supervisor\service-child-windows-job-anchor.js

ProcessId    : 9392
CreationDate : 03/11/2026 15:52:36
CommandLine  : "C:\Program Files\nodejs\node.exe"  --max-old-space-size=8141 
               C:\Users\giopi\AppData\Roaming\npm\node_modules\openclaw\dist\index.js gateway --port 18789 
               --task-supervisor-child=729425970

ProcessId    : 5584
CreationDate : 03/11/2026 15:52:44
CommandLine  : "C:\Program Files\nodejs\node.exe" 
               C:\Users\giopi\AppData\Roaming\npm\node_modules\openclaw\dist\process\spawn-broker\worker.js

ProcessId    : 9292
CreationDate : 03/11/2026 15:54:33
CommandLine  : "C:\Program Files\nodejs\node.exe" 
               C:\Users\giopi\AppData\Roaming\npm\node_modules\openclaw\dist\infra\sqlite-readonly-location.worker.js 
               --openclaw-sqlite-readonly-child session

ProcessId    : 4812
CreationDate : 03/11/2026 15:57:03
CommandLine  : "C:\Program Files\nodejs\node.exe" 
               C:\Users\giopi\AppData\Roaming\npm\node_modules\openclaw\dist\infra\sqlite-readonly-location.worker.js 
               --openclaw-sqlite-readonly-child session

## Lock dello state directory
total 4
drwxrwxrwx 1 agenti agenti 4096 Nov  3 15:53 .
drwxrwxrwx 1 agenti agenti 4096 Oct 27 05:29 ..
-rwxrwxrwx 1 agenti agenti  629 Nov  3 16:17 state.c0b7d20c336882aa.lock

## Startup: cosa c'è
total 4
drwxrwxrwx 1 agenti agenti 4096 Nov  3 15:19 .
drwxrwxrwx 1 agenti agenti 4096 Oct 30 14:48 ..
-rwxrwxrwx 1 agenti agenti  343 Nov  1 09:57 AGENTI_INVISIBILI.vbs
-rwxrwxrwx 1 agenti agenti  405 Nov  3 15:23 OpenClaw Gateway.vbs
-rwxrwxrwx 1 agenti agenti  171 Oct 30 15:05 WIDGET_AGENTROUTER.vbs
-rwxrwxrwx 1 agenti agenti  174 Dec 10  2025 desktop.ini

--- 'OpenClaw Gateway.vbs' ---
' OpenClaw Gateway - aspetta 90 secondi (stessa regola dei 60 dei guardiani WSL):
' al login il PC non e' ancora pronto e il Gateway si impianta sul lock di stato.
Set shell = CreateObject("WScript.Shell")
shell.Environment("Process")("OPENCLAW_WINDOWS_TASK_HIDDEN_LAUNCHER") = "wscript"
WScript.Quit shell.Run("cmd.exe /c ""timeout /t 90 /nobreak >nul & C:\Users\giopi\.openclaw\gateway.cmd""", 0, True)

--- gateway.cmd (prime righe) ---
@echo off
rem OpenClaw Gateway
set "TMPDIR=C:\Users\giopi\AppData\Local\Temp"
set "NODE_OPTIONS="
set "OPENCLAW_GATEWAY_PORT=18789"
set "OPENCLAW_SYSTEMD_UNIT=openclaw-gateway.service"
set "OPENCLAW_WINDOWS_TASK_NAME=OpenClaw Gateway"
set "OPENCLAW_SERVICE_MARKER=openclaw"
set "OPENCLAW_SERVICE_KIND=gateway"
if not defined OPENCLAW_WINDOWS_TASK_HIDDEN_LAUNCHER set "OPENCLAW_WINDOWS_TASK_HIDDEN_LAUNCHER=cmd"
"C:\Program Files\nodejs\node.exe" --max-old-space-size=8141 C:\Users\giopi\AppData\Roaming\npm\node_modules\openclaw\dist\index.js gateway --port 18789 --task-supervisor < NUL

## Log OpenClaw: i piu' recenti (Windows)
## Log OpenClaw: i piu' recenti (WSL)
## Fine

<!-- fine gateway_diag -->
