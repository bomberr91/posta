# Indice rapido — `posta`

Guida di navigazione della cartella della Centrale Agenti. **Non spostare i file elencati**: la Centrale e i launcher usano i loro percorsi attuali.

## Avvio e installazione

- `CENTRALE_AGENTI.bat` — launcher principale.
- `8_CENTRALE_GUI.bat` — aggiorna la repo e avvia la GUI della Centrale.
- `00_INSTALLA_AGENTI/` — installatori e diagnostica, ordinati in cima a Esplora file.
  - `01_HERMES.bat` — installazione Hermes nativa Windows.
  - `02_DIAGNOSTICA_HERMES_WINDOWS.bat` — controllo di sola lettura; non installa.
  - `03_OPENCODE_WINDOWS.bat` — controlla OpenCode; lo installa solo se manca, senza configurare provider o toccare altri agenti.
  - `04_GOOSE_WINDOWS.bat` — installa Goose Desktop ufficiale x64, verifica lo ZIP e crea un'icona; non configura provider né avvia l'app.
  - `05_SECONDHAND_WINDOWS.bat` — installa Open Interpreter (Secondhand) ufficiale, verifica la versione e crea un'icona; non configura provider né avvia l'agente.
  - `06_ANTIGRAVITY_WINDOWS.bat` — installa Antigravity CLI ufficiale Google, riprova i download interrotti, verifica la versione e crea un'icona; non avvia l'agente né configura account/provider.
  - `07_ICONE_AGENTI_WINDOWS.bat` — crea/aggiorna le icone con logo di Hermes, OpenCode, Secondhand e Antigravity; lascia Goose e OpenClaw intatti e non avvia agenti.
  - `08_ICONA_OPENCLAW_WINDOWS.bat` — crea solo il collegamento Desktop OpenClaw con logo ufficiale, usando il launcher WSL esistente; non installa o modifica l'agente.
- `6_BROWSER_AGENTI.bat` — browser isolato per agenti.
- `7_SQUADRA_FUSION.bat` — avvio squadra Fusion.

## Cartelle di lavoro

- `gui/` — interfaccia e server della Centrale.
- `dal_pc/` — aggiornamenti e rapporti ricevuti dal PC.
- `RISPOSTE_AGENTI/` — risposte degli agenti salvate su file.
- `fatti/` — attività concluse e relativi marker.
- `raccogilink/` — strumento per cercare e raccogliere link.

## Regola: agenti separati

Ogni agente mantiene la propria installazione, configurazione e dati. Non migrare o fondere i dati senza richiesta esplicita. OpenClaw era già installato: resta com'è, non va reinstallato né modificato. Hermes è ora installato nativamente su Windows e può essere avviato da PowerShell con `hermes`; il collegamento al Hub è un passaggio separato.
