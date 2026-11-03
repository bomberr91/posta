# Risposta a «verifica_riavvio»

_03/11/2026 15:48 · FilippoPC_

Data: 03/11/2026 15:48:21
Acceso da: up 1 minute

## Attesa del boot (Gateway e motore sono lenti)
(attesa conclusa: motore=VIVO gateway=KO)

## Porte
- Gateway OpenClaw  18789 : KO
- Motore OmniRoute  20128 : VIVO
- Cervello portiere 20129 : VIVO
- Browser agenti    18800 : KO   (chiuso a riposo: normale)

## Guardiani
- scorta_posta.sh : 2
- scorta_cervello.sh : 1
- scorta_motore.sh : 1
- postino.sh --loop : 2
- omniroute : 3
- sonda LongCat : 1
- sveglia 19:00 : 1

## Sonda LongCat: ultimi 3 campioni
03/11 15:19 | 000 | {"error":{"code":"too_many_requests","message":"AppId:**QK9I Usage limit reached.","type":
03/11 15:30 | 000 | {"error":{"code":"too_many_requests","message":"AppId:**QK9I Usage limit reached.","type":
03/11 15:47 | 402 | {"error":{"code":"too_many_requests","message":"AppId:**QK9I Usage limit reached.","type":

## Portiere: ultime 2 richieste
{"tipo": "sentinella", "nota": "fonti quote aggiornate: FREE-LLM-API-Provider (push 2026-11-02) — ricontrollare portiere_quote.txt", "quando": "2026-11-02 23:18:14"}
{"tipo": "richiesta", "agente": "cervello-0ce8fd8054a79bcc", "politica": "migliore", "rotta": "motore-mappato", "modello": "auto/best-reasoning", "ms": 8148, "quando": "2026-11-02 23:18:19"}

## Motore (guardiano)
[INFO] [SQLITE_BACKEND] sqlite.backend.initialized
[INFO] [MEMORY_MANAGER] Initialized backend {"id":"sqlite"}
[STARTUP] Embedded services bootstrap complete
[ProxyRefusalMemory] module loaded more than once (duplicated bundle copy)
--- End recent output ---


## Postino
[03/11 15:18] ✓ risposta pronta in dal_pc/risolvi_ko_avvio.md
[03/11 15:19] → compito: togli_popup_e_riarma.sh (tentativo 1/3)
[03/11 15:20] ✓ risposta pronta in dal_pc/togli_popup_e_riarma.md
[03/11 15:23] → compito: risolvi_ko_avvio2.sh (tentativo 1/3)
[03/11 15:26] ✓ risposta pronta in dal_pc/risolvi_ko_avvio2.md
[03/11 15:35] → compito: verifica_riavvio.sh (tentativo 1/3)
[03/11 15:47] postino acceso · repo: bomberr91 · opencode: /home/agenti/.opencode/bin/opencode
[03/11 15:48] → compito: verifica_riavvio.sh (tentativo 2/3)

<!-- fine verifica_riavvio -->
