# Risposta a «ripara_motore»

_03/11/2026 09:44 · FilippoPC_

## Stato iniziale
- 20128/v1/models: HTTPError
- 20128/: RISPONDE
- 20128/api/status: HTTPError
- processi omniroute:
    agenti    1004    12  0 08:33 tty2     00:00:00 flock -n /tmp/omni.lk bash -c . ~/.nvm/nvm.sh; OMNIROUTE_SERVER_HOST=127.0.0.1 omniroute
    agenti    1005  1004  0 08:33 tty2     00:00:06 node /home/agenti/.nvm/versions/node/v22.23.3/bin/omniroute
    agenti    4454  1005  0 08:36 tty2     00:00:33 omniroute (v16.3.8)

## Variabili d'ambiente del processo omniroute (porta/host)
    OMNIROUTE_SERVER_HOST=127.0.0.1
    HOSTTYPE=x86_64
- porta dichiarata: PATH=/home/agenti/.local/bin:/home/agenti/.opencode/bin:/home/agenti/.local/bin:/home/agenti/.hermes/hermes-agent/bin:/home/agenti/.opencode/bin:/home/agenti/.local/bin:/home/agenti/.hermes/hermes-agent/bin:/home/agenti/.nvm/versions/node/v22.23.3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/mnt/c/Program Files/WindowsApps/MicrosoftCorporationII.WindowsSubsystemForLinux_3.0.3.0_x64__8wekyb3d8bbwe:/mnt/c/WINDOWS/system32:/mnt/c/WINDOWS:/mnt/c/WINDOWS/System32/Wbem:/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/:/mnt/c/WINDOWS/System32/OpenSSH/:/mnt/c/Program Files/dotnet/:/mnt/c/Program Files/WSL/:/mnt/c/Program Files/nodejs/:/mnt/c/Users/giopi/AppData/Local/agy/bin:/mnt/c/Users/giopi/AppData/Local/Programs/Open Interpreter/bin:/mnt/c/Users/giopi/AppData/Local/hermes/bin:/mnt/c/Users/giopi/AppData/Local/Programs/Python/Python312/Scripts/:/mnt/c/Users/giopi/AppData/Local/Programs/Python/Python312/:/mnt/c/Users/giopi/AppData/Local/Programs/Python/Launcher/:/mnt/c/Users/giopi/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/giopi/AppData/Local/PowerToys/DSCModules/:/mnt/c/Users/giopi/AppData/Local/Microsoft/WinGet/Packages/DenoLand.Deno_Microsoft.Winget.Source_8wekyb3d8bbwe:/mnt/c/Users/giopi/AppData/Local/OpenClaw/deps/portable-git/usr/bin:/mnt/c/Users/giopi/AppData/Local/OpenClaw/deps/portable-git/cmd:/mnt/c/Users/giopi/AppData/Roaming/npm:/snap/bin 

## Config di OmniRoute: porta dichiarata

## Log di avvio (ultime 15 righe)
- /home/agenti/posta/dal_pc/omni_start.log:
    [STARTUP] Quota fetchers registered
    [STARTUP] JWT_SECRET restored from persistent store
    [proxyLogger] Loaded 200 proxy logs from SQLite
    [Shutdown] Graceful shutdown handlers registered.
    [STARTUP] Spend batch writer started
    [STARTUP] Guardrail registry initialized
    [STARTUP] Builtin skill handlers registered
    [STARTUP] Quota cache background refresh started
    [ProviderLimitsSync] Scheduler started — interval: 70m
    [STARTUP] Provider limits sync scheduler started
    [INFO] [QuotaAutoPing] scheduler started
    [STARTUP] Quota auto-ping scheduler started (opt-in, no-op until enabled)
    [ModelSync] Scheduler started — interval: 6h (phase offset +45m)
    --- End recent output ---
    

## Riavvio del motore
- omniroute fermato; il guardiano lo riavvia entro 120 s

## Stato finale
- portiere /salute: {"ok": true, "nome": "Portiere", "porta": 20129, "f3": true, "provider": 59, "gruppi": 3, "regole": 0, "motore": true, "riserva": 5, "struttura": []}
- 20128/v1/models: HTTPError
- ultime righe /tmp/scorta_motore.log:

<!-- fine ripara_motore -->
