# VERDETTO BLOCCO 1 (idee 1-16)
- motore: opencode(cervello/auto) [riserva]
- fine: Fri Oct 30 18:28:12 CET 2026

### Idea 1 - COMPRESSIONE TOON dei risultati JSON dei tool
- **VERDETTO**: SICURA
- **FASE**: F3
- **SFORZO**: L  **RISCHIO**: basso
- **MOTIVO**: Riduce i token di output (es. 3458→427) senza cambiare la risposta. Si implementa come post-elaborazione in `cervello.py`, allineato al risparmio token (regola 11). Nessun costo o dipendenza esterna (regola 1).

### Idea 2 - SPOGLIATURA SCHEMI TOOL (via schemi inutili per richieste di sola lettura)
- **VERDETTO**: SICURA
- **FASE**: F3
- **SFORZO**: L  **RISCHIO**: basso
- **MOTIVO**: Rimuove metadati non necessari dai tool_calls, risparmiando token (regola 11). Modifica contenuta in `cervello.py`, nessun impatto esterno (regola 2).

### Idea 3 - CACHE SEMANTICA locale (embedding locali, domanda simile → risposta in 171ms, 0 token)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: basso
- **MOTIVO**: Risparmia token e tempo per domande ripetute (regola 11). Usa embedding locali (no API esterne, regola 1). Richiede codice di similarità in `cervello.py`.

### Idea 4 - TIER ROUTING con sessioni appiccicose (facile→gratis, sale di livello solo se serve)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: basso
- **MOTIVO**: Ottimizza il costo routando prima ai tier gratis (regola 11). Logica interna a `cervello.py`, nessun endpoint esposto (regola 6).

### Idea 5 - PAGELLA PROVIDER (salute/(prezzo)^2, castigo 30-120s, retry su 5xx/429/408)
- **VERDETTO**: DECIDE-IL-CAPO
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: medio
- **MOTIVO**: Introduce logica di scoring e retry. Richiede tuning parametri (regola 5: euristica accettabile). Verificare impatto su provider gratuiti (regola 1).

### Idea 6 - MODELLI-POLITICA ("auto"/"cheap"/"fast"/"free" → regole di scelta interne)
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S  **RISCHIO**: basso
- **MOTIVO**: Alias interni a `cervello.py` (es. "cheap" → modello gratis, regola 11). Nessun costo o dipendenza (regole 1-2). Patch minima.

### Idea 7 - BILANCIAMENTO MULTI-CHIAVE (scelta pesata tra chiavi dello stesso provider)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: basso
- **MOTIVO**: Ruota chiavi dello stesso provider (regola 3). Codice in `cervello.py`, nessun endpoint esposto (regola 6).

### Idea 8 - CHIAVI VIRTUALI CON BUDGET (chiavi finte per-agente con tetto richieste/spesa)
- **VERDETTO**: DECIDE-IL-CAPO
- **FASE**: F3
- **SFORZO**: L  **RISCHIO**: alto
- **MOTIVO**: Richiede contatori per-agente e permessi (regola 8: complesso in Python puro). Verificare fattibilità senza DB esterni.

### Idea 9 - CIRCUIT BREAKER (provider escluso dopo N fallimenti, fino a guarigione)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: basso
- **MOTIVO**: Migliora affidabilità (regola 11). Logica interna a `cervello.py`, nessun costo (regola 1).

### Idea 10 - HOT-RELOAD (ricarica `portiere_lista.txt` senza riavvio)
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S  **RISCHIO**: basso
- **MOTIVO**: Funzionalità locale, nessun impatto esterno (regole 2-6). Patch semplice.

### Idea 11 - PUNTEGGIO COMPLESSITA' per "auto" (prompt corto→gratis, lungo→tier migliore)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: basso
- **MOTIVO**: Risparmia token routando prompt semplici ai tier gratis (regola 11). Euristica accettabile (regola 5).

### Idea 12 - ROTAZIONE CHIAVI A QUOTA ESAURITA (chiave gemella fino a mezzanotte)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: basso
- **MOTIVO**: Evita interruzioni su provider gratuiti (regola 12 esistente). Logica interna, nessun costo (regola 1).

### Idea 13 - POLITICHE PER-AGENTE dichiarative (JSON "retry 3, fallback X, cache on")
- **VERDETTO**: DECIDE-IL-CAPO
- **FASE**: F3
- **SFORZO**: L  **RISCHIO**: alto
- **MOTIVO**: Richiede parser JSON e logica complessa per-agente (regola 8: fattibile in Python?). Verificare overhead.

### Idea 14 - PESI PER CANALE + DISABILITAZIONE AUTOMATICA (conferma idea 7-8)
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S  **RISCHIO**: basso
- **MOTIVO**: Semplice sistema di weighting e disabilitazione (regola 11). Nessun costo o rischio (regole 1-6).

### Idea 15 - PAGELLA PER SINGOLA CHIAVE (salute a finestra per chiave, 401/403 → lista nera)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: basso
- **MOTIVO**: Migliora affidabilità chiavi (regola 11). Logica interna, nessun endpoint esposto (regola 6).

### Idea 16 - SCOPE PER CHIAVE-AGENTE (agenti limitati a modelli/quota specifici)
- **VERDETTO**: DECIDE-IL-CAPO
- **FASE**: F3
- **SFORZO**: L  **RISCHIO**: alto
- **MOTIVO**: Richiede sistema permessi granulare (regola 8: complesso in Python puro). Valutare priorità vs sforzo.

---

**TABELLA RIASSUNTIVA**
| n | verdetto        | fase |
|---|-----------------|------|
| 1 | SICURA          | F3   |
| 2 | SICURA          | F3   |
| 3 | SICURA          | F2   |
| 4 | SICURA          | F2   |
| 5 | DECIDE-IL-CAPO  | F2   |
| 6 | SICURA          | F1   |
| 7 | SICURA          | F2   |
| 8 | DECIDE-IL-CAPO  | F3   |
| 9 | SICURA          | F2   |
|10 | SICURA          | F1   |
|11 | SICURA          | F2   |
|12 | SICURA          | F2   |
|13 | DECIDE-IL-CAPO  | F3   |
|14 | SICURA          | F1   |
|15 | SICURA          | F2   |
|16 | DECIDE-IL-CAPO  | F3   |

**CONTEGGI**:
- SICURA: 11
- DECIDE-IL-CAPO: 3
- PARCHEGGIO: 0
- SCARTO: 0
