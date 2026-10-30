# VERDETTO BLOCCO 4 (idee 49-64)
- motore: opencode(cervello/auto) [riserva]
- fine: Fri Oct 30 18:30:57 CET 2026

### Idea 49 - OrcaRouter Free Tier (Hacker)
- **VERDETTO**: CACCIA
- **FASE**: CACCIA
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Aggiunge modelli gratis (deepseek-v4-flash-free, deepseek-v4-pro-free) e alias `orcarouter/free` per routing automatico. Richiede solo registrazione (regola 1 ok).

### Idea 50 - Glass-Box Logging
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Log interni per debug (modello scelto, difficoltà stimata). Non richiede dipendenze esterne, si scrive in `cervello.py` (regola 2 ok).

### Idea 51 - 429 Intelligenti
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M **RISCHIO**: basso
- **MOTIVO**: Distingue 429 riprovabili vs. non riprovabili usando header `Retry-After`. Ottimizza retry (regola 5 ok).

### Idea 52 - Sonda Credenziali Gratis
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Verifica chiavi via `GET /v1/models` (costo 0 token). Rafforza sicurezza (regola 3 ok).

### Idea 53 - OrcaRouter Lite (Difficulty Scoring)
- **VERDETTO**: DECIDE-IL-CAPO
- **FASE**: -
- **SFORZO**: L **RISCHIO**: medio
- **MOTIVO**: Richiede SQLite e banda per training. Viola regola 8 (no Postgres/Redis?). **REGOLA VIOLATA**: 8.

### Idea 54 - IO Intelligence Free Tier
- **VERDETTO**: CACCIA
- **FASE**: CACCIA
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Modelli gratis (gemma-4-26b-a4b-it, nemotron-3.5-lightning). Verifica accesso reale (regola 1 ok).

### Idea 55 - Catalogo vs Accesso Reale
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M **RISCHIO**: basso
- **MOTIVO**: Sonda disponibilità modello prima del routing. Previene errori 402 (regola 4 ok).

### Idea 56 - Orchestrazione-come-Modello
- **VERDETTO**: PARCHEGGIO
- **FASE**: -
- **SFORZO**: L **RISCHIO**: alto
- **MOTIVO**: Richiede modelli locali non implementati. **CONDIZIONE-SBLOCCO**: Attivare modelli locali (idea 29).

### Idea 57 - Big Pickle OpenCode
- **VERDETTO**: CACCIA
- **FASE**: CACCIA
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Modello gratis 200K contesto (alias GLM). Usa account esistente (regola 1 ok).

### Idea 58 - Sessione Stabile
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Inoltra header `x-opencode-session` per caching. Compatibile con Lynkr (idea 4).

### Idea 59 - Atomic Chat (Locale)
- **VERDETTO**: PARCHEGGIO
- **FASE**: -
- **SFORZO**: L **RISCHIO**: medio
- **MOTIVO**: Per modelli locali futuri. **CONDIZIONE-SBLOCCO**: Attivare modelli locali (idea 29).

### Idea 60 - Pagella EWMA
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M **RISCHIO**: basso
- **MOTIVO**: Media mobile esponenziale per TTFT/TPS. Migliora pagella (idea 5).

### Idea 61 - Periodo di Grazia
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M **RISCHIO**: basso
- **MOTIVO**: Evita castighi iniziali per nuovi provider. Raffina castigo (idea 17).

### Idea 62 - Ollama Cloud Free
- **VERDETTO**: CACCIA
- **FASE**: CACCIA
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Modelli gratis (gpt-oss, nemotron-3-ultra). Verifica limiti (regola 1 ok).

### Idea 63 - Vercel AI Gateway
- **VERDETTO**: CACCIA
- **FASE**: CACCIA
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: $5/mese gratis per team. Usa account esistente (regola 1 ok).

### Idea 64 - Verifica OmniRoute
- **VERDETTO**: SICURA
- **FASE**: F3
- **SFORZO**: L **RISCHIO**: basso
- **MOTIVO**: Usa compressione RTK+Caveman esistente. Ottimizza token (idea 42).

---

**TABELLA RIASSUNTIVA**

| n | verdetto       | fase  |
|---|----------------|-------|
| 49| CACCIA         | CACCIA|
| 50| SICURA         | F1    |
| 51| SICURA         | F2    |
| 52| SICURA         | F1    |
| 53| DECIDE-IL-CAPO | -     |
| 54| CACCIA         | CACCIA|
| 55| SICURA         | F2    |
| 56| PARCHEGGIO     | -     |
| 57| CACCIA         | CACCIA|
| 58| SICURA         | F1    |
| 59| PARCHEGGIO     | -     |
| 60| SICURA         | F2    |
| 61| SICURA         | F2    |
| 62| CACCIA         | CACCIA|
| 63| CACCIA         | CACCIA|
| 64| SICURA         | F3    |

**CONTEGGIO VERDETTI**:
- SICURA: 9  
- DECIDE-IL-CAPO: 1  
- PARCHEGGIO: 2  
- CACCIA: 6  
- SCARTO: 0
