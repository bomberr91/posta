# Risposta a «indaga_navy_longcat»

_02/11/2026 15:41 · FilippoPC_

# Indagine NavyAI e LongCat — 02/11/2026 15:41

Metodo: catalogo con la chiave, poi chat vera sul modello curato e sui candidati
del catalogo (max 4), poi ricerca del free tier. L'esito si decide sul corpo
della risposta: un HTTP 200 con HTML non prova niente.

================================================================
NavyAI (id in lista: navy)
  indirizzo: https://api.navy/v1
  modello in lista: schizogpt
  modelli extra in lista: gpt-6.1-sol;gpt-6-astra;gpt-5.6-sol
  chiave: trovata, 51 caratteri
  GET https://api.navy/v1/models -> HTTP 200
    modelli nel catalogo: 132
      - schizogpt
      - gpt-6.1-sol
      - gpt-6-astra
      - gpt-6-sol
      - gpt-6-luna
      - gpt-5.6-sol
      - gpt-5.6-terra
      - gpt-5.6-luna
      - gpt-5.5
      - claude-opus-5.5
      - claude-opus-5
      - claude-opus-4.8
  chat modello 'schizogpt' -> HTTP 403
    corpo: {"error":{"message":"The Free plan is temporarily paused for all users. You can purchase a plan at https://api.navy/dashboard/billing to continue using the API.","type":"permission_error","code":"insufficient_plan"}}
  chat modello 'gpt-6.1-sol' -> HTTP 403
    corpo: {"error":{"message":"The Free plan is temporarily paused for all users. You can purchase a plan at https://api.navy/dashboard/billing to continue using the API.","type":"permission_error","code":"insufficient_plan"}}
  chat modello 'gpt-6-astra' -> HTTP 403
    corpo: {"error":{"message":"The Free plan is temporarily paused for all users. You can purchase a plan at https://api.navy/dashboard/billing to continue using the API.","type":"permission_error","code":"insufficient_plan"}}
  chat modello 'gpt-6-sol' -> HTTP 403
    corpo: {"error":{"message":"The Free plan is temporarily paused for all users. You can purchase a plan at https://api.navy/dashboard/billing to continue using the API.","type":"permission_error","code":"insufficient_plan"}}

================================================================
LongCat (id in lista: longcat)
  indirizzo: https://api.longcat.chat/openai/v1
  modello in lista: LongCat-2.5
  modelli extra in lista: LongCat-2.5-Preview;LongCat-2.0
  chiave: trovata, 32 caratteri
  GET https://api.longcat.chat/openai/v1/models -> HTTP 000
    corpo: 
  chat modello 'LongCat-2.5' -> HTTP 402
    corpo: {"error":{"code":"too_many_requests","message":"AppId:**QK9I Usage limit reached.","type":"rate_limit_error"}}

================================================================
Ricerca del free tier (Exa/Tavily, gratis)
--- NavyAI API free tier chat completion model names
RISPOSTA (Tavily):
  The sources do not provide specific information about the free tier chat completion model names for NavyAI API. The documentation for the complete model list mentions a model alias "gpt-4o" under the type "openai/chat-completions" and tagged "playground:chat", "tier:tier_2". However, there is no mention of a free tier or specific model names associated with it. Other sources discuss free tiers and models from different providers like Mistral, OpenRouter, and Cloudflare Workers AI, but none directly address NavyAI's free tier chat completion models.

1. Complete Model List | AI/ML API Documentation
   https://docs.aimlapi.com/api-references/service-endpoints/complete-model-list
   16384, "cutoffAt": "2023-10-01", "cutoffAt": "2023-10-01", "url": " "url": " "docsUrl": " "docsUrl": " "docsJson": " "docsJson": " }, }, "type": "openai/chat-completions", "type": "openai/chat-completions", "aliases": ["gpt-4o"], "aliases": ["gpt-4o"], "tags": ["playground:chat", "tier:tier_2"] "tags": ["playground:chat", "tier:tier_2"] }} [...] idstringOptional Keep models matching this id, or ca
2. Best Free AI APIs and Open-Source AI Models in 2027
   https://www.edenai.co/post/top-free-generative-ai-apis-and-open-source-models
   Groq is best for real-time chatbots, voice apps, and latency-sensitive workloads where response speed directly affects user experience. The catch is that the free tier is rate-limited, so it works well for demos and early testing, but may not cover sustained traffic without moving to a paid plan. ### Cerebras 2,100 tokens/second, the fastest inference available anywhere 60,000 tokens/min throughpu
