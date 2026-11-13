# COSA FA

- **AgentMemory** è un layer di memoria persistente per agenti di coding che memorizza i dati in file Markdown locali. Include un diario di lavoro quotidiano e una lavagna per appunti. Può utilizzare qmd per la ricerca locale.

- **OpenDots** è un sistema che coordina agenti CLI, modelli cloud o locali Ollama, intorno a un obiettivo scelto dall'utente. Ascolta per informazioni in entrata, mantiene la cronologia delle attività e le note, e può verificare i progressi su una pianificazione configurabile. L'utente sceglie il progetto, le modifiche consentite, i controlli e le regole di approvazione.

- **FreeLLMAPI** aggrega i tier gratuiti di diversi provider, più endpoint personalizzati compatibili con OpenAI, dietro un singolo endpoint `/v1`. Le chiavi dei provider sono memorizzate crittografate. Un router seleziona il miglior modello disponibile per ogni richiesta, passa al provider successivo quando uno è limitato, e tiene traccia dell'uso per chiave in modo da rimanere sotto ogni limite gratuito.

# COME SI INTEGRA COL CERVELLO

- **AgentMemory** può essere integrato con il nostro ponte/ponte-arena e mem0, che già utilizziamo, per una memoria persistente e una ricerca locale. Potrebbe essere utile per memorizzare e recuperare informazioni rilevanti per le sessioni di coding.

- **OpenDots** potrebbe essere integrato con il nostro keeper+guardiani e battito nuovo per una pianificazione e un monitoraggio degli agenti. Potrebbe essere utile per gestire e coordinare le attività degli agenti in modo più efficiente.

- **FreeLLMAPI** potrebbe essere integrato con il nostro cervello+OmniRoute per una gestione unificata delle richieste a modelli di linguaggio. Potrebbe essere utile per aggregare e instradare le richieste a diversi provider di modelli di linguaggio.

# QUANTO RISPARMIA/COSTA

- **AgentMemory** è gratuito e non richiede un account, un servizio remoto, un flusso di pagamento o un runtime proprietario. Non ci sono costi associati all'uso di AgentMemory.

- **OpenDots** è gratuito e non richiede un account, un servizio remoto, un flusso di pagamento o un runtime proprietario. Non ci sono costi associati all'uso di OpenDots.

- **FreeLLMAPI** è gratuito e non richiede un account, un servizio remoto, un flusso di pagamento o un runtime proprietario. Non ci sono costi associati all'uso di FreeLLMAPI.

# RISCHI

- **AgentMemory** non ha rischi significativi. È un layer di memoria persistente per agenti di coding che memorizza i dati in file Markdown locali. Non ci sono rischi associati all'uso di AgentMemory.

- **OpenDots** non ha rischi significativi. È un sistema che coordina agenti CLI, modelli cloud o locali Ollama, intorno a un obiettivo scelto dall'utente. Non ci sono rischi associati all'uso di OpenDots.

- **FreeLLMAPI** non ha rischi significativi. Aggrega i tier gratuiti di diversi provider, più endpoint personalizzati compatibili con OpenAI, dietro un singolo endpoint `/v1`. Non ci sono rischi associati all'uso di FreeLLMAPI.

# RICETTA DI CASA

- **AgentMemory** può essere utilizzato per memorizzare e recuperare informazioni rilevanti per le sessioni di coding. Può essere integrato con il nostro ponte/ponte-arena e mem0, che già utilizziamo, per una memoria persistente e una ricerca locale.

- **OpenDots** può essere utilizzato per gestire e coordinare le attività degli agenti in modo più efficiente. Può essere integrato con il nostro keeper+guardiani e battito nuovo per una pianificazione e un monitoraggio degli agenti.

- **FreeLLMAPI** può essere utilizzato per aggregare e instradare le richieste a diversi provider di modelli di linguaggio. Può essere integrato con il nostro cervello+OmniRoute per una gestione unificata delle richieste a modelli di linguaggio.

