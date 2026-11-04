# Risposta a «deepdog_cervello_collaudo»

_04/11/2026 17:21 · FilippoPC_

### 1. .env del cane: serve CERVELLO_API_KEY (e' la chiave fissa del portone)
CERVELLO_API_KEY aggiunta al .env
28:CERVELLO_API_KEY=«chiave mascherata»
7:OPENROUTER_API_KEY=«chiave mascherata»

### 2. il cane e' vivo? (se e' gia' vivo NON apro un'altra finestra)
il cane e' gia' vivo: non avvio un'altra finestra
8765: APERTA

### 3. i processi Windows di Deep Dog (dal lato WSL ps non si vedono)
python.exe                   17600 Console                    2      4.268 K
python.exe                   16068 Console                    2    105.744 K

### 4. COLLAUDO REALE: una ricerca vera col wrapper (ora python3, non curl)
exit del wrapper: 1
cane vivo (porta 8765)
domanda: che modelli offre il cervello locale?
domanda mandata, aspetto il report (max 10 minuti)...
stato: failed
report: dal_pc/deepdog_reports/deepdog_ricerca_2026-11-04_17-21-16.md  (dal testo dello stato)
errore del cane: APIStatusError: Error code: 402 - This request requires more credits, or fewer max_tokens. You requested up to 32000 tokens, but can only afford 4447. To increase, visit https://openrouter.ai/settings/credits and upgrade to a paid account

--- estratto:
   (il cane non ha scritto un report)

il postino pubblica i report in dal_pc/deepdog_reports/ -> gli agenti li ritrovano nel repo

### 5. PROVA: la chiamata LLM e' passata dal cervello?
-- ultime righe del log del portiere (20129):
{"tipo": "richiesta", "agente": "cervello-168fedf2616d6d39", "politica": "auto", "rotta": "motore", "modello": "auto", "ms": 5550, "quando": "2026-11-04 16:21:49"}
{"tipo": "cache", "agente": "cervello-168fedf2616d6d39", "rotta": "cache", "ms": 0, "quando": "2026-11-04 16:22:38"}
{"tipo": "richiesta", "agente": "cervello-168fedf2616d6d39", "politica": "auto", "rotta": "motore", "modello": "auto", "ms": 6167, "quando": "2026-11-04 16:22:45"}
{"tipo": "richiesta", "agente": "cervello-168fedf2616d6d39", "politica": "auto", "rotta": "motore", "modello": "auto", "ms": 5571, "quando": "2026-11-04 16:27:57"}
-- stato del cane:
   status           failed
   error            APIStatusError: Error code: 402 - This request requires more credits, or fewer max_tokens. You requested up to 32000 tokens, but can only afford 4447. To increase, visit https://openrouter.ai/settings

### 6. verdetto
nessuna richiesta al cervello nel log (potrebbe essere gia' stata registrata prima): guarda /api/status qui sopra
FINE

<!-- fine deepdog_cervello_collaudo -->
