# VERDETTO BLOCCO 2 (idee 17-33)
- motore: opencode(cervello/auto) [riserva]
- fine: Fri Oct 30 18:28:59 CET 2026

### Idea 17 - Castigo per (chiave, modello)
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Isola i fallimenti a un modello specifico di una chiave, preservando il resto. Allineato alla regola 11 (risparmio token) e non stravolge il cervello.

### Idea 18 - Tassonomia errori
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Gestione euristica degli errori (es. 413 → modello più capiente) migliora l'affidabilità senza sonde LLM (regola 5 rispettata).

### Idea 19 - Corsa tra provider
- **VERDETTO**: DECIDE-IL-CAPO
- **FASE**: F2
- **SFORZO**: M **RISCHIO**: medio
- **MOTIVO**: Riduce latenza ma aggiunge complessità. Richiede collaudo (sandbox). **REGOLA VIOLATA**: Nessuna, ma rischio di instabilità.

### Idea 20 - Quote persistenti su disco
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Serializzazione leggera, sopravvive al riavvio (regola 8: Python puro).

### Idea 21 - Guardia solo-gratis
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Blocca modelli a pagamento (regola 1: costo zero). Critico per evitare addebiti accidentali.

### Idea 22 - Quota giornaliera finita → 1 ora
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Evita spam di retry (regola 11: rotazione chiavi).

### Idea 23 - Due motori keyless nuovi
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Kilo Gateway e OVHcloud AI sono GRATIS e senza chiave (regola 1). Aggiunta diretta alla riserva.

### Idea 24 - Strategie annidate
- **VERDETTO**: DECIDE-IL-CAPO
- **FASE**: F2
- **SFORZO**: M **RISCHIO**: medio
- **MOTIVO**: Potenzialmente utile ma richiede refactor del fallback. **REGOLA VIOLATA**: Nessuna, ma complessità da valutare.

### Idea 25 - Timeout per richiesta
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Taglia chiamate bloccate (regola 8: affidabilità).

### Idea 26 - Token-agente ricchi
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M **RISCHIO**: basso
- **MOTIVO**: Controllo granulare (regola 3: chiavi nel portachiavi). Allineato a idea 8 e 16.

### Idea 27 - Salute = tasso di successo
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Metrica più affidabile degli errori secchi (regola 11: rotazione provider).

### Idea 28 - Traduttore di formati
- **VERDETTO**: PARCHEGGIO
- **FASE**: -
- **SFORZO**: L **RISCHIO**: medio
- **MOTIVO**: Utile per compatibilità futura (es. Gemini CLI). **CONDIZIONE-SBLOCCO**: Richiesta esplicita di un agente o client.

### Idea 29 - Alias
- **VERDETTO**: PARCHEGGIO
- **FASE**: -
- **SFORZO**: L **RISCHIO**: basso
- **MOTIVO**: Per modelli locali (non nostro focus attuale). **CONDIZIONE-SBLOCCO**: Implementazione modelli locali.

### Idea 30 - Gruppi-fallback per nome
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M **RISCHIO**: basso
- **MOTIVO**: Risolve chiavi gemelle con eleganza (regola 11: rotazione).

### Idea 31 - Routing per consumo osservato
- **VERDETTO**: SICURA
- **FASE**: F2
- **SFORZO**: M **RISCHIO**: medio
- **MOTIVO**: Previene 429 su una chiave mentre l'altra è libera (regola 11).

### Idea 32 - Context_window_fallbacks
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Catena di riserva per "contesto troppo lungo" (regola 4: no sostituzione silenziosa).

### Idea 33 - Drop_params
- **VERDETTO**: SICURA
- **FASE**: F1
- **SFORZO**: S **RISCHIO**: basso
- **MOTIVO**: Scarta parametri non supportati (meglio di `riserva()` che strippa tutto).

---

**TABELLA RIASSUNTIVA**

| n | Verdetto       | Fase |
|---|----------------|------|
|17| SICURA         | F1   |
|18| SICURA         | F1   |
|19| DECIDE-IL-CAPO | F2   |
|20| SICURA         | F1   |
|21| SICURA         | F1   |
|22| SICURA         | F1   |
|23| SICURA         | F1   |
|24| DECIDE-IL-CAPO | F2   |
|25| SICURA         | F1   |
|26| SICURA         | F2   |
|27| SICURA         | F1   |
|28| PARCHEGGIO     | -    |
|29| PARCHEGGIO     | -    |
|30| SICURA         | F2   |
|31| SICURA         | F2   |
|32| SICURA         | F1   |
|33| SICURA         | F1   |

**CONTEGGI**:
- **SICURA**: 14 idee  
- **DECIDE-IL-CAPO**: 2 idee  
- **PARCHEGGIO**: 2 idee  

**NOTE FINALI**:  
- Idee 17, 18, 20-23, 25, 27, 30-33 pronte per F1/F2 (14 SICURA + 2 DECIDE).  
- Idee 28-29 parcheggiate per futuri use case.  
- Idea 19 (corsa provider) e 24 (strategie annidate) richiedono discussione col capo.  
- Aggiunta keyless (idea 23) e miglioramenti a pagella/castigo (idee 17,18,27) rafforzano F2.
