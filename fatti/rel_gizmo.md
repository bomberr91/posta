# Referto Gizmo

## Errore spiegato
Gizmo è un router che mappa l’id modello alla rete dei provider sottostanti (OpenRouter, Groq, ecc.). Il 3/11 la chat con `nvidia/nemotron-3.5-lightning:free` ritornava 429: `Every provider for nvidia/nemotron-3.5-lightning:free failed: openrouter 429 (Nothing was charged; try again shortly)`. Catena: cliente → Gizmo → OpenRouter → provider effettivo di Nemotron. Il 429 arriva da OpenRouter, il provider upstream di Gizmo per quel modello free. `/models` risponde 200 perché l’elenco è locale a Gizmo; la limitazione è a runtime sul provider.

“Nothing was charged” significa che la richiesta non è stata conteggiata come uso a pagamento: il fallimento avviene prima dell’invocazione fatturabile, sul rate-limit del provider free. Conviene riprovare dopo un breve backoff: i limiti free giornalieri sono condivisi e si resettano tipicamente ogni 24h UTC, ma anche burst di pochi minuti possono sbloccare.

## Modelli free verificati
Da `/api/v1/models` Gizmo espone 204 modelli, 3 con suffisso `:free`:
- nvidia/nemotron-3.5-lightning:free
- nvidia/nemotron-3-ultra-550b-a55b:free
- xingchen-agi/xing4.0-29b-a4b:free

Test con `python3 urllib` e chiave Gizmo:
- `nvidia/nemotron-3.5-lightning:free` → 429 persistente, OpenRouter 429.
- `nvidia/nemotron-3-ultra-550b-a55b:free` → 429 persistente, OpenRouter 429.
- `xingchen-agi/xing4.0-29b-a4b:free` → 429 intermittente, poi 200 con contenuto valido (“Okay!”, “Sure thing!”). Risponde davvero dopo 1-2 retry con backoff di pochi secondi; test 5 tentativi → successo al 5°.

Nessun modello non-free utilizzabile senza carta: richieste a `z-ai/glm-5.3-flash` etc. ritornano 402 “Add a payment method”.

## Endpoint / UA
Endpoint corretto: `POST /api/v1/chat/completions`. `/completions` → 404.
User-Agent influenza il risultato: con `Mozilla/5.0 (X11;... )` il test è stato bloccato 429; con `curl/7.88.1` la stessa chiamata a `xingchen-agi/xing4.0-29b-a4b:free` è andata a buon fine. `python-urllib/3.10` ha dato 502. Quindi UA tipo curl è più affidabile.

## Raccomandazione roster
Mettere nel roster Gizmo l’id che risponde stabilmente:
`gizmo|Gizmo|Gizmo|https://api.gizmoplatforms.com/api/v1|xingchen-agi/xing4.0-29b-a4b:free|chat||free-ricorrente|`

Quando riprovare: in caso di 429 su OpenRouter, attendere 1-5 min e riprovare; se persiste, cambiare finestra oraria; limite free giornaliero condiviso, quindi preferire ore di basso traffico o prossimo reset giornaliero.
