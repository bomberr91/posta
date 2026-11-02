# Risposta a «indaga_quota_8provider»

_02/11/2026 16:08 · FilippoPC_

# Indagine quota sui provider fermi — 02/11/2026 16:08

Nessuna conclusione qui dentro: solo codici, corpi e testate. Le domande
"quando torna" e "cosa fare" le risponde l'agente, dopo.

================================================================
### AI Horde — roster dei volontari
  worker online: wicked-tutu-26b-w8a16
  worker online: koboldcpp/Llama-3.2-1B-Instruct
  worker online: koboldcpp/Qwen3.5-27B-heretic
  worker online: koboldcpp/gemma-4-26B-A4B-it-ultra-uncensored-heretic
  worker online: koboldcpp/gemma-4-31B-it-heretic
  worker online: koboldcpp/gemma-3-270m-it-F16
  worker online: koboldcpp/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-Q4_K_M
  worker online: koboldcpp/L3-8B-Stheno-v3.2
  chat AI Horde 'wicked-tutu-26b-w8a16' -> HTTP 404 : {"error":{"message":"The model 'wicked-tutu-26b-w8a16' is not known to this horde: the text model reference does not list it and no online worker serves chat jobs with it.","type":"not_found_error","p
  chat AI Horde 'koboldcpp/Llama-3.2-1B-Instruct' -> HTTP 503 : {"error":{"message":"No online worker can serve this request at the moment; it was cancelled. Retry later.","type":"api_error","param":null,"code":"no_eligible_worker","metadata":{"request_id":"6ec169
  chat AI Horde 'koboldcpp/gemma-4-26B-A4B-it-ultra-uncensored-heretic' -> HTTP 000 : {"error":{"message":"No online worker can serve this request at the moment; it was cancelled. Retry later.","type":"api_error","param":null,"code":"no_eligible_worker","metadata":{"request_id":"6ec169
  catalogo freellmapi: 'aihorde' · modelli=32 rpm=[] rpd=[]
    id gratuiti dal catalogo (dal piu' promettente):
      - koboldcpp/gemma-4-31B-it-heretic (rank 73, rpm None, rpd None)
      - koboldcpp/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive (rank 93, rpm None, rpd None)
      - koboldcpp/Gemma-4-E4B-it-Ultra-Uncensored-Heretic (rank 93, rpm None, rpd None)
      - koboldcpp/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-Q4_K_M (rank 93, rpm None, rpd None)
      - koboldcpp/Llama-3.2-3B (rank 95, rpm None, rpd None)
      - koboldcpp/Qwen/Qwen3.5-0.8B (rank 95, rpm None, rpd None)
      - meta-llama/Llama-3.2-3B-Instruct (rank 95, rpm None, rpd None)
      - koboldcpp/Llama-3.2-3B-Instruct-Q4_K_M (rank 95, rpm None, rpd None)
      - koboldcpp/Qwen3-4B-Nymphaea-RP.i1-Q4_K_S (rank 95, rpm None, rpd None)
      - koboldcpp/llama-3.2-3b-instruct-q4_k_m (rank 95, rpm None, rpd None)
      - koboldcpp/Qwen_Qwen3-0.6B-IQ4_XS (rank 97, rpm None, rpd None)
      - koboldcpp/digo-prayudha/unsloth-llama-3.2-1b-gguf (rank 97, rpm None, rpd None)
   · [Free volunteer queue, slow] AI Horde routes to volunteer-run workers through a priority queue, so latency is seconds to minutes, not the sub-second of hosted providers. The anonymous key 0000000000 runs at the lowest priority; register a free key at aihorde.net for higher priority. The provider uses a 120s timeout.
   · [No tool calling] AI Horde's OpenAI-compatible proxy does not support function/tool calling. The provider drops tools, tool_choice and parallel_tool_calls so a tool-using request still completes as plain chat instead of failing.
   · [Usage is kudos; tokens estimated] The proxy returns usage as {"kudos": N} with no token counts, and rejects max_tokens below 16 and a non-array stop. The AIHordeProvider normalizes the request (floors max_tokens, wraps stop) and synthesizes prompt/completion token estimates so analytics and savings math aren't zero.
   · [Roster + context depend on online workers] Model availability changes as volunteer workers come and go, so a listed model can be temporarily unserved. The effective context window is set by the worker (often 4-8K), not the model's native maximum.
   · [Uneven quality] Output quality varies by worker and quantization, and some workers append template or instruction text after the answer. Best treated as free fallback capacity, not a primary model.
   · [123B has heavy queue (seeded disabled)] Behemoth-X-123B has deep queue depth (50s+ ETA even on trivial prompts). Seeded disabled; enable only if minute-scale latency is acceptable.

================================================================
### NaraRouter  (id=nara)
  indirizzo: https://router.bynara.id/v1   modello in lista: auto   modo: modelli   tipo: chat
  extra in lista: nessuno
  chiave: trovata, 50 caratteri
  GET https://router.bynara.id/v1/models -> HTTP 200
  testate:
    strict-transport-security: max-age=31536000; includeSubDomains
    x-content-type-options: nosniff
    x-frame-options: DENY
    x-request-id: 629f86f1-36bb-4922-b8b0-49dd56c9a466
    id nel catalogo: 44
      - claude-fable-5.1
      - claude-haiku-5.5
      - claude-opus-4.8
      - claude-opus-5
      - claude-opus-5.5
      - claude-sonnet-5
      - claude-sonnet-5.5
      - deepseek-v4.1-flash
      - deepseek-v4.1-flash-fast
      - deepseek-v4.1-flash-uncensored
  chat 'auto' -> HTTP 404
    corpo: {"error":{"type":"not_found","message":"The requested model does not exist.","request_id":"c51fc5e5-9049-43fb-9182-d275a75ca7bf"}}
    testate:
      strict-transport-security: max-age=31536000; includeSubDomains
      x-content-type-options: nosniff
      x-frame-options: DENY
      x-request-id: c51fc5e5-9049-43fb-9182-d275a75ca7bf
    (errore di NOME MODELLI: provo il prossimo candidato)
  chat 'claude-fable-5.1' -> HTTP 429
    corpo: {"error":{"type":"rate_limited","message":"Insufficient credits. Please top up your balance and try again in a few minutes.","request_id":"11dcdbf5-de60-4943-be06-21e059340f95"}}
    testate:
      strict-transport-security: max-age=31536000; includeSubDomains
      x-content-type-options: nosniff
      x-frame-options: DENY
      x-request-id: 11dcdbf5-de60-4943-be06-21e059340f95
  endpoint di quota:
  catalogo freellmapi: 'nara' · modelli=9 rpm=[10] rpd=[]
    id gratuiti dal catalogo (dal piu' promettente):
      - nex-n2.5-pro (rank 49, rpm 10, rpd None)
      - laguna-s-2.1 (rank 57, rpm 10, rpd None)
      - ling-3.0-flash-vl-free (rank 57, rpm 10, rpd None)
      - ling-3.0-flash-fin-free (rank 61, rpm 10, rpd None)
      - nemotron-3-ultra-free (rank 61, rpm 10, rpd None)
      - agnes-2.5-flash (rank 63, rpm 10, rpd None)
      - ling-3.0-flash-sante-free (rank 65, rpm 10, rpd None)
      - nemotron-3-super-free (rank 81, rpm 10, rpd None)
      - nemotron-3.5-lightning-free (rank 81, rpm 10, rpd None)
   · [Daily free quota] NaraRouter free access requires a no-card account key plus Telegram channel/link verification. The free plan is documented at 7M tokens/day and 10 req/min, with daily reset.
   · [Moved to a paid plan] Key-tested on September 21, 2026: NaraRouter answers stepfun-3.7-flash with 402 payment_required, "Insufficient credits. Please top up your balance." The route left the free plan.

================================================================
### UnoRouter  (id=unorouter)
  indirizzo: https://api.unorouter.com/v1   modello in lista: qwen3.8-27b:free   modo: modelli   tipo: chat
  extra in lista: qwen/qwen3.8-27b
  chiave: trovata, 51 caratteri
  GET https://api.unorouter.com/v1/models -> HTTP 200
  testate:
    x-oneapi-request-id: 202611021509507683189398268d9d6vsnWCNhi
    id nel catalogo: 327
      - absolutereality:free
      - agnes-2.5-flash:free
      - agnes-3.0-flash:free
      - agnes-image-2.0-flash:free
      - agnes-image-2.1-flash:free
      - agnes-image-2.5-flash:free
      - albedobase-xl-31:free
      - albedobase-xl-sdxl:free
      - allam-2-7b:free
      - amponyxl:free
  chat 'qwen3.8-27b:free' -> HTTP 200
    corpo: {"id":"chatcmpl-21f4bc93-f83c-461a-9720-550db3b2db57","object":"chat.completion","created":1793632191,"model":"qwen/qwen3.8-27b","choices":[{"index":0,"message":{"role":"assistant","content":"OK"},"logprobs":null,"finish_reason":"stop"}],"usage":{"queue_time":0.121545789,"prompt_tokens":17,"prompt_t
    testate:
      cache-control: private, max-age=0, no-store, no-cache, must-revalidate
      set-cookie: __cf_bm=fgI2on2AZVruG18M87yqZdbDOxDCXqcNhxL9qPKNklw-1793632191.5714-1.0.1.1-TfYMOnGTvHgvIz23k8hMNok_J3s.XWH283ovhiECrV0tJhbrJ5nKaqUespUMQAkhjthHeqlQoZyHek8ok_3WyTTuLU9DU5cdvb2HQF0JkdTgQtcgkxfgFRBphUTsD3AW; HttpOnly; SameSite=None; Secure; Path=/; Domain=groq.com; Expires=Mon, 02 Nov 2026 15:39:51 GMT
      strict-transport-security: max-age=15552000
      x-groq-region: fra
      x-oneapi-request-id: 202611021509514302282808268d9d6M0d4NcCa
      x-ratelimit-limit-requests: 1000
      x-ratelimit-limit-tokens: 8000
      x-ratelimit-remaining-requests: 997
      x-ratelimit-remaining-tokens: 7919
      x-ratelimit-reset-requests: 4m19.2s
      x-ratelimit-reset-tokens: 607ms
      x-request-id: req_01m6ecyh2yez1vk0gf69jkqzdg
  endpoint di quota:
  catalogo freellmapi: 'unorouter' · modelli=2 rpm=[1] rpd=[]
    id gratuiti dal catalogo (dal piu' promettente):
      - glm-5.3:free (rank 17, rpm 1, rpd None)
      - glm-5.3-flash:free (rank 23, rpm 1, rpd None)

================================================================
### Chutes  (id=chutes)
  indirizzo: https://llm.chutes.ai/v1   modello in lista: google/gemma-4-31B-turbo-TEE   modo: modelli   tipo: chat
  extra in lista: nessuno
  chiave: trovata, 102 caratteri
  GET https://llm.chutes.ai/v1/models -> HTTP 200
  testate:
    strict-transport-security: max-age=31536000; includeSubDomains
    access-control-allow-headers: DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-Chute-Id,X-Instance-Id,X-E2E-Nonce,X-E2E-Stream,X-E2E-Path,X-Enable-Thinking,X-Provider,X-Provider-Version,X-Title
    access-control-expose-headers: X-Chutes-Quota-Total,X-Chutes-Quota-Used,X-Chutes-Quota-Remaining,X-Chutes-RL-User,X-Chutes-RL-Chute,X-Chutes-InvocationID,DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-Enable-Thinking,X-Provider,X-Provider-Version,X-Title,Content-Type,Authorization,Content-Type,Cache-Control,X-Chute-Id,X-Instance-Id,X-E2E-Nonce,X-E2E-Stream,X-E2E-Path
    access-control-max-age: 1728000
    id nel catalogo: 17
      - Qwen/Qwen3.8-27B-TEE
      - google/gemma-4-31B-turbo-TEE
      - Qwen/Qwen3.6-27B-TEE
      - deepseek-ai/DeepSeek-V3.2-TEE
      - moonshotai/Kimi-K2.6-TEE
      - zai-org/GLM-5.1-TEE
      - zai-org/GLM-5.2-TEE
      - Qwen/Qwen3.5-397B-A17B-TEE
      - deepseek-ai/DeepSeek-V4-Flash-0731-TEE
      - moonshotai/Kimi-K3-TEE
  chat 'google/gemma-4-31B-turbo-TEE' -> HTTP 402
    corpo: {"detail":{"message":"Quota exceeded and account balance is $0.0, please pay with fiat or send tao to 5CFJQV5MpmXmMP9MPRhSZixcAUib2xMCK45hbvFdUWAP17jN"}}
    testate:
      strict-transport-security: max-age=31536000; includeSubDomains
      access-control-expose-headers: X-Chutes-Quota-Total,X-Chutes-Quota-Used,X-Chutes-Quota-Remaining,X-Chutes-RL-User,X-Chutes-RL-Chute,X-Chutes-InvocationID,DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-Enable-Thinking,X-Provider,X-Provider-Version,X-Title,Content-Type,Authorization,Content-Type,Cache-Control,X-Chute-Id,X-Instance-Id,X-E2E-Nonce,X-E2E-Stream,X-E2E-Path
      access-control-max-age: 1728000
  endpoint di quota:
  catalogo freellmapi: questo provider NON c'è nel catalogo (limiti da documentare a parte)

================================================================
### HuggingFace Router  (id=huggingface)
  indirizzo: https://router.huggingface.co/v1   modello in lista: meta-llama/Llama-3.1-8B-Instruct   modo: chat   tipo: chat
  extra in lista: nessuno
  chiave: trovata, 37 caratteri
  GET https://router.huggingface.co/v1/models -> HTTP 200
  testate:
    x-powered-by: huggingface-moon
    x-request-id: Root=1-6ae8a7c7-73ca561a241ac82d276c4d10
    access-control-expose-headers: X-Repo-Commit,X-HF-Warning,X-Request-Id,X-Error-Code,X-Error-Message,X-Total-Count,ETag,Link,Accept-Ranges,Content-Range,X-Linked-Size,X-Linked-ETag,X-Xet-Hash,RateLimit,RateLimit-Policy
    x-robots-tag: none
    x-cache: Miss from cloudfront
    x-amz-cf-pop: MXP63-P8
    x-amz-cf-id: X6XhOY2W02ox2xyeZSPEY4MSaYbQiDGNfaaHhoMrXR2toPCXCi6R8A==
    strict-transport-security: max-age=31536000
    id nel catalogo: 134
      - deepseek-ai/DeepSeek-V4.1-Flash-1017
      - Qwen/Qwen3.8-27B
      - MiniMaxAI/MiniMax-M3.1-Flash
      - deepseek-ai/DeepSeek-V4.1-Flash
      - moonshotai/Kimi-K3
      - meta-llama/Llama-3.1-8B-Instruct
      - zai-org/GLM-5.3-Flash
      - google/gemma-4-31B-it
      - zai-org/GLM-5.3
      - reflection/Beam-1.0-501B-A23B
  chat 'meta-llama/Llama-3.1-8B-Instruct' -> HTTP 402
    corpo: {"error":"You have no remaining credits. Purchase pre-paid credits to continue using Inference Providers. Alternatively, subscribe to PRO to get monthly included credits."}
    testate:
      x-powered-by: huggingface-moon
      x-request-id: Root=1-6ae8a7c8-1e5588db6fc35c29195c61e2
      access-control-expose-headers: X-Repo-Commit,X-HF-Warning,X-Request-Id,X-Error-Code,X-Error-Message,X-Total-Count,ETag,Link,Accept-Ranges,Content-Range,X-Linked-Size,X-Linked-ETag,X-Xet-Hash,RateLimit,RateLimit-Policy
      x-robots-tag: none
      x-error-code: PrepaidCreditsRequired
      x-error-message: You have no remaining credits. Purchase pre-paid credits to continue using Inference Providers. Alternatively, subscribe to PRO to get monthly included credits.
      x-cache: Error from cloudfront
      x-amz-cf-pop: MXP63-P8
      x-amz-cf-id: 0F3nQ1DaMtH9bXOS5_TdW9ruXj6ow3auIZQo99P_1lpK_7KKVMdbnw==
      strict-transport-security: max-age=31536000
  endpoint di quota:
  catalogo freellmapi: questo provider NON c'è nel catalogo (limiti da documentare a parte)

================================================================
### Google AI Studio  (id=gemini)
  indirizzo: https://generativelanguage.googleapis.com/v1beta/openai   modello in lista: gemini-2.0-flash   modo: chat   tipo: chat
  extra in lista: nessuno
  chiave: trovata, 53 caratteri
  GET https://generativelanguage.googleapis.com/v1beta/openai/models -> HTTP 200
  testate:
    vary: X-Origin
    x-xss-protection: 0
    x-frame-options: SAMEORIGIN
    x-content-type-options: nosniff
    id nel catalogo: 60
      - models/gemini-2.5-flash
      - models/gemini-2.5-pro
      - models/gemini-2.5-flash-preview-tts
      - models/gemini-2.5-pro-preview-tts
      - models/gemma-4-26b-a4b-it
      - models/gemma-4-31b-it
      - models/gemini-flash-latest
      - models/gemini-flash-lite-latest
      - models/gemini-pro-latest
      - models/gemini-2.5-flash-lite
  chat 'gemini-2.0-flash' -> HTTP 404
    corpo: [{  "error": {    "code": 404,    "message": "This model models/gemini-2.0-flash is no longer available. Please update your code to use models/gemini-3.8-flash for the latest features and improvements. We recommend you to use the Interactions API (https://ai.google.dev/gemini-api/docs/get-started
    testate:
      vary: X-Origin
      x-xss-protection: 0
      x-frame-options: SAMEORIGIN
      x-content-type-options: nosniff
  endpoint di quota:
  catalogo freellmapi: questo provider NON c'è nel catalogo (limiti da documentare a parte)

================================================================
### OpenCode Zen  (id=opencode)
  indirizzo: https://opencode.ai/zen/v1   modello in lista: glm-5.3   modo: chat   tipo: chat
  extra in lista: nessuno
  chiave: trovata, 51 caratteri
  GET https://opencode.ai/zen/v1/models -> HTTP 200
  testate:
    access-control-allow-headers: Content-Type, Authorization, X-Api-Key, X-Opencode-Org-Id
    x-opencode-log-id: 01a19ccf-7eb3-7dde-80c7-af9b24f82fed
    id nel catalogo: 39
      - big-pickle
      - beam-free
      - flint-40b-free
      - mimo-v2.6-flash-free
      - nemotron-3.5-super-vl-free
      - nemotron-3.5-lightning-free
      - deepseek-v4.1-flash-free
      - glm-5.3-flash-free
      - claude-fable-5-1
      - claude-haiku-5-5
  chat 'glm-5.3' -> HTTP 402
    corpo: {"error":{"type":"server_error","message":"Upstream request failed: Insufficient account funds"}}
    testate:
      x-opencode-log-id: 01a19ccf-816f-77ae-9d4b-ab915f902343
  endpoint di quota:
  catalogo freellmapi: questo provider NON c'è nel catalogo (limiti da documentare a parte)

================================================================
### Api.Airforce  (id=api-airforce)
  indirizzo: https://api.airforce/v1   modello in lista: glm-4.7-flash   modo: chat   tipo: chat
  extra in lista: nessuno
  chiave: trovata, 55 caratteri
  GET https://api.airforce/v1/models -> HTTP 200
  testate:
    access-control-expose-headers: x-airforce-trace-id
    strict-transport-security: max-age=31536000; includeSubDomains
    x-airforce-trace-id: tr_bef4d2f557744d308d9ff630
    x-content-type-options: nosniff
    x-frame-options: DENY
    x-models-cache: STALE
    id nel catalogo: 793
      - suno-v5.5
      - codestral-latest
      - ministral-3b-latest
      - ministral-3b-2512
      - gpt-oss-120b
      - gemma3-270m:free
      - kimi-k2.7-code
      - nano-banana-pro
      - nano-banana-2
      - llama-instant
  chat 'glm-4.7-flash' -> HTTP 503
    corpo: {"error":{"message":"Model 'glm-4.7-flash' is temporarily unavailable: the provider returned an error and no fallback provider recovered (HTTP 2xx error body).","type":"upstream_unavailable","param":null,"code":"503"}}
    testate:
      access-control-expose-headers: x-airforce-trace-id
      strict-transport-security: max-age=31536000; includeSubDomains
      x-airforce-trace-id: tr_823b4a30a29b4bd696d60cad
      x-content-type-options: nosniff
      x-frame-options: DENY
  endpoint di quota:
    /usage -> HTTP 308 : 
    /quota -> HTTP 308 : 
    /billing/usage -> HTTP 308 : 
    /rate_limit -> HTTP 308 : 
    /api/usage -> HTTP 308 : 
    /limits -> HTTP 308 : 
    /account -> HTTP 308 : 
  catalogo freellmapi: 'airforce' · modelli=18 rpm=[1] rpd=[1000]
    id gratuiti dal catalogo (dal piu' promettente):
      - gpt-oss-20b (rank 89, rpm 1, rpd 1000)
      - mistral-code-latest (rank 89, rpm 1, rpd 1000)
      - rnj-1 (rank 91, rpm 1, rpd 1000)
      - unmoderated-gpt (rank 91, rpm 1, rpd 1000)
      - llama-instant (rank 95, rpm 1, rpd 1000)
      - ministral-14b-2512 (rank 95, rpm 1, rpd 1000)
      - ministral-14b-latest (rank 95, rpm 1, rpd 1000)
      - ministral-3b-2512 (rank 97, rpm 1, rpd 1000)
      - ministral-3b-latest (rank 97, rpm 1, rpd 1000)
      - ministral-8b-2512 (rank 97, rpm 1, rpd 1000)
      - ministral-8b-latest (rank 97, rpm 1, rpd 1000)
      - codestral-2508 (rank 99, rpm 1, rpd 1000)
   · [Free plan is 1 request per minute] Api.Airforce Free grants 1,000 requests per day at 1 request per minute per account with per-model token caps and no card. The 21 listed routes returned matching model IDs on September 15. kimi-k2.7-code requires a paid plan; gpt-oss-120b, Mistral Large and Mistral Medium returned 503 and are excluded. Most routes are proxied Mistral free-plan models; treat them as sharing that upstream capacity.

================================================================
Fine: qui ci sono solo i fatti. Il verdetto (chi tiene, chi esce, quando torna)
lo scrive l'agente nel compito successivo.

<!-- fine indaga_quota_8provider -->
