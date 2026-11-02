# Risposta a «verdetto_quota_8provider»

_02/11/2026 16:10 · FilippoPC_

[0m
> build · big-pickle
[0m
[0m$ [0mls -la ~/posta/dal_pc/ 2>/dev/null; echo "---"; ls -la ~/posta/lavori/ 2>/dev/null | head -50; echo "---"; ls -la ~/posta/ 2>/dev/null
(no output)
[0m
[0m$ [0mcat ~/posta/dal_pc/indaga_quota_8provider.md 2>/dev/null || echo "REPORT NON PRESENTE"
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
[0m
[0m$ [0mls -la ~/posta/; echo "=== portiere ==="; cat ~/posta/portiere_lista.txt 2>/dev/null; echo "=== lavori ==="; ls -la ~/posta/lavori/
total 1912
drwxr-xr-x 1 agenti agenti    4096 Nov  2 16:08 .
drwxr-x--- 1 agenti agenti    4096 Nov  2 15:19 ..
drwxr-xr-x 1 agenti agenti    4096 Nov  2 16:10 .git
-rw-r--r-- 1 agenti agenti     165 Nov  1 18:21 .gitignore
-rw-r--r-- 1 agenti agenti      10 Oct 27 15:20 .padrone
drwxr-xr-x 1 agenti agenti    4096 Oct 27 15:20 00_INSTALLA_AGENTI
-rw-r--r-- 1 agenti agenti    1116 Oct 27 15:20 6_BROWSER_AGENTI.bat
-rw-r--r-- 1 agenti agenti     133 Oct 27 15:20 7_SQUADRA_FUSION.bat
-rw-r--r-- 1 agenti agenti     286 Oct 29 09:40 8_CENTRALE_GUI.bat
-rw-r--r-- 1 agenti agenti    1897 Oct 27 15:20 APRI_OPENCLAW.bat
-rw-r--r-- 1 agenti agenti     892 Oct 27 15:20 CENTRALE_AGENTI.bat
-rw-r--r-- 1 agenti agenti    2376 Oct 27 15:20 CONFIGURA_OPENCLAW.bat
-rw-r--r-- 1 agenti agenti    8674 Oct 27 15:20 GUIDA_OPENCLAW.md
-rw-r--r-- 1 agenti agenti    2354 Oct 27 15:20 INDICE_CARTELLE.md
-rw-r--r-- 1 agenti agenti   11563 Oct 27 15:20 INSTALLA_OPENCLAW.bat
-rw-r--r-- 1 agenti agenti    3770 Oct 27 15:20 RAPPORTO_AGENTI.txt
-rw-r--r-- 1 agenti agenti      49 Oct 27 15:20 README.md
drwxr-xr-x 1 agenti agenti    4096 Nov  2 10:48 RISPOSTE_AGENTI
drwxr-xr-x 1 agenti agenti    4096 Nov  2 12:59 __pycache__
-rw-r--r-- 1 agenti agenti    6179 Oct 27 15:20 agenti_stato.sh
-rwxr-xr-x 1 agenti agenti   13517 Nov  2 12:59 aggiorna_tutto.sh
-rw-r--r-- 1 agenti agenti   19296 Nov  2 14:30 appello_chiavi.sh
-rwxr-xr-x 1 agenti agenti    3256 Oct 28 17:12 apri_free_llm_hub.sh
-rwxr-xr-x 1 agenti agenti    4071 Oct 27 15:20 apri_openclaw.sh
-rwxr-xr-x 1 agenti agenti   12053 Nov  2 12:59 centrale.sh
-rw-r--r-- 1 agenti agenti  103746 Nov  1 23:23 cervello.py
-rw-r--r-- 1 agenti agenti   22489 Oct 27 15:20 checkin_agentrouter.py
-rw-r--r-- 1 agenti agenti    1573 Oct 27 15:20 checkin_agentrouter.sh
-rw-r--r-- 1 agenti agenti    4100 Nov  2 15:05 chiave_di.py
-rw-r--r-- 1 agenti agenti    4531 Oct 27 15:20 chiavi_env.sh
-rw-r--r-- 1 agenti agenti    6493 Oct 31 18:53 compressione.py
drwxr-xr-x 1 agenti agenti    4096 Nov  2 16:10 da_me
drwxr-xr-x 1 agenti agenti    4096 Nov  2 16:10 dal_pc
drwxr-xr-x 1 agenti agenti    4096 Nov  2 16:10 fatti
drwxr-xr-x 1 agenti agenti    4096 Oct 28 17:12 free-llm-hub
-rw-r--r-- 1 agenti agenti   17736 Oct 27 15:20 fusion_engine.py
-rw-r--r-- 1 agenti agenti    5246 Nov  1 18:21 gate_pubblicazione.py
drwxr-xr-x 1 agenti agenti    4096 Nov  1 20:43 gui
-rw-r--r-- 1 agenti agenti   11389 Nov  2 12:59 installa_agenti.sh
drwxr-xr-x 1 agenti agenti    4096 Nov  2 16:08 lavori
-rw-r--r-- 1 agenti agenti    6154 Oct 27 15:20 leggi_discord.py
-rw-r--r-- 1 agenti agenti    6619 Oct 27 15:20 leggi_fb_cdp.mjs
-rw-r--r-- 1 agenti agenti    9080 Oct 27 15:20 leggi_fb_cdp.py
-rwxr-xr-x 1 agenti agenti    6871 Oct 27 15:20 leggi_video.py
-rwxr-xr-x 1 agenti agenti     164 Nov  1 22:24 lista.txt
-rw-r--r-- 1 agenti agenti    1002 Oct 27 15:20 mappa_innesto.txt
drwxr-xr-x 1 agenti agenti    4096 Nov  2 16:08 missione
-rw-r--r-- 1 agenti agenti    5098 Oct 27 15:20 omni_chiavi.sh
-rw-r--r-- 1 agenti agenti    4982 Oct 27 15:20 omni_free.sh
-rwxr-xr-x 1 agenti agenti    8549 Oct 27 15:20 openclaw_fix.sh
-rw-r--r-- 1 agenti agenti    2483 Oct 27 15:20 openclaw_stato.sh
-rw-r--r-- 1 agenti agenti    3323 Nov  1 22:24 per_agente.py
-rw-r--r-- 1 agenti agenti  167987 Nov  2 12:59 portiere_catalogo.json
-rw-r--r-- 1 agenti agenti     317 Oct 31 17:16 portiere_gruppi.txt
-rw-r--r-- 1 agenti agenti   12121 Nov  2 15:41 portiere_lista.txt
-rw-r--r-- 1 agenti agenti   19374 Nov  2 16:08 portiere_log.jsonl
-rw-r--r-- 1 agenti agenti     536 Oct 31 18:21 portiere_quote.txt
-rw-r--r-- 1 agenti agenti    1747 Nov  2 16:08 portiere_stato.json
-rw-r--r-- 1 agenti agenti     780 Oct 27 15:20 postino.log
-rwxr-xr-x 1 agenti agenti   11783 Nov  2 13:32 postino.sh
-rw-r--r-- 1 agenti agenti     540 Oct 27 15:20 prova.sh
-rw-r--r-- 1 agenti agenti    4962 Oct 27 15:20 prova_agenti.sh
-rw-r--r-- 1 agenti agenti    5223 Oct 27 15:20 prova_provider.sh
-rw-r--r-- 1 agenti agenti    2269 Oct 27 15:20 ricerca_strategica.py
-rw-r--r-- 1 agenti agenti    3296 Oct 27 15:20 serbatoio_hub_v2.json
-rw-r--r-- 1 agenti agenti 1202960 Oct 27 15:20 skills_pack.tar.gz
-rwxr-xr-x 1 agenti agenti     308 Oct 27 15:20 squadra.sh
-rw-r--r-- 1 agenti agenti     315 Nov  2 11:55 stato_fusion.json
drwxr-xr-x 1 agenti agenti    4096 Oct 30 16:49 strumenti
drwxr-xr-x 1 agenti agenti    4096 Nov  1 23:23 tests
-rwxr-xr-x 1 agenti agenti    7878 Oct 27 15:20 verifica.sh
=== portiere ===
# portiere_lista.txt — LA LISTA DEL PORTIERE (motore nostro, porta 20129)
# formato: id|etichetta|nome nel portachiavi|indirizzo API|modello di partenza|modo|tipo|classe|extra|auth
#   nome nel portachiavi = SENZA  → provider che non vuole chiave
#   modo = chat (prova una domanda vera) · modelli (solo elenco modelli)
#   tipo = chat · immagini · video · voce · embedding · visione · db   (assente = chat)
#   classe = keyless | free-ricorrente | trial | pin-only   (gratis e senza carta)
#   extra  = altri modelli da provare, separati da ';'
#   auth   = none (NESSUN header Authorization) | sentinel (Bearer 0000000000)
#   NOTA 2/11: i modelli che «ragionano» (Routeway, UnoRouter, AnyAPI, Gizmo, OVH) rispondono
#   con il testo in reasoning_content e il content vuoto se max_tokens e' troppo piccolo:
# Regola: qui ci stanno TUTTE le chiavi di cui conosciamo l'indirizzo, anche quelle che
# non fanno chat: il Portiere è nostro e deve poter pescare la chiave giusta.
# Indirizzi verificati uno per uno il 21/10/2026 (elenco modelli 200), dal portachiavi.

# ── CHAT ────────────────────────────────────────────────────────────────────
groq|Groq|Groq|https://api.groq.com/openai/v1|qwen/qwen3.8-27b|chat||free-ricorrente||
gemini|Google AI Studio|Google AI Studio|https://generativelanguage.googleapis.com/v1beta/openai|gemini-2.0-flash|chat||free-ricorrente||
mistral|Mistral|Mistral|https://api.mistral.ai/v1|ministral-8b-latest|chat||free-ricorrente||
cohere|Cohere|Cohere|https://api.cohere.ai/compatibility/v1|command-r-plus-08-2024|chat||free-ricorrente||
openrouter|OpenRouter|OpenRouter|https://openrouter.ai/api/v1|openrouter/auto|chat||free-ricorrente||
nvidia|NVIDIA|NVIDIA|https://integrate.api.nvidia.com/v1|nvidia/nemotron-3-ultra-550b-a55b|chat||free-ricorrente||
huggingface|HuggingFace Router|HuggingFace Router|https://router.huggingface.co/v1|meta-llama/Llama-3.1-8B-Instruct|chat||free-ricorrente||
pollinations|Pollinations|Pollinations|https://text.pollinations.ai/openai|openai-fast|chat||free-ricorrente||
agentrouter|AgentRouter|AgentRouter|https://agentrouter.org/v1|gpt-5.6-sol|anthropic||free-ricorrente|gpt-6-astra;gpt-6.1-sol|
opencode|OpenCode Zen|OpenCode Zen|https://opencode.ai/zen/v1|glm-5.3|chat||free-ricorrente||
aion|Aion Labs|Aion Labs|https://api.aionlabs.ai/v1|aion-labs/aion-3.5|chat||free-ricorrente||
api-airforce|Api.Airforce|Api.Airforce|https://api.airforce/v1|glm-4.7-flash|chat||free-ricorrente||
bazaarlink|BazaarLink|BazaarLink|https://bazaarlink.ai/api/v1|auto:free|chat||free-ricorrente||
clod|CLōD|CLōD|https://api.clod.io/v1|Trinity Mini|chat||free-ricorrente||
navy|NavyAI|NavyAI|https://api.navy/v1|schizogpt|chat||free-ricorrente|gpt-6.1-sol;gpt-6-astra;gpt-5.6-sol||
orcarouter|OrcaRouter|OrcaRouter|https://api.orcarouter.ai/v1|orcarouter/free|modelli||free-ricorrente||
nara|NaraRouter|NaraRouter|https://router.bynara.id/v1|auto|modelli||free-ricorrente||
routeway|Routeway|Routeway|https://api.routeway.ai/v1|gemma-4-26b-a4b-it-chimerax:free|modelli||free-ricorrente|minimax-m3.1-flash:free|
septorlabs|Septor Labs|Septor Labs|https://api.septorlabs.com/v1|auto|modelli||free-ricorrente||
typhoon|Typhoon|Typhoon|https://api.opentyphoon.ai/v1|typhoon-v2.5-30b-a3b-instruct|modelli||free-ricorrente||
tokenharbor|Token Harbor|Token Harbor|https://tokenharbor.ai/v1|deepseek-v4-flash:free|modelli||free-ricorrente||
teamorouter|TeamoRouter|TeamoRouter|https://api.teamorouter.com/v1|deepseek-v4-flash-free|chat||free-ricorrente|deepseek-flash-free;glm-5.3-flash-free|
unorouter|UnoRouter|UnoRouter|https://api.unorouter.com/v1|qwen3.8-27b:free|modelli||free-ricorrente|qwen/qwen3.8-27b|
plugsky|Plugsky|Plugsky|https://plugsky.com/v1|plugsky-micro|chat||free-ricorrente||
simplellm|SimpleLLM|SimpleLLM|https://api.simplellm.eu/v1|free-Llama-3.1-8B-Instruct|chat||free-ricorrente||
llmtr|LLMTR|LLMTR|https://llmtr.com/v1|nvidia/nemotron-3-ultra-550b-a55b|chat||free-ricorrente||
router9|Router9|Router9|https://api.router9.com/v1|deepseek-v4-flash|modelli||free-ricorrente||
waterfall|Waterfall|Waterfall|https://api.getwaterfall.org/v1|auto|modelli||free-ricorrente|nemotron-3-super-120b-free;nemotron-3-super-120b-a12b-free;nemotron-3.5-lightning-free;laguna-s-2.1-free;ling-3.0-flash-vl-free;ling-3.0-flash-sante-free;nex-n2.5-pro-free;nex-n2.5-mini-free;lfm-2.5-2.6b-free|
blazeapi|BlazeAPI|BlazeAPI|https://api.blazeapi.org/paid/v1|free/claude-haiku-4.5|chat||free-ricorrente||
logfare|Logfare|Logfare|https://logfare.ai/v1|auto|modelli||free-ricorrente||
lucidity|Lucidity|Lucidity (Composite)|https://composite.lucidity.sh/v1|minimax/minimax-m3.1-flash:free|modelli||free-ricorrente||
freeai|FreeAI|FreeAI|https://api.free.ai/v1|qwen7b|chat||free-ricorrente||
speka|Speka|Speka|https://speka.me/v1|nvidia/nemotron-3-ultra-550b-a55b|chat||free-ricorrente||
nscale|Nscale|Nscale|https://inference.api.nscale.com/v1|Qwen/Qwen3-4B-Instruct-2507|chat||free-ricorrente|Qwen/Qwen3-8B;meta-llama/Llama-3.1-8B-Instruct;Qwen/Qwen3-4B-Thinking-2507|
chutes|Chutes|Chutes.ai|https://llm.chutes.ai/v1|google/gemma-4-31B-turbo-TEE|modelli||free-ricorrente||
ovh|OVH|SENZA|https://oai.endpoints.kepler.ai.cloud.ovh.net/v1|Mistral-Nemo-Instruct-2407|modelli||keyless|gpt-oss-120b;Meta-Llama-3_3-70B-Instruct;Qwen3.5-397B-A17B;gpt-oss-20b|none
sealion|SeaLION|SeaLION|https://api.sea-lion.ai/v1|aisingapore/Llama-SEA-LION-v3-70B-IT|modelli||free-ricorrente||
aihorde|AI Horde (senza chiave)|SENZA|https://oai.aihorde.net/v1|koboldcpp/gemma-4-26B-A4B-it-ultra-uncensored-heretic|chat||keyless|koboldcpp/gemma-3-270m-it-F16;koboldcpp/Llama-3.2-1B-Instruct;koboldcpp/gemma-4-31B-it-heretic|sentinel
pollinationsfree|Pollinations (senza chiave)|SENZA|https://text.pollinations.ai/openai|openai-fast|chat||keyless||none

# ── NUOVE DEL 21/10 (indirizzo trovato e provato stamattina) ────────────────
llm7|LLM7|LLM7|https://api.llm7.io/v1|DeepSeek-V4-Flash-0731|modelli||free-ricorrente||
longcat|LongCat|LongCat|https://api.longcat.chat/openai/v1|LongCat-2.5|chat||free-ricorrente|LongCat-2.5-Preview;LongCat-2.0||
ollamacloud|Ollama Cloud|Ollama Cloud|https://ollama.com/v1|auto|modelli||free-ricorrente||
requesty|Requesty|Requesty|https://router.requesty.ai/v1|auto|modelli||free-ricorrente||
zhipu|Zhipu|Zhipu|https://open.bigmodel.cn/api/paas/v4|auto|modelli||free-ricorrente||
electronhub|ElectronHub|ElectronHub|https://api.electronhub.ai/v1|gpt-4o|modelli||free-ricorrente||
inferbase|Inferbase|Inferbase|https://api.inferbase.ai/v1|auto|modelli||free-ricorrente||
blockrun|BlockRun|BlockRun|https://api.blockrun.ai/v1|nvidia/nemotron-3-nano-omni-30b-a3b-reasoning|modelli||free-ricorrente||
sail|Sail|Sail|https://api.sailresearch.com/v1|moonshotai/Kimi-K2.6|chat||free-ricorrente||
anyapi|AnyAPI|AnyAPI|https://api.anyapi.ai/v1|nvidia/nemotron-3.5-lightning:free|modelli||free-ricorrente||
kilo|Kilo (senza chiave)|SENZA|https://api.kilo.ai/api/gateway/v1|liquid/lfm-2.5-2.6b:free|modelli||keyless|nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free;openrouter/free;kilo-auto/free|none
cloudflare|Cloudflare Workers AI|Cloudflare Workers AI|SPECIALE-CLOUDFLARE|@cf/meta/llama-3.3-70b-instruct-fp8-fast|chat||free-ricorrente||
#   Cloudflare: la chiave nel registro è «account_id:token», e il router ricava l'indirizzo da lì
#   (https://api.cloudflare.com/client/v4/accounts/<account_id>/ai/v1). L'elenco modelli NON sta su
#   /models: sta su /ai/models/search. Il vecchio llama-3.1-8b è stato deprecato (410) → 3.3-70b-fast.

# ── INDIRIZZI RECUPERATI DALLE INFO DELLA REPO FREELMAPI (MIT) — 21/10 notte ──
# Fonte: tashfeenahmed/freellmapi, server/src/providers/index.ts e providers/*.ts.
# Provati uno per uno da qui il 21/10: elenco modelli 200 E una domanda vera andata a buon fine.
#   · Agnes = «OpenAI-compatible» dietro LiteLLM+vLLM, modelli Agnes a $0/token, niente carta,
#     ~30 richieste in parallelo prima del 429. Ragiona prima di rispondere → timeout 60 s.
#   · xKiro = gateway OpenAI-compatibile su api.xkiro.com/v1 (l'apice ai.xkiro com'è oggi non serve);
#     /v1/models risponde 200 ANCHE senza chiave, quindi la prova di validità va su /v1/usage;
#     i modelli «premium» danno 403, quelli liberi (Mistral, MiniMax, DeepSeek) rispondono.
#   · DreamPrompting = gli id sono «fornitore/modello» (groq/…, mistral/…) oppure «auto».
#   · Gizmo = api.gizmoplatforms.com; i modelli a pagamento dicono «add a payment method»,
#     quelli liberi finiscono con «:free».
agnes|Agnes AI|Agnes AI|https://apihub.agnes-ai.com/v1|agnes-2.5-flash|chat||free-ricorrente||
xkiro|xKiro|xKiro|https://api.xkiro.com/v1|mistralai/ministral-14b|chat||free-ricorrente||
dreamprompting|DreamPrompting|DreamPrompting|https://dreamprompting.com/api/v1|groq/openai/gpt-oss-20b|chat||free-ricorrente||
gizmo|Gizmo|Gizmo|https://api.gizmoplatforms.com/api/v1|nvidia/nemotron-3.5-lightning:free|chat||free-ricorrente||

# ── NON CHAT (restano chiavi nostre: immagini, video, voce, memoria) ────────
speechify|Speechify|Speechify|https://api.speechify.ai/v1|—|no|voce|free-ricorrente||
jina|Jina AI|Jina AI (n2)|https://api.jina.ai/v1|jina-embeddings-v3|no|embedding|free-ricorrente||
qdrant|Qdrant Cloud|Qdrant Cloud — cluster «Bomber91»|https://4e506b83-cf3b-4dab-b1ff-774a090094ba.eu-central-1-0.aws.cloud.qdrant.io|—|no|db|free-ricorrente||
fal|fal.ai|fal.ai|https://fal.run|—|no|immagini|free-ricorrente||
wavespeed|WaveSpeedAI|WaveSpeedAI|https://api.wavespeed.ai/api/v3|—|no|video|free-ricorrente||
moondream|Moondream|Moondream|https://api.moondream.ai/v1|moondream/moondream3-preview|no|visione|free-ricorrente||
pollinationsimg|Pollinations (immagini, senza chiave)|SENZA|https://image.pollinations.ai|flux|no|immagini|keyless||none

## NOTE DEL 21/10 NOTTE (provate una per una dal router)
# · Chutes: la chiave risponde all'elenco modelli ma la chat dà 402 «balance is $0.0, please pay»:
#   il loro piano free vuole un saldo diverso da zero → resta in lista ma il router lo mette in pausa da sé.
# · Kilo: RISOLTO 2/11 — è keyless MA vuole NESSUN header Authorization (con un token
#   qualunque, anche «free» o «0000000000», risponde 401 INVALID_TOKEN). Indirizzo giusto
#   https://api.kilo.ai/api/gateway/v1 ; i modelli gratis arrivano dal catalogo freellmapi.
# · OVH: è keyless e vuole NESSUN header Authorization (con una chiave qualunque risponde 403).
#   Chat: Mistral-Nemo-Instruct-2407 · 2 richieste al minuto.
# · AI Horde: vuole il sentinel «Bearer 0000000000» e max_tokens >= 16. Il roster cambia ogni
#   ora: i modelli con worker online si vedono su https://aihorde.net/api/v2/status/models
# · Cloudflare Workers AI: la chiave deve essere nel formato «account_id:api_token»; la nostra è
#   solo il token, quindi l'indirizzo non si può comporre. Appena c'è l'account id si accende.
# · Sail e i modelli che «ragionano» (Agnes): rispondono col pensiero e il testo vuoto → ora il
#   router fa un secondo giro con più spazio e la risposta arriva.

## DA CONFERMARE — non contano nel numero del Portiere
# Nome nel portachiavi | perché è fermo
✅ risolto 21/10 (riga chat qui sopra: apihub.agnes-ai.com/v1) — Agnes AI|il loro indirizzo API non risponde su nessun host provato (servono le loro istruzioni)
AI21|ritirato: il servizio Studio non esiste più
Kilo|risolto 2/11: è dentro come «Kilo (senza chiave)» (keyless, senza header)
✅ risolto 21/10 (riga chat qui sopra: api.xkiro.com/v1) — xKiro|indirizzo API mai scritto nel portachiavi (xkiro.ai non esiste)
✅ risolto 21/10 (riga chat qui sopra: dreamprompting.com/api/v1) — DreamPrompting|indirizzo API mai scritto nel portachiavi (dreamrompting.com non esiste)
✅ risolto 21/10 (riga chat qui sopra: api.gizmoplatforms.com/api/v1) — Gizmo|indirizzo API mai scritto nel portachiavi (api.gizmo.ai risponde 403)
Nebius|chiave mai presa: al signup chiede la carta
=== lavori ===
total 376
drwxr-xr-x 1 agenti agenti   4096 Nov  2 16:08 .
drwxr-xr-x 1 agenti agenti   4096 Nov  2 16:08 ..
-rwxr-xr-x 1 agenti agenti   4999 Nov  1 22:24 OCCHI_FB_BATCH.md
-rwxr-xr-x 1 agenti agenti   4971 Nov  1 22:51 OCCHI_FB_RETRY.md
-rwxr-xr-x 1 agenti agenti   7062 Nov  2 11:55 aggiorna_catalogo.py
-rwxr-xr-x 1 agenti agenti   2876 Oct 30 17:59 analista.sh
-rwxr-xr-x 1 agenti agenti   1733 Nov  1 15:43 audit_catena.sh
-rw-r--r-- 1 agenti agenti 177166 Nov  2 16:08 catalogo_freellmapi.json
-rwxr-xr-x 1 agenti agenti    363 Oct 30 18:17 catena_completa.sh
-rw-r--r-- 1 agenti agenti   4325 Nov  1 23:21 cerca.sh
-rwxr-xr-x 1 agenti agenti   3255 Nov  1 17:07 cura_catena.sh
-rw-r--r-- 1 agenti agenti   4147 Nov  1 23:21 deepdog_ricerca.sh
-rwxr-xr-x 1 agenti agenti   4742 Oct 31 21:39 deepopen_prova.sh
-rwxr-xr-x 1 agenti agenti   1694 Nov  1 15:14 giudice_lusso.sh
-rwxr-xr-x 1 agenti agenti   2177 Nov  1 12:13 miniera_catena.sh
-rwxr-xr-x 1 agenti agenti   1246 Nov  2 11:55 modelli_aihorde.py
-rwxr-xr-x 1 agenti agenti  21158 Nov  1 22:39 occhi_fb.sh
-rwxr-xr-x 1 agenti agenti   1909 Oct 30 18:44 revisore.sh
-rwxr-xr-x 1 agenti agenti   2499 Nov  2 11:55 scorta_cervello.sh
-rwxr-xr-x 1 agenti agenti    146 Nov  1 09:57 scorta_motore.sh
-rwxr-xr-x 1 agenti agenti   2912 Nov  2 13:32 scorta_posta.sh
-rwxr-xr-x 1 agenti agenti   3185 Nov  2 11:55 sentinella_chiavi.sh
-rwxr-xr-x 1 agenti agenti    954 Oct 30 18:03 seriale.sh
-rwxr-xr-x 1 agenti agenti   4053 Oct 31 22:00 setaccio_vena.sh
[0m
[0m$ [0mls -la ~/posta/lavori/catalogo_freellmapi.json ~/posta/lavori/sentinella_chiavi.sh ~/posta/lavori/scorta_cervello.sh ~/posta/lavori/modelli_aihorde.py ~/posta/dal_pc/sentinella_chiavi.md 2>&1
-rw-r--r-- 1 agenti agenti   2319 Nov  2 16:10 /home/agenti/posta/dal_pc/sentinella_chiavi.md
-rw-r--r-- 1 agenti agenti 177166 Nov  2 16:08 /home/agenti/posta/lavori/catalogo_freellmapi.json
-rwxr-xr-x 1 agenti agenti   1246 Nov  2 11:55 /home/agenti/posta/lavori/modelli_aihorde.py
-rwxr-xr-x 1 agenti agenti   2499 Nov  2 11:55 /home/agenti/posta/lavori/scorta_cervello.sh
-rwxr-xr-x 1 agenti agenti   3185 Nov  2 11:55 /home/agenti/posta/lavori/sentinella_chiavi.sh
[0m
[0m$ [0mecho "=== sentinella_chiavi.sh ==="; cat ~/posta/lavori/sentinella_chiavi.sh; echo; echo "=== scorta_cervello.sh ==="; cat ~/posta/lavori/scorta_cervello.sh; echo; echo "=== modelli_aihorde.py ==="; cat ~/posta/lavori/modelli_aihorde.py; echo; echo "=== sentinella_chiavi.md ==="; cat ~/posta/dal_pc/sentinella_chiavi.md
(no output)
[0m
[0m$ [0mpython3 - <<'EOF'
import json
p=json.load(open('/home/agenti/posta/lavori/catalogo_freellmapi.json'))
print(type(p))
if isinstance(p,dict):
    print(list(p.keys())[:40])
EOF
<class 'dict'>
['generato', 'versione', 'tier', 'provider', 'quirk']
[0m
[0m$ [0mcat ~/posta/lavori/sentinella_chiavi.sh
#!/usr/bin/env bash
# sentinella_chiavi.sh — la sentinella che tiene VIVE le chiavi.
#
# Cosa fa, una volta ogni SEI ORE (non di piu': i piani gratis hanno limiti):
#   1. rigenera il catalogo freellmapi (https://api.freellmapi.co/v1/latest):
#      i modelli gratis cambiano nome e id, il catalogo e' l'unica fonte sicura.
#   2. ri-prova SOLO chi e' in cooldown/reset (appello --solo-problemi): chi
#      rispondeva continua a valere, chi e' scaduto viene riprovato.
#   3. check-in AgentRouter (+25$/giorno) se il browser degli agenti e' acceso
#      e non e' gia' stato fatto oggi.
#   4. lascia un rapporto in dal_pc/sentinella_chiavi.md (il postino lo pubblica).
#
# Il file di stato (fatti/sentinella_ultimo_giro) dice quando e' passata
# l'ultima volta: nessuna aspettativa, nessun loop che morde.
set -u
DIR="$HOME/posta"
LOG="/tmp/sentinella_chiavi.log"
STATO="$DIR/fatti/sentinella_ultimo_giro"
ORE=6
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
cd "$DIR" 2>/dev/null || { say "non trovo ~/posta"; exit 1; }
mkdir -p fatti dal_pc

# --- guardia: non due giri ravvicinati
if [ -f "$STATO" ]; then
  ORA=$(date +%s); PRIMA=$(cat "$STATO" 2>/dev/null || echo 0)
  case "$PRIMA" in ''|*[!0-9]*) PRIMA=0 ;; esac
  if [ $(( (ORA - PRIMA) )) -lt $((ORE * 3600)) ]; then
    say "non e' ancora passato il tempo (aspetto)"
    exit 0
  fi
fi
date +%s > "$STATO"
say "giro iniziato"

RAPPORTO="dal_pc/sentinella_chiavi.md"
{
  echo "# 🛡️ Sentinella delle chiavi — $(date '+%d/%m/%Y %H:%M')"
  echo
} > "$RAPPORTO"

# 1) catalogo
echo "## 1. Catalogo freellmapi" >> "$RAPPORTO"
CAT_OUT=$(python3 lavori/aggiorna_catalogo.py 2>&1)
echo '```' >> "$RAPPORTO"; echo "$CAT_OUT" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
say "catalogo: $(echo "$CAT_OUT" | head -1)"

# 2) ri-prova di chi e' in cooldown/reset
echo >> "$RAPPORTO"; echo "## 2. Appello (solo i problemi)" >> "$RAPPORTO"
APP=$(timeout 600 bash appello_chiavi.sh --solo-problemi 2>&1 | tail -25)
echo '```' >> "$RAPPORTO"; echo "$APP" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
RES=$(python3 - << 'PY' 2>/dev/null
import json, os
p = os.path.expanduser("~/.posta_appello.json")
try:
    d = json.load(open(p, encoding="utf-8"))
except Exception:
    print("catalogo non letto")
    raise SystemExit
print(f"riserva ora: {len(d.get('riserva', []))} su {len(d.get('voci', []))} provider")
PY
)
echo >> "$RAPPORTO"; echo "$RES" >> "$RAPPORTO"
say "appello: $RES"

# 3) check-in AgentRouter (+25$/giorno)
echo >> "$RAPPORTO"; echo "## 3. Check-in AgentRouter" >> "$RAPPORTO"
FLAG="$HOME/.ar_checkin_$(date +%F)"
if [ "$(date +%H%M)" -ge 1805 ] && [ ! -f "$FLAG" ] && [ ! -f "$HOME/.ar_login_manuale" ] \
   && curl -s --max-time 2 http://127.0.0.1:9222/json/version >/dev/null 2>&1; then
  AR=$(timeout 300 bash checkin_agentrouter.sh 2>&1 | tail -20)
  echo '```' >> "$RAPPORTO"; echo "$AR" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
  say "check-in agentrouter eseguito"
else
  echo "check-in non eseguito: o non e' l'ora (dopo le 18:05), o il browser degli agenti non risponde, o e' gia' stato fatto oggi." >> "$RAPPORTO"
  say "check-in agentrouter saltato"
fi

say "giro finito · rapporto: $RAPPORTO"
exit 0
[0m
[0m$ [0mcat ~/posta/lavori/scorta_cervello.sh; echo "=== AIHORDE ==="; cat ~/posta/lavori/modelli_aihorde.py; echo "=== SENTINELLA REPORT ==="; cat ~/posta/dal_pc/sentinella_chiavi.md
(no output)
[0m
[0m$ [0mpython3 - <<'EOF'
import json
p=json.load(open('/home/agenti/posta/lavori/catalogo_freellmapi.json'))
print("generato",p.get("generato"),"versione",p.get("versione"),"tier",p.get("tier"))
prov=p.get("provider")
print("provider type",type(prov), "n", len(prov) if hasattr(prov,'__len__') else '?')
if isinstance(prov,list):
    for x in prov[:2]: print(json.dumps(x,ensure_ascii=False)[:800])
elif isinstance(prov,dict):
    for k in list(prov)[:2]: print(k, json.dumps(prov[k],ensure_ascii=False)[:800])
print("QUIRK type",type(p.get("quirk")))
EOF
generato 02/11/2026 13:32 versione 2026.11.01.395dc3 tier monthly
provider type <class 'dict'> n 33
google {"nome": "Google AI Studio", "etichetta": "Google AI Studio", "modelli": [{"id": "gemini-3.8-flash", "rank": 25, "vel": 4, "rpm": null, "rpd": null, "ctx": 1048576, "strumenti": true, "visione": true}, {"id": "gemini-flash-latest", "rank": 25, "vel": 10, "rpm": 10, "rpd": 20, "ctx": null, "strumenti": true, "visione": true}, {"id": "gemini-3.7-flash", "rank": 29, "vel": 4, "rpm": 10, "rpd": 20, "ctx": 1048576, "strumenti": true, "visione": true}, {"id": "gemini-3.6-flash", "rank": 39, "vel": 5, "rpm": 10, "rpd": 20, "ctx": 1048576, "strumenti": true, "visione": true}, {"id": "gemini-3.5-flash", "rank": 41, "vel": 5, "rpm": 10, "rpd": 20, "ctx": 1048576, "strumenti": true, "visione": true}, {"id": "gemini-3.8-live", "rank": 49, "vel": 10, "rpm": 10, "rpd": 20, "ctx": null, "strumenti": true
ovh {"nome": "OVH AI Endpoints", "etichetta": "OVH", "modelli": [{"id": "Qwen3.8-27B", "rank": 39, "vel": 9, "rpm": 2, "rpd": null, "ctx": 262144, "strumenti": true, "visione": false}, {"id": "Qwen3.6-27B", "rank": 65, "vel": 9, "rpm": 2, "rpd": null, "ctx": 131072, "strumenti": true, "visione": false}, {"id": "Qwen3.5-397B-A17B", "rank": 71, "vel": 9, "rpm": 2, "rpd": null, "ctx": 262144, "strumenti": true, "visione": false}, {"id": "Qwen3.5-9B", "rank": 79, "vel": 9, "rpm": 2, "rpd": null, "ctx": 262144, "strumenti": true, "visione": false}, {"id": "gpt-oss-120b", "rank": 83, "vel": 9, "rpm": 2, "rpd": null, "ctx": 131072, "strumenti": true, "visione": false}, {"id": "gpt-oss-20b", "rank": 89, "vel": 10, "rpm": 2, "rpd": null, "ctx": 131072, "strumenti": true, "visione": false}, {"id": "Meta
QUIRK type <class 'dict'>
[0m
[0m$ [0mcat ~/posta/lavori/scorta_cervello.sh
#!/bin/bash
# GUARDIANO DEL CERVELLO (1/11 sera, riscritto)
#
# PRIMA: `flock -n /tmp/cervello.lk bash -c 'cd ~/posta; python3 cervello.py'`
#   → avviava il cervello in primo piano dentro il flock, SENZA LOG.
#   Se la partenza falliva non se ne sapeva niente, e se il lock restava
#   stretto `flock -n` falliva in silenzio: il cervello restava giù e
#   nessuno se ne accorgeva (è successo due volte l'1/11 sera).
#
# ADESSO: controlla SE il cervello risponde, e se non risponde lo riavvia
#   con un log che si può leggere, usando un lock a TEMPO (non istantaneo).
#   Il cervello gira staccato dal guardiano (nohup): se il guardiano muore,
#   il cervello resta vivo.
LOG="/tmp/scorta_cervello.log"
CERV="/tmp/cervello.log"
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
cd "$HOME/posta" || { say "non trovo ~/posta"; exit 1; }
say "guardiano avviato (pid $$)"

while true; do
  if ! (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
    say "cervello DOWN: lo riavvio"
    # lock a tempo: se qualcun altro sta già tentando, aspetto e riprovo
    if flock -w 30 /tmp/cervello.lk true 2>/dev/null; then
      # AUDIT FINALE: senza PYTHONUNBUFFERED il log resta VUOTO proprio
      # quando serve (il cane muore e non si sa perche').
      PYTHONUNBUFFERED=1 nohup python3 cervello.py >> "$CERV" 2>&1 &
      for i in $(seq 1 20); do
        sleep 3
        if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
          say "cervello risorto (~$((i*3))s)"
          break
        fi
      done
      if ! (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
        say "il cervello NON e' tornato: ultime righe di $CERV:"
        tail -5 "$CERV" >> "$LOG" 2>/dev/null
      fi
    else
      say "lock /tmp/cervello.lk occupato: aspetto e riprovo"
    fi
  fi
  # ── la sentinella delle chiavi (una volta ogni 6 ore) ──
  # Rigenera il catalogo freellmapi, ri-prova chi e' in cooldown e fa il
  # check-in AgentRouter. Il file di stato dentro la sentinella fa la guardia
  # precisa; qui si controlla solo per non lanciarla ogni 30 secondi.
  PRIMA_S=$(cat /tmp/sentinella_giro 2>/dev/null || echo 0)
  case "$PRIMA_S" in ''|*[!0-9]*) PRIMA_S=0 ;; esac
  if [ $(( $(date +%s) - PRIMA_S )) -ge 21600 ]; then
    date +%s > /tmp/sentinella_giro
    say "lancio la sentinella delle chiavi"
    timeout 1200 bash "$HOME/posta/lavori/sentinella_chiavi.sh" >> "$LOG" 2>&1 \
      || say "sentinella: esito non zero (vedi /tmp/sentinella_chiavi.log)"
  fi

  sleep 30
done
[0m
[0m$ [0mcat ~/posta/lavori/modelli_aihorde.py
(no output)
[0m
[0m$ [0mcat ~/posta/dal_pc/sentinella_chiavi.md
# 🛡️ Sentinella delle chiavi — 02/11/2026 13:32

## 1. Catalogo freellmapi
```
catalogo 2026.11.01.395dc3 · 33 provider · 342 modelli · 80 quirk
scritto: /home/agenti/posta/lavori/catalogo_freellmapi.json
```

## 2. Appello (solo i problemi)
```

  [33m—[0m AgentRouter        nessuna chiave nel portachiavi
  [31m✗[0m AI Horde (senza chiave)  28404 ms  {"error":{"message":"The model 'koboldcpp/Gemma-4-E4B-it-Ultra-Uncensored-Heretic' is not 
  [31m✗[0m Aion Labs            2303 ms  chiave rifiutata
  [33m◐[0m Api.Airforce         4130 ms  limite o credito finito adesso
  [33m◐[0m Chutes               2184 ms  limite o credito finito adesso
  [33m—[0m fal.ai             nessuna chiave nel portachiavi
  [33m◐[0m Google AI Studio    32016 ms  limite o credito finito adesso
  [33m◐[0m HuggingFace Router   2079 ms  limite o credito finito adesso
  [31m✗[0m Jina AI               877 ms  elenco modelli: risposta 404
  [31m✗[0m LongCat              2484 ms  {"error":{"code":"invalid_parameter","message":"Unsupported model (model=auto)","type":"in
  [31m✗[0m Moondream            1365 ms  elenco modelli: risposta 404
  [31m✗[0m NaraRouter           8926 ms  {"error":{"type":"not_found","message":"The requested model does not exist.","request_id":
  [31m✗[0m NavyAI               2354 ms  {"error":{"message":"The model 'navy-auto' does not exist or is not supported for chat com
  [33m—[0m Nscale             nessuna chiave nel portachiavi
  [33m◐[0m OpenCode Zen         2323 ms  limite o credito finito adesso
  [31m✗[0m Speechify             970 ms  elenco modelli: risposta 404
  [33m—[0m TeamoRouter        nessuna chiave nel portachiavi
  [33m◐[0m UnoRouter            1832 ms  limite o credito finito adesso
  [31m✗[0m Waterfall            1817 ms  chiave rifiutata
  [31m✗[0m WaveSpeedAI           992 ms  elenco modelli: risposta 404
  [32m✓[0m Zhipu               81565 ms  ha risposto davvero (glm-4.6v-flash)

  Rapporto: /home/agenti/posta/dal_pc/appello_chiavi.md
  Riserva pronta: /home/agenti/.posta_appello.json
```

riserva ora: 42 su 62 provider

## 3. Check-in AgentRouter
check-in non eseguito: o non e' l'ora (dopo le 18:05), o il browser degli agenti non risponde, o e' gia' stato fatto oggi.
[0m
[0m→ [0mRead lavori/modelli_aihorde.py
[0m
[0m$ [0mpython3 - <<'EOF'
import json
p=json.load(open('/home/agenti/posta/lavori/catalogo_freellmapi.json'))
prov=p['provider']; q=p['quirk']
print("PROVIDERS:", list(prov.keys()))
print()
for k,v in prov.items():
    nome=(v.get('nome') or '')+' '+(v.get('etichetta') or '')
    if any(s.lower() in (k+' '+nome).lower() for s in ['nara','uno','chute','hugg','google','opencode','airforce','horde']):
        print("KEY",k,"|",v.get('nome'),"|",v.get('etichetta'),"| modelli",len(v.get('modelli',[])))
        for m in v.get('modelli',[]):
            print("   ",m.get('id'),"rank",m.get('rank'),"rpm",m.get('rpm'),"rpd",m.get('rpd'))
        print()
print("=== QUIRK keys ===")
print(list(q.keys()))
EOF
PROVIDERS: ['google', 'ovh', 'cloudflare', 'groq', 'openrouter', 'cohere', 'llm7', 'mistral', 'zhipu', 'nvidia', 'agnes', 'bazaarlink', 'aihorde', 'kilo', 'aion', 'requesty', 'sealion', 'nara', 'xkiro', 'unorouter', 'routeway', 'electronhub', 'router9', 'septor', 'clod', 'speechify', 'airforce', 'dreamprompting', 'waterfall', 'logfare', 'moondream', 'speka', 'llmtr']

KEY google | Google AI Studio | Google AI Studio | modelli 17
    gemini-3.8-flash rank 25 rpm None rpd None
    gemini-flash-latest rank 25 rpm 10 rpd 20
    gemini-3.7-flash rank 29 rpm 10 rpd 20
    gemini-3.6-flash rank 39 rpm 10 rpd 20
    gemini-3.5-flash rank 41 rpm 10 rpd 20
    gemini-3.8-live rank 49 rpm 10 rpd 20
    gemini-3.8-live-extended-thinking rank 49 rpm 10 rpd 20
    gemini-robotics-er-2-preview rank 57 rpm 10 rpd 20
    gemini-3.5-flash-lite rank 63 rpm 15 rpd 20
    gemini-flash-lite-latest rank 63 rpm 10 rpd 20
    gemma-4-31b-it rank 69 rpm 15 rpd 1000
    gemini-3-flash-preview rank 71 rpm 10 rpd 20
    gemma-4-26b-a4b-it rank 73 rpm 15 rpd 1000
    gemini-3.1-flash-lite rank 75 rpm 15 rpd 20
    gemini-3.1-flash-lite-preview rank 75 rpm 10 rpd 20
    gemini-2.5-flash rank 81 rpm 10 rpd 20
    gemini-2.5-flash-lite rank 89 rpm 15 rpd 20

KEY aihorde | AI Horde | AI Horde (senza chiave) | modelli 32
    koboldcpp/gemma-4-31B-it-heretic rank 73 rpm None rpd None
    koboldcpp/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive rank 93 rpm None rpd None
    koboldcpp/Gemma-4-E4B-it-Ultra-Uncensored-Heretic rank 93 rpm None rpd None
    koboldcpp/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-Q4_K_M rank 93 rpm None rpd None
    koboldcpp/Llama-3.2-3B rank 95 rpm None rpd None
    koboldcpp/Qwen/Qwen3.5-0.8B rank 95 rpm None rpd None
    meta-llama/Llama-3.2-3B-Instruct rank 95 rpm None rpd None
    koboldcpp/Llama-3.2-3B-Instruct-Q4_K_M rank 95 rpm None rpd None
    koboldcpp/Qwen3-4B-Nymphaea-RP.i1-Q4_K_S rank 95 rpm None rpd None
    koboldcpp/llama-3.2-3b-instruct-q4_k_m rank 95 rpm None rpd None
    koboldcpp/Qwen_Qwen3-0.6B-IQ4_XS rank 97 rpm None rpd None
    koboldcpp/digo-prayudha/unsloth-llama-3.2-1b-gguf rank 97 rpm None rpd None
    koboldcpp/Llama-3.2-1B-Instruct rank 97 rpm None rpd None
    koboldcpp/L3-8B-Stheno-v3.2 rank 99 rpm None rpd None
    koboldcpp/L3-Super-Nova-RP-8B rank 99 rpm None rpd None
    aphrodite/SicariusSicariiStuff/Impish_LLAMA_4B rank 99 rpm None rpd None
    koboldcpp/TheDrummer_Behemoth-128B-v3-Q4_K_M rank 101 rpm None rpd None
    aphrodite/TheDrummer/Behemoth-X-123B-v2.1 rank 101 rpm None rpd None
    koboldcpp/[ctx:65536] Magidonia-24B-heretic- rank 101 rpm None rpd None
    aphrodite/TheDrummer/Cydonia-24B-v4.3 rank 103 rpm None rpd None
    aphrodite/TheDrummer/Skyfall-31B-v4.2 rank 103 rpm None rpd None
    koboldcpp/Cydonia-24B-v4.3 rank 103 rpm None rpd None
    koboldcpp/mini-magnum-12b-v1.1 rank 105 rpm None rpd None
    koboldcpp/Angelic_Eclipse-12B rank 105 rpm None rpd None
    koboldcpp/Rocinante-X-12B rank 105 rpm None rpd None
    koboldcpp/L3-8B-Stheno-v3.2-Q5_K_M rank 105 rpm None rpd None
    aphrodite/SicariusSicariiStuff/Impish_Bloodmoon_12B rank 105 rpm None rpd None
    koboldcpp/MN-Violet-Lotus-12B.Q8_0 rank 105 rpm None rpd None
    koboldcpp/ReadyArt/Forgotten-Safeword-22B rank 105 rpm None rpd None
    koboldcpp/lunahr/thea-rp-3b-25r rank 106 rpm None rpd None
    koboldcpp/mradermacher/Cerebras-GPT-111M-instruction-GGUF rank 202 rpm None rpd None
    koboldcpp/mradermacher/pythia-70m-deduped.f16.gguf rank 203 rpm None rpd None

KEY nara | NaraRouter | NaraRouter | modelli 9
    nex-n2.5-pro rank 49 rpm 10 rpd None
    laguna-s-2.1 rank 57 rpm 10 rpd None
    ling-3.0-flash-vl-free rank 57 rpm 10 rpd None
    ling-3.0-flash-fin-free rank 61 rpm 10 rpd None
    nemotron-3-ultra-free rank 61 rpm 10 rpd None
    agnes-2.5-flash rank 63 rpm 10 rpd None
    ling-3.0-flash-sante-free rank 65 rpm 10 rpd None
    nemotron-3-super-free rank 81 rpm 10 rpd None
    nemotron-3.5-lightning-free rank 81 rpm 10 rpd None

KEY unorouter | UnoRouter | UnoRouter | modelli 2
    glm-5.3:free rank 17 rpm 1 rpd None
    glm-5.3-flash:free rank 23 rpm 1 rpd None

KEY airforce | Api.Airforce | Api.Airforce | modelli 18
    gpt-oss-20b rank 89 rpm 1 rpd 1000
    mistral-code-latest rank 89 rpm 1 rpd 1000
    rnj-1 rank 91 rpm 1 rpd 1000
    unmoderated-gpt rank 91 rpm 1 rpd 1000
    llama-instant rank 95 rpm 1 rpd 1000
    ministral-14b-2512 rank 95 rpm 1 rpd 1000
    ministral-14b-latest rank 95 rpm 1 rpd 1000
    ministral-3b-2512 rank 97 rpm 1 rpd 1000
    ministral-3b-latest rank 97 rpm 1 rpd 1000
    ministral-8b-2512 rank 97 rpm 1 rpd 1000
    ministral-8b-latest rank 97 rpm 1 rpd 1000
    codestral-2508 rank 99 rpm 1 rpd 1000
    codestral-latest rank 99 rpm 1 rpd 1000
    mistral-code-fim-latest rank 99 rpm 1 rpd 1000
    open-mistral-nemo rank 99 rpm 1 rpd 1000
    open-mistral-nemo-2407 rank 99 rpm 1 rpd 1000
    mistral-tiny-2407 rank 99 rpm 1 rpd 1000
    mistral-tiny-latest rank 99 rpm 1 rpd 1000

=== QUIRK keys ===
['cloudflare', 'kilo', 'llm7', 'ovh', 'nvidia', 'openrouter', 'requesty', 'google', 'cohere', 'pollinations', 'opencode', 'zhipu', 'aihorde', 'nara', 'huggingface', 'github', 'modelscope', 'bai', 'qianfan', 'volcengine', 'xfyun', 'sail', 'radeon', 'electronhub', 'experiential', 'router9', 'septor', 'clod', 'speechify', 'blaze', 'navy', 'orcarouter', 'mistral', 'lucidity', 'airforce', 'dreamprompting', 'waterfall', 'logfare', 'reka', 'aclide', 'moondream', 'speka', 'llmtr', 'xkiro', 'gizmo', 'blockrun', 'typhoon', 'plugsky', 'inferbase', 'simplellm', 'freeai', 'kenari', 'jamai', 'nabh', 'novai']
[0m
[0m$ [0mpython3 - <<'EOF'
import json
p=json.load(open('/home/agenti/posta/lavori/catalogo_freellmapi.json'))
q=p['quirk']
for k in ['google','nara','unorouter','airforce','opencode','huggingface','aihorde','chutes']:
    print("="*70); print("QUIRK",k)
    v=q.get(k)
    print(json.dumps(v,ensure_ascii=False,indent=2) if v is not None else "  (nessun quirk)")
EOF
======================================================================
QUIRK google
[
  {
    "slug": "gemini-thinking-token-room",
    "titolo": "Thinking tokens use output cap",
    "testo": "Gemini Flash can spend hidden thinking tokens inside maxOutputTokens. Avoid tiny max_tokens values or set thinkingBudget to 0 when provider support is available.",
    "gravita": "info"
  },
  {
    "slug": "nov01-media-google-gemini-3-5-transcribe",
    "titolo": "Shared renewable free allowance",
    "testo": "Ongoing Gemini API free-tier quota; account limits apply. Live tested 2026-11-01. Model entries share the provider allowance; they do not each grant separate credits. https://ai.google.dev/gemini-api/docs/pricing",
    "gravita": "info"
  }
]
======================================================================
QUIRK nara
[
  {
    "slug": "nara-free-plan",
    "titolo": "Daily free quota",
    "testo": "NaraRouter free access requires a no-card account key plus Telegram channel/link verification. The free plan is documented at 7M tokens/day and 10 req/min, with daily reset.",
    "gravita": "info"
  },
  {
    "slug": "nara-stepfun-paid-2026-09-21",
    "titolo": "Moved to a paid plan",
    "testo": "Key-tested on September 21, 2026: NaraRouter answers stepfun-3.7-flash with 402 payment_required, \"Insufficient credits. Please top up your balance.\" The route left the free plan.",
    "gravita": "warning"
  }
]
======================================================================
QUIRK unorouter
  (nessun quirk)
======================================================================
QUIRK airforce
[
  {
    "slug": "airforce-free-plan-limits",
    "titolo": "Free plan is 1 request per minute",
    "testo": "Api.Airforce Free grants 1,000 requests per day at 1 request per minute per account with per-model token caps and no card. The 21 listed routes returned matching model IDs on September 15. kimi-k2.7-code requires a paid plan; gpt-oss-120b, Mistral Large and Mistral Medium returned 503 and are excluded. Most routes are proxied Mistral free-plan models; treat them as sharing that upstream capacity.",
    "gravita": "info"
  }
]
======================================================================
QUIRK opencode
[
  {
    "slug": "zen-promo-roster",
    "titolo": "Limited-time promo, roster rotates",
    "testo": "OpenCode Zen free models are explicitly limited-time promotional access (\"available for a limited time\" per the docs), not a recurring quota. The roster rotates: qwen3.6-plus and minimax-m3 promos already ended. Expect any row here to die without notice; prompts/outputs may be used for model improvement.",
    "gravita": "warning"
  },
  {
    "slug": "opencode-responses-only",
    "titolo": "Responses API only",
    "testo": "OpenCode Zen exposes this model through POST /v1/responses rather than /v1/chat/completions. Clients and adapters must use the Responses API transport.",
    "gravita": "warning"
  },
  {
    "slug": "zen-serves-ultra-fast",
    "titolo": "Zen serves the 550B fast",
    "testo": "OpenCode Zen serves nemotron-3-ultra in ~2s with working tool calls where the OpenRouter route hangs — the live-verified path for this model.",
    "gravita": "info"
  },
  {
    "slug": "zen-free-client-locked",
    "titolo": "OpenCode's free tier only works inside OpenCode",
    "testo": "On September 17, 2026 every free Zen model answered 403 FreeTierError (\"OpenCode's free tier can only be used from within OpenCode\") on a valid key, with or without the OpenCode client headers, and deepseek-v4-flash-free answered 400 \"Model is unavailable\". The rows are disabled until OpenCode opens the free roster to API clients again.",
    "gravita": "warning"
  }
]
======================================================================
QUIRK huggingface
[
  {
    "slug": "hf-tiny-credit",
    "titolo": "Small $0.10/month routed credit",
    "testo": "HuggingFace Inference Providers grants only ~$0.10/month of routed credit on the free tier (PRO is $2/month). Enough for light experimentation; exhausts quickly. Credits apply only to HF-routed requests.",
    "gravita": "warning"
  },
  {
    "slug": "hf-monthly-credits-exhausted",
    "titolo": "Monthly included credits run out",
    "testo": "HuggingFace meters Inference Providers in dollars, not tokens: free accounts get $0.10 credited every month. When it is spent every route answers 402 \"You have depleted your monthly included credits\", as happened during the September 18, 2026 audit. This is a spent-wallet state, not a dead route, and it clears when the monthly grant renews. Rows are kept enabled and the router should treat 402 here as a provider-level cooldown to the start of next month rather than a per-model failure.",
    "gravita": "info"
  },
  {
    "slug": "hf-router-no-enabled-provider-2026-09-21",
    "titolo": "No inference provider serves this model",
    "testo": "Key-tested on September 21, 2026: the HuggingFace router answered these ids with \"The requested model is not supported by any provider you have enabled\". They are catalogued on the Hub but no Inference Provider serves them, so the route cannot succeed for any account. Separately, the router meters dollars against a $0.10 monthly included credit, not tokens; when that credit is spent every other row returns 402 until the monthly reset.",
    "gravita": "warning"
  },
  {
    "slug": "huggingface-free-credits-ended-20261007",
    "titolo": "Free-account inference credits ended",
    "testo": "Hugging Face now lists no included Inference Providers credits for Free accounts. The official documentation change merged October 7, 2026 (huggingface/hub-docs#2865). Routed inference requires purchased credits or a paid subscription; ZeroGPU Spaces are a separate service and do not fund these router endpoints. Existing records are retained but disabled. See https://huggingface.co/docs/inference-providers/pricing.",
    "gravita": "warning"
  }
]
======================================================================
QUIRK aihorde
[
  {
    "slug": "aihorde-anon-slow",
    "titolo": "Free volunteer queue, slow",
    "testo": "AI Horde routes to volunteer-run workers through a priority queue, so latency is seconds to minutes, not the sub-second of hosted providers. The anonymous key 0000000000 runs at the lowest priority; register a free key at aihorde.net for higher priority. The provider uses a 120s timeout.",
    "gravita": "warning"
  },
  {
    "slug": "aihorde-no-tools",
    "titolo": "No tool calling",
    "testo": "AI Horde's OpenAI-compatible proxy does not support function/tool calling. The provider drops tools, tool_choice and parallel_tool_calls so a tool-using request still completes as plain chat instead of failing.",
    "gravita": "info"
  },
  {
    "slug": "aihorde-usage-estimated",
    "titolo": "Usage is kudos; tokens estimated",
    "testo": "The proxy returns usage as {\"kudos\": N} with no token counts, and rejects max_tokens below 16 and a non-array stop. The AIHordeProvider normalizes the request (floors max_tokens, wraps stop) and synthesizes prompt/completion token estimates so analytics and savings math aren't zero.",
    "gravita": "info"
  },
  {
    "slug": "aihorde-roster-rotates",
    "titolo": "Roster + context depend on online workers",
    "testo": "Model availability changes as volunteer workers come and go, so a listed model can be temporarily unserved. The effective context window is set by the worker (often 4-8K), not the model's native maximum.",
    "gravita": "info"
  },
  {
    "slug": "aihorde-quality-uneven",
    "titolo": "Uneven quality",
    "testo": "Output quality varies by worker and quantization, and some workers append template or instruction text after the answer. Best treated as free fallback capacity, not a primary model.",
    "gravita": "warning"
  },
  {
    "slug": "aihorde-behemoth-slow",
    "titolo": "123B has heavy queue (seeded disabled)",
    "testo": "Behemoth-X-123B has deep queue depth (50s+ ETA even on trivial prompts). Seeded disabled; enable only if minute-scale latency is acceptable.",
    "gravita": "warning"
  }
]
======================================================================
QUIRK chutes
  (nessun quirk)
[0m
[93m[1m! [0mpermission requested: external_directory (/tmp/*); auto-rejecting
[0m✗ [0mcd /tmp && rm -rf freellmapi && timeout 60 git clone --depth 1 https://github.com/tashfeenahmed/freellmapi.git 2>&1 | tail -5; ls /tmp/freellmapi 2>/dev/null | head failed
[91m[1mError: [0mThe user rejected permission to use this specific tool call.
[0m
[0m$ [0mfind /home/agenti -maxdepth 5 -type f \( -name 'provider-quota.ts' -o -name 'cooldown-probe.ts' -o -name 'model-state.ts' -o -name 'scoring.ts' \) 2>/dev/null; echo "---dirs---"; find /home/agenti -maxdepth 4 -type d -iname '*freellm*' 2>/dev/null
---dirs---
/home/agenti/posta/free-llm-hub/api/freellmapi
/home/agenti/posta_bak_0211/free-llm-hub/api/freellmapi
[0m

<!-- fine verdetto_quota_8provider -->
