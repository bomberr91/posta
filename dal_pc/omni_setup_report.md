# 🧠 Rapporto OmniRoute v2 — 20/10/2026 22:29

## Tentativi di attivazione
- modal: ① Database: /home/agenti/.omniroute/storage.sqlite ✖ Provider API key is required. Pass --api-key or OMNIROUTE_API_KEY.   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- vertex: ① Database: /home/agenti/.omniroute/storage.sqlite ✖ Provider API key is required. Pass --api-key or OMNIROUTE_API_KEY.   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- cloudflare-ai: ① Database: /home/agenti/.omniroute/storage.sqlite ✖ Provider API key is required. Pass --api-key or OMNIROUTE_API_KEY.   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- scaleway: ① Database: /home/agenti/.omniroute/storage.sqlite ✖ Provider API key is required. Pass --api-key or OMNIROUTE_API_KEY.   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- reka: ① Database: /home/agenti/.omniroute/storage.sqlite ✖ Provider API key is required. Pass --api-key or OMNIROUTE_API_KEY.   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- gemini: già attivo
- groq: già attivo
- blackbox: ① Database: /home/agenti/.omniroute/storage.sqlite ✖ Provider API key is required. Pass --api-key or OMNIROUTE_API_KEY.   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- mistral: già attivo
- cohere: già attivo
- morph: ① Database: /home/agenti/.omniroute/storage.sqlite ✖ Provider API key is required. Pass --api-key or OMNIROUTE_API_KEY.   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- ai21: ① Database: /home/agenti/.omniroute/storage.sqlite ✖ Provider API key is required. Pass --api-key or OMNIROUTE_API_KEY.   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- nous-research: ①  ✖ locking protocol   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- arcee-ai: ①  ✖ locking protocol   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- liquid: ①  ✖ locking protocol   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- inception: ①  ✖ locking protocol   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- freebuff: ①  ✖ locking protocol   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- charm-hyper: ①  ✖ locking protocol   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- agentrouter: già attivo
- unorouter: ①  ✖ locking protocol   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- openrouter: già attivo
- requesty: ①  ✖ locking protocol   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- zylo-api: ①  ✖ locking protocol   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  
- fastrouter: ①  ✖ locking protocol   ②     omniroute providers remove <id> — remove a connection (requires confirmation)  

## Connessioni attive dopo i tentativi
  📋 Loaded env from /home/agenti/.omniroute/.env
  📋 Loaded env from /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env
  ⚠ STORAGE_ENCRYPTION_KEY in /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env is ignored, /home/agenti/.omniroute/.env set it first
  ⚠ /home/agenti/.nvm/versions/node/v22.23.3/lib/node_modules/omniroute/.env lives inside the installed package: updating OmniRoute replaces it. Move the values you set to /home/agenti/.omniroute/.env, which updates leave alone.
✖ locking protocol 

## Riaccensione motore + test VERO
### Domanda di prova al modello auto (deve rispondere OK):
{"id":"chatcmpl-3c4f3338-417c-406f-ad24-a09bb8a7d897","object":"chat.completion","created":1792528359,"model":"openai/gpt-oss-120b","choices":[{"index":0,"finish_reason":"length","message":{"role":"assistant","content":"","reasoning":"The user says: \"Rispondi solo con la parola: OK\". That means"},"logprobs":null}],"usage":{"prompt_tokens":80,"completion_tokens":20,"total_tokens":100,"completion_tokens_details":{"reasoning_tokens":18}},"system_fingerprint":"fp_8655ddce88"}
