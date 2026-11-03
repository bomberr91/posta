# Risposta a «patch_browser_agenti»

_03/11/2026 09:55 · FilippoPC_

## 1. Browser isolato (CDP 18800)
- 18800: non risponde (URLError) -> va avviato dal collegamento sul desktop

## 2. Skill use-my-browser: tolgo --autoConnect
- copia: /home/agenti/.agents/skills/use-my-browser
    [parametro] README.md: --autoConnect -> --browserUrl 18800
    [porta] README.md: 9222 -> 18800
    [parametro] README.zh.md: --autoConnect -> --browserUrl 18800
    [porta] README.zh.md: 9222 -> 18800
    [avviso] inserito in README.md
- copia: /home/agenti/.config/opencode/skills/use-my-browser
    [parametro] README.md: --autoConnect -> --browserUrl 18800
    [porta] README.md: 9222 -> 18800
    [parametro] README.zh.md: --autoConnect -> --browserUrl 18800
    [porta] README.zh.md: 9222 -> 18800
    [avviso] inserito in README.md
- copia: /home/agenti/.claude/skills/use-my-browser
    [parametro] README.md: --autoConnect -> --browserUrl 18800
    [porta] README.md: 9222 -> 18800
    [parametro] README.zh.md: --autoConnect -> --browserUrl 18800
    [porta] README.zh.md: 9222 -> 18800
    [avviso] inserito in README.md

## 3. Config OpenCode: MCP chrome-devtools sul browser isolato
- MCP chrome-devtools aggiornato verso http://127.0.0.1:18800
- config finale:
    {
      "$schema": "https://opencode.ai/config.json",
      "mcp": {
        "chrome-devtools": {
          "type": "local",
          "command": [
            "npx",
            "-y",
            "chrome-devtools-mcp@latest",
            "--browserUrl=http://127.0.0.1:18800"
          ],
          "enabled": true
        }
      }
    }

## 4. Verifica
- ATTENZIONE: resta --autoConnect in:
    /home/agenti/.agents/skills/use-my-browser/README.md
    /home/agenti/.config/opencode/skills/use-my-browser/README.md
    /home/agenti/.claude/skills/use-my-browser/README.md
- il config OpenCode punta a 18800: OK

<!-- fine patch_browser_agenti -->
