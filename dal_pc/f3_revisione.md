[0m
> build · auto
[0m
**MODULO 1 — compressione.py**

**Errori rilevati:**

1. **`taglia_storia` non protegge l'ultimo messaggio utente**  
   **Bug:** La funzione protegge solo gli ultimi 4 messaggi, ma se l'ultimo messaggio utente è prima di questi, viene tagliato.  
   **Casi non gestiti:** Se la storia termina con messaggi non-utente, l'ultimo messaggio utente (anche se non tra gli ultimi 4) viene riassunto.  
   **Correzione:** Identificare esplicitamente l'ultimo messaggio utente e aggiungerlo ai protetti.

2. **Test `taglia_storia` verifica male i system message**  
   **Errore di test:** Controlla solo se "system" è presente nel content, non se il messaggio originale è preservato.  
   **Correzione:** Verificare che il primo messaggio abbia ancora content=`keep`.

3. **`json_a_toon` fallisce su liste vuote di dizionari**  
   **Caso non gestito:** Se `oggetto` è una lista vuota di dizionari, genera un'intestazione senza righe.  
   **Nota:** Non critico per le specifiche, ma incoerente con "tabella".

**Verdetto: BOCCIATO**

**Correzione per `taglia_storia`:**
```python
def taglia_storia(messaggi, max_caratteri):
    nuovi = [{'role': m['role'], 'content': m['content']} for m in messaggi]
    totale = sum(len(m['content']) for m in nuovi)
    if totale <= max_caratteri:
        return nuovi
    
    # Trova indici protetti: system, ultimi 4, ULTIMO USER
    system_indices = {i for i, m in enumerate(messaggi) if m['role'] == 'system'}
    ultimi_quattro = set(range(max(0, len(messaggi)-4), len(messaggi)))
    
    ultimo_utente = None
    for i in reversed(range(len(messaggi))):
        if messaggi[i]['role'] == 'user':
            ultimo_utente = i
            break
    protetti = system_indices.copy()
    if ultimo_utente is not None:
        protetti.add(ultimo_utente)
    protetti.update(ultimi_quattro)
    
    da_tagliare = [i for i in range(len(messaggi)) if i not in protetti]
    da_tagliare.sort()
    
    for i in da_tagliare:
        msg = messaggi[i]
        if totale <= max_caratteri:
            break
        originale = len(msg['content'])
        nuovi[i]['content'] = f"[tagliato: {msg['role']}, {originale} caratteri]"
        totale -= originale - len(nuovi[i]['content'])
    
    return nuovi
```

**Correzione test `taglia_storia`:**
```python
# Test taglia_storia
storia_lunga = [{'role': 'user', 'content': 'a' * 200} for _ in range(30)]
storia_lunga[0] = {'role': 'system', 'content': 'keep'}  # System da preservare
storia_lunga[-1] = {'role': 'assistant', 'content': 'ultimo'}  # Ultimo non-user
storia_cort = taglia_storia(storia_lunga, 4000)

# Verifiche corrette
assert storia_cort[0]['content'] == 'keep', "System modificato"
ultimo_user = next(i for i, m in enumerate(storia_lunga) if m['role'] == 'user' and i > 0)
assert storia_cort[ultimo_user]['content'].startswith('[tagliato:') is False, "Ultimo user tagliato"
assert sum(len(m['content']) for m in storia_cort) < 4000, "Totale >=4000"
```

---

**MODULO 2 — per_agente.py**

**Errori rilevati:**

**Nessun errore critico.**  
- `carica_profili` gestisce correttamente file mancanti/rotti.  
- `applica_profilo` rispetta le specifiche di override (es. non sovrascrive `max_tokens` se payload è già più basso).  
- Test verificano casi limite (file mancante, JSON corrotto, priorità payload).

**Verdetto: PROMOSSO**
