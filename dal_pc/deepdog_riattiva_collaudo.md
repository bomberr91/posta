# Risposta a «deepdog_riattiva_collaudo»

_04/11/2026 17:26 · FilippoPC_

### 1. stato attuale del cane (/api/status)
{"status": "failed", "message": "Ricerca terminata: failed", "report": "", "error": "APIStatusError: Error code: 402 - This request requires more credits, or fewer max_tokens. You requested up to 32000 tokens, but can only afford 4447. To increase, visit https://openrouter.ai/settings/credits and upgrade to a paid account", "events": ["Ricerca avviata", "Configurazione verificata", "Preparazione del piano di ricerca", "Ricerca non riuscita"], "elapsed_seconds": 1}

### 2. imposto il provider 'cervello' a runtime (/api/setup)
POST /api/setup FALLITO: HTTP Error 400: Bad Request {"error": "Opzione di setup non valida"}

### 3. stato dopo il setup
   status           failed
   error            APIStatusError: Error code: 402 - This request requires more credits, or fewer max_tokens. You requested up to 32000 tokens, but can only afford 4447. To increase, visit https://openrouter.ai/settings/credits and upgrade to a paid account

### 4. COLLAUDO REALE: una ricerca vera col wrapper
exit del wrapper: 1
cane vivo (porta 8765)
domanda: che modelli offre il cervello locale?
domanda mandata, aspetto il report (max 10 minuti)...
stato: failed
report: dal_pc/deepdog_reports/deepdog_ricerca_2026-11-04_17-26-38.md  (dal testo dello stato)
errore del cane: APIStatusError: Error code: 402 - This request requires more credits, or fewer max_tokens. You requested up to 32000 tokens, but can only afford 4447. To increase, visit https://openrouter.ai/settings/credits and upgrade to a paid account

--- estratto:
   (il cane non ha scritto un report)

il postino pubblica i report in dal_pc/deepdog_reports/ -> gli agenti li ritrovano nel repo

### 5. PROVA: la chiamata e' passata dal cervello (127.0.0.1:20129)?
-- ultime righe del log del portiere:
{"tipo": "richiesta", "agente": "cervello-168fedf2616d6d39", "politica": "auto", "rotta": "motore", "modello": "auto", "ms": 2020, "quando": "2026-11-04 16:21:43"}
{"tipo": "richiesta", "agente": "cervello-168fedf2616d6d39", "politica": "auto", "rotta": "motore", "modello": "auto", "ms": 5550, "quando": "2026-11-04 16:21:49"}
{"tipo": "cache", "agente": "cervello-168fedf2616d6d39", "rotta": "cache", "ms": 0, "quando": "2026-11-04 16:22:38"}
{"tipo": "richiesta", "agente": "cervello-168fedf2616d6d39", "politica": "auto", "rotta": "motore", "modello": "auto", "ms": 6167, "quando": "2026-11-04 16:22:45"}
{"tipo": "richiesta", "agente": "cervello-168fedf2616d6d39", "politica": "auto", "rotta": "motore", "modello": "auto", "ms": 5571, "quando": "2026-11-04 16:27:57"}
-- provider usato dal cane:
   model_provider: None
   status: failed | error: APIStatusError: Error code: 402 - This request requires more credits, or fewer max_tokens. You requested up to 32000 tokens, but can only afford 4447. To increase, visit https://openrouter.ai/settings/credits and upgrade to a paid account
FINE

<!-- fine deepdog_riattiva_collaudo -->
