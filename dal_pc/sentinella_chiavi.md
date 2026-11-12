# 🛡️ Sentinella delle chiavi — 12/11/2026 16:03

## 1. Catalogo freellmapi
```
catalogo 2026.11.12 · 33 provider · 357 modelli · 100 quirk
scritto: /home/agenti/posta/lavori/catalogo_freellmapi.json
```

## 2. Appello (solo i problemi)
```
  · Moondream          non-chat: escluso dall'appello (il cervello lo usa su richiesta)
  [31m✗[0m Nscale               1277 ms  {"error":{"message":"No matching route found. It is likely because the model specified in 
  [32m✓[0m NVIDIA              31700 ms  ha risposto davvero (nvidia/nemotron-3-ultra-550b-a55b)
  [31m✗[0m Ollama Cloud         1079 ms  {"error":{"message":"model \"auto\" not found. Try glm-5.3-flash:cloud.","type":"not_found
  [33m◐[0m OpenCode Zen          812 ms  limite o credito finito adesso
  [32m✓[0m OpenRouter           9268 ms  ha risposto davvero (dots-studio/dots-3-note-preview:free)
  [32m✓[0m Plugsky              2479 ms  ha risposto davvero (plugsky-micro)
  [33m—[0m Qdrant Cloud       nessuna chiave nel portachiavi
  [32m✓[0m Requesty             2342 ms  ha risposto davvero (nvidia/nemotron-3-ultra-550b-a55b)
  [31m✗[0m Router9              1648 ms  {"error":{"code":"model_requires_upgrade","message":"Model \"deepseek/deepseek-v4-pro\" is
  [32m✓[0m Routeway             2422 ms  ha risposto davvero (gemma-4-26b-a4b-it-chimerax:free)
  [32m✓[0m Sail                 4387 ms  ha risposto davvero (moonshotai/Kimi-K3)
  [32m✓[0m SeaLION              5255 ms  ha risposto davvero (aisingapore/Qwen-SEA-LION-v4.5-27B-IT)
  [32m✓[0m Septor Labs          4299 ms  ha risposto davvero (minimax-m2.5-free)
  [32m✓[0m SimpleLLM             861 ms  ha risposto davvero (free-Llama-3.1-8B-Instruct)
  · Speechify          non-chat: escluso dall'appello (il cervello lo usa su richiesta)
  [32m✓[0m Speka                4095 ms  ha risposto davvero (nvidia/nemotron-3-ultra-550b-a55b)
  [32m✓[0m Typhoon              1406 ms  ha risposto davvero (typhoon-v2.5-30b-a3b-instruct)
  [33m◐[0m UnoRouter             508 ms  limite o credito finito adesso
  · WaveSpeedAI        non-chat: escluso dall'appello (il cervello lo usa su richiesta)
  [31m✗[0m xKiro                1614 ms  {"error":{"message":"Model \"qwen/qwen3.7-max:free\" does not exist.","type":"not_found_er
  [33m◐[0m Zhipu                1143 ms  limite o credito finito adesso

  Rapporto: /home/agenti/posta/dal_pc/appello_chiavi.md
  Riserva pronta: /home/agenti/.posta_appello.json
```

riserva ora: 28 su 61 provider

## 3. NavyAI (sentinella dedicata)
```
NavyAI: chiave trovata (51 caratteri)
  schizogpt -> HTTP 403 "message":"The Free plan is temporarily paused for all users. You can purchase a plan at ht
  gpt-6.1-sol -> HTTP 403 "message":"The Free plan is temporarily paused for all users. You can purchase a plan at ht
  gpt-6-astra -> HTTP 403 "message":"The Free plan is temporarily paused for all users. You can purchase a plan at ht
  gpt-5.6-sol -> HTTP 403 "message":"The Free plan is temporarily paused for all users. You can purchase a plan at ht
```

## 4. Check-in AgentRouter
check-in non eseguito: o non e' l'ora (dopo le 18:05), o il browser degli agenti non risponde, o e' gia' stato fatto oggi.

## 5. LongCat - quota giornaliera
sonda non avviata: nessun log in ~/sonda_longcat.log

## 6. Servizi parcheggiati (Waterfall, NavyAI)
```
# 📡 Sentinella dei servizi parcheggiati — 12/11/2026 09:54

Ogni giorno bussa a Waterfall e NavyAI (parcheggiati, fuori dal roster): aspettiamo che si muovano da soli.

## Waterfall (waterfall)
- indirizzo: https://api.getwaterfall.org/v1 · modello: auto · chiave: presente
- esito: HTTP 401
```
{"error":"invalid_api_key","message":"Unknown or revoked API key."}
```

## NavyAI (navy)
- indirizzo: https://api.navy/v1 · modello: schizogpt · chiave: presente
- esito: HTTP 403
```
{"error":{"message":"The Free plan is temporarily paused for all users. You can purchase a plan at https://api.navy/dashboard/billing to continue using the API.","type":"permission_error","code":"insufficient_plan"}}
```

--- fine sentinella servizi ---
```
