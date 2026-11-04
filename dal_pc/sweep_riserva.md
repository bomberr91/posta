# MISURA DI VITALITA' DELLA RISERVA — 04/11/2026 22:12

Metodo: una richiesta minima per provider (max_tokens 5). Nessuna scrittura,
nessuna cancellazione, nessuna chiave stampata.

provider misurati: 58 | verdi: 23 | non verdi: 35

## VERDI (rispondono davvero)
  agnes              200    risponde
  bazaarlink         200    risponde
  blockrun           200    risponde
  cohere             200    risponde
  electronhub        200    risponde
  freeai             200    risponde
  gemini             200    risponde
  inferbase          200    risponde
  mistral            200    risponde
  nscale             200    risponde
  nvidia             200    risponde
  openrouter         200    risponde
  plugsky            200    risponde
  pollinations       200    risponde
  pollinationsfree   200    risponde
  router9            200    risponde
  routeway           200    risponde
  sail               200    risponde
  sealion            200    risponde
  speka              200    risponde
  tokenharbor        200    risponde
  typhoon            200    risponde
  unorouter          200    risponde

## NON VERDI (candidati da togliere — proposta, NESSUNA cancellazione fatta)
  agentrouter        400            {"error":{"code":"content-blocked","message":"content-blocked (request id: 202611050512186
  aihorde            400            {"error":{"message":"Invalid 'max_tokens': the AI Horde refuses a token limit below 16, th
  aion               403            error code: 1010 
  anyapi             429            {"error":{"message":"Rate limit reached: free-tier daily cap is shared across users. Switc
  api-airforce       403            error code: 1010 
  blazeapi           TIMEOUT/RETE   The read operation timed out
  clod               403            error code: 1010 
  dreamprompting     403            error code: 1010 
  ghmodels           200            200 ma non e' una chat
  gizmo              403            error code: 1010 
  groq               403            error code: 1010 
  huggingface        402            {"error":"Purchase pre-paid credits to continue using Inference Providers. Alternatively, 
  jina               422            {"detail":"Validation error: 'body -> model' Input should be 'jina-ocr-v1'","request_id":"
  kilo               401            {"error":{"code":"INVALID_TOKEN","message":"Your authentication token is invalid. Please s
  llm7               503            {"error":{"message":"This model is temporarily busy. Please try again shortly or choose an
  llmtr              429            {"error":{"message":"Free models are busy right now. Paid models are not affected. Please 
  logfare            TIMEOUT/RETE   The read operation timed out
  longcat            402            AppId:**QK9I Usage limit reached.
  lucidity           404            {"error":{"message":"Free model variants were retired unless explicitly enabled by an admi
  moondream          403            error code: 1010 
  navy               403            error code: 1010 
  ollamacloud        404            {"error":{"message":"model \"auto\" not found. Try gemma4:31b-cloud, which is in the Free 
  opencode           403            error code: 1010 
  orcarouter         429            {"error":{"code":"free_rate_limited","message":"Free model capacity is limited right now. 
  ovh                403            {"message":"Forbidden: authentication failed.  Please generate a new one at https://kepler
  pollinationsimg    200            200 ma non e' una chat
  qdrant             403            forbidden
  requesty           400            {"error":{"origin":"router","message":"Invalid model ID. See https://app.requesty.ai/model
  septorlabs         403            error code: 1010 
  simplellm          TIMEOUT/RETE   The read operation timed out
  speechify          404            The requested resource was not found.
  waterfall          401            invalid_api_key
  wavespeed          400            {"code":400,"message":"Model not found."}
  xkiro              403            error code: 1010 
  zhipu              400            模型不存在，请检查模型代码。

## in squadra (non propongo di toccarli)
  chutes, cloudflare, cohere, ghmodels, groq, kilo, llmtr, mistral, nvidia, opencode, pollinations

--- sweep_riserva: scritto in dal_pc/sweep_riserva.md ---

<!-- fine sweep_riserva -->
