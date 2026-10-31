# Risposta a «collaudo_fase1»

_31/10/2026 09:58 · FilippoPC_

## COLLAUDO FASE 1 SUL PC — 09:58

### 1. Versione in esecuzione (deve dire FASE 1)
FASE 1

### 2. Politiche in /v1/models (devono esserci auto/gratis/veloce/migliore)
['auto', 'gratis', 'veloce', 'migliore', 'openai-fast', '—']

### 3. Ping risposto in casa (deve dire cervello/locale, 0 token)
cervello/locale (ping: risposta in casa, 0 token) → OK

### 4. Guardia solo-gratis (gpt-5 deve essere rifiutato)
{"error": {"message": "Guardia solo-gratis: 'gpt-5' sembra un modello a pagamento. Usa 'auto', 'gratis', 'veloce' o 'migliore' (regola: costo zero)."}

### 5. Sonda credenziali (zero token)
Sonda credenziali (GET /models, nessun token speso):
  🔴 Groq                   chiave RIFIUTATA (403)
  ✅ Google AI Studio       chiave valida
  ✅ Mistral                chiave valida
  🟡 Cohere                 risponde 429 (endpoint diverso?)
  ✅ OpenRouter             chiave valida
  ✅ NVIDIA                 chiave valida
  ✅ HuggingFace Router     chiave valida
  ✅ Pollinations           chiave valida
  ✅ GitHub Models          chiave valida
  🔴 AgentRouter            chiave ASSENTE nel portachiavi
  🔴 OpenCode Zen           chiave RIFIUTATA (403)
  🔴 Aion Labs              chiave RIFIUTATA (403)
  🔴 Api.Airforce           chiave RIFIUTATA (403)
  ✅ BazaarLink             chiave valida
  🔴 CLōD                   chiave RIFIUTATA (403)
  🔴 NavyAI                 chiave RIFIUTATA (403)
  ✅ OrcaRouter             chiave valida
  ✅ NaraRouter             chiave valida
  ✅ Routeway               chiave valida
  🔴 Septor Labs            chiave RIFIUTATA (403)
  ✅ Typhoon                chiave valida
  ✅ Token Harbor           chiave valida
  🔴 TeamoRouter            chiave ASSENTE nel portachiavi
  ✅ UnoRouter              chiave valida
  ✅ Plugsky                chiave valida
  ✅ SimpleLLM              chiave valida
  ✅ LLMTR                  chiave valida
  ✅ Router9                chiave valida
  ✅ Waterfall              chiave valida
  ✅ BlazeAPI               chiave valida
  ✅ Logfare                chiave valida
  ✅ Lucidity               chiave valida
  ✅ FreeAI                 chiave valida
  ✅ Speka                  chiave valida
  🔴 Nscale                 chiave RIFIUTATA (401)
  ✅ Chutes                 chiave valida
  🔴 OVH                    chiave RIFIUTATA (403)
  ✅ SeaLION                chiave valida
  — AI Horde (senza chiave) senza chiave (keyless, salto)
  — Pollinations (senza chiave) senza chiave (keyless, salto)
  ✅ LLM7                   chiave valida
  ✅ LongCat                chiave valida
  ✅ Ollama Cloud           chiave valida
  ✅ Requesty               chiave valida
  ✅ Zhipu                  chiave valida
  ✅ ElectronHub            chiave valida
  ✅ Inferbase              chiave valida
  ✅ BlockRun               chiave valida
  ✅ Sail                   chiave valida
  ✅ AnyAPI                 chiave valida
  — Kilo (senza chiave)    senza chiave (keyless, salto)
  🟡 Cloudflare Workers AI  risponde 405 (endpoint diverso?)
  ✅ Agnes AI               chiave valida
  🔴 xKiro                  chiave RIFIUTATA (403)
  🔴 DreamPrompting         chiave RIFIUTATA (403)
  🔴 Gizmo                  chiave RIFIUTATA (403)
  🟡 Speechify              risponde 404 (endpoint diverso?)
  ✅ Jina AI                chiave valida
  🟡 Qdrant Cloud           risponde 404 (endpoint diverso?)
  🔴 fal.ai                 chiave ASSENTE nel portachiavi
  🔴 WaveSpeedAI            chiave RIFIUTATA (401)
  🔴 Moondream              chiave RIFIUTATA (403)
  — Pollinations (immagini, senza chiave) senza chiave (keyless, salto)

### 6. Glass-box: ultime righe del log
{"tipo": "banale", "agente": "cervello-2de5c12e398bc6e0", "rotta": "locale", "ms": 0, "quando": "2026-10-31 09:58:24"}
{"tipo": "bloccato", "agente": "cervello-2de5c12e398bc6e0", "modello": "gpt-5", "rotta": "guardia", "quando": "2026-10-31 09:58:24"}

<!-- fine collaudo_fase1 -->
