# 🛡️ Sentinella delle chiavi — 19/11/2026 19:42

## 1. Catalogo freellmapi
```
catalogo non letto: <urlopen error [Errno -3] Temporary failure in name resolution>
```

## 2. Appello (solo i problemi)
```
  · Moondream          non-chat: escluso dall'appello (il cervello lo usa su richiesta)
  [31m✗[0m Nscale              40848 ms  non raggiungibile
  [31m✗[0m NVIDIA              41197 ms  non raggiungibile
  [31m✗[0m OpenCode Zen        41076 ms  non raggiungibile
  [31m✗[0m OpenRouter          41385 ms  non raggiungibile
  [31m✗[0m OrcaRouter          20754 ms  non raggiungibile
  [31m✗[0m Plugsky             21948 ms  non raggiungibile
  [33m—[0m Qdrant Cloud       nessuna chiave nel portachiavi
  [31m✗[0m Requesty            41125 ms  non raggiungibile
  [31m✗[0m Router9             41121 ms  non raggiungibile
  [31m✗[0m Routeway            41522 ms  non raggiungibile
  [31m✗[0m Sail                20803 ms  non raggiungibile
  [31m✗[0m SeaLION             41177 ms  non raggiungibile
  [31m✗[0m Septor Labs         41835 ms  non raggiungibile
  [31m✗[0m SimpleLLM           20657 ms  non raggiungibile
  · Speechify          non-chat: escluso dall'appello (il cervello lo usa su richiesta)
  [31m✗[0m Speka               40870 ms  non raggiungibile
  [31m✗[0m Typhoon             21375 ms  non raggiungibile
  [31m✗[0m UnoRouter           41968 ms  non raggiungibile
  · WaveSpeedAI        non-chat: escluso dall'appello (il cervello lo usa su richiesta)
  [31m✗[0m xKiro               40457 ms  non raggiungibile
  [31m✗[0m Zhipu               40725 ms  non raggiungibile

  Rapporto: /home/agenti/posta/dal_pc/appello_chiavi.md
  Riserva pronta: /home/agenti/.posta_appello.json
```

riserva ora: 8 su 61 provider

## 3. NavyAI (sentinella dedicata)
```
NavyAI: chiave trovata (51 caratteri)
  schizogpt -> HTTP 000 
  gpt-6.1-sol -> HTTP 000 
  gpt-6-astra -> HTTP 000 
  gpt-5.6-sol -> HTTP 000 
```

## 4. Check-in AgentRouter
check-in non eseguito: o non e' l'ora (dopo le 18:05), o il browser degli agenti non risponde, o e' gia' stato fatto oggi.

## 6. Servizi parcheggiati (Waterfall, NavyAI)
```
# 📡 Sentinella dei servizi parcheggiati — 19/11/2026 00:08

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
