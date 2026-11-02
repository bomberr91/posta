# SambaNova Cloud Free Tier: Registration Requirements, Credit Card Policy, and Rate Limits

**Date of Research:** November 1, 2026
**Target Audience:** Developers and researchers evaluating the SambaNova platform

---

## 1. Executive Summary

The SambaNova Cloud platform, built on SambaNova's proprietary Reconfigurable Dataflow Units (RDUs) rather than conventional GPUs, offers developers access to large language models through a tiered pricing structure. As of November 2026, the platform has undergone a significant transition: the original no-payment-method "Free Tier" has been deprecated and replaced by a "Developer Tier" that requires a payment method. This report provides a definitive, sourced analysis of the three core questions: registration requirements, whether a credit card is needed, and the specific rate limits imposed.

The critical finding is that SambaNova's documentation is internally contradictory on the credit card question. The official Rate Limits Policy states that a "Free Tier" applies when no payment method is linked, while the official Plans page states "Add a payment method and purchase credits to run your first requests." Community reports and third-party integrations confirm that new accounts created after the Developer Tier launch (February 8, 2025) require a payment method to make any API calls, effectively eliminating the truly free tier. The $5 free credit offered at launch may no longer be available for new sign-ups. Rate limits for accounts without a payment method are extremely restrictive at 20 requests per day per model, while the Developer Tier offers 60–240 requests per minute depending on the model.

---

## 2. Registration Requirements for the Free Tier

### 2.1 Step-by-Step Sign-Up Process

Creating a SambaNova Cloud account follows a straightforward process documented by both official sources and third-party walkthroughs. The user navigates to cloud.sambanova.ai, clicks "Sign Up," and provides an email address and password. After accepting the terms of service, the platform sends a verification email to the provided address. Once the email is verified, the user is redirected to the SambaCloud Dashboard [1].

### 2.2 Required and Optional Fields

The core registration requires only an email address and a password. No phone verification is enforced at any stage of the sign-up process, which distinguishes SambaNova from some competitors that require phone verification for API access [1]. The platform does not require an organization name, use-case description, or other demographic fields during initial registration, though such information may be requested later during billing setup.

### 2.3 Social Login Options

SambaNova Cloud supports multiple authentication methods beyond email-and-password. Google OAuth login is available and has been confirmed as a working authentication method through community support threads. A user who encountered a login error with Google was able to have the issue resolved by SambaNova support, confirming that Google login is a supported and maintained option [2]. Microsoft login is also available, though with a notable caveat: while personal Outlook accounts work successfully, Microsoft corporate or work accounts may encounter issues. A SambaNova support representative confirmed they tested Outlook login successfully but acknowledged that corporate Microsoft accounts could face authentication problems, and this issue was raised with the authentication development team [3].

### 2.4 Email Verification

Email verification is a mandatory step in the registration process. The user must check their inbox and click a verification link before being granted access to the dashboard. The verification window is not explicitly documented, but the process is described as immediate in practice [1]. Once verified, the user can access the dashboard, explore the Playground, generate API keys, and view plans.

### 2.5 API Key Generation

After registration, users can generate up to 25 API keys from the API Keys section of the dashboard. Each key is a unique string that authenticates requests when using the SambaNova API in code or third-party tools. The keys are bare UUIDs without an `sk-` prefix, which means they require careful handling to avoid accidental exposure in logs or version control [1][4].

---

## 3. Credit Card Requirement

### 3.1 The Core Contradiction in Official Documentation

The question of whether a credit card is required for the SambaNova Cloud free tier is the most complex and ambiguous aspect of the platform's offering. The official documentation contains a direct internal contradiction that requires careful parsing.

The **Rate Limits Policy** documentation states: "Free Tier: Applied when there is no payment method linked with your account" and "Developer Tier: Applied when a payment method is linked with your account" [5]. This implies that a no-payment-method tier still exists and that rate limits are determined by whether a card is on file.

