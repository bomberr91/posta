# Risposta a «assegnazioni_dump»

_04/11/2026 10:30 · FilippoPC_

==============================================================
 DUMP ASSEGNAZIONI — 04/11/2026 10:30
 utente: agenti   home: /home/agenti
==============================================================

### A. CONFIG DEGLI AGENTI (sul PC)
--- OPENCODE
    file: /home/agenti/.config/opencode/opencode.jsonc
   mcp.chrome-devtools.type                       = local
   mcp.chrome-devtools.command[0]                 = npx
   mcp.chrome-devtools.command[1]                 = -y
   mcp.chrome-devtools.command[2]                 = «presente (26 caratteri)»
   mcp.chrome-devtools.command[3]                 = --browserUrl=http:
--- OPENCODE (altro)
    file: /home/agenti/.config/opencode/opencode.json
   provider.cervello.options.baseURL              = http:
   provider.cervello.options.apiKey               = sk-cervello
   model                                          = cervello/auto
--- GOOSE
    file: /home/agenti/.config/goose/config.yaml
   GOOSE_PROVIDER                                 = openrouter
   GOOSE_MODEL                                    = google/gemma-4-31b-it:free
   OPENROUTER_API_KEY                             = «presente (non stampata)»
--- OPENCODE (jsonc)
    file: /home/agenti/.config/opencode/opencode.jsonc
   mcp.chrome-devtools.type                       = local
   mcp.chrome-devtools.command[0]                 = npx
   mcp.chrome-devtools.command[1]                 = -y
   mcp.chrome-devtools.command[2]                 = «presente (26 caratteri)»
   mcp.chrome-devtools.command[3]                 = --browserUrl=http:

### B. IL PORTIERE (cervello) — la sua lista e il modello 'cervello/migliore'
--- PORTIERE (prime righe utili)
    file: /home/agenti/posta/portiere_lista.txt
   gemini|Google AI Studio|Google AI Studio|https = //generativelanguage.googleapis.com/v1beta/openai|gemini-3.8-flash|chat||free-ricorrente|gemini-flash-latest;models/gemini-3.8-flash|
   ghmodels|GitHub Models|GitHub Models|https     = //models.github.ai/inference|openai/gpt-4.1|chat||free-ricorrente|gpt-4.1;openai/gpt-4o;openai/Llama-3.3-70B-Instruct;openai/deepseek-R1;mistral-ai/Mi
   agentrouter|AgentRouter|AgentRouter|https      = //agentrouter.org/v1|gpt-5.6-sol|anthropic||free-ricorrente|gpt-6-astra;gpt-6.1-sol|
   orcarouter|OrcaRouter|OrcaRouter|https         = //api.orcarouter.ai/v1|orcarouter/free|modelli||free-ricorrente||
   routeway|Routeway|Routeway|https               = //api.routeway.ai/v1|gemma-4-26b-a4b-it-chimerax:free|modelli||free-ricorrente|minimax-m3.1-flash:free|
   septorlabs|Septor Labs|Septor Labs|https       = //api.septorlabs.com/v1|auto|modelli||free-ricorrente||
   tokenharbor|Token Harbor|Token Harbor|https    = «presente (non stampata)»
   unorouter|UnoRouter|UnoRouter|https            = //api.unorouter.com/v1|qwen3.8-27b:free|modelli||free-ricorrente|glm-5.3:free;glm-5.3-flash:free;qwen/qwen3.8-27b|
   router9|Router9|Router9|https                  = //api.router9.com/v1|deepseek-v4-flash|modelli||free-ricorrente||
   waterfall|Waterfall|Waterfall|https            = //api.getwaterfall.org/v1|auto|modelli||free-ricorrente|nemotron-3-super-120b-free;nemotron-3-super-120b-a12b-free;nemotron-3.5-lightning-free;laguna-
   logfare|Logfare|Logfare|https                  = //logfare.ai/v1|auto|modelli||free-ricorrente||
   lucidity|Lucidity|Lucidity (Composite)|https   = //composite.lucidity.sh/v1|minimax/minimax-m3.1-flash:free|modelli||free-ricorrente||
   ovh|OVH|SENZA|https                            = «presente (non stampata)»
   sealion|SeaLION|SeaLION|https                  = //api.sea-lion.ai/v1|aisingapore/Llama-SEA-LION-v3-70B-IT|modelli||free-ricorrente||
   pollinationsfree|Pollinations (senza chiave)|SENZA|https = «presente (non stampata)»
   llm7|LLM7|LLM7|https                           = //api.llm7.io/v1|DeepSeek-V4-Flash-0731|modelli||free-ricorrente||
   ollamacloud|Ollama Cloud|Ollama Cloud|https    = //ollama.com/v1|auto|modelli||free-ricorrente||
   requesty|Requesty|Requesty|https               = //router.requesty.ai/v1|auto|modelli||free-ricorrente||
   zhipu|Zhipu|Zhipu|https                        = //open.bigmodel.cn/api/paas/v4|auto|modelli||free-ricorrente||
   electronhub|ElectronHub|ElectronHub|https      = //api.electronhub.ai/v1|gpt-4o|modelli||free-ricorrente||
   inferbase|Inferbase|Inferbase|https            = //api.inferbase.ai/v1|auto|modelli||free-ricorrente||
   blockrun|BlockRun|BlockRun|https               = //api.blockrun.ai/v1|nvidia/nemotron-3-nano-omni-30b-a3b-reasoning|modelli||free-ricorrente||
   kilo|Kilo (senza chiave)|SENZA|https           = «presente (non stampata)»
   pollinationsimg|Pollinations (immagini, senza chiave)|SENZA|https = «presente (non stampata)»
   ✅ risolto 21/10 (riga chat qui sopra           = apihub.agnes-ai.com/v1) — Agnes AI|il loro indirizzo API non risponde su nessun host provato (servono le loro istruzioni)
   Kilo|risolto 2/11                              = «presente (non stampata)»
--- PONTE (comandi agenti)
    file: /home/agenti/posta/lavori/ponte/ponte.json
   token_file                                     = /home/agenti/CHIAVI_LOCALI.md
   token_re                                       = «presente (20 caratteri)»
   agenti.test.cmd[0]                             = bash
   agenti.test.cmd[1]                             = -c
   agenti.test.cmd[2]                             = echo ciao dal ponte && date && hostname
   agenti.goose.cmd[0]                            = bash
   agenti.goose.cmd[1]                            = /home/agenti/posta/lavori/ponte/goose_run.sh
   agenti.goose.cmd[2]                            = {compito}
   agenti.opencode.cmd[0]                         = opencode
   agenti.opencode.cmd[1]                         = run
   agenti.opencode.cmd[2]                         = {compito}
   agenti.secondhand.cmd[0]                       = interpreter
   agenti.secondhand.cmd[1]                       = exec
   agenti.secondhand.cmd[2]                       = {compito}
   agenti.hermes.cmd[0]                           = /mnt/c/Users/giopi/AppData/Local/hermes/bin/hermes.exe
   agenti.hermes.cmd[1]                           = -z
   agenti.hermes.cmd[2]                           = {compito}
   agenti.antigravity.cmd[0]                      = /mnt/c/Users/giopi/AppData/Local/agy/bin/agy.exe
   agenti.antigravity.cmd[1]                      = -p
   agenti.antigravity.cmd[2]                      = {compito}
   agenti.antigravity.cmd[3]                      = --effort
   agenti.antigravity.cmd[4]                      = low
   agenti.openclaw.cmd[0]                         = cmd.exe
   agenti.openclaw.cmd[1]                         = /c
   agenti.openclaw.cmd[2]                         = openclaw agent --message {compito} --local

