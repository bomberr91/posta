# Risposta a «squadra_nonverdi»

_03/11/2026 17:05 · FilippoPC_

=== MISURA (chat vera su piu' modelli) ===
==============================================================================
== anyapi (AnyAPI) base=https://api.anyapi.ai/v1 modello-nostro=nvidia/nemotron-3.5-lightning:free chiave=SI
-- /models -> 200
-- modelli totali: 10 · con 'free': 8
-- candidati provati: nvidia/nemotron-3.5-lightning:free, google/gemma-4-26b-a4b-it:free, nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free, nvidia/nemotron-3-ultra-550b-a55b:free, dots-studio/dots-3-note-preview:free, recursive/flint-v1.0:free, xingchen-agi/xing4.0-29b-a4b:free, respan/span-01-lite:free
   nvidia/nemotron-3.5-lightning:free             HTTP 429  {"error":{"message":"Rate limit reached: free-tier daily cap is shared across users. Switch to a paid model for best per
   google/gemma-4-26b-a4b-it:free                 HTTP 429  {"error":{"message":"Rate limit reached: free-tier daily cap is shared across users. Switch to a paid model for best per
   nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free HTTP 429  {"error":{"message":"Rate limit reached: free-tier daily cap is shared across users. Switch to a paid model for best per
   nvidia/nemotron-3-ultra-550b-a55b:free         HTTP 429  {"error":{"message":"Rate limit reached: free-tier daily cap is shared across users. Switch to a paid model for best per
   dots-studio/dots-3-note-preview:free           HTTP 429  {"error":{"message":"Rate limit reached: free-tier daily cap is shared across users. Switch to a paid model for best per
   recursive/flint-v1.0:free                      HTTP 429  {"error":{"message":"Rate limit reached: free-tier daily cap is shared across users. Switch to a paid model for best per
   xingchen-agi/xing4.0-29b-a4b:free              HTTP 429  {"error":{"message":"Rate limit reached: free-tier daily cap is shared across users. Switch to a paid model for best per
   respan/span-01-lite:free                       HTTP 404  {"error":{"message":"This model answers only /v1/decisions and /v1/systemone.","type":"endpoint_not_available","param":"

==============================================================================
== gizmo (Gizmo) base=https://api.gizmoplatforms.com/api/v1 modello-nostro=nvidia/nemotron-3.5-lightning:free chiave=SI
-- /models -> 200
-- modelli totali: 204 · con 'free': 3
-- candidati provati: nvidia/nemotron-3.5-lightning:free, nvidia/nemotron-3-ultra-550b-a55b:free, xingchen-agi/xing4.0-29b-a4b:free, z-ai/glm-5.3-flashx-legal, openai/gpt-6.1-sol-pro, z-ai/glm-5.3-flash:batch, qwen/qwen3.5-35b-a3b
   nvidia/nemotron-3.5-lightning:free             HTTP 429  {"error":{"message":"Every provider for nvidia/nemotron-3.5-lightning:free failed: openrouter 429 (HTTP 429). Nothing wa
   nvidia/nemotron-3-ultra-550b-a55b:free         HTTP 429  {"error":{"message":"Every provider for nvidia/nemotron-3-ultra-550b-a55b:free failed: openrouter 429 (HTTP 429). Nothin
   >>> xingchen-agi/xing4.0-29b-a4b:free              HTTP 200  '1.  **Analyze the Input:** The user said "Say OK". This is a very simple, open-e'
   z-ai/glm-5.3-flashx-legal                      HTTP 402  {"error":{"message":"Add a payment method to use paid models with your API key. Free models (IDs ending in :free) work w
   openai/gpt-6.1-sol-pro                         HTTP 402  {"error":{"message":"Add a payment method to use paid models with your API key. Free models (IDs ending in :free) work w
   z-ai/glm-5.3-flash:batch                       HTTP 402  {"error":{"message":"Add a payment method to use paid models with your API key. Free models (IDs ending in :free) work w
   qwen/qwen3.5-35b-a3b                           HTTP 402  {"error":{"message":"Add a payment method to use paid models with your API key. Free models (IDs ending in :free) work w

==============================================================================
== typhoon (Typhoon) base=https://api.opentyphoon.ai/v1 modello-nostro=typhoon-v2.5-30b-a3b-instruct chiave=SI
-- /models -> 200
-- modelli totali: 7 · con 'free': 0
-- candidati provati: typhoon-v2.5-30b-a3b-instruct, typhoon-ocr-v1.5, typhoon-ocr, typhoon-ocr-preview
   >>> typhoon-v2.5-30b-a3b-instruct                  HTTP 200  'OK'
   typhoon-ocr-v1.5                               HTTP 0  ERR The read operation timed out
   typhoon-ocr                                    HTTP 0  ERR The read operation timed out
   >>> typhoon-ocr-preview                            HTTP 200  '{"natural_text": "OK"}'


=== AGENTI IN PARALLELO (max 18 minuti) ===

=== REFERTO anyapi ===
(l'agente non ha scritto fatti/rel_anyapi.md — ultime righe del suo output)
[91m[1mError: [0mUnexpected error

locking protocol
(agente anyapi non riuscito)


=== REFERTO gizmo ===
(l'agente non ha scritto fatti/rel_gizmo.md — ultime righe del suo output)
[91m[1mError: [0mUnexpected error

locking protocol
(agente gizmo non riuscito)


=== REFERTO typhoon ===
# Relazione su Typhoon

## 1. Differenza tra "elenco modelli" e "chat vera"

L'**elenco modelli** (endpoint `/models`) verifica la disponibilità dei modelli sull'API, mentre la **chat vera** (endpoint `/chat/completions`) testa l'effettiva capacità di generare risposte. Il 2/11, l'elenco modelli di Typhoon non rispondeva (non 200), ma la chat vera con `typhoon-v2.5-30b-a3b-instruct` funzionava. Questo perché l'endpoint `/models` potrebbe essere temporaneamente inaccessibile per manutenzione o overload, mentre l'endpoint chat remained operativo. Ora il roster usa la chat vera per verificare la disponibilità, garantendo maggiore affidabilità.

## 2. Verifica di altri modelli gratuiti e limiti

Testati i modelli gratuiti di Typhoon:
- **typhoon-ocr-preview**: Risposta ricevuta (output: `{"natural_text": "ตราด"}`).
- **typhoon-v2.5-30b-a3b-instruct**: Risposta ricevuta (output: "Hello! How can I assist you today? 😊").

L'endpoint `/models` elenca 7 modelli, ma nessuno è contrassegnato come gratuito. Tuttavia, `typhoon-v2.5-30b-a3b-instruct` e `typhoon-ocr-preview` hanno risposto senza errori di quota. **Limiti non specificati** dall'API; si consiglia monitoraggio per evitare rate limit.

## 3. Idoneità per la riserva del Portiere

Typhoon è **pronto per entrare nella riserva del Portiere come chat di scorta** con il modello **`typhoon-v2.5-30b-a3b-instruct`**. La sua stabilità e la capacità di gestire richieste chat lo rendono adatto come backup affidabile.
=== FINE SQUADRA ===

<!-- fine squadra_nonverdi -->