However, the **Plans page** describes the Free plan as: "Start exploring SambaNova Cloud. Add a payment method and purchase credits to run your first requests" [6]. This directly contradicts the Rate Limits Policy by stating that a payment method is required even for the Free plan.

### 3.2 The Historical Context: Free Tier Deprecation

The contradiction is explained by the platform's history. On February 8, 2025, SambaNova launched the Developer Tier, which marked the beginning of the end for the original no-payment-required free tier. An official SambaNova staff member (Alex) confirmed in a community discussion: "Our free tier is indeed being transferred to the developer tier" and "We do not have any current plans to maintain the free tier in any state" [7].

The transition was accompanied by a $5 free credit offer for all existing and new developers, described as expiring in 3 months and translating to "over 30 million free tokens on Llama 8B" [8]. An additional $5 in credits was offered to top community contributors. However, this credit offer appears to have been a limited-time promotion at launch, and no current SambaNova page states that it is still available [9].

### 3.3 Current State: What New Users Experience

Community reports from mid-2026 confirm that new accounts now require a payment method. One user reported: "Tried helping a friend of mine make an account so he could check Sambanova's services, but now a payment method is needed to use it" [10]. A third-party integration provider (NeuroLink) that probed the platform live in August 2026 confirmed: "new accounts have no free allowance — every call returns 402 PAYMENT_METHOD_REQUIRED (balance_units: 0) until a payment method is added and credits are purchased" [4].

The official knowledge article explains that "Any Free Tier tokens consumed prior to February 8th 2025 will not be charged to your credit card," establishing that date as the cutoff for the original free tier [11]. Usage data after that date reflects actual charges or credit consumption.

### 3.4 The $5 Free Credit Question

The $5 free credit for new developers was prominently featured in the February 2025 launch blog post [8]. However, third-party documentation notes: "SpiderGate's picker still says '$5 starter credit, 3 months.' That offer appears only in SambaNova's 2025 launch post; no current SambaNova page states it" [9]. This suggests the offer may have expired or been discontinued, though SambaNova has not explicitly stated its current status. Users signing up today should not assume free credits are available.

### 3.5 Summary of Credit Card Policy

The practical answer for a developer signing up in November 2026 is: **a credit card (or other payment method) is required to make any API calls.** While the Rate Limits Policy documentation still references a "Free Tier" for accounts without a payment method, the Plans page and community evidence indicate that new accounts cannot use the API without adding a payment method and purchasing credits. The original no-card-required free tier has been effectively deprecated. The $5 free credit that accompanied the transition may no longer be available.

---

## 4. Rate Limits and Usage Constraints

### 4.1 Free Tier Rate Limits (No Payment Method)

For accounts that somehow still operate without a payment method, the official Rate Limits Policy defines three limit types: Requests per Minute (RPM), Requests per Day (RPD), and Tokens per Day (TPD). The Free Tier limits are identical across all available models [5]:

| Model | RPM | RPD | TPD |
|-------|-----|-----|-----|
| DeepSeek-V3.1 | 20 | 20 | 200,000 |
| Meta-Llama-3.3-70B-Instruct | 20 | 20 | 200,000 |
| gpt-oss-120b | 20 | 20 | 200,000 |
| DeepSeek-V3.2 (Preview) | 20 | 20 | 200,000 |
| gemma-4-31B-it (Preview) | 20 | 20 | 200,000 |

The most restrictive limit is the **20 requests per day** cap. This means a user can make only 20 API calls per day across all models combined (or per model, depending on interpretation — see Section 4.3). The 200,000 tokens per day limit is generous relative to the 20-request cap, suggesting that request count, not token volume, is the binding constraint for most use cases [5].

### 4.2 Developer Tier Rate Limits (Payment Method Linked)

Once a payment method is linked, the account moves to the Developer Tier, which offers substantially higher limits [5]:

