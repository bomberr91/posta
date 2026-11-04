✅ COMPLETATO — issue #37 — 21s — exit 0
Agente: `goose`

### Output (coda)
```
[goose_run] via cervello locale (nessuna chiave provider) · modello=auto · bin=/home/agenti/.local/bin/goose

    __( O)>  ● new session · openai auto
   \____)    20261104_30 · /home/agenti/posta
     L L     goose is ready

  ────────────────────────────────────────
  ▸ shell
    command: cd /mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog


  ────────────────────────────────────────
  ▸ shell
    command: cmd.exe /c start "" "C:\Users\giopi\Documents\AgentWorkspace\deepdog\Avvia Deep Dog Web.bat"


  ────────────────────────────────────────
  ▸ shell
    command: timeout 15


  ────────────────────────────────────────
  ▸ shell
    command: python3 -c "import socket;s=socket.socket();s.settimeout(5);print('8765 APERTA' if s.connect_ex(('127.0.0.1',8765))==0 else '8765 CHIUSA')"


  ────────────────────────────────────────
  ▸ shell
    command: cmd.exe /c tasklist | findstr /I python

(no output)Try 'timeout --help' for more information.

Command exited with code 1258765 CHIUSA'\\wsl.localhost\Ubuntu\home\agenti\posta'
CMD.EXE � stato avviato utilizzando il percorso precedente come directory
corrente. I percorsi UNC non sono supportati. Per impostazione predefinita,
verr� utilizzata la directory di Windows.

Output may be incomplete because stream draining timed out after process exit.bash: line 1: findstr: command not found
'\\wsl.localhost\Ubuntu\home\agenti\posta'
CMD.EXE � stato avviato utilizzando il percorso precedente come directory
corrente. I percorsi UNC non sono supportati. Per impostazione predefinita,
verr� utilizzata la directory di Windows.

Command exited with code 1278765: CHIUSA
'\\\\wsl.localhost\\Ubuntu\\home\\agenti\\posta'
CMD.EXE � stato avviato utilizzando il percorso precedente come directory
corrente. I percorsi UNC non sono supportati. Per impostazione predefinita,
verr� utilizzata la directory di Windows.

bash: line 1: findstr: command not found
'\\\\wsl.localhost\\Ubuntu\\home\\agenti\\posta'
CMD.EXE � stato avviato utilizzando il percorso precedente come directory
corrente. I percorsi UNC non sono supportati. Per impostazione predefinita,
verr� utilizzata la directory di Windows.

FINE
```

Consegna: `/consegne/37-riattiva-deep-dog-una-sola-finestra`