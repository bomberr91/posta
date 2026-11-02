# Chiavi: quadro ordinato (2/11, sera)

Numero autorevole: **l'appello dal PC**. Ultimo giro completo+parziale: 14:33.
Esito: **42 chat verdi su 62** (i 6 non-chat escono dall'appello) — stamattina erano 32.
Aggiornamento sera: **Nscale è risolto** (era fra i "nessuna chiave"), verificato dal PC
→ al prossimo giro l'appello dovrebbe salire a **43/62**. Le tre chiavi (TeamoRouter,
fal.ai, Nscale) sono ora **intere nel vault del PC**: backup `~/CHIAVI_LOCALI.md.bak-20261102-151516`. TeamoRouter e fal.ai hanno la chiave valida
ma non possono fare chat (motivi in A).

**Chiusi oggi:** Aion Labs (era il mio estrattore: tagliava la chiave all'underscore) ·
AgentRouter (chiave troncata nel vault + strada sbagliata: ora va su `/v1/messages`
in stile Anthropic, con `x-api-key`, UA da Claude CLI e domanda **in inglese**) ·
AnyAPI · Typhoon · Gizmo · Token Harbor · BlockRun (nomi-modello nuovi, verificati con
chat vera) · Zhipu (glm-4.6v-flash) · i 6 non-chat esclusi dall'appello ma tenuti in
lista per il cervello.

## A. I 21 che NON rispondono — con la causa e la decisione

| # | Provider | Esito dal PC | Causa vera | Cosa serve |
|---|---|---|---|---|
| 1 | AgentRouter | nessuna chiave | la chiave **è** nel mio vault (riga 33) ma il PC non la trova → i due vault non coincidono | 1 comando sul PC per vedere se la riga c'è |
| 2 | TeamoRouter | **crediti esauriti** | chiave **valida** (catalogo 200, 71 modelli) ma la chat risponde 400 «Your TeamoRouter wallet balance is insufficient» → **non ricaricare** (niente carte) | niente: si usa quando avrà crediti gratis |
| 3 | fal.ai | **account bloccato** | chiave **valida** (401 con chiave falsa, 200 col catalogo) ma la generazione dice 403 «User is locked. Reason: TOP_UP» → chiedono la carta | niente: provider solo media, e le immagini le fa già Pollinations |
| 4 | ~~Nscale~~ | **risponde** | **risolto il 2/11 sera e CONFERMATO dal PC** (`fatti/prova_nscale.sh`: catalogo 200 con 26 modelli, chat 200 in 0,35 s → "OK"); token JWT da 1207 caratteri nel vault, base `https://inference.api.nscale.com/v1`, 401 con token fasullo | — |
| 5 | Jina AI | 404 | OCR/reranker: non è un provider di chat | **togliere dalla lista** |
| 6 | Speechify | 404 | text-to-speech | **togliere dalla lista** |
| 7 | WaveSpeedAI | 404 | immagini/video | **togliere dalla lista** |
| 8 | Moondream | 404 | visione | **togliere dalla lista** |
| 9 | ~~Aion Labs~~ | **risponde** | la chiave era buona: **era il mio estrattore** che tagliava la chiave all'underscore (`alv2_…_yQ058` → 401). Risolto il 2/11: ora risponde (`aion-labs/aion-3.5`) | — |
| 10 | Waterfall | chiave rifiutata | **chiave morta**: "Unknown or revoked API key" su tutti e 20 i modelli gratis (il suo /models è pubblico, per questo sembrava vivo e su freellmapi resta verde) | **ti serve una chiave nuova** (modello `auto` + 10 id gratis già in lista). In cima nei SOSPESI: controllo quotidiano |
| 11 | NavyAI | modello `navy-auto` inesistente | free tier **pausato da loro** + nome modello sbagliato | **togliere dalla lista** |
| 12 | LongCat | `Unsupported model (auto)` | nome modello sbagliato + quota esaurita | **togliere dalla lista** |
| 13 | NaraRouter | model not found | id del modello sbagliato (402/429) | riprovare col catalogo |
| 14 | UnoRouter | occupato (429) | quota/free finita **adesso** | si riprende da solo |
| 15 | Chutes | occupato | quota | si riprende da solo |
| 16 | HuggingFace Router | occupato | quota | si riprende da solo |
| 17 | OpenCode Zen | occupato | free usage limit via API (dentro OpenCode funziona) | si riprende da solo |
| 18 | Api.Airforce | occupato | quota | si riprende da solo |
| 19 | Google AI Studio | occupato | quota | si riprende da solo |
| 20 | AI Horde | modello senza worker | il roster cambia ogni ora: serve un id con worker online | si riprende col roster |
| 21 | Zhipu | **risponde** (glm-4.6v-flash) | era quota, è rientrato alle 13:33 | — |

## B. I 42 che rispondono, raggruppati per modello che funziona

| Modello/rotta che risponde | Provider |
|---|---|
| `nvidia/nemotron-3-ultra-550b-a55b` | NVIDIA · Speka · Requesty |
| `nvidia/nemotron-3.5-lightning:free` | Gizmo · AnyAPI |
| `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning` | BlockRun |
| `qwen/qwen3.8-27b` (e varianti free) | Groq · LLMTR · Cloudflare (`@cf/qwen/…`) |
| `deepseek-v4-flash` | Token Harbor · Router9 · Logfare (`auto`) · BazaarLink |
| `typhoon-v2.5-30b-a3b-instruct` | Typhoon |
| `minimax` free | Lucidity · Septor Labs |
| `openai-fast` | Pollinations (con e senza chiave) · Kilo · OpenRouter · dots-studio |
| `gemma` / `gemma4` | Routeway (`muse-glimmer-30b:free`) · Ollama Cloud (`gemma4:31b-cloud`) · CLōD |
| `qwen/qwen3.8-max:free` | xKiro |
| Mistral / ministral | Mistral · SimpleLLM · OrcaRouter · Inferbase |
| altri | Groq-compatible, Cohere, Agnie AI, DreamPrompting, FreeAI, SeaLION, BlazeAPI, Sail, LLM7, ElectronHub, Zhipu |
| **indirizzo valido ma NON chat** | Qdrant Cloud · Pollinations (immagini) → **togliere dalla lista della chat** |

## C. Le decisioni (per chiudere)

1. ~~Togliere i non-chat~~ **NON si tolgono**: restano nella lista con il loro `tipo`
   (immagini · video · voce · embedding · visione · db) e il cervello li usa quando
   un agente chiede qualcosa in quel dominio (`cervello.py: immagini()`, `scopri()`).
   Sono solo **esclusi dall'appello** (dal 2/11 l'appello non li interroga più:
   prima dicevano "404" e sembravano guasti)
2. ~~Togliere Aion Labs~~ **risolto**: la chiave era buona, era l'estrattore che la
   tagliava. Ora Aion risponde
3. **Waterfall**: la chiave è stata **revocata** → serve una chiave nuova
4. **NavyAI e LongCat**: il free tier è in pausa / la quota è esaurita → propose di
   toglierli per ora (si possono rimettere quando tornano)
5. ~~TeamoRouter: serve la chiave intera~~ **fatto**: la chiave è nel vault, ma il
   wallet è vuoto → resta in lista, non ricaricare
6. ~~AgentRouter: capire perché il PC non la trova~~ **fatto**: il vault PC aveva la
   chiave **troncata** → sostituita con l'intera
7. Gli **8 "occupato"** e **AI Horde** non richiedono nulla: la sentinella li riprova
   ogni 6 ore e l'appello li riprova a ogni giro