| Model | RPM | RPD | Notes |
|-------|-----|-----|-------|
| DeepSeek-V3.1 | 60 | 12,000 | Production model |
| Meta-Llama-3.3-70B-Instruct | 240 | 48,000 | Production model |
| gpt-oss-120b | 60 | 12,000 | Production model |
| DeepSeek-V3.2 (Preview) | 60 | 12,000 | Preview model |
| gemma-4-31B-it (Preview) | 60 | 12,000 | Preview model |

Developer Tier accounts are also subject to a **20 million tokens per day cap across all models** [5]. The Meta-Llama-3.3-70B-Instruct model receives the highest limits at 240 RPM and 48,000 RPD, reflecting its status as the most popular production model. The blog post announcing the Developer Tier noted that RPM on 70B and 405B models was increased by 50%, and RPM on Llama 8B was doubled [8].

### 4.3 How Rate Limits Are Enforced

Rate limits are enforced on a per-model basis and are tied to the account, not to individual API keys. A community support response clarified: "On the Free Tier, each model has its own limit of 20 requests per minute, 20 requests per day, and 200,000 tokens per day. These limits are per model and tied to your account (not the API key), which is why switching to a different key on the same account wouldn't change anything" [12].

The daily limit resets on a **fixed daily window** rather than exactly 24 hours from the last request. This means that if a user exhausts their daily limit late in the day, the reset time may be later than expected [12]. The API returns rate limit information in response headers: `x-ratelimit-limit-requests`, `x-ratelimit-remaining-requests`, `x-ratelimit-reset-requests` for per-minute limits, and corresponding `-day` headers for daily limits [5].

Users can hit either limit type (RPM or RPD) depending on which threshold is reached first. If a rate limit is hit, the API returns an error message in the response [5].

### 4.4 Context Length Limits

The context length varies by model and is not differentiated by tier. All production models (DeepSeek-V3.1, Meta-Llama-3.3-70B-Instruct, gpt-oss-120b) support a 128k token context window. Among preview models, gemma-4-31B-it also supports 128k tokens, while DeepSeek-V3.2 supports 32k tokens. The MiniMax-M3.1-Flash model, available only on the Developer Tier, supports up to 1 million tokens [13].

---

## 5. Model Access and Feature Restrictions

### 5.1 Models Available on the Free Tier

The Free Tier (accounts without a payment method) provides access to five models, categorized as Production or Preview [5][13]:

**Production Models:**
- **DeepSeek-V3.1** — 128k context, text only
- **Meta-Llama-3.3-70B-Instruct** — 128k context, text only
- **gpt-oss-120b** — 128k context, text only

**Preview Models:**
- **DeepSeek-V3.2** — 32k context, text only
- **gemma-4-31B-it** — 128k context, text, image, and video input

Preview models are explicitly designated "for evaluation purposes and developer experimentation only, and should not be used in production environments. These models have limited capacity and may be removed at short notice" [13].

### 5.2 Additional Models on the Developer Tier

The Developer Tier adds access to the **MiniMax-M3.1-Flash** model, which supports a 1 million token context window and handles text and image modalities [13]. The Developer Tier also unlocks the ability to run inference on custom fine-tuned checkpoints, a feature not available on the Free Tier [14].

### 5.3 Feature Availability

The following advanced features are available through the SambaNova API and are not explicitly gated by tier, though their practical availability depends on having an account with credits:

**Streaming:** The API supports streaming responses using Server-Sent Events (SSE), compatible with the OpenAI Python client library. Streaming is available for all models [15].

**Function Calling / Tool Use:** Function calling is fully supported, allowing models to suggest and fill function arguments based on user-defined tools in JSON Schema format. The `tool_choice` parameter supports `auto`, `required`, `none`, and specific function enforcement [16].

**Structured Output / JSON Mode:** The API supports structured output through the `text.format` field, which accepts `json_schema` and `json_object` format types. This allows developers to constrain model responses to a specific JSON schema [17].

**System Prompts:** System prompts are supported through the OpenAI-compatible chat completions API, as demonstrated in official code examples [15].