### C. CHIAVI/AGENTI NEI SCRIPT DEL PC (quali provider sono usati da cosa)
   ~/posta/lavori/OCCHI_FB_BATCH.md                           -> GEMINI, Gemini
   ~/posta/lavori/OCCHI_FB_RETRY.md                           -> GEMINI, Gemini, gemini
   ~/posta/lavori/aggiorna_catalogo.py                        -> AI Horde, Cloudflare, Cohere, Groq, Kilo, LLM7, LLMTR, Logfare, Mistral, Moondream, NVIDIA, NaraRouter, OVH, OpenRouter, Requesty, Router9, Routeway, SeaLION, Septor, Speechify, Speka, UnoRouter, Waterfall, Zhipu, cloudflare, cohere, groq, kilo, llm7, llmtr, logfare, mistral, moondream, nvidia, openrouter, ovh, requesty, router9, routeway, sealion, septor, speechify, speka, unorouter, waterfall, xKiro, xkiro, zhipu
   ~/posta/lavori/catalogo_freellmapi.json                    -> AI Horde, BlazeAPI, Cerebras, Cloud, Cloudflare, Cohere, DeepSeek, Exa, Gemini, Gizmo, Groq, Hugging Face, HuggingFace, Inferbase, Kilo, LLM7, LLMTR, Logfare, LongCat, Lucidity, Mistral, Moondream, NVIDIA, NaraRouter, NavyAI, OVH, OpenRouter, OrcaRouter, Plugsky, Requesty, Router9, Routeway, Sail, SeaLION, Septor, SimpleLLM, Speechify, Speka, Typhoon, UnoRouter, Waterfall, Zhipu, blazeapi, cloud, cloudflare, cohere, deepseek, exa, gemini, gizmo, groq, huggingface, inferbase, kilo, llm7, llmtr, logfare, longcat, lucidity, mistral, moondream, nvidia, openrouter, orcarouter, ovh, plugsky, requesty, router9, routeway, sail, sealion, septor, simplellm, speechify, speka, typhoon, unorouter, waterfall, xKiro, xkiro, zhipu
   ~/posta/lavori/cerca.sh                                    -> EXA, Exa, FIRECRAWL, LINKUP, TAVILY, Tavily, exa, tavily
   ~/posta/lavori/cura_catena.sh                              -> Gemini, gemini
   ~/posta/lavori/giudice_lusso.sh                            -> AgentRouter, agentrouter, anthropic, deepseek
   ~/posta/lavori/modelli_aihorde.py                          -> AI Horde
   ~/posta/lavori/occhi_fb.sh                                 -> GEMINI, Gemini, gemini
   ~/posta/lavori/ponte/PROTOCOLLO.md                         -> cloud
   ~/posta/lavori/ponte/goose_run.sh                          -> OPENROUTER, OpenRouter, nvidia, openrouter
   ~/posta/lavori/scorta_cervello.sh                          -> AgentRouter
   ~/posta/lavori/scorta_motore.sh                            -> OMNIROUTE, OmniRoute, omniroute
   ~/posta/lavori/scorta_posta.sh                             -> LongCat, longcat
   ~/posta/lavori/sentinella_chiavi.sh                        -> AgentRouter, LongCat, NavyAI, Waterfall, agentrouter, longcat, navyai
   ~/posta/lavori/sentinella_servizi.sh                       -> NavyAI, Waterfall, waterfall
   ~/posta/da_me/assegnazioni_dump.sh                         -> AI Horde, AgentRouter, Anthropic, AnyAPI, BlazeAPI, Cerebras, Cloudflare, Cohere, DeepSeek, Exa, Firecrawl, Gemini, Gizmo, Groq, Inferbase, Jina, Kilo, LLM7, LLMTR, Linkup, Logfare, LongCat, Lucidity, Mistral, Moondream, NVIDIA, NaraRouter, NavyAI, OVH, OmniRoute, OpenRouter, OrcaRouter, Plugsky, Polllinations, Qdrant, Requesty, Router9, Routeway, Sail, SeaLION, Septor, SimpleLLM, Speechify, Speka, Tavily, Token Harbor, Typhoon, UnoRouter, UptimeRobot, Waterfall, WaveSpeed, Zhipu, xKiro
   ~/posta/fatti/accendi_omniroute_2.sh                       -> OMNIROUTE, omniroute
   ~/posta/fatti/accendi_omniroute_e_rilancia.sh              -> OMNIROUTE, omniroute
   ~/posta/fatti/ar_canali_aperti.sh                          -> AGENTROUTER, agentrouter, anthropic, exa
   ~/posta/fatti/ar_processo3.sh                              -> agentrouter, anthropic, deepseek, exa
   ~/posta/fatti/ar_processo4.sh                              -> agentrouter, anthropic, deepseek, exa
   ~/posta/fatti/ar_tutte_le_chiavi.sh                        -> AGENTROUTER, agentrouter, anthropic, deepseek, exa
   ~/posta/fatti/audit_cervello.sh                            -> AgentRouter
   ~/posta/fatti/autonomia_avvio.sh                           -> OMNIROUTE, OmniRoute, omniroute
   ~/posta/fatti/avvia_sonda_longcat.sh                       -> LongCat, longcat
   ~/posta/fatti/buongiorno_1_11.sh                           -> OmniRoute
   ~/posta/fatti/cerca_aiza.sh                                -> OmniRoute, omniroute
   ~/posta/fatti/collaudo_f2b4.sh                             -> OMNIROUTE
   ~/posta/fatti/collaudo_gruppi_kilo.sh                      -> KILO, kilo
   ~/posta/fatti/collaudo_provider.py                         -> Groq, Mistral, NVIDIA, deepseek, groq, mistral, nvidia
   ~/posta/fatti/consigliere_saggio.sh                        -> OMNIROUTE, OmniRoute, deepseek, omniroute
   ~/posta/fatti/controlla_omni.sh                            -> OMNIROUTE, omniroute
   ~/posta/fatti/crea_bat_omniroute.sh                        -> OMNIROUTE, OmniRoute, omniroute
   ~/posta/fatti/deepdog_antiveleno.sh                        -> DEEPSEEK, Exa
   ~/posta/fatti/deepdog_both.sh                              -> Exa, Tavily
   ~/posta/fatti/deepdog_diagnosi.sh                          -> DEEPSEEK, OPENROUTER
   ~/posta/fatti/deepdog_env.sh                               -> OPENROUTER, TAVILY, openrouter, tavily
   ~/posta/fatti/deepdog_fix.sh                               -> DEEPSEEK, DeepSeek, EXA, OPENROUTER, OpenRouter, TAVILY, deepseek, openrouter
   ~/posta/fatti/deepdog_ok_definitivo.sh                     -> openrouter
   ~/posta/fatti/deepdog_toggle.sh                            -> DEEPSEEK, OPENROUTER, deepseek, tavily
   ~/posta/fatti/deepopen_diagnosi.sh                         -> HuggingFace, huggingface
   ~/posta/fatti/deepopen_round5.sh                           -> huggingface
   ~/posta/fatti/deploy_cura.sh                               -> gemini
   ~/posta/fatti/diag_rete.py                                 -> groq, mistral, nvidia, tavily
   ~/posta/fatti/diagnosi_cervello.sh                         -> OMNIROUTE, OmniRoute
   ~/posta/fatti/diagnostica_cervello.sh                      -> OmniRoute, omniroute
   ~/posta/fatti/exa_completo.sh                              -> EXA, exa
   ~/posta/fatti/gateway_diag.sh                              -> OmniRoute
   ~/posta/fatti/github_models_prova.sh                       -> deepseek, mistral
   ~/posta/fatti/github_models_prova2.sh                      -> deepseek, mistral
   ~/posta/fatti/goose_configura.sh                           -> OPENROUTER, OpenRouter, nvidia, openrouter
   ~/posta/fatti/goose_ponte_riavvio.sh                       -> OpenRouter, nvidia
   ~/posta/fatti/imposta_agent_provider.sh                    -> GROQ, Groq, MISTRAL, Mistral, NVIDIA, deepseek, groq, mistral, nvidia
   ~/posta/fatti/indaga_navy_longcat.sh                       -> Exa, LongCat, NavyAI, Tavily, exa, longcat
   ~/posta/fatti/indaga_quota_8provider.sh                    -> AI Horde, HuggingFace, NaraRouter, UnoRouter, exa, gemini, huggingface, unorouter
   ~/posta/fatti/inventario_avvio.sh                          -> OmniRoute, omniroute
   ~/posta/fatti/kilo_finale.sh                               -> KILO, Kilo, kilo, nvidia, openrouter
   ~/posta/fatti/kilo_free.sh                                 -> KILO, kilo, openrouter
   ~/posta/fatti/kilo_grezzo.sh                               -> KILO, kilo, nvidia, openrouter
   ~/posta/fatti/kilo_pregiati.sh                             -> KILO, cohere, kilo, nvidia, openrouter
   ~/posta/fatti/kilo_redirect.sh                             -> KILO, kilo, openrouter
   ~/posta/fatti/leggi_lista.sh                               -> deepseek, mistral
   ~/posta/fatti/longcat_esito.sh                             -> LONGCAT, LongCat, longcat
   ~/posta/fatti/motore_collaudo.sh                           -> OMNIROUTE
   ~/posta/fatti/motore_update.sh                             -> OMNIROUTE, omniroute
   ~/posta/fatti/prova_agentrouter.sh                         -> AgentRouter, DeepSeek, agentrouter, anthropic, deepseek
   ~/posta/fatti/prova_agentrouter2.sh                        -> AgentRouter, agentrouter, anthropic, deepseek
   ~/posta/fatti/prova_motore_auth.sh                         -> OMNIROUTE, OmniRoute
   ~/posta/fatti/prova_nararouter.sh                          -> NaraRouter, nararouter
   ~/posta/fatti/prova_navyai.sh                              -> NavyAI, navyai
   ~/posta/fatti/prova_nscale.sh                              -> exa
   ~/posta/fatti/reddit_leggi.py                              -> Gemini, TAVILY, Tavily, cloud, tavily
   ~/posta/fatti/rel_anyapi.md                                -> AnyAPI, anyapi, nvidia
   ~/posta/fatti/rel_gizmo.md                                 -> Gizmo, Groq, OpenRouter, gizmo, nvidia, openrouter
   ~/posta/fatti/rel_typhoon.md                               -> Typhoon, typhoon
   ~/posta/fatti/riavvia_guardiano_cervello.sh                -> AgentRouter
   ~/posta/fatti/ricerca_canale.py                            -> TAVILY, Tavily, tavily
   ~/posta/fatti/ripara_motore.sh                             -> OMNIROUTE, OmniRoute, omniroute
   ~/posta/fatti/ripulisci_report_chiavi.py                   -> CLOUDFLARE, Cohere, speka
   ~/posta/fatti/risolvi_ko_avvio.sh                          -> OMNIROUTE, OmniRoute, omniroute
   ~/posta/fatti/risolvi_ko_avvio2.sh                         -> OMNIROUTE, OmniRoute, omniroute
   ~/posta/fatti/rito_nuovo.sh                                -> OmniRoute
   ~/posta/fatti/scaglione1_applica_innesti.sh                -> GEMINI, Gemini, gemini
   ~/posta/fatti/setup_tavily.sh                              -> Tavily, tavily
   ~/posta/fatti/sonda_longcat.sh                             -> LongCat, longcat
   ~/posta/fatti/sonda_studio.sh                              -> GEMINI, gemini
   ~/posta/fatti/squadra_nonverdi.sh                          -> AnyAPI, GIZMO, Gizmo, TYPHOON, Typhoon, anyapi, gizmo, groq, mistral, nvidia, openrouter, typhoon
   ~/posta/fatti/squadra_nonverdi2.sh                         -> anyapi, gizmo
   ~/posta/fatti/stato_1520.sh                                -> LongCat, OmniRoute, longcat, omniroute
   ~/posta/fatti/stato_invisibili.sh                          -> OmniRoute
   ~/posta/fatti/sveglia_agentrouter.sh                       -> AGENTROUTER, AgentRouter, agentrouter
   ~/posta/fatti/sveglia_longcat_1900.sh                      -> LongCat, longcat
   ~/posta/fatti/sveglia_zcode.sh                             -> agentrouter
   ~/posta/fatti/team_nararouter.sh                           -> NaraRouter, nararouter
   ~/posta/fatti/test_blackout.sh                             -> OmniRoute, omniroute
   ~/posta/fatti/togli_popup_e_riarma.sh                      -> LONGCAT, LongCat, longcat, omniroute
   ~/posta/fatti/verifica_agent_provider.sh                   -> gemini
   ~/posta/fatti/verifica_otto_provider.sh                    -> anyapi, gizmo, longcat, typhoon, waterfall
   ~/posta/fatti/verifica_riavvio.sh                          -> LongCat, OmniRoute, longcat, omniroute
   ~/posta/fatti/verita_403.sh                                -> gemini
   ~/posta/fatti/verita_agentrouter.sh                        -> AGENTROUTER, agentrouter, anthropic, deepseek, exa
   ~/posta/fatti/zcode_audit_chiavi.sh                        -> OVH
   ~/.agents/skills/agent-browser/SKILL.md                    -> cloud
   ~/.agents/skills/autoresearch/SKILL.md                     -> Exa, exa
   ~/.agents/skills/build-mcp-server/SKILL.md                 -> Anthropic, Cloudflare, cloud, cloudflare, exa
   ~/.agents/skills/build-mcp-server/references/auth.md       -> Anthropic, anthropic
   ~/.agents/skills/build-mcp-server/references/deploy-cloudflare-workers.md -> Cloudflare, cloudflare, exa
   ~/.agents/skills/build-mcp-server/references/remote-http-scaffold.md -> Anthropic, Cloudflare, cloudflare, exa
   ~/.agents/skills/build-mcp-server/references/tool-design.md -> Anthropic
   ~/.agents/skills/build-mcp-server/references/versions.md   -> anthropic, cloudflare
   ~/.agents/skills/build-with-exa/SKILL.md                   -> EXA, Exa, exa
   ~/.agents/skills/build-with-exa/references/agent.md        -> EXA, Exa, exa
   ~/.agents/skills/build-with-exa/references/answer.md       -> EXA, Exa, exa
   ~/.agents/skills/build-with-exa/references/common-mistakes.md -> Exa, Nvidia, exa
   ~/.agents/skills/build-with-exa/references/contents.md     -> EXA, Exa, exa
   ~/.agents/skills/build-with-exa/references/http-requests.md -> EXA, Exa, exa
   ~/.agents/skills/build-with-exa/references/migrate-websets-to-agent.md -> Exa, exa
   ~/.agents/skills/build-with-exa/references/models-and-modes.md -> Exa, exa
   ~/.agents/skills/build-with-exa/references/monitors.md     -> EXA, Exa, exa
   ~/.agents/skills/build-with-exa/references/openai-compat.md -> EXA, Exa, exa
   ~/.agents/skills/build-with-exa/references/prompting-and-patterns.md -> Anthropic, Exa, exa
   ~/.agents/skills/build-with-exa/references/sdks.md         -> EXA, Exa, exa
   ~/.agents/skills/build-with-exa/references/search.md       -> Exa, Nvidia, exa
   ~/.agents/skills/build-with-exa/references/snapshot.md     -> EXA, Exa, exa
   ~/.agents/skills/docx/scripts/merge_runs.py                -> exa
   ~/.agents/skills/ffmpeg/reference.md                       -> Exa
   ~/.agents/skills/firecrawl/SKILL.md                        -> FIRECRAWL, Firecrawl, exa, firecrawl
   ~/.agents/skills/firecrawl/rules/install.md                -> Firecrawl, firecrawl
   ~/.agents/skills/firecrawl/rules/security.md               -> Firecrawl, firecrawl
   ~/.agents/skills/frontend-design/SKILL.md                  -> Anthropic, exa
   ~/.agents/skills/learn-agent-skills/SKILL.md               -> exa
   ~/.agents/skills/learn-mcp/SKILL.md                        -> exa
   ~/.agents/skills/marketingskills/AGENTS.md                 -> exa, firecrawl
   ~/.agents/skills/marketingskills/CLAUDE.md                 -> exa, firecrawl
   ~/.agents/skills/marketingskills/CONTRIBUTING.md           -> exa
   ~/.agents/skills/marketingskills/README.md                 -> Tavily
   ~/.agents/skills/marketingskills/VERSIONS.md               -> Cloud, Exa, Firecrawl, Gemini, exa, firecrawl, waterfall
   ~/.agents/skills/marketingskills/docs/skill-release-packaging.md -> exa
   ~/.agents/skills/marketingskills/partners.json             -> Tavily
   ~/.agents/skills/marketingskills/scripts/claude-web-descriptions.json -> waterfall
   ~/.agents/skills/marketingskills/skills/ab-testing/SKILL.md -> Exa
   ~/.agents/skills/marketingskills/skills/ab-testing/references/sample-size-guide.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/ad-creative/SKILL.md -> Anthropic, Exa, Gemini, exa
   ~/.agents/skills/marketingskills/skills/ad-creative/references/awareness-headlines.md -> exa
   ~/.agents/skills/marketingskills/skills/ad-creative/references/creative-review-page.md -> exa
   ~/.agents/skills/marketingskills/skills/ad-creative/references/generative-tools.md -> Cloud, Exa, GEMINI, Gemini, WaveSpeed, cloud, exa, gemini
   ~/.agents/skills/marketingskills/skills/ad-creative/references/hook-system.md -> exa
   ~/.agents/skills/marketingskills/skills/ad-creative/references/imessage-video-ads.md -> exa
   ~/.agents/skills/marketingskills/skills/ad-creative/references/motion-video-ads.md -> Gemini, exa, gemini
   ~/.agents/skills/marketingskills/skills/ad-creative/references/short-form-video-specs.md -> exa
   ~/.agents/skills/marketingskills/skills/ad-creative/references/static-ad-templates.md -> exa
   ~/.agents/skills/marketingskills/skills/ads/SKILL.md       -> Exa, exa
   ~/.agents/skills/marketingskills/skills/ads/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/ads/references/ad-copy-templates.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/ads/references/audience-targeting.md -> Exa
   ~/.agents/skills/marketingskills/skills/ads/references/audit-guardrails.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/ads/references/conversion-tracking.md -> exa
   ~/.agents/skills/marketingskills/skills/ads/references/creative-research-automation.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/ads/references/google-ads-audit-checklist.md -> exa
   ~/.agents/skills/marketingskills/skills/ads/references/google-search-playbook.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/ads/references/meta-andromeda-playbook.md -> exa
   ~/.agents/skills/marketingskills/skills/ads/references/meta-decision-system.md -> exa
   ~/.agents/skills/marketingskills/skills/ads/references/operating-check.md -> exa
   ~/.agents/skills/marketingskills/skills/ads/references/payback-period.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/ads/references/reading-google-ads-data.md -> exa
   ~/.agents/skills/marketingskills/skills/ads/references/rsa-output-spec.md -> exa
   ~/.agents/skills/marketingskills/skills/ai-seo/SKILL.md    -> Gemini, cloud, exa
   ~/.agents/skills/marketingskills/skills/ai-seo/evals/evals.json -> Gemini, exa
   ~/.agents/skills/marketingskills/skills/ai-seo/references/agent-defaults.md -> Anthropic, Exa, exa
   ~/.agents/skills/marketingskills/skills/ai-seo/references/agent-readiness.md -> Gemini, exa
   ~/.agents/skills/marketingskills/skills/ai-seo/references/ai-attribution.md -> gemini
   ~/.agents/skills/marketingskills/skills/ai-seo/references/answer-accuracy.md -> Exa, Gemini, exa
   ~/.agents/skills/marketingskills/skills/ai-seo/references/citations-vs-recommendations.md -> Exa, Gemini
   ~/.agents/skills/marketingskills/skills/ai-seo/references/content-patterns.md -> Exa, Gemini, exa
   ~/.agents/skills/marketingskills/skills/ai-seo/references/content-types.md -> exa
   ~/.agents/skills/marketingskills/skills/ai-seo/references/format-volatility.md -> Gemini, exa
   ~/.agents/skills/marketingskills/skills/ai-seo/references/linkedin-ai-citations.md -> Gemini
   ~/.agents/skills/marketingskills/skills/ai-seo/references/okf.md -> Cloud, Cloudflare, cloud, exa
   ~/.agents/skills/marketingskills/skills/ai-seo/references/platform-ranking-factors.md -> Anthropic, Cloud, Gemini, anthropic, cloud, exa
   ~/.agents/skills/marketingskills/skills/ai-seo/references/positioning-and-consensus.md -> exa
   ~/.agents/skills/marketingskills/skills/ai-seo/references/prompt-portfolio.md -> Exa, Gemini
   ~/.agents/skills/marketingskills/skills/ai-seo/references/youtube-ai-citations.md -> Gemini, exa
   ~/.agents/skills/marketingskills/skills/analytics/SKILL.md -> Exa, Gemini, exa
   ~/.agents/skills/marketingskills/skills/analytics/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/analytics/references/ga4-implementation.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/analytics/references/gtm-implementation.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/aso/SKILL.md       -> Exa, exa
   ~/.agents/skills/marketingskills/skills/aso/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/aso/references/google-play-specs.md -> Gemini, exa
   ~/.agents/skills/marketingskills/skills/aso/references/report-template.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/aso/references/scoring-criteria.md -> Exa, cohere
   ~/.agents/skills/marketingskills/skills/attribution/SKILL.md -> exa
   ~/.agents/skills/marketingskills/skills/attribution/references/attribution-models.md -> exa
   ~/.agents/skills/marketingskills/skills/attribution/references/by-business-type.md -> exa
   ~/.agents/skills/marketingskills/skills/attribution/references/first-party-tracking.md -> exa
   ~/.agents/skills/marketingskills/skills/attribution/references/measurement-paradigms.md -> exa
   ~/.agents/skills/marketingskills/skills/churn-prevention/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/churn-prevention/references/cancel-flow-patterns.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/churn-prevention/references/dunning-playbook.md -> exa
   ~/.agents/skills/marketingskills/skills/co-marketing/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/co-marketing/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/co-marketing/references/partnership-types.md -> exa
   ~/.agents/skills/marketingskills/skills/cold-email/SKILL.md -> exa
   ~/.agents/skills/marketingskills/skills/cold-email/evals/evals.json -> cloud, exa
   ~/.agents/skills/marketingskills/skills/cold-email/references/deliverability.md -> Exa
   ~/.agents/skills/marketingskills/skills/cold-email/references/follow-up-sequences.md -> Exa
   ~/.agents/skills/marketingskills/skills/cold-email/references/linkedin-outreach.md -> cloud, exa
   ~/.agents/skills/marketingskills/skills/cold-email/references/outbound-plays.md -> Exa
   ~/.agents/skills/marketingskills/skills/cold-email/references/subject-lines.md -> exa
   ~/.agents/skills/marketingskills/skills/community-marketing/SKILL.md -> Exa
   ~/.agents/skills/marketingskills/skills/competitor-profiling/SKILL.md -> Firecrawl, exa, firecrawl
   ~/.agents/skills/marketingskills/skills/competitor-profiling/evals/evals.json -> Firecrawl
   ~/.agents/skills/marketingskills/skills/competitor-profiling/references/templates.md -> exa
   ~/.agents/skills/marketingskills/skills/competitor-profiling/references/tool-reference.md -> Exa, Firecrawl, exa, firecrawl
   ~/.agents/skills/marketingskills/skills/competitors/SKILL.md -> exa
   ~/.agents/skills/marketingskills/skills/competitors/references/content-architecture.md -> Exa
   ~/.agents/skills/marketingskills/skills/content-strategy/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/content-strategy/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/content-strategy/references/headless-cms.md -> Cloud, Exa, GROQ
   ~/.agents/skills/marketingskills/skills/copy-editing/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/copy-editing/evals/evals.json -> Cloud
   ~/.agents/skills/marketingskills/skills/copy-editing/references/content-refresh.md -> exa
   ~/.agents/skills/marketingskills/skills/copy-editing/references/plain-english-alternatives.md -> exa
   ~/.agents/skills/marketingskills/skills/copywriting/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/copywriting/references/ai-tells.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/copywriting/references/copy-frameworks.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/copywriting/references/natural-transitions.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/cro/SKILL.md       -> exa
   ~/.agents/skills/marketingskills/skills/cro/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/cro/references/experiments.md -> exa
   ~/.agents/skills/marketingskills/skills/cro/references/form.md -> Exa
   ~/.agents/skills/marketingskills/skills/customer-research/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/customer-research/references/interviews-and-surveys.md -> exa
   ~/.agents/skills/marketingskills/skills/customer-research/references/source-guides.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/directory-submissions/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/directory-submissions/references/directory-list.md -> Anthropic, Cloud, cloud, exa
   ~/.agents/skills/marketingskills/skills/directory-submissions/references/positioning-variations.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/emails/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/emails/references/copy-guidelines.md -> Exa
   ~/.agents/skills/marketingskills/skills/emails/references/email-types.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/events/SKILL.md    -> Exa
   ~/.agents/skills/marketingskills/skills/events/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/events/references/sponsorship-roi.md -> exa
   ~/.agents/skills/marketingskills/skills/events/references/webinar-funnel.md -> exa
   ~/.agents/skills/marketingskills/skills/free-tools/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/free-tools/evals/evals.json -> Exa, exa
   ~/.agents/skills/marketingskills/skills/free-tools/references/tool-benchmarks.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/free-tools/references/tool-types.md -> Exa
   ~/.agents/skills/marketingskills/skills/image/SKILL.md     -> Cloud, Cloudflare, Exa, Gemini, exa, gemini
   ~/.agents/skills/marketingskills/skills/image/evals/evals.json -> Cloud, Cloudflare, Gemini, exa
   ~/.agents/skills/marketingskills/skills/image/references/ai-image-prompting.md -> Exa, Gemini, exa
   ~/.agents/skills/marketingskills/skills/influencer-marketing/SKILL.md -> exa
   ~/.agents/skills/marketingskills/skills/influencer-marketing/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/influencer-marketing/references/newsletter-sponsorships.md -> exa
   ~/.agents/skills/marketingskills/skills/influencer-marketing/references/telegram-channels.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/influencer-marketing/references/ugc-creator-program.md -> exa
   ~/.agents/skills/marketingskills/skills/launch/SKILL.md    -> Exa
   ~/.agents/skills/marketingskills/skills/launch/references/site-launch-qa.md -> Exa
   ~/.agents/skills/marketingskills/skills/lead-magnets/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/lead-magnets/evals/evals.json -> Exa, exa
   ~/.agents/skills/marketingskills/skills/lead-magnets/references/content-to-skill-corpus-design.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/lead-magnets/references/content-to-skill-release.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/lead-magnets/references/content-to-skill.md -> exa
   ~/.agents/skills/marketingskills/skills/lead-magnets/references/format-guide.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-council/references/advisors/ann-handley.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-council/references/advisors/eugene-schwartz.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-council/references/advisors/gary-halbert.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-council/references/advisors/gary-vaynerchuk.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-council/references/advisors/rory-sutherland.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-council/references/advisors/russell-brunson.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-ideas/SKILL.md -> Exa
   ~/.agents/skills/marketingskills/skills/marketing-ideas/references/guerrilla-marketing.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-ideas/references/ideas-by-category.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-loops/SKILL.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-loops/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/marketing-loops/references/loop-catalog.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-loops/references/loop-orchestration.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-loops/references/loop-state.md -> Exa
   ~/.agents/skills/marketingskills/skills/marketing-loops/references/loop-template.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-loops/references/seo-operator.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/SKILL.md -> Exa, cohere, exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/aarrr-framework.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/budget-planning.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/example-quietude.md -> Exa, cohere, exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/growth-patterns.md -> Exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/idea-cross-reference.md -> Exa, cohere, exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/market-sizing.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/measurement-framework.md -> Exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/methodology.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/ops-stack-mapping.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/plan-template.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-plan/references/team-and-agency-model.md -> cohere
   ~/.agents/skills/marketingskills/skills/marketing-psychology/SKILL.md -> exa
   ~/.agents/skills/marketingskills/skills/marketing-psychology/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/offers/SKILL.md    -> exa
   ~/.agents/skills/marketingskills/skills/offers/references/bonus-stacking.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/offers/references/examples.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/offers/references/guarantee-design.md -> Exa
   ~/.agents/skills/marketingskills/skills/offers/references/offer-anatomy.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/offers/references/offer-formats.md -> exa
   ~/.agents/skills/marketingskills/skills/offers/references/saas-offers.md -> exa
   ~/.agents/skills/marketingskills/skills/offers/references/scarcity-urgency.md -> Exa
   ~/.agents/skills/marketingskills/skills/offers/references/value-equation.md -> exa
   ~/.agents/skills/marketingskills/skills/onboarding/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/onboarding/references/activation-models.md -> exa
   ~/.agents/skills/marketingskills/skills/onboarding/references/experiments.md -> exa
   ~/.agents/skills/marketingskills/skills/popups/SKILL.md    -> Exa
   ~/.agents/skills/marketingskills/skills/pricing/SKILL.md   -> Exa
   ~/.agents/skills/marketingskills/skills/pricing/references/pricing-page-teardown.md -> Anthropic, cohere, exa
   ~/.agents/skills/marketingskills/skills/pricing/references/research-methods.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/pricing/references/tier-structure.md -> Exa
   ~/.agents/skills/marketingskills/skills/product-marketing/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/product-marketing/references/brand-voice.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/programmatic-seo/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/programmatic-seo/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/programmatic-seo/references/implementation-platforms.md -> exa
   ~/.agents/skills/marketingskills/skills/programmatic-seo/references/playbooks.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/prospecting/SKILL.md -> Firecrawl, Waterfall, exa, firecrawl, waterfall
   ~/.agents/skills/marketingskills/skills/prospecting/evals/evals.json -> exa, waterfall
   ~/.agents/skills/marketingskills/skills/prospecting/references/account-research.md -> exa
   ~/.agents/skills/marketingskills/skills/prospecting/references/b2b-prospecting.md -> exa, waterfall
   ~/.agents/skills/marketingskills/skills/prospecting/references/compliance.md -> Firecrawl, exa
   ~/.agents/skills/marketingskills/skills/prospecting/references/data-sources.md -> Firecrawl, Waterfall, exa, firecrawl, waterfall
   ~/.agents/skills/marketingskills/skills/prospecting/references/demand-signals.md -> Firecrawl, exa
   ~/.agents/skills/marketingskills/skills/prospecting/references/enrichment-playbook.md -> Exa, Waterfall, exa, waterfall
   ~/.agents/skills/marketingskills/skills/prospecting/references/local-prospecting.md -> Firecrawl, exa
   ~/.agents/skills/marketingskills/skills/prospecting/references/saas-prospecting.md -> waterfall
   ~/.agents/skills/marketingskills/skills/prospecting/references/signal-plays.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/prospecting/references/sourcing-and-enrichment.md -> Exa, waterfall
   ~/.agents/skills/marketingskills/skills/public-relations/references/crisis-communications.md -> Exa
   ~/.agents/skills/marketingskills/skills/public-relations/references/journalist-pitching.md -> Anthropic
   ~/.agents/skills/marketingskills/skills/public-relations/references/media-outlets.md -> Hugging Face, cloud
   ~/.agents/skills/marketingskills/skills/public-relations/references/newsjacking.md -> exa
   ~/.agents/skills/marketingskills/skills/public-relations/references/press-platforms.md -> exa
   ~/.agents/skills/marketingskills/skills/public-relations/references/statement-templates.md -> exa
   ~/.agents/skills/marketingskills/skills/referrals/SKILL.md -> exa
   ~/.agents/skills/marketingskills/skills/referrals/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/referrals/references/affiliate-operations.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/referrals/references/affiliate-programs.md -> Exa
   ~/.agents/skills/marketingskills/skills/referrals/references/program-examples.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/referrals/references/review-platform-rules.md -> exa
   ~/.agents/skills/marketingskills/skills/referrals/references/review-program-operations.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/referrals/references/review-programs.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/referrals/references/viral-mechanisms.md -> exa
   ~/.agents/skills/marketingskills/skills/revops/SKILL.md    -> Waterfall, exa
   ~/.agents/skills/marketingskills/skills/revops/references/inbound-routing.md -> exa
   ~/.agents/skills/marketingskills/skills/revops/references/scoring-models.md -> Exa, cloud, exa
   ~/.agents/skills/marketingskills/skills/sales-enablement/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/sales-enablement/references/cold-call-scripts.md -> exa
   ~/.agents/skills/marketingskills/skills/sales-enablement/references/deck-frameworks.md -> exa
   ~/.agents/skills/marketingskills/skills/sales-enablement/references/demo-scripts.md -> cloud, exa
   ~/.agents/skills/marketingskills/skills/sales-enablement/references/objection-library.md -> exa
   ~/.agents/skills/marketingskills/skills/schema/SKILL.md    -> exa
   ~/.agents/skills/marketingskills/skills/schema/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/schema/references/schema-examples.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/seo-audit/SKILL.md -> exa
   ~/.agents/skills/marketingskills/skills/seo-audit/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/seo-audit/references/ai-writing-detection.md -> exa
   ~/.agents/skills/marketingskills/skills/seo-audit/references/international-seo.md -> exa
   ~/.agents/skills/marketingskills/skills/seo-audit/references/local-seo-pages-and-measurement.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/seo-audit/references/local-seo.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/seo-audit/references/rankings-push.md -> exa
   ~/.agents/skills/marketingskills/skills/seo-audit/references/title-tags.md -> exa
   ~/.agents/skills/marketingskills/skills/signup/SKILL.md    -> exa
   ~/.agents/skills/marketingskills/skills/site-architecture/SKILL.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/site-architecture/references/navigation-patterns.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/site-architecture/references/platforms-and-migration.md -> Cloudflare, exa
   ~/.agents/skills/marketingskills/skills/site-architecture/references/site-type-templates.md -> Exa, exa
   ~/.agents/skills/marketingskills/skills/sms/SKILL.md       -> exa
   ~/.agents/skills/marketingskills/skills/sms/references/compliance.md -> exa
   ~/.agents/skills/marketingskills/skills/sms/references/platforms.md -> Cloud
   ~/.agents/skills/marketingskills/skills/sms/references/whatsapp.md -> Cloud, Exa, exa
   ~/.agents/skills/marketingskills/skills/social/SKILL.md    -> Exa, exa
   ~/.agents/skills/marketingskills/skills/social/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/social/references/carousel-frameworks.md -> exa
   ~/.agents/skills/marketingskills/skills/social/references/listening-sources-template.md -> exa
   ~/.agents/skills/marketingskills/skills/social/references/listening.md -> exa
   ~/.agents/skills/marketingskills/skills/social/references/post-templates.md -> exa
   ~/.agents/skills/marketingskills/skills/social/references/reverse-engineering.md -> Exa
   ~/.agents/skills/marketingskills/skills/video/SKILL.md     -> Exa, exa
   ~/.agents/skills/marketingskills/skills/video/evals/evals.json -> exa
   ~/.agents/skills/marketingskills/skills/video/references/ai-video-prompting.md -> Exa
   ~/.agents/skills/marketingskills/skills/video/references/edit-anatomy.md -> exa
   ~/.agents/skills/marketingskills/skills/video/references/product-demo-recording.md -> exa
   ~/.agents/skills/marketingskills/tests/test_skill_packaging.py -> exa
   ~/.agents/skills/marketingskills/tools/PARTNERS.md         -> exa
   ~/.agents/skills/marketingskills/tools/REGISTRY.md         -> Cloud, Exa, Firecrawl, Waterfall, exa, firecrawl, waterfall
   ~/.agents/skills/marketingskills/tools/SETUP.md            -> Cloud, Exa, exa
   ~/.agents/skills/marketingskills/tools/clis/README.md      -> EXA, Exa, FIRECRAWL, Firecrawl, exa, firecrawl
   ~/.agents/skills/marketingskills/tools/composio/README.md  -> Exa
   ~/.agents/skills/marketingskills/tools/composio/marketing-tools.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/activecampaign.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/adobe-analytics.md -> Cloud, exa
   ~/.agents/skills/marketingskills/tools/integrations/ahrefs.md -> Exa, exa
   ~/.agents/skills/marketingskills/tools/integrations/aisa.md -> Exa, Firecrawl, Tavily, exa
   ~/.agents/skills/marketingskills/tools/integrations/amplitude.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/apify.md -> cloud, exa
   ~/.agents/skills/marketingskills/tools/integrations/apollo.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/attentive.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/attio.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/audiencetap.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/beehiiv.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/brevo.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/browserbase.md -> Firecrawl, exa
   ~/.agents/skills/marketingskills/tools/integrations/calendly.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/clay.md -> waterfall
   ~/.agents/skills/marketingskills/tools/integrations/clearbit.md -> Exa
   ~/.agents/skills/marketingskills/tools/integrations/close.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/composio.md -> Exa, exa
   ~/.agents/skills/marketingskills/tools/integrations/converly.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/crossbeam.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/customer-io.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/dataforseo.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/demio.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/dub-co.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/exa.md -> Exa, exa
   ~/.agents/skills/marketingskills/tools/integrations/firecrawl.md -> FIRECRAWL, Firecrawl, exa, firecrawl
   ~/.agents/skills/marketingskills/tools/integrations/firehose.md -> Exa
   ~/.agents/skills/marketingskills/tools/integrations/fullenrich.md -> Waterfall, exa
   ~/.agents/skills/marketingskills/tools/integrations/ga4.md -> Cloud, cloud
   ~/.agents/skills/marketingskills/tools/integrations/glasser.md -> Exa, Gemini, exa
   ~/.agents/skills/marketingskills/tools/integrations/google-ads.md -> Cloud
   ~/.agents/skills/marketingskills/tools/integrations/google-search-console.md -> Cloud, cloud, exa
   ~/.agents/skills/marketingskills/tools/integrations/heyreach.md -> Cloud
   ~/.agents/skills/marketingskills/tools/integrations/hubspot.md -> Exa, exa
   ~/.agents/skills/marketingskills/tools/integrations/hunter.md -> Exa, exa, waterfall
   ~/.agents/skills/marketingskills/tools/integrations/hyperframes.md -> Cloud
   ~/.agents/skills/marketingskills/tools/integrations/instantly.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/intercom.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/keywords-everywhere.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/kit.md -> Exa, exa
   ~/.agents/skills/marketingskills/tools/integrations/klaviyo.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/leadmagic.md -> waterfall
   ~/.agents/skills/marketingskills/tools/integrations/lemlist.md -> Exa, exa
   ~/.agents/skills/marketingskills/tools/integrations/livestorm.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/mailchimp.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/mention-me.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/mixpanel.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/nitrosend.md -> Gemini, exa
   ~/.agents/skills/marketingskills/tools/integrations/onesignal.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/outreach.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/paddle.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/partnerstack.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/plausible.md -> Exa, exa
   ~/.agents/skills/marketingskills/tools/integrations/plivo.md -> Cloud, exa
   ~/.agents/skills/marketingskills/tools/integrations/ploy.md -> Cloudflare, Gemini, cloudflare, exa
   ~/.agents/skills/marketingskills/tools/integrations/posthog.md -> Cloud, exa
   ~/.agents/skills/marketingskills/tools/integrations/postmark.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/postscript.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/rankparse.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/resend.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/rewardful.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/rowbound.md -> exa, waterfall
   ~/.agents/skills/marketingskills/tools/integrations/salesforce.md -> Exa, exa
   ~/.agents/skills/marketingskills/tools/integrations/sanity.md -> GROQ
   ~/.agents/skills/marketingskills/tools/integrations/savvycal.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/segment.md -> Exa, exa
   ~/.agents/skills/marketingskills/tools/integrations/semrush.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/sendgrid.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/sequenzy.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/shopify.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/similarweb.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/snov.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/sparktoro.md -> Gemini
   ~/.agents/skills/marketingskills/tools/integrations/strapi.md -> Cloud
   ~/.agents/skills/marketingskills/tools/integrations/stripe.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/theirstack.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/tiktok-ads.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/tolt.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/truelist.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/trustpilot.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/twilio.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/typeform.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/wistia.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/wordpress.md -> exa
   ~/.agents/skills/marketingskills/tools/integrations/zapier.md -> Exa, exa
   ~/.agents/skills/marketingskills/tools/integrations/zoominfo.md -> exa
   ~/.agents/skills/memory-merger/SKILL.md                    -> Exa, exa
   ~/.agents/skills/oss-review/SKILL.md                       -> Exa
   ~/.agents/skills/pdf/SKILL.md                              -> exa
   ~/.agents/skills/pdf/forms.md                              -> Exa, exa
   ~/.agents/skills/pdf/reference.md                          -> exa
   ~/.agents/skills/pdf/scripts/extract_form_structure.py     -> exa
   ~/.agents/skills/playwright/SKILL.md                       -> exa
   ~/.agents/skills/playwright/references/cli.md              -> exa
   ~/.agents/skills/playwright/references/workflows.md        -> exa
   ~/.agents/skills/pytest-coverage/SKILL.md                  -> exa
   ~/.agents/skills/requesting-code-review/SKILL.md           -> Exa
   ~/.agents/skills/requesting-code-review/code-reviewer.md   -> Exa, exa
   ~/.agents/skills/reviewable/SKILL.md                       -> exa
   ~/.agents/skills/seo-audit/SKILL.md                        -> Exa, exa
   ~/.agents/skills/skill-invocation-router/SKILL.md          -> exa
   ~/.agents/skills/skill-invocation-router/references/invocation-model.md -> Exa
   ~/.agents/skills/skill-invocation-router/scripts/simulate_invocation.py -> exa
   ~/.agents/skills/skill-release-gate/SKILL.md               -> exa
   ~/.agents/skills/skill-release-gate/references/eval-contract.md -> exa
   ~/.agents/skills/skill-release-gate/scripts/evaluate_skill.py -> exa
   ~/.agents/skills/skill-safety-reviewer/SKILL.md            -> exa
   ~/.agents/skills/skill-safety-reviewer/assets/sandbox-policy.json -> exa
   ~/.agents/skills/skill-safety-reviewer/references/threat-model.md -> exa
   ~/.agents/skills/subagent-driven-development/SKILL.md      -> Exa, exa
   ~/.agents/skills/subagent-driven-development/implementer-prompt.md -> exa
   ~/.agents/skills/subagent-driven-development/task-reviewer-prompt.md -> exa
   ~/.agents/skills/systematic-debugging/CREATION-LOG.md      -> Exa, exa
   ~/.agents/skills/systematic-debugging/SKILL.md             -> Exa, exa
   ~/.agents/skills/systematic-debugging/condition-based-waiting.md -> exa
   ~/.agents/skills/systematic-debugging/defense-in-depth.md  -> Exa
   ~/.agents/skills/systematic-debugging/find-polluter.sh     -> Exa
   ~/.agents/skills/systematic-debugging/root-cause-tracing.md -> Exa
   ~/.agents/skills/systematic-debugging/test-pressure-1.md   -> exa
   ~/.agents/skills/taste-skill/CHANGELOG.md                  -> exa
   ~/.agents/skills/taste-skill/README.md                     -> exa
   ~/.agents/skills/taste-skill/examples/v2/CREDITS.md        -> exa
   ~/.agents/skills/taste-skill/research/laziness/README.md   -> Gemini
   ~/.agents/skills/taste-skill/research/laziness/findings/empirical-results.md -> DeepSeek
   ~/.agents/skills/taste-skill/research/laziness/findings/references.md -> Anthropic, Gemini
   ~/.agents/skills/taste-skill/research/laziness/remediation/architectural-patterns.md -> Anthropic, Cloud, Exa
   ~/.agents/skills/taste-skill/research/laziness/remediation/parameter-tuning.md -> Exa, Gemini, cohere
   ~/.agents/skills/taste-skill/research/laziness/remediation/reference-prompts.md -> exa
   ~/.agents/skills/taste-skill/research/laziness/root-causes/cognitive-shortcuts.md -> Gemini
   ~/.agents/skills/taste-skill/research/laziness/root-causes/output-limits.md -> Gemini, gemini
   ~/.agents/skills/taste-skill/research/laziness/root-causes/training-data-bias.md -> exa
   ~/.agents/skills/taste-skill/skills/brandkit/SKILL.md      -> Exa, cloud, cohere, exa
   ~/.agents/skills/taste-skill/skills/brutalist-skill/SKILL.md -> exa
   ~/.agents/skills/taste-skill/skills/gpt-tasteskill/SKILL.md -> Exa, exa
   ~/.agents/skills/taste-skill/skills/image-to-code-skill/SKILL.md -> EXA, Exa, cohere, exa
   ~/.agents/skills/taste-skill/skills/imagegen-frontend-mobile/SKILL.md -> EXA, Exa, cloud, cohere, exa
   ~/.agents/skills/taste-skill/skills/imagegen-frontend-web/SKILL.md -> EXA, Exa, exa
   ~/.agents/skills/taste-skill/skills/minimalist-skill/SKILL.md -> exa
   ~/.agents/skills/taste-skill/skills/output-skill/SKILL.md  -> exa
   ~/.agents/skills/taste-skill/skills/soft-skill/SKILL.md    -> exa
   ~/.agents/skills/taste-skill/skills/stitch-skill/DESIGN.md -> Exa, Waterfall, exa
   ~/.agents/skills/taste-skill/skills/stitch-skill/SKILL.md  -> Exa, Gemini, exa, waterfall
   ~/.agents/skills/taste-skill/skills/taste-skill-v1/SKILL.md -> exa, waterfall
   ~/.agents/skills/taste-skill/skills/taste-skill-v2-experimental/SKILL.md -> Cloud, Cloudflare, EXA, Exa, cloud, exa
   ~/.agents/skills/taste-skill/skills/taste-skill/README.md  -> exa
   ~/.agents/skills/taste-skill/skills/taste-skill/SKILL.md   -> exa
   ~/.agents/skills/taste-skill/skills/taste-skill/evals/evals.json -> exa
   ~/.agents/skills/taste-skill/skills/taste-skill/library/directions.json -> exa
   ~/.agents/skills/taste-skill/skills/taste-skill/library/heroes.json -> exa
   ~/.agents/skills/taste-skill/skills/taste-skill/library/motions.json -> exa
   ~/.agents/skills/taste-skill/skills/taste-skill/library/photos.json -> Waterfall, cloud, exa, sail, waterfall
   ~/.agents/skills/taste-skill/skills/taste-skill/library/sections.json -> exa
   ~/.agents/skills/taste-skill/skills/taste-skill/library/type.json -> exa
   ~/.agents/skills/taste-skill/skills/taste-skill/references/colour.md -> exa
   ~/.agents/skills/taste-skill/skills/taste-skill/references/critique.md -> cohere, exa
   ~/.agents/skills/taste-skill/skills/taste-skill/references/imagery.md -> exa
   ~/.agents/skills/taste-skill/skills/taste-skill/references/research.md -> cloud
   ~/.agents/skills/taste-skill/skills/taste-skill/references/type.md -> cohere, exa
   ~/.agents/skills/test-driven-development/SKILL.md          -> Exa
   ~/.agents/skills/test-driven-development/writing-good-tests.md -> exa
   ~/.agents/skills/tts/SKILL.md                              -> Exa, cloud, exa
   ~/.agents/skills/tts/scripts/render_timeline.py            -> cloud, exa
   ~/.agents/skills/use-my-browser/README.md                  -> Exa, exa
   ~/.agents/skills/use-my-browser/SKILL.md                   -> exa
   ~/.agents/skills/use-my-browser/references/anti-automation-friction.md -> exa
   ~/.agents/skills/use-my-browser/references/browser-capability-matrix.md -> Exa
   ~/.agents/skills/use-my-browser/references/debug-handoff.md -> exa
   ~/.agents/skills/use-my-browser/references/selector-bridge.md -> Exa, exa
   ~/.agents/skills/use-my-browser/references/site-patterns/README.md -> Exa, exa
   ~/.agents/skills/use-my-browser/references/task-routing.md -> exa
   ~/.agents/skills/video/references/animatic-keyframes.md    -> exa
   ~/.agents/skills/video/references/camera-lighting-vocabulary.md -> Exa, exa
   ~/.agents/skills/video/references/dramaturgy.md            -> Exa, exa
   ~/.agents/skills/video/references/fixes-and-skeletons.md   -> exa
   ~/.agents/skills/video/references/kling.md                 -> Exa, cohere, exa
   ~/.agents/skills/video/references/patterns-and-genres.md   -> Exa, exa
   ~/.agents/skills/video/references/race-and-speed.md        -> exa
   ~/.agents/skills/video/references/role-modes.md            -> cohere
   ~/.agents/skills/video/references/seedance-25.md           -> Exa, cohere, exa
   ~/.agents/skills/video/references/seedance.md              -> Exa, exa
   ~/.agents/skills/video/references/universal-rules.md       -> Exa, exa
   ~/.agents/skills/video/references/veo.md                   -> Exa, cohere, exa
   ~/.agents/skills/videodb/SKILL.md                          -> Exa, exa
   ~/.agents/skills/videodb/reference/api-reference.md        -> Exa, exa
   ~/.agents/skills/videodb/reference/capture.md              -> Exa
   ~/.agents/skills/videodb/reference/editor.md               -> Exa
   ~/.agents/skills/videodb/reference/generative.md           -> Exa
   ~/.agents/skills/videodb/reference/rtstream-reference.md   -> Exa
   ~/.agents/skills/videodb/reference/rtstream.md             -> exa
   ~/.agents/skills/videodb/reference/search.md               -> Exa, exa
   ~/.agents/skills/videodb/reference/streaming.md            -> Exa, exa
   ~/.agents/skills/videodb/scripts/ws_listener.py            -> Exa
   ~/.agents/skills/writing-plans/SKILL.md                    -> exa
   ~/.agents/skills/xlsx/SKILL.md                             -> Exa, exa
   ~/.config/opencode/node_modules/cross-spawn/README.md      -> Exa
   ~/.config/opencode/node_modules/effect/README.md           -> exa
   ~/.config/opencode/node_modules/effect/node_modules/uuid/README.md -> Exa, exa
   ~/.config/opencode/node_modules/effect/node_modules/uuid/package.json -> exa
   ~/.config/opencode/node_modules/fast-check/README.md       -> Exa, exa
   ~/.config/opencode/node_modules/kubernetes-types/README.md -> Exa, exa
   ~/.config/opencode/node_modules/msgpackr/README.md         -> exa
   ~/.config/opencode/node_modules/pure-rand/README.md        -> exa
   ~/.config/opencode/node_modules/toml/README.md             -> exa
   ~/.config/opencode/skills/agent-browser/SKILL.md           -> cloud
   ~/.config/opencode/skills/autoresearch/SKILL.md            -> Exa, exa
   ~/.config/opencode/skills/build-mcp-server/SKILL.md        -> Anthropic, Cloudflare, cloud, cloudflare, exa
   ~/.config/opencode/skills/build-mcp-server/references/auth.md -> Anthropic, anthropic
   ~/.config/opencode/skills/build-mcp-server/references/deploy-cloudflare-workers.md -> Cloudflare, cloudflare, exa
   ~/.config/opencode/skills/build-mcp-server/references/remote-http-scaffold.md -> Anthropic, Cloudflare, cloudflare, exa
   ~/.config/opencode/skills/build-mcp-server/references/tool-design.md -> Anthropic
   ~/.config/opencode/skills/build-mcp-server/references/versions.md -> anthropic, cloudflare
   ~/.config/opencode/skills/build-with-exa/SKILL.md          -> EXA, Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/agent.md -> EXA, Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/answer.md -> EXA, Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/common-mistakes.md -> Exa, Nvidia, exa
   ~/.config/opencode/skills/build-with-exa/references/contents.md -> EXA, Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/http-requests.md -> EXA, Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/migrate-websets-to-agent.md -> Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/models-and-modes.md -> Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/monitors.md -> EXA, Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/openai-compat.md -> EXA, Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/prompting-and-patterns.md -> Anthropic, Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/sdks.md -> EXA, Exa, exa
   ~/.config/opencode/skills/build-with-exa/references/search.md -> Exa, Nvidia, exa
   ~/.config/opencode/skills/build-with-exa/references/snapshot.md -> EXA, Exa, exa
   ~/.config/opencode/skills/docx/scripts/merge_runs.py       -> exa
   ~/.config/opencode/skills/ffmpeg/reference.md              -> Exa
   ~/.config/opencode/skills/firecrawl/SKILL.md               -> FIRECRAWL, Firecrawl, exa, firecrawl
   ~/.config/opencode/skills/firecrawl/rules/install.md       -> Firecrawl, firecrawl
   ~/.config/opencode/skills/firecrawl/rules/security.md      -> Firecrawl, firecrawl
   ~/.config/opencode/skills/frontend-design/SKILL.md         -> Anthropic, exa
   ~/.config/opencode/skills/learn-agent-skills/SKILL.md      -> exa
   ~/.config/opencode/skills/learn-mcp/SKILL.md               -> exa
   ~/.config/opencode/skills/memory-merger/SKILL.md           -> Exa, exa
   ~/.config/opencode/skills/oss-review/SKILL.md              -> Exa
   ~/.config/opencode/skills/pdf/SKILL.md                     -> exa
   ~/.config/opencode/skills/pdf/forms.md                     -> Exa, exa
   ~/.config/opencode/skills/pdf/reference.md                 -> exa
   ~/.config/opencode/skills/pdf/scripts/extract_form_structure.py -> exa
   ~/.config/opencode/skills/playwright/SKILL.md              -> exa
   ~/.config/opencode/skills/playwright/references/cli.md     -> exa
   ~/.config/opencode/skills/playwright/references/workflows.md -> exa
   ~/.config/opencode/skills/pytest-coverage/SKILL.md         -> exa
   ~/.config/opencode/skills/requesting-code-review/SKILL.md  -> Exa
   ~/.config/opencode/skills/requesting-code-review/code-reviewer.md -> Exa, exa
   ~/.config/opencode/skills/reviewable/SKILL.md              -> exa
   ~/.config/opencode/skills/seo-audit/SKILL.md               -> Exa, exa
   ~/.config/opencode/skills/skill-invocation-router/SKILL.md -> exa
   ~/.config/opencode/skills/skill-invocation-router/references/invocation-model.md -> Exa
   ~/.config/opencode/skills/skill-invocation-router/scripts/simulate_invocation.py -> exa
   ~/.config/opencode/skills/skill-release-gate/SKILL.md      -> exa
   ~/.config/opencode/skills/skill-release-gate/references/eval-contract.md -> exa
   ~/.config/opencode/skills/skill-release-gate/scripts/evaluate_skill.py -> exa
   ~/.config/opencode/skills/skill-safety-reviewer/SKILL.md   -> exa
   ~/.config/opencode/skills/skill-safety-reviewer/assets/sandbox-policy.json -> exa
   ~/.config/opencode/skills/skill-safety-reviewer/references/threat-model.md -> exa
   ~/.config/opencode/skills/subagent-driven-development/SKILL.md -> Exa, exa
   ~/.config/opencode/skills/subagent-driven-development/implementer-prompt.md -> exa
   ~/.config/opencode/skills/subagent-driven-development/task-reviewer-prompt.md -> exa
   ~/.config/opencode/skills/systematic-debugging/CREATION-LOG.md -> Exa, exa
   ~/.config/opencode/skills/systematic-debugging/SKILL.md    -> Exa, exa
   ~/.config/opencode/skills/systematic-debugging/condition-based-waiting.md -> exa
   ~/.config/opencode/skills/systematic-debugging/defense-in-depth.md -> Exa
   ~/.config/opencode/skills/systematic-debugging/find-polluter.sh -> Exa
   ~/.config/opencode/skills/systematic-debugging/root-cause-tracing.md -> Exa
   ~/.config/opencode/skills/systematic-debugging/test-pressure-1.md -> exa
   ~/.config/opencode/skills/tavily-best-practices/SKILL.md   -> TAVILY, Tavily, exa, tavily
   ~/.config/opencode/skills/tavily-best-practices/references/crawl.md -> exa, tavily
   ~/.config/opencode/skills/tavily-best-practices/references/extract.md -> Exa, Tavily, exa, tavily
   ~/.config/opencode/skills/tavily-best-practices/references/integrations.md -> ANTHROPIC, Anthropic, Exa, Gemini, TAVILY, Tavily, anthropic, exa, gemini, tavily
   ~/.config/opencode/skills/tavily-best-practices/references/research.md -> Exa, Tavily, exa, tavily
   ~/.config/opencode/skills/tavily-best-practices/references/sdk.md -> Cohere, TAVILY, Tavily, exa, tavily
   ~/.config/opencode/skills/tavily-best-practices/references/search.md -> Exa, Tavily, exa, tavily
   ~/.config/opencode/skills/tavily-entity/SKILL.md           -> Tavily, tavily
   ~/.config/opencode/skills/tavily-list/SKILL.md             -> Tavily, tavily
   ~/.config/opencode/skills/tavily-monitor/SKILL.md          -> Tavily, tavily
   ~/.config/opencode/skills/tavily-research/SKILL.md         -> Tavily, tavily
   ~/.config/opencode/skills/tavily-research/references/researcher.md -> tavily
   ~/.config/opencode/skills/tavily-search/SKILL.md           -> Tavily, exa, tavily
   ~/.config/opencode/skills/tavily-search/references/crawl.md -> tavily
   ~/.config/opencode/skills/tavily-search/references/map.md  -> exa, tavily
   ~/.config/opencode/skills/tavily-search/references/setup.md -> TAVILY, Tavily, tavily
   ~/.config/opencode/skills/test-driven-development/SKILL.md -> Exa
   ~/.config/opencode/skills/test-driven-development/writing-good-tests.md -> exa
   ~/.config/opencode/skills/tts/SKILL.md                     -> Exa, cloud, exa
   ~/.config/opencode/skills/tts/scripts/render_timeline.py   -> cloud, exa
   ~/.config/opencode/skills/use-my-browser/README.md         -> Exa, exa
   ~/.config/opencode/skills/use-my-browser/SKILL.md          -> exa
   ~/.config/opencode/skills/use-my-browser/references/anti-automation-friction.md -> exa
   ~/.config/opencode/skills/use-my-browser/references/browser-capability-matrix.md -> Exa
   ~/.config/opencode/skills/use-my-browser/references/debug-handoff.md -> exa
   ~/.config/opencode/skills/use-my-browser/references/selector-bridge.md -> Exa, exa
   ~/.config/opencode/skills/use-my-browser/references/site-patterns/README.md -> Exa, exa
   ~/.config/opencode/skills/use-my-browser/references/task-routing.md -> exa
   ~/.config/opencode/skills/video/references/animatic-keyframes.md -> exa
   ~/.config/opencode/skills/video/references/camera-lighting-vocabulary.md -> Exa, exa
   ~/.config/opencode/skills/video/references/dramaturgy.md   -> Exa, exa
   ~/.config/opencode/skills/video/references/fixes-and-skeletons.md -> exa
   ~/.config/opencode/skills/video/references/kling.md        -> Exa, cohere, exa
   ~/.config/opencode/skills/video/references/patterns-and-genres.md -> Exa, exa
   ~/.config/opencode/skills/video/references/race-and-speed.md -> exa
   ~/.config/opencode/skills/video/references/role-modes.md   -> cohere
   ~/.config/opencode/skills/video/references/seedance-25.md  -> Exa, cohere, exa
   ~/.config/opencode/skills/video/references/seedance.md     -> Exa, exa
   ~/.config/opencode/skills/video/references/universal-rules.md -> Exa, exa
   ~/.config/opencode/skills/video/references/veo.md          -> Exa, cohere, exa
   ~/.config/opencode/skills/videodb/SKILL.md                 -> Exa, exa
   ~/.config/opencode/skills/videodb/reference/api-reference.md -> Exa, exa
   ~/.config/opencode/skills/videodb/reference/capture.md     -> Exa
   ~/.config/opencode/skills/videodb/reference/editor.md      -> Exa
   ~/.config/opencode/skills/videodb/reference/generative.md  -> Exa
   ~/.config/opencode/skills/videodb/reference/rtstream-reference.md -> Exa
   ~/.config/opencode/skills/videodb/reference/rtstream.md    -> exa
   ~/.config/opencode/skills/videodb/reference/search.md      -> Exa, exa
   ~/.config/opencode/skills/videodb/reference/streaming.md   -> Exa, exa
   ~/.config/opencode/skills/videodb/scripts/ws_listener.py   -> Exa
   ~/.config/opencode/skills/writing-plans/SKILL.md           -> exa
   ~/.config/opencode/skills/xlsx/SKILL.md                    -> Exa, exa

