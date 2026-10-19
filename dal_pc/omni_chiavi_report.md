# 🔑 Rapporto innesto chiavi in OmniRoute — 19/10/2026 09:47

- groq: ①   ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone. Provider credential (hidden): ✖ Provider credential is required.  ② Login: enabled Provider: groq (Groq) 
- gemini: ①   ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone. Provider credential (hidden): ✖ Provider credential is required.  ② Login: enabled Provider: gemini (gemini) 
- mistral: ①   ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone. Provider credential (hidden): ✖ Provider credential is required.  ② Login: enabled Provider: mistral (Mistral) 
- cohere: ①   ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone. Provider credential (hidden): ✖ Provider credential is required.  ② Login: enabled Provider: cohere (cohere) 
- openrouter: ①   ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone. Provider credential (hidden): ✖ Provider credential is required.  ② Login: enabled Provider: openrouter (OpenRouter) 
- nvidia: ①   ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone. Provider credential (hidden): ✖ Provider credential is required.  ② Login: enabled Provider: nvidia (nvidia) 
- agentrouter: ①   ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone. Provider credential (hidden): ✖ Provider credential is required.  ② Login: enabled Provider: agentrouter (agentrouter) 

## Connessioni configurate adesso
  📋 Loaded env from /home/agenti/.omniroute/.env
  📋 Loaded env from /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env
  ⚠ STORAGE_ENCRYPTION_KEY in /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env is ignored, /home/agenti/.omniroute/.env set it first
  ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone.

OmniRoute Providers

f47c670f   agentrouter    agentrouter              unknown
776dfd0a   cohere         cohere                   unknown
a1b9e8b9   gemini         gemini                   unknown
c6096a89   groq           Groq                     unknown
7fe1fb15   mistral        Mistral                  unknown
5f6c397d   nvidia         nvidia                   unknown
2d2d2b71   openrouter     OpenRouter               unknown

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

## Riaccensione motore + domanda di prova
{"id":"chatcmpl-8aa36235-a685-4d6b-a5b7-f96430c3c9ea","object":"chat.completion","created":1792396147,"model":"openai/gpt-oss-120b","choices":[{"index":0,"finish_reason":"length","message":{"role":"assistant","content":"","reasoning":"The user wants a response only with the word \"OK\". So I should reply with"},"logprobs":null}],"usage":{"prompt_tokens":80,"completion_tokens":20,"total_tokens":100,"completion_tokens_details":{"reasoning_tokens":18}},"system_fingerprint":"fp_a655021f7d"}