**OpenAI Compatibility:** The SambaNova API is designed to be compatible with the OpenAI client libraries. Developers can simply change the base URL and API key to switch from OpenAI to SambaNova [18][15].

**Fine-Tuning:** Fine-tuning and custom model checkpoints are available but are not part of the Free Tier offering. The Developer Guide mentions "Custom Checkpoints" as a feature for running inference on fine-tuned checkpoints, but this requires a Developer Tier account [14].

### 5.4 Inference Performance

SambaNova's key differentiator is inference speed. The company claims world-record performance: up to 200 tokens per second on the Llama 3.1 405B model, up to 580 tokens per second on Llama 3.1 70B, and optimal performance on Llama 3.1 8B. This is achieved through SambaNova's custom Reconfigurable Dataflow Units (RDUs), which are purpose-built for AI workloads rather than relying on conventional GPUs [19].

---

## 6. Data Privacy and Terms of Service Considerations

### 6.1 Is API Data Used for Training?

This is a critical question for developers evaluating any AI platform. SambaNova's legal and policy framework provides a clear answer: **Customer Content (prompts, inputs, and outputs) is not used for model training or fine-tuning.**

The SambaCloud Terms of Service, Section 5.2, states: "We may collect and use query logs, and any data (but not Customer Content) relating to the operation, support and/or use of the Service ('Service Usage Data') to provide administration Service, develop, improve, support, and operate our products and Service, or to investigate fraud, abuse or violations of this Agreement" [20]. The key phrase is "but not Customer Content" — Customer Content is explicitly excluded from the data that SambaNova may collect and use for service improvement.

Customer Content is defined as "software, data, text, audio, video or images... transferred to us for processing" [20]. This covers the actual prompts and responses sent through the API.

A SambaNova staff member (Dhananjay) confirmed in a community forum: "By default, input tokens and prompts sent to the API are not stored or archived and are not used for training or fine-tuning" [21]. The product page makes an even stronger marketing claim: "SambaCloud never sees or collects any of your data or user prompts, ensuring full data privacy" [18].

Third-party analysis from terms.fru.dev independently confirms this reading, giving SambaNova a "Protective" rating for training on API data, meaning Customer Content is excluded from training [22].

### 6.2 Data Retention Policy

The Data Processing Agreement provides the most specific retention details. Section 7 of Annex I states: "Prompts, inputs and completions submitted to or generated through the Services are processed transiently to generate the response and are retained for no more than 30 days solely for security, fraud and abuse monitoring and then deleted" [23]. This means that while prompts are not permanently stored, they may be retained for up to 30 days for security purposes before deletion.

Account, authentication, billing, and Service Usage Data are retained for the duration of the contractual relationship and thereafter as described in the return or deletion policy [23]. The Privacy Policy (dated May 27, 2023) provides additional context: Personal Information is kept during the contractual relationship plus the applicable limitation period, marketing data is kept for three years after last contact, and cookies are retained for 13 months [24].

### 6.3 Differences Between Free and Paid Tiers

The Terms of Service and Data Processing Agreement do not distinguish between free and paid tiers in their data handling provisions. The same data protection commitments apply regardless of tier. However, the Privacy Policy notes that for users whose data is used to improve products (which applies to the free tier of some competitors), SambaNova's terms explicitly exclude Customer Content from such use [20][24].

### 6.4 Opt-Out Options

Because Customer Content is not used for training by default, there is no separate opt-out mechanism for training data usage. The Data Processing Agreement includes standard provisions for data subject rights, including access, deletion, and correction requests, which can be exercised by emailing privacy@sambanova.ai or calling 650-263-1153 [24]. California residents have additional rights under the CCPA [24].

---

## 7. Competitive Context and Strategic Analysis

### 7.1 Comparative Table of Free Tier Offerings

