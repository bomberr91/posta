# 🔑 Rapporto innesto chiavi in OmniRoute — 21/10/2026 10:43

/home/agenti/posta/omni_chiavi.sh: line 83: QUI: unbound variable

## Connessioni configurate adesso
  📋 Loaded env from /home/agenti/.omniroute/.env
  📋 Loaded env from /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env
  ⚠ STORAGE_ENCRYPTION_KEY in /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env is ignored, /home/agenti/.omniroute/.env set it first
  ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone.

OmniRoute Providers

f47c670f   agentrouter    agentrouter              active
776dfd0a   cohere         cohere                   active
a1b9e8b9   gemini         gemini                   active
c6096a89   groq           Groq                     active
7fe1fb15   mistral        Mistral                  active
5f6c397d   nvidia         nvidia                   active
2d2d2b71   openrouter     OpenRouter               active

## Test di tutte le connessioni (a motore spento)
  📋 Loaded env from /home/agenti/.omniroute/.env
  📋 Loaded env from /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env
  ⚠ STORAGE_ENCRYPTION_KEY in /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env is ignored, /home/agenti/.omniroute/.env set it first
  ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone.

OmniRoute Provider Tests

SKIP agentrouter: Provider test not supported
SKIP cohere: Provider test not supported
SKIP gemini: Provider test not supported
OK Groq: provider test passed
OK Mistral: provider test passed
SKIP nvidia: Provider test not supported
OK OpenRouter: provider test passed

## 📊 LINEE: 3/7 superano il test (4 non testabili dal CLI, non per forza rotte)

## Riaccensione motore + domanda di prova
