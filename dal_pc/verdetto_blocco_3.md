# VERDETTO BLOCCO 3 (idee 34-48)
- motore: opencode(cervello/auto) [riserva]
- fine: Fri Oct 30 18:30:17 CET 2026

### Idea 34 - Internalizzare parco keyless OmniRoute
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S  **RISCHIO**: basso
- **MOTIVO**: Riduce anelli, aumenta robustezza. Copia diretta dei provider senza chiave (Pollinations, LongCat, ecc.) nel cervello.

### Idea 35 - Gemini CLI via OAuth (180K req/mese)
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S  **RISCHIO**: basso
- **MOTIVO**: Modello grosso gratis con autenticazione esistente. Nessun costo aggiuntivo.

### Idea 36 - Auto-scoperta modelli (arbstr)
- **VERDETTO**: DECIDE-IL-CAPO
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: medio
- **MOTIVO**: Automatizza /v1/models ma richiede igiene risposte (no leak errori/chiavi).

### Idea 37 - Shadow/Mirror (future-agi)
- **VERDETTO**: PARCHEGGIO
- **FASE**: CACCIA
- **SFORZO**: L  **RISCHIO**: alto
- **MOTIVO**: Doppia spesa token per controllo qualità. **CONDIZIONE-SBLOCCO**: risparmi > costo.

### Idea 38 - ToolPolicy per chiave (future-agi)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: medio
- **MOTIVO**: Controllo granulare tool per agente (es. "solo grep per OpenClaw").

### Idea 39 - Tassonomia gratis (freellmpool)
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S  **RISCHIO**: basso
- **MOTIVO**: Struttura portachiavi in free-ricorrente/keyless/trial/disabilitato.

### Idea 40 - Nuove prede caccia (freellmpool)
- **VERDETTO**: SICURA (CACCIA)
- **FASE**: CACCIA
- **SFORZO**: S  **RISCHIO**: basso
- **MOTIVO**: LLM7, Aion Labs, SiliconFlow, HF router free tier. **CACCIA TOKEN**.

### Idea 41 - freellmpool come riserva (alternativa OmniRoute)
- **VERDETTO**: DECIDE-IL-CAPO
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: medio
- **MOTIVO**: Ridondanza vs. manutenzione doppia. Valutare con il capo.

### Idea 42 - RTK compression (9Router)
- **VERDETTO**: PARCHEGGIO
- **FASE**: F3
- **SFORZO**: L  **RISCHIO**: alto
- **MOTIVO**: -20/40% token input. **CONDIZIONE-SBLOCCO**: verificare se OmniRoute lo fa già (idea 64).

### Idea 43 - Contatori quota con countdown (9Router)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: medio
- **MOTIVO**: Spreme ogni quota prima del reset (5h/giorno/settimana).

### Idea 44 - Multi-account round-robin (9Router)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: medio
- **MOTIVO**: Ruota account per provider + scalata a quota esaurita.

### Idea 45 - Combo personalizzate (9Router)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: medio
- **MOTIVO**: Catene Abbonamento->Economico->Gratis componibili (estende modelli-politica).

### Idea 46 - Intercetta richieste banali (free-claude-code)
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S  **RISCHIO**: basso
- **MOTIVO**: Risparmia quota/latenza su 5 categorie (es. "estrai filepath").

### Idea 47 - Parser tool-call euristico (free-claude-code)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: medio
- **MOTIVO**: Converte tool call testuali in strutturate (regola 5 violata? No: euristico).

### Idea 48 - Rate limit furbo (free-claude-code)
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M  **RISCHIO**: medio
- **MOTIVO**: Finestra scorrevole + backoff esponenziale su 429.

---

**Tabella Riassuntiva | n | verdetto | fase**  
| 34-48 | SICURA (12) | PARCHEGGIO (2) | DECIDE-IL-CAPO (2) |  
| F1 (5) | F2 (8) | F3/CACCIA (2) |  

**Conteggi Verdetti**:  
- SICURA: 12  
- DECIDE-IL-CAPO: 2  
- PARCHEGGIO: 2  
- SCARTO: 0