| Provider | Credit Card Required? | Free Tier Rate Limits | Models Available | Data Used for Training? |
|----------|---------------------|----------------------|------------------|------------------------|
| **SambaNova** | Yes (effectively) | 20 RPM, 20 RPD, 200K TPD per model | 5 models (DeepSeek, Llama, GPT-OSS, Gemma) | No (Customer Content excluded) |
| **Groq** | No | 30 RPM, 6K TPM (Llama 3.3 70B); 30 RPM, 30K TPM (Llama 3.1 8B) | 20+ models including Llama, GPT-OSS, Qwen, Whisper | Varies by model |
| **Google Gemini** | No | Generous free tier (exact limits not published) | Gemini 3.8/3.7/3.6 Flash (Standard and Priority) | Yes (free tier data used for improvement) |
| **Anthropic Claude** | Yes | No free API tier; Start tier: 1,000 RPM, 2M ITPM | Claude Opus, Sonnet, Haiku, Fable | No |
| **Cohere** | No | 1,000 API calls/month, 20 req/min | Command A, Command R, Embed, Rerank | Varies |

### 7.2 Detailed Competitive Analysis

**Groq** offers the most directly comparable service to SambaNova, as both focus on ultra-fast inference using specialized hardware (Groq uses LPUs, SambaNova uses RDUs). Groq's free tier is significantly more generous: no credit card is required, and rate limits are substantially higher. For example, Llama 3.3 70B on Groq's free tier gets 30 RPM and 6,000 TPM, compared to SambaNova's 20 RPM and 20 RPD [25]. Groq also offers a wider model selection, including multiple Llama variants, GPT-OSS, Qwen, and Whisper for audio transcription [26]. Groq's Developer plan unlocks 250K TPM and 1K RPM for most models [25].

**Google Gemini** provides the most generous free tier in the market. No credit card is required, and the free tier includes access to Gemini 3.8 Flash, 3.7 Flash, and 3.6 Flash models at no cost with generous rate limits. The trade-off is that free tier data is used to improve Google's products [27]. Google's paid tier pricing is competitive, with input prices as low as $0.75 per million tokens for Gemini 3.8 Flash through the end of 2026 [27].

**Anthropic Claude** has no true free API tier. A credit card is required for any API access, though new organizations may start in an Evaluation tier with lower limits while account history is established. The Start tier offers 1,000 RPM, 2M input tokens per minute, and 400K output tokens per minute for most models [28]. Anthropic's approach is the most restrictive for developers wanting to experiment without financial commitment.

**Cohere** offers trial API keys without a credit card requirement, limited to 1,000 API calls per month and 20 requests per minute for Command A models [29]. This is more generous than SambaNova's effective 20 requests per day but less generous than Groq or Google.

### 7.3 Strategic Analysis of SambaNova's Approach

SambaNova's decision to effectively eliminate the no-payment-method free tier represents a strategic shift from customer acquisition to revenue generation. Several factors explain this move:

**Infrastructure Cost Management:** SambaNova's custom RDU hardware, while delivering exceptional performance (up to 200 tokens/second on Llama 3.1 405B), represents a significant capital investment. Offering free inference at scale is expensive, and the company appears to have determined that the developer goodwill generated by a free tier did not justify the infrastructure costs [19].

**Competitive Pressure from Groq:** Groq's more generous free tier and wider model selection put pressure on SambaNova to differentiate on performance rather than price. SambaNova's response has been to emphasize its speed advantage — the company claims 200 tokens/second on the 405B model versus "the average GPU provider's performance of just 20 tokens/second" [19] — while requiring payment for access.

**The $5 Credit as a Transition Mechanism:** The $5 free credit offered at the Developer Tier launch was designed to ease the transition from free to paid. At $0.60 per million input tokens for Llama 3.3 70B, $5 translates to roughly 8 million input tokens or a mix of input and output [30]. This is sufficient for substantial experimentation but forces users to add a payment method, creating a billing relationship that can scale to paid usage.

**Data Privacy as a Differentiator:** SambaNova's commitment to not training on Customer Content is a genuine differentiator compared to Google's Gemini free tier, which explicitly uses data for product improvement. For enterprise developers and privacy-conscious users, this commitment may justify the payment requirement [20][18].