3. Mistral launches a free tier for developers to test its AI models
   https://finance.yahoo.com/news/mistral-launches-free-tier-developers-191150859.html
   7. Insurance 1. Find Car Insurance 2. Types of Car Insurance 3. Car Insurance Discounts 4. Find Life Insurance 8. Taxes 1. How to File 2. Refund Status 3. Tax Extension 4. Child Tax Credit 9. Investing 1. Investing Basics 2. Real Estate Investing 3. Retirement Basics 10. Calculators 6. 1. Daily Shows 2. The 8:30 3. Sozzi Unleashed 4. The Daily Wolf 5. Market Hang 6. In the Loop 7. Weekly Shows [..
4. Best 10 Free AI Model Providers With API Key : r/FluentMac
   https://www.reddit.com/r/FluentMac/comments/1s43g39/best_10_free_ai_model_providers_with_api_key
   2. Check the "Share inputs and outputs with OpenAI" section –if there is a line "You're enrolled for complimentary daily tokens" – you're in! 3. Enable for all or specific projects on your account. Later on you can check whether your API usage is free by going to Usage and grouping your Responses and Chat Completions stats by Service Tier: > Get your OpenAI API key here. # 2. Mistral [...] # 8. NV
5. GitHub - ClawLabsAI/free-ai-models: Daily-updated list of free AI models (free LLM APIs), ranked by quality with live status. Plus one OpenAI-compatible endpoint that routes to the best one. · GitHub
   https://github.com/ClawLabsAI/free-ai-models
   3. OVHcloud publishes a permanent anonymous tier (no signup, no key) limited to 2 requests/minute per IP per model. Their `/v1/models` catalogue does answer without a key; on 2026-09-23 four chat completions from two different models, spaced over several minutes, all returned `API rate limit exceeded`. Useful to know the endpoint exists; not something to put in front of users without a key. ↩ [...

--- LongCat API free tier quota model names openai compatible
RISPOSTA (Tavily):
  The LongCat API offers an OpenAI-compatible endpoint `/v1/chat/completions` and is compatible with both the OpenAI and Anthropic API formats. The LongCat-2.0 model is described as high-performance and agentic, with a 1M token context window and a maximum output length of 128K tokens. Currently, LongCat-Flash-Lite has unlimited quota but will later offer a free tier with 50 million tokens per day. The LongCat API platform confirms API access and token purchase, but specific details about the free tier quota model names are not provided in the sources.

1. Support longcat AI · Issue #3876 · can1357/oh-my-pi · GitHub
   https://github.com/can1357/oh-my-pi/issues/3876
   OpenAI-compatible endpoint: ` (`/v1/chat/completions`). Anthropic-compatible endpoint: ` (`/v1/messages`). Bearer API key from the LongCat console. Sole model: `LongCat-2.0` (1M ctx, 128K max output, agentic). Rate limits surface as HTTP 429 with `error.code = "rate_limit_exceeded"` and `retry_after`. [...] Before implementation, maintainers need to decide or confirm: provider id and env var name,
2. Quick Start | LongCat API Docs
   https://longcat.chat/platform/docs
   | Model Name | API Format | Description | --- | LongCat-2.5-Preview | OpenAI/Anthropic | High-performance Agentic model | | LongCat-2.0 | OpenAI/Anthropic | High-performance Agentic model | ## Rate Limiting Rules ​ ### Single Request Limit ​ Maximum context length: + LongCat-2.5-Preview: 1M token context window with a maximum output length of 128K tokens + LongCat-2.0: 1M token context window with
3. Free AI APIs for Prototyping: How Far Can You Get Without Paying? | by Vitaly Sem | Medium
   https://medium.com/@virtualik/free-ai-apis-for-prototyping-how-far-can-you-get-without-paying-4c33099aa1c8
   Another big plus: the API is OpenAI-compatible. That means you do not need to rebuild your whole integration around some exotic Software Development Kit (SDK). In most cases, switching providers is mostly a matter of changing the base URL, the API key, and the model name. For chat and LLM usage, Groq’s free tier is surprisingly practical. [...] This can be useful if your bot accepts screenshots, s
4. Free AI Models on AIHubMix | AIHubMix Blog
   https://aihubmix.com/blog/free-ai-models-on-aihubmix
   A: AIHubMix offers a unified OpenAI-compatible API aggregating 500+ global models including 27+ continuously updated free models, and unlike OpenRouter, the free tier includes frontier proprietary models like GPT-5.5, GPT-Image-2, and Gemini 3 (not just open-source). Paid models are priced more competitively. The platform is officially operated by AIHubMix, LLC (USA) with formal authorization from
5. Meituan LongCat on X: "LongCat-Flash-Lite now supports API access (500~700 tps generation speed depends on data distribution) You can apply on the LongCat API page. For now, the model has unlimited quota. Later on, Lite will offer a free tier with 50 million tokens per day. 🌐 Official site: htt… / X
   https://x.com/Meituan_LongCat/status/2019773072849637725
   LongCat-Flash-Lite now supports API access (500~700 tps generation speed depends on data distribution) You can apply on the LongCat API page. For now, the model has unlimited quota. Later on, Lite will offer a free tier with 50 million tokens per day. 🌐 Official site: longcat.ai ⚙️ LongCat API Platform: longcat.chat/platform/usage Inference code for LongCat Series is also open-sourced. Thanks to t

================================================================
Fine. Adesso serve un verdetto: tenere i due provider in lista o toglierli.

<!-- fine indaga_navy_longcat -->
