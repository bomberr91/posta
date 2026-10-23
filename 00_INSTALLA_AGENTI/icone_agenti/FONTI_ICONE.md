# Icone desktop agenti

File `.ico` per le scorciatoie Windows create da `07_ICONE_AGENTI_WINDOWS.bat`.

- **Hermes** — icona ufficiale Hermes Agent, repository NousResearch: https://github.com/NousResearch/hermes-agent/tree/main/assets
- **OpenCode** — marchio OpenCode, adattamento SVG di Simple Icons: https://github.com/simple-icons/simple-icons/blob/develop/icons/opencode.svg · linee guida ufficiali: https://opencode.ai/brand
- **Secondhand / Open Interpreter** — marchio dal repository ufficiale: https://github.com/openinterpreter/openinterpreter/tree/main/logo
- **Antigravity** — icona a colori dalla pagina ufficiale Google Press Assets: https://antigravity.google/press/
- **OpenClaw** — icona `.ico` dal repository ufficiale: https://github.com/openclaw/openclaw/tree/main/apps/linux/src-tauri/icons

`07_ICONE_AGENTI_WINDOWS.bat` copia le prime quattro icone in `%LOCALAPPDATA%\AgentiDesktop\icone` e aggiorna le rispettive scorciatoie; Goose e OpenClaw restano intatti. `08_ICONA_OPENCLAW_WINDOWS.bat`, su richiesta, crea solo la scorciatoia per il comando OpenClaw nativo Windows e copia il suo logo; non usa WSL e non modifica installazione, configurazione o dati dell'agente.