### 7.4 Trade-Offs and Non-Obvious Patterns

The most notable pattern is the tension between SambaNova's exceptional inference performance and its restrictive access model. The company offers the fastest inference available for large open-source models (200 tokens/second on 405B) but requires a payment method to access it, while competitors like Groq offer slower but still impressive performance (280 tokens/second on Llama 3.3 70B) with a genuinely free tier [19][26].

Another non-obvious pattern is the discrepancy between SambaNova's documentation and its actual practice. The Rate Limits Policy still describes a Free Tier that applies "when there is no payment method linked," but the Plans page and community evidence indicate this tier is no longer functional for new accounts [5][6][10]. This documentation lag creates confusion for developers evaluating the platform.

The 20 requests per day limit on the legacy Free Tier is unusually restrictive compared to industry norms. Even Cohere's trial tier, which limits to 1,000 calls per month, allows roughly 33 calls per day [29]. SambaNova's 20 RPD limit suggests the Free Tier was designed more as a demonstration than a usable development environment.

---

## 8. Research Gaps and Unanswered Questions

Despite comprehensive research, several questions remain unresolved:

**Status of the $5 Free Credit:** No current SambaNova page explicitly states whether the $5 free credit for new Developer Tier sign-ups is still available. The offer was prominently featured in the February 2025 launch blog post, but third-party documentation notes that no current page states it [9][8]. Users should not assume free credits are available without verifying during the sign-up flow.

**Exact Rate Limits for the Legacy Free Tier:** While the official documentation specifies 20 RPM, 20 RPD, and 200,000 TPD for the Free Tier, it is unclear whether these limits are still enforced for accounts that somehow remain without a payment method, or whether such accounts simply cannot make any API calls at all. Community reports suggest the latter [10][4].

**Model Availability Changes:** The model catalog is dynamic. Preview models "may be removed at short notice" [13], and the availability of specific models on the Free Tier versus Developer Tier may change without notice. The MiniMax-M3.1-Flash model, for example, appears only in the Developer Tier pricing page but not in the Free Tier rate limits documentation [30][5].

**Feature Parity Details:** While streaming, function calling, and structured output are documented features, it is not explicitly stated whether all features are available on both tiers. The documentation does not specify tier-based feature gating beyond model access and rate limits.

**Data Retention for Free Tier Specifically:** The Data Processing Agreement provides general retention policies, but does not distinguish between free and paid tiers. It is unclear whether free tier accounts have different data retention or deletion timelines compared to paid accounts [23].

**Enterprise Tier Details:** The Plans page mentions an Enterprise tier with "production rate limits, all models, and custom rate limits," but no specific details about pricing or limits are publicly available [6].

---

## 9. Conclusion

For a developer evaluating SambaNova Cloud in November 2026, the practical answers to the three core questions are:

**Registration Requirements:** An email address and password are sufficient to create an account. Google and Microsoft OAuth are supported (though Microsoft corporate accounts may have issues). No phone verification is required. Email verification is mandatory.

**Credit Card Requirement:** A credit card (or other payment method) is effectively required to use the API. The original no-payment-method Free Tier has been deprecated since February 2025. New accounts must add a payment method and purchase credits to make API calls. The $5 free credit that accompanied the transition may no longer be available.

**Rate Limits:** Accounts with a payment method (Developer Tier) receive 60–240 RPM and 12,000–48,000 RPD depending on the model, with a 20 million tokens per day cap across all models. The legacy Free Tier (if accessible) offers only 20 RPM, 20 RPD, and 200,000 TPD per model — limits so restrictive that they render the tier unsuitable for any serious development work.

