# INSTALLA — ponte arena → agenti locali (in 10 minuti)

> Tutto gratis. Prerequisito: `gh` già autenticato in WSL (lo usa già il postino).

## 1. Copia il pacchetto nel repo
```bash
cp -r /mnt/c/Users/giopi/Documents/AgentWorkspace/ponte-arena ~/posta/lavori/ponte
cd ~/posta/lavori/ponte
```

## 2. Crea le etichette (una volta sola)
```bash
gh label create inbox           -R bomberr91/posta --color 0E8A16 --force
gh label create in-corso        -R bomberr91/posta --color FBCA04 --force
gh label create richiede-conferma -R bomberr91/posta --color D93F0B --force
gh label create bloccato        -R bomberr91/posta --color B60205 --force
```

## 3. Configura `ponte.json`
- `repo_path`: metti `/home/agenti/posta` (abilita commit+push delle consegne; se lo lasci `null` consegna solo in locale, comodo per i test)
- `agenti`: **adatta i comandi ai CLI veri** dei tuoi agenti (openclaw, goose, hermes, opencode, ...). `{compito}` e `{contesto}` vengono sostituiti dal testo della issue.
- `workdir_default`: da dove gli agenti partono (es. `/home/agenti`)

## 4. Prova in sicurezza (non tocca nulla)
```bash
python3 poller.py --once --dry-run
```
Poi apri una issue di prova nel repo col corpo (vedi TEMPLATE_ISSUE.md):
```markdown
target: goose
compito:
Stampa "ciao dal ponte" e la data odierna.

contesto:
Test del ponte: non toccare file, rispondi solo con l'output.
```
e riprova `--once --dry-run`: deve elencare la issue e dire cosa farebbe.

## 5. Primo giro vero (un ciclo solo, poi si ferma)
```bash
python3 poller.py --once
```
Controlla la issue: deve essere chiusa, con il commento di esito e (se `repo_path` impostato) la cartella `/consegne/<N>-.../` nel repo.

## 6. Loop permanente
```bash
nohup python3 poller.py > poller.log 2>&1 &
```
oppure (consigliato) un timer systemd utente:
```ini
# ~/.config/systemd/user/ponte.service
[Unit]
Description=Ponte arena->agenti via GitHub
[Service]
WorkingDirectory=%h/posta/lavori/ponte
ExecStart=/usr/bin/python3 %h/posta/lavori/ponte/poller.py
Restart=on-failure
[Install]
WantedBy=default.target
```
```bash
systemctl --user daemon-reload && systemctl --user enable --now ponte
journalctl --user -u ponte -f
```

## 7. Uso dall'agente di arena
- Apri issue col corpo del TEMPLATE_ISSUE.md (etichetta `inbox`; `richiede-conferma` se delicata)
- "Controlla la issue #N" per leggere stato ed esito
- I file consegnati stanno in `/consegne/<N>-.../` nel repo

## Disattivazione
```bash
systemctl --user disable --now ponte   # se systemd
pkill -f poller.py                     # se nohup
```
Il lock `_stato/poller.lock` viene rimosso da solo all'uscita; se restasse (kill -9),
cancellalo a mano prima di riavviare.