### D. CHIAVI NEI FILE DI CONFIG (quali portachiavi/richiamano)
--- CHIAVI_ENV (script di caricamento chiavi)
    file: /home/agenti/posta/chiavi_env.sh
   OC_KEY                                         = «presente (non stampata)»
   GQ_KEY                                         = «presente (non stampata)»
   GM_KEY                                         = «presente (non stampata)»
   [ -z "${GM_KEY                                 = «presente (non stampata)»
   OM_KEY                                         = «presente (non stampata)»
   AN_KEY                                         = «presente (non stampata)»
   AR_KEY                                         = «presente (non stampata)»
   OMNI_URL="http                                 = //127.0.0.1:20128/v1"
   CERVELLO_URL="http                             = //127.0.0.1:20129/v1"
   SITO_URL="http                                 = //127.0.0.1:4000/v1"          # posto del motore «sito» (new-api/9router/LiteLLM)
   OPENAI_BASE_URL="$SITO_URL"                    = OPENAI_BASE_URL="$SITO_URL"
   OPENAI_BASE_URL="$OMNI_URL"                    = OPENAI_BASE_URL="$OMNI_URL"
   OPENAI_BASE_URL="$CERVELLO_URL"                = OPENAI_BASE_URL="$CERVELLO_URL"
   OPENAI_BASE_URL="$OMNI_URL"                    = OPENAI_BASE_URL="$OMNI_URL"
   export OPENCODE_API_KEY                        = «presente (non stampata)»
   export GROQ_API_KEY                            = «presente (non stampata)»
   export GEMINI_API_KEY                          = «presente (non stampata)»
   export AGENTROUTER_API_KEY                     = «presente (non stampata)»
   export OPENAI_API_BASE="$OPENAI_BASE_URL"      = export OPENAI_API_BASE="$OPENAI_BASE_URL"
   export OPENAI_API_KEY                          = «presente (non stampata)»
   export OPENAI_MODEL="${OPENAI_MODEL            = -auto}"
   export OMNIROUTE_API_KEY                       = «presente (non stampata)»
   export OPENAI_HOST="${OPENAI_HOST              = -${OPENAI_BASE_URL%/v1}}"
   export GOOSE_PROVIDER="${GOOSE_PROVIDER        = -openai}"
   export GOOSE_MODEL="${GOOSE_MODEL              = -${OPENAI_MODEL:-auto}}"
   printf '  %-22s %s\n' "OpenCode Zen"   "$([ -n "${OC_KEY = «presente (non stampata)»
   printf '  %-22s %s\n' "Groq"           "$([ -n "${GQ_KEY = «presente (non stampata)»
   printf '  %-22s %s\n' "Google AI Studio" "$([ -n "${GM_KEY = «presente (non stampata)»
   printf '  %-22s %s\n' "OmniRoute"      "$([ -n "${OM_KEY = «presente (non stampata)»
   printf '  %-22s %s\n' "AgentRouter"    "$([ -n "${AR_KEY = «presente (non stampata)»
   echo "  cervello di default per gli agenti     = $OPENAI_BASE_URL  (modello: $OPENAI_MODEL)"
   echo "  catena                                 = OmniRoute → motore sito (4000) → Portiere 20129 ($([ -f "$HOME/.posta_appello.json" ] && echo 'appello pronto' || echo 'appello non ancora fatto'))"
--- CHIAVI_ENV (script di caricamento chiavi)
    file: /home/agenti/posta_bak_0211/chiavi_env.sh
   OC_KEY                                         = «presente (non stampata)»
   GQ_KEY                                         = «presente (non stampata)»
   GM_KEY                                         = «presente (non stampata)»
   [ -z "${GM_KEY                                 = «presente (non stampata)»
   OM_KEY                                         = «presente (non stampata)»
   AN_KEY                                         = «presente (non stampata)»
   AR_KEY                                         = «presente (non stampata)»
   OMNI_URL="http                                 = //127.0.0.1:20128/v1"
   CERVELLO_URL="http                             = //127.0.0.1:20129/v1"
   SITO_URL="http                                 = //127.0.0.1:4000/v1"          # posto del motore «sito» (new-api/9router/LiteLLM)
   OPENAI_BASE_URL="$SITO_URL"                    = OPENAI_BASE_URL="$SITO_URL"
   OPENAI_BASE_URL="$OMNI_URL"                    = OPENAI_BASE_URL="$OMNI_URL"
   OPENAI_BASE_URL="$CERVELLO_URL"                = OPENAI_BASE_URL="$CERVELLO_URL"
   OPENAI_BASE_URL="$OMNI_URL"                    = OPENAI_BASE_URL="$OMNI_URL"
   export OPENCODE_API_KEY                        = «presente (non stampata)»
   export GROQ_API_KEY                            = «presente (non stampata)»
   export GEMINI_API_KEY                          = «presente (non stampata)»
   export AGENTROUTER_API_KEY                     = «presente (non stampata)»
   export OPENAI_API_BASE="$OPENAI_BASE_URL"      = export OPENAI_API_BASE="$OPENAI_BASE_URL"
   export OPENAI_API_KEY                          = «presente (non stampata)»
   export OPENAI_MODEL="${OPENAI_MODEL            = -auto}"
   export OMNIROUTE_API_KEY                       = «presente (non stampata)»
   export OPENAI_HOST="${OPENAI_HOST              = -${OPENAI_BASE_URL%/v1}}"
   export GOOSE_PROVIDER="${GOOSE_PROVIDER        = -openai}"
   export GOOSE_MODEL="${GOOSE_MODEL              = -${OPENAI_MODEL:-auto}}"
   printf '  %-22s %s\n' "OpenCode Zen"   "$([ -n "${OC_KEY = «presente (non stampata)»
   printf '  %-22s %s\n' "Groq"           "$([ -n "${GQ_KEY = «presente (non stampata)»
   printf '  %-22s %s\n' "Google AI Studio" "$([ -n "${GM_KEY = «presente (non stampata)»
   printf '  %-22s %s\n' "OmniRoute"      "$([ -n "${OM_KEY = «presente (non stampata)»
   printf '  %-22s %s\n' "AgentRouter"    "$([ -n "${AR_KEY = «presente (non stampata)»
   echo "  cervello di default per gli agenti     = $OPENAI_BASE_URL  (modello: $OPENAI_MODEL)"
   echo "  catena                                 = OmniRoute → motore sito (4000) → Portiere 20129 ($([ -f "$HOME/.posta_appello.json" ] && echo 'appello pronto' || echo 'appello non ancora fatto'))"
FINE DUMP

### E. PROCESSI ATTIVI (chi gira adesso)
   11    6719 bash /home/agenti/posta/lavori/scorta_cervello.sh
   12    6719 bash /home/agenti/posta/lavori/scorta_motore.sh
 1313    6669 python3 cervello.py
 1456    6644 bash postino.sh --loop
27151    1170 bash postino.sh --loop
28399    1076 bash postino.sh --loop
29650     985 bash postino.sh --loop
30986     876 python3 poller.py
 6310     128 bash postino.sh --loop

### F. PORTE APERTE (servizi nostri)
State Recv-Q Send-Q Local Address:Port Peer Address:PortProcess

<!-- fine assegnazioni_dump -->