SambaNova Cloud remains a compelling option for developers who need ultra-fast inference on large open-source models and who value data privacy (Customer Content is not used for training). However, the platform's effective elimination of a truly free tier places it at a competitive disadvantage against Groq and Google Gemini for developers who want to experiment without financial commitment. The decision to require a payment method upfront reflects a strategic prioritization of revenue generation over customer acquisition, a trade-off that developers should weigh against SambaNova's genuine performance advantages.

## Sources

[1] Medium (https://towardsdev.com/getting-started-with-sambanova-and-sambacloud-97f0d7e1123a)
[2] I Can't login using Google (https://community.sambanova.ai/t/i-cant-login-using-google/484)
[3] How can i convert the current gmail account to company Microsoft Login account (https://community.sambanova.ai/t/how-can-i-convert-the-current-gmail-account-to-company-microsoft-login-account/1132)
[4] neurolink/docs/getting-started/providers/sambanova.md at release · juspay/neurolink · GitHub (https://github.com/juspay/neurolink/blob/release/docs/getting-started/providers/sambanova.md)
[5] Rate Limits Policy - SambaNova Documentation (https://docs.sambanova.ai/docs/en/models/rate-limits)
[6] Plans (https://cloud.sambanova.ai/plans)
[7] Is free tier going away? (https://community.sambanova.ai/t/is-free-tier-going-away/847)
[8] SambaNova Cloud Developer Tier Is Live! (https://sambanova.ai/blog/sambanova-cloud-developer-tier-is-live)
[9] Get a SambaNova key — SpiderGate Docs (https://gate.spideriq.ai/docs/providers/sambanova)
[10] Question about free tier - Discussion - SambaNova Developer Community (https://community.sambanova.ai/t/question-about-free-tier/1711)
[11] Why do I see a monetary value for "Usage" data that exists before the Development Tier launch? (https://community.sambanova.ai/t/why-do-i-see-a-monetary-value-for-usage-data-that-exists-before-the-development-tier-launch/902)
[12] The daily limit is not resetting after 24 hours (https://community.sambanova.ai/t/the-daily-limit-is-not-resetting-after-24-hours/1704)
[13] SambaCloud Supported Models - SambaNova Documentation (https://docs.sambanova.ai/docs/en/models/sambacloud-models)
[14] SambaNova Developer Guide - SambaNova Documentation (https://docs.sambanova.ai/docs/en/get-started/overview)
[15] OpenAI Client Libraries Compatibility Guide - SambaNova Documentation (https://docs.sambanova.ai/docs/en/features/openai-compatibility)
[16] Function Calling and JSON Mode Guide - SambaNova Documentation (https://docs.sambanova.ai/docs/en/features/function-calling)
[17] Responses Implementation Guide - SambaNova Documentation (https://docs.sambanova.ai/docs/en/features/responses)
[18] SambaCloud | Full-Stack AI Platform for Large Open-Source Models (https://sambanova.ai/products/sambacloud)
[19] Get your AI API Key (https://sambanova.ai/lp/ai-api-key)
[20] SambaCloud Terms Of Service | SambaNova (https://sambanova.ai/cloud-end-user-license-agreement)
[21] Data handling and retention (https://community.sambanova.ai/t/data-handling-and-retention/1314)
[22] Does SambaNova train on your data? SambaNova terms, quoted (https://terms.fru.dev/vendors/sambanova)
[23] Data Processing Agreement | SambaNova (https://sambanova.ai/data-processing-agreement-sambanova)
[24] Privacy Policy | SambaNova (https://sambanova.ai/privacy-policy)
[25] Rate Limits - GroqDocs (https://console.groq.com/docs/rate-limits)
[26] Supported Models - GroqDocs (https://console.groq.com/docs/models)
[27] Gemini Developer API pricing  |  Gemini API  |  Google AI for Developers (https://ai.google.dev/pricing)
[28] Rate limits - Claude Platform Docs (https://docs.anthropic.com/en/api/rate-limits)
[29] Different Types of API Keys and Rate Limits | Cohere (https://docs.cohere.com/docs/rate-limits)
[30] Pricing (https://cloud.sambanova.ai/plans/pricing)