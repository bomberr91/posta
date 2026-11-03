# Risposta a «salute_cervello»

_03/11/2026 09:19 · FilippoPC_

## Cervello e portiere
- portiere 20129: RISPONDE {"ok": true, "nome": "Portiere", "porta": 20129, "f3": true, "provider": 59, "gruppi": 3, "regole": 0, "motore": true, "riserva": 5, "struttura": []}
- motore   20128: NON RISPONDE (HTTPError)

## Processi di guardia (guardiano, sentinella, scorer)
agenti    1026  1023  0 08:33 tty1     00:00:03 bash postino.sh --loop
agenti   27240  1026  0 09:19 tty1     00:00:00 bash postino.sh --loop

## Ultime 3 richieste nel portiere_log.jsonl
{"tipo": "cache", "agente": "cervello-0ce8fd8054a79bcc", "rotta": "cache", "ms": 0, "quando": "2026-11-02 22:06:48"}
{"tipo": "sentinella", "nota": "fonti quote aggiornate: FREE-LLM-API-Provider (push 2026-11-02) — ricontrollare portiere_quote.txt", "quando": "2026-11-02 23:18:14"}
{"tipo": "richiesta", "agente": "cervello-0ce8fd8054a79bcc", "politica": "migliore", "rotta": "motore-mappato", "modello": "auto/best-reasoning", "ms": 8148, "quando": "2026-11-02 23:18:19"}

## Browser isolato OpenClaw (CDP 18800)
- CDP 18800: non risponde (URLError) -> browser OpenClaw da riavviare

<!-- fine salute_cervello -->
