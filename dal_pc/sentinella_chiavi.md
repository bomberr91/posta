# 🛡️ Sentinella delle chiavi — 26/11/2026 21:51

## 1. Catalogo freellmapi
```
catalogo 2026.11.26 · 31 provider · 299 modelli · 115 quirk
scritto: /home/agenti/posta/lavori/catalogo_freellmapi.json
```

## 2. Appello (solo i problemi)
```

  [31m✗[0m AgentRouter         18208 ms  {"error":{"message":"当前分组 default 下对于模型 gpt-5.6-sol 无可用渠道 (req
  [31m✗[0m AI Horde            61126 ms  {"error":{"message":"The model 'koboldcpp/gemma-4-26B-A4B-it-ultra-uncensored-heretic' is 
  [33m◐[0m Api.Airforce          887 ms  limite o credito finito adesso
  [33m◐[0m BazaarLink           2932 ms  limite o credito finito adesso
  [31m✗[0m BlazeAPI              668 ms  {"error":{"message":"Model \"free/claude-haiku-4.5\" not found or unavailable.","type":"in
  [31m✗[0m CLōD                1234 ms  chiave rifiutata
  [33m◐[0m Cohere               1079 ms  limite o credito finito adesso
  [33m◐[0m Google AI Studio     5039 ms  limite o credito finito adesso
  [33m◐[0m Gizmo                3344 ms  limite o credito finito adesso
  [32m✓[0m Logfare             11731 ms  ha risposto davvero (logfare/auto)
  [33m◐[0m Lucidity             1278 ms  limite o credito finito adesso
  [31m✗[0m Mistral              1305 ms  {"object":"error","message":"You need a subscription to access this API.","type":"billing_
  [31m✗[0m Nscale               1295 ms  {"error":{"message":"No matching route found. It is likely because the model specified in 
  [33m◐[0m OpenCode Zen          770 ms  limite o credito finito adesso
  [33m◐[0m OrcaRouter           1198 ms  limite o credito finito adesso
  [33m—[0m Qdrant Cloud       nessuna chiave nel portachiavi
  [31m✗[0m Router9              1737 ms  {"error":{"code":"model_requires_upgrade","message":"Model \"deepseek/deepseek-v4-pro\" is
  [31m✗[0m Sail                 1326 ms  {"error":{"message":"model 'moonshotai/Kimi-K3' is not supported","type":"invalid_request_
  [31m✗[0m Speka                1284 ms  {"error":{"message":"Model 'nvidia/nemotron-3-ultra-550b-a55b' is temporarily unavailable 
  [31m✗[0m UnoRouter            1288 ms  {"error":{"code":"model_not_found","message":"Model \"qwen/qwen3.8-27b\" is not offered he
  [33m◐[0m Zhipu                1771 ms  limite o credito finito adesso

  Rapporto: /home/agenti/posta/dal_pc/appello_chiavi.md
  Riserva pronta: /home/agenti/.posta_appello.json
```

riserva ora: 30 su 61 provider

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

## 6. Servizi parcheggiati (Waterfall, NavyAI)
```
# 📡 Sentinella dei servizi parcheggiati — 26/11/2026 09:51

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
