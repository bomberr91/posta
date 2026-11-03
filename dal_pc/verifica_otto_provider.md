# Risposta a «verifica_otto_provider»

_03/11/2026 16:48 · FilippoPC_

======================================================================
typhoon (Typhoon)  base=https://api.opentyphoon.ai/v1  modello=typhoon-v2.5-30b-a3b-instruct  chiave=SI
   /models -> 200 [{"id":"typhoon-v2.5-30b-a3b-instruct","object":"model","display_name":"typhoon-v2.5-30b-a3b-instruct"},{"id":
   CHAT -> 200  risposta: 'OK'
======================================================================
tokenharbor (Token Harbor)  base=https://tokenharbor.ai/v1  modello=deepseek-v4-flash:free  chiave=SI
   /models -> 200 {"object":"list","data":[{"id":"claude-sonnet-4.6","object":"model","created":1700000000,"owned_by":"tokenharb
   CHAT -> 200  risposta: 'OK'
======================================================================
waterfall (Waterfall)  base=https://api.getwaterfall.org/v1  modello=auto  chiave=SI
   /models -> 200 {"object":"list","data":[{"id":"auto","object":"model","created":0,"owned_by":"waterfall"},{"id":"sea-lion-7b-
   CHAT -> 401  {"error":"invalid_api_key","message":"Unknown or revoked API key."}
======================================================================
navy (NavyAI)  base=https://api.navy/v1  modello=schizogpt  chiave=SI
   /models -> 200 {"object":"list","data":[{"id":"schizogpt","object":"model","created":1749028256,"owned_by":"navyai","endpoint
   CHAT -> 403  {"error":{"message":"The Free plan is temporarily paused for all users. You can purchase a plan at https://api.navy/dashboard/billing to continue using the API.","type":"permission
======================================================================
anyapi (AnyAPI)  base=https://api.anyapi.ai/v1  modello=nvidia/nemotron-3.5-lightning:free  chiave=SI
   /models -> 200 {"data":[{"id":"google/gemma-4-26b-a4b-it:free","object":"model","created":1677610602,"owned_by":"openai","tag
   CHAT -> 429  {"error":{"message":"Rate limit reached: free-tier daily cap is shared across users. Switch to a paid model for best performance.","type":"free_tier_capacity","param":null,"code":"
======================================================================
gizmo (Gizmo)  base=https://api.gizmoplatforms.com/api/v1  modello=nvidia/nemotron-3.5-lightning:free  chiave=SI
   /models -> 200 {"object":"list","data":[{"id":"z-ai/glm-5.3-flashx-legal","object":"model","owned_by":"z-ai"},{"id":"openai/g
   CHAT -> 429  {"error":{"message":"Every provider for nvidia/nemotron-3.5-lightning:free failed: openrouter 429 (HTTP 429). Nothing was charged; try again shortly.","type":"rate_limit_error","co
======================================================================
aihorde (AI Horde)  base=https://oai.aihorde.net/v1  modello=koboldcpp/gemma-4-26B-A4B-it-ultra-uncensored-heretic  chiave=NO
   /models -> 200 {"object":"list","data":[{"id":"koboldcpp/debug-gemma-4-E2B-Queen-it-qat-q4_0-unquantized.i1-Q4_K_M","object":
   CHAT -> 0  ERR <urlopen error [Errno 111] Connection refused>
======================================================================
longcat (LongCat)  base=https://api.longcat.chat/openai/v1  modello=LongCat-2.5  chiave=SI
   /models -> 200 {"object":"list","data":[{"id":"LongCat-2.5-Preview","object":"model","owned_by":"LongCat","display_name":"Lon
   CHAT -> 402  {"error":{"code":"too_many_requests","message":"AppId:**QK9I Usage limit reached.","type":"rate_limit_error"}}
FINE

<!-- fine verifica_otto_provider -->
