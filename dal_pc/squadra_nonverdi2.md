# Risposta a «squadra_nonverdi2»

_03/11/2026 17:51 · FilippoPC_

=== AGENTE anyapi (in sequenza) ===
(il referto c'e' gia')
# AnyAPI — referto (3/11/2026)

## L'errore 429

La chat risponde:

    429 free_tier_capacity
    "Rate limit reached: free-tier daily cap is shared across users.
     Switch to a paid model for best performance."

Non è un limite al minuto della singola chiave: è il tetto giornaliero del pool
gratuito, condiviso da tutti gli utenti free. I modelli gratuiti "normali"
attingono tutti allo stesso serbatoio; quando è esaurito, qualsiasi loro id dà
lo stesso 429 (header `x-should-retry: false`, nessun `Retry-After`).

La documentazione (FAQ e pricing) dice: piano Free = 100.000 AnyToken al giorno,
"reset every 24 hours", i token non usati non si accumulano. Non è pubblicato il
fuso esatto del reset: va trattato come ciclo giornaliero, non come quota che si
ricarica a ogni richiesta.

**Conviene riprovare?** Sì, ma con giudizio. Nei test lo stesso modello ha
alternato 429 e 200 nel giro di pochi minuti: 2-3 tentativi con attesa 2-5 s
possono passare. Se il 429 resta, inutile insistere: o si aspetta il reset
giornaliero, o si usa un altro provider in fallback.

## Modelli gratuiti che esistono davvero

Da `GET /v1/models` (e dal catalogo `catalogo_freellmapi.json`, sezione anyapi):

- `google/gemma-4-26b-a4b-it:free`
- `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free`
- `nvidia/nemotron-3-ultra-550b-a55b:free`
- `dots-studio/dots-3-note-preview:free`
- `nvidia/nemotron-3.5-lightning:free`
- `recursive/flint-v1.0:free`
- `xingchen-agi/xing4.0-29b-a4b:free`
- `respan/span-01-lite:free` (modo `decisions`, non chat)

I modelli free pubblicizzati sul sito (Qwen 3.8 27B, Ling 3.0, Gemma 3n) non
sono disponibili con questa chiave: 404 `model_not_found` o 403
`key_model_access_denied`. Contano solo gli id restituiti da `/models`.

## Esito delle prove (3/11)

- Tutti i sei modelli free "condivisi" (Gemma, i tre Nemotron, dots, flint):
  **429** sullo stesso tetto.
- `xingchen-agi/xing4.0-29b-a4b:free`: **200**, contenuto reale
  (`"ciao mondo"`), `cost: 0.0`, con header
  `x-ratelimit-team-remaining-tokens: 99999` / `...limit-tokens: 100000`.
  È l'unico con una quota "team" propria e visibile; resta comunque soggetto
  alla capacità condivisa e ogni tanto può dare 429.
- `respan/span-01-lite[:free]` e `convai/laya`: 404 su `/chat/completions`
  ("answers only /v1/decisions and /v1/systemone"). Non sono modelli da chat.

## Modello da mettere nel roster

Sostituire il primario `nvidia/nemotron-3.5-lightning:free` (sempre 429) con:

    xingchen-agi/xing4.0-29b-a4b:free

La riga del roster diventa:

    anyapi|AnyAPI|AnyAPI|https://api.anyapi.ai/v1|xingchen-agi/xing4.0-29b-a4b:free|chat||free-ricorrente|google/gemma-4-26b-a4b-it:free;nvidia/nemotron-3.5-lightning:free

Nota: è un modello "reasoning"; i token di ragionamento consumano la quota
giornaliera (una risposta breve può valere ~300 token). Tenere `max_tokens`
basso e i prompt corti.

## Si può evitare il tetto condiviso?

- `/v1/responses`: stesso 429; nessun vantaggio.
- Header speciali: non ne ho trovati; `x-should-retry: false` è informativo.
- Endpoint alternativi: `/v1/decisions` e `/v1/systemone` esistono per
  respan/convai, ma non sono chat e non aiutano.
- Modelli con quota propria: è la via osservata, cioè `xingchen`.
- Piano free separato: no; il pool gratuito resta condiviso. La garanzia si
  ottiene solo con un piano a pagamento (che toglie il tetto free) o con un
  provider diverso nel roster.

## Quando il tetto si esaurisce

1. Controllare `x-ratelimit-team-remaining-tokens` quando presente.
2. Ritentare 2-3 volte con backoff (2-5 s); se ancora 429, passare al fallback.
3. non fare retry aggressivi: peggiorano solo la congestione.
4. Aspettare il reset giornaliero (24 h) per la quota Free.
5. In produzione, tenere un provider non-AnyAPI come fallback.

=== AGENTE gizmo (in sequenza) ===
(nessun rel_gizmo.md — ultime righe)
[91m[1mError: [0mUnexpected error

locking protocol
(agente gizmo non riuscito)

=== FINE ===

<!-- fine squadra_nonverdi2 -->
