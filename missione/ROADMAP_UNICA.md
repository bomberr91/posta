# Roadmap unica — Hub Centrale e agenti

**Stato:** scaletta operativa canonica, riordinata il 28/10/2026 a partire dalla decisione più recente del 27/10 e dai piani storici pertinenti.  
**Obiettivo:** una sola piattaforma locale, a costo zero, in cui gli agenti usano il gateway dell’Hub; l’Hub non avvia né orchestra i processi degli agenti.  
**Repo applicativa principale:** `bomberr91/posta` (Centrale e gateway). `bomberr91/free-llm-hub` resta fonte/anteprima di elementi UI, non una seconda architettura da mantenere in parallelo.

> Questo file è l’unica coda attiva. Gli altri documenti restano intatti come fonti, registro storico o specifiche; non si devono riaprire le loro vecchie liste come lavori aggiuntivi. La decisione del 27/10 prevale sulle proposte precedenti incompatibili. Questa roadmap ordina il lavoro, ma non autorizza da sola chiamate live, spese, accessi remoti o modifiche distruttive.

## 0. Regole non negoziabili

1. **Costo zero:** solo provider/modelli con gratuità verificata e autorizzati; niente carte, trial a rischio addebito, abbonamenti o crediti a pagamento.
2. **Chiavi upstream:** restano nel portachiavi locale dell’Hub; mai nel repository, nella chat, nei log o nelle mani degli agenti. Ogni agente riceve solo un token del gateway con permessi limitati e revocabili.
3. **Agenti → Hub:** l’Hub offre API OpenAI-compatibili; non lancia agenti locali e non diventa il loro process manager.
4. **Richiesta esplicita:** non sostituire in silenzio un modello scelto dall’utente o dall’agente. Il fallback automatico appartiene solo a `auto` o a una regola esplicitamente autorizzata.
5. **Niente sonda LLM per richiesta:** catalogo e salute vengono riusati/cacheati; la richiesta valida produce una sola chiamata effettiva, senza ping preventivo.
6. **Sicurezza prima dell’accessibilità:** nessun endpoint sulla LAN o su Internet senza autenticazione, autorizzazioni e configurazione esplicita. Nessun prompt salvato nei log per default.
7. **Agenti manuali e supervisionati:** niente autostart, gateway permanenti o automazioni browser/GUI non approvate. Un agente scrive alla volta; azioni rischiose richiedono conferma.
8. **Procedura di rilascio:** audit del codice reale → mock e test offline → anteprima workspace → revisione dell’utente → solo allora commit/push. Il repo locale non si resetta alla cieca.
9. **Vincolo temporale registrato:** non interrogare le quote LLMTR prima del 30/10/2026; dopo quella data resta necessaria l’autorizzazione e la verifica di costo zero.

## 1. Stato e prossima consegna

- **UI già aggiornata in `free-llm-hub/main`** (commit `bbc524f`): rimane Focus; rimossi Approfondisci e il relativo flusso, insieme alle altre modifiche già presenti nella preview.
- **Centrale `posta/main`**: il flusso Approfondisci è stato rimosso con commit `a77a5e6`.
- **Badge fisso in basso “ANTEPRIMA (dimostrativa)…”**: rimosso da `posta/gui/hub.html` (commit `3633470`) e verificato assente anche nella bundle standalone che `g` avvia (bundle upstream `bbc524f`, aggiornata e pin corretta nel commit `004359d`). Restano le indicazioni di anteprima dentro le risposte demo/mock.
- Su `posta/main` sono pubblicati i lavori S0–S3 e le correzioni mirate S4: `fda9825` (suite offline + router/token) e `3633470` (badge). Il test dell’utente dopo 8→g ha mostrato UI invariata: causa trovata nel routing, perché `/` del server Centrale reindirizza alla UI separata `~/free-llm-hub` su :3000, mentre il vecchio menu 8 aggiornava solo `~/posta`. Il test personale ha identificato la causa precisa: `g` avviava `apri_free_llm_hub.sh`, che fissava la copia incorporata `posta/free-llm-hub` al vecchio commit `1277fef`, quindi non usava l’UI aggiornata. Pubblicato `004359d`: aggiornata la bundle incorporata al commit upstream `bbc524f`, aggiornato il pin/verificatore di avvio e rimosso dal menu 8 il tentativo fuorviante di aggiornare un checkout separato.
- **Correzione importante emersa dall’audit successivo del 28/10:** la verifica dell’utente (8→g mostra `bbc524f`) provava il bundle giusto, ma non l’integrazione con il Router Hub. La UI attiva incorporata conteneva ancora FreeLLMAPI :31415, il campo/lettura della sua chiave e codice di risposte demo; i 29 test offline verificavano il backend, non il collegamento dashboard→Hub. FreeLLMAPI è stato scartato e OmniRoute non è il router primario: questi elementi non vanno ripristinati.
- **Candidato non pubblicato: estensione minima per Agent Gateway, non sostituisce la dashboard utente.** La preview `POSTA_ROUTER_HUB_PREVIEW.html` e la patch `POSTA_ROUTER_HUB_UI.patch` provengono da `posta-router-hub-ui-2026-10-28.1`; l’utente ha chiarito il 28/10 che la dashboard storica completa deve restare quella principale e che cronologia, squadre/fusion, Focus, allegati/ricerca e il lavoro esistente non vanno rimpiazzati. La UI minima è adatta solo come possibile estensione separata per gli agenti; non è stata applicata o pubblicata. La patch attuale sovrascrive la pagina principale e quindi non è approvata per il rilascio così com’è. Non pubblicare; prima convertirla in pagina/estensione separata e intervenire solo sulle impostazioni della dashboard storica, dopo audit delle dipendenze e salvaguardia delle funzioni.
- Test del candidato (non equivalente all’accettazione della dashboard): suite Python **30/30**, test Node **7/7**, smoke del launcher su porte isolate; catalogo vuoto → chat 403 prima di qualsiasi provider. Nessuna chiamata live. Questi risultati valgono per il client minimale Agent Gateway, non per la dashboard storica.

## 2. Ordine per impegno — dagli scaglioni leggeri ai più pesanti

Le dimensioni indicano complessità relativa, non una promessa di durata. Ogni turno prende **un solo risultato verificabile**, chiude con test e aggiorna questa roadmap; niente sessioni-monolite.

| Scaglione | Peso | Lavori | Criterio di chiusura |
|---|---|---|---|
| **S0** | Minimo, documenti/statico | Consolidare fonti e link; rimuovere badge dimostrativo; controlli sintassi e riferimenti; inventario read-only di UI/API | Diff piccolo, link e syntax check verdi; zero chiamate esterne |
| **S1** | Leggero, UI locale | Rimuovere dal selettore chat prima “Libero” e gli agenti locali; eliminare le relative mappature/controlli; poi rimuovere il contatore aggregato e impostare Router Hub come motore primario | Anteprima locale; Focus e catalogo/router restano; nessun comando agente parte dalla chat |
| **S2** | Medio, test mock | Definire test per autenticazione, modelli consentiti, esplicito/auto, fallback, revoca, errore e cooldown | Suite offline ripetibile, senza provider o chiavi |
| **S3** | Medio-alto, API/router | Correggere soltanto le lacune reali di `/v1/models`, `/v1/chat/completions`, catalogo/capacità e compatibilità; adapter e back-off | Contratto API verificato con mock e nessun fallback silenzioso |
| **S4** | Alto, sicurezza/configurazione | Token per agente, scope/revoca, portachiavi locale, configurazione guidata e logging sicuro | Revisione del confine rete; nessun segreto in UI/log/repo |
| **S5** | Alto, integrazione agenti | Standalone uno alla volta, poi collegamento di un agente al gateway, infine handoff/collaborazione controllata | Prova innocua e autorizzazioni chiare; scritture serializzate |
| **S6** | Esteso, funzioni di prodotto | Ricerca/fonti, file, storage, stima token, RAG, fusion avanzate, export e diagnostica | Modulo isolato, limiti/costi verificati, test dedicati |
| **S7** | Molto esteso/opzionale | Media/video, tool/MCP aggiuntivi, skills, altri agenti, vista remota/Vercel | Nuova priorità approvata; architettura, licenza, costo e sicurezza verificati prima di iniziare |

### Modalità di lavoro a sessioni brevi

1. **Un obiettivo per turno**; per UI/API tenere il diff piccolo e non mescolare refactor.
2. Aprire con stato e prossima azione da questa scaletta; chiudere con esito, file toccati, test e prossimo micro-passo.
3. Se un test fallisce, fermarsi e ripristinare solo il proprio diff, senza reset globali o sovrascritture.
4. Prima mock/statici; chiamate esterne solo se strettamente necessarie, autorizzate e gratuite. Eccezione esplicita del 28/10: una sola credenziale OpenCode Zen su modello gratuito verificato, usata solo per smoke test e revisioni read-only; nessun'altra chiave del portachiavi usata e nessuna chiave upstream dell'Hub condivisa.
5. Le attività parallele sono solo analisi indipendenti senza scritture concorrenti; una sola modifica alla volta.
6. Quando serve un team sandbox: usare OpenCode headless installato in `/tmp/ocbin` (mai nel workspace) e workdir separati in `/tmp`. Per compiti leggeri: 2 revisori read-only in parallelo; per modifiche sostanziali: fino a 3 revisori indipendenti e un coordinatore/giudice che verifica e fonde. Al massimo un writer dedicato. Goose documenta un limite tecnico di 10 subagent, non un obiettivo operativo. Prima fare una delega smoke-test con modello gratuito verificato: il catalogo del 15–16/10 è storico e la disponibilità ruota.
7. Per non perdere lavoro, ogni agente scrive checkpoint/risultati a file e conclude con marker verificabile; il supervisore può rilanciare un task caduto, ma ha tentativi limitati e non rende gli agenti permanenti tra reset della sandbox. `/tmp` sparisce tra i turni: salvare nel workspace solo report/checkpoint piccoli.
8. Prima di usare `supervisore_agente.sh` va corretto il default del log (`LOGNAME` è una variabile d’ambiente, non il nome del file log) e va verificato un timeout per i task bloccati; non fidarsi della ricetta storica senza test.

### Stato — S0–S3 pubblicati; correzioni mirate S4 pubblicate; test browser personale pendente

- ✅ S0: riconosciuto `HUB_CENTRALE.md` del 27/10 come fonte delle decisioni più recenti; rimandi e roadmap consolidati; badge fisso rimosso e pubblicato su `posta/main` (commit `3633470`); 8 script inline controllati con `node --check`.
- ✅ Mappati gli handler: `refreshModelSelect()` costruisce il menu; `sel.onchange` persiste il modello; la chat usa `/api/chat`. Il vecchio ramo UI→agente è stato rimosso da `hub.html`; non resta una chiamata chat a `/api/agente` o `/api/agente/stop`.
- ✅ S1: `PROVIDERS` espone solo Router Hub come provider chat, con `auto:smart` predefinito e `auto:fast`, `tailor`, `vision`, `docs`, `code`, `trading`; rimosse dal selettore le voci locali/Libero, i mapping-pilota, il launcher e le finte risposte mock relative. Le selezioni obsolete salvate ricadono sul Router Hub. Rimosso il contatore grafico aggregato; preservati `bumpUsage()` interno, `/api/contabilita` nella vista capacità, Focus, squadre e snippet/configurazione `/v1`. Nel `server.py` pubblicato, le route legacy `/api/agente` e `/api/agente/stop` sono disabilitate in fail-closed; nessun avvio CLI dall’Hub.
- ✅ S1 verificato e presente su `posta/main`: test statico di accettazione, harness Node del selettore (default, alias e migrazione legacy), route agenti legacy disabilitate. Nessuna chiamata ai provider Hub. La prova browser dinamica resta affidata al tuo test dopo 8 → g.
- ✅ Sei revisioni OpenCode read-only (in coppie parallele) e uno smoke test hanno usato una sola credenziale OpenCode Zen su modello gratuito verificato; tutti i processi sono terminati. Per S2 i due brief erano minimizzati e senza roster. Nessun segreto upstream dell’Hub è stato passato. Nota privacy: nella sessione precedente erano state inviate copie ampie contenenti etichette hardcoded di modelli/provider e i report ne hanno riprodotte alcune; non è stato inviato `CHIAVI_LOCALI.md` né valori di chiavi Hub. Mantenere per il futuro solo brief/estratti redatti.
- ✅ Confine architetturale: `GET /v1/models` e `POST /v1/chat/completions` richiedono Bearer token e sono distinti dal vecchio `/api/agente`; footer/snippet `/v1` restano intatti. La contabilità browser interna è distinta da `/api/contabilita`.
- ✅ S4 mirato (28/10), pubblicato in `fda9825`: bind su loopback (già presente su `main`), `/api/agente-token` verifica peer loopback, authority locale e Origin HTTP coerente, inclusa normalizzazione IPv4-mapped. L’accesso effettivo dalla GUI del PC resta da provare.
- ✅ Suite offline pubblicata: 29 test, senza provider e senza portachiavi; copre allowlist, esplicito/auto, retry, autenticazione/revoca e token endpoint con peer/Host/Origin contraffatti. Tutti passano.
- ✅ Hardening auth incluso in S2: `agente_autorizzato()` ora accetta un solo token Bearer (schema case-insensitive, whitespace controllato, compare constant-time); `token_agente()` chiude il file dopo la lettura.
- ✅ S3 pubblicato in `fda9825`: `_candidati()` e `candidati_agente()` selezionano un solo ID esplicito; sconosciuto/ambiguo non espande. `chat_riposta()` e `chat_stream()` consentono retry solo con alias automatici espliciti.
- ✅ Correzioni S4 pubblicate in `fda9825`: `/api/agente-token` rifiuta peer remoti, Host non locale e Origin esterne/mismatch; nessun token reale né provider usati. I due revisori read-only avevano evidenziato spoof Host e indirizzi mapped, coperti dai controlli e dai test.
- ➡️ Prossimo passo: dopo il tuo aggiornamento 8 e apertura g, raccogliere esito del test browser locale (pagina, caricamento, chiamata innocua al token endpoint). Non usare provider live né abilitare LAN; correggere eventuali incompatibilità risultanti.

### Conteggio avanzamento

- **Roadmap completa non opzionale:** S0–S6 = 7 scaglioni. S0–S3 chiusi; **4/7 completati, 3 ancora aperti** (S4–S6). Le correzioni mirate di esposizione S4 sono pubblicate, ma la verifica browser locale è pendente.
- **Obiettivo core “client agenti → gateway Hub”:** dopo S3 restano **2 scaglioni** (S4–S5); dentro S5 serve solo la verifica standalone necessaria e l’integrazione controllata di almeno un agente al gateway, non costruire un orchestratore Hub→agenti.
- **S6** amplia il prodotto (RAG, storage, export e diagnostica) e non è prerequisito per il gateway core; **S7 è un ulteriore scaglione opzionale/non approvato**.
- I sotto-piani A–J non si sommano al conteggio: sono dettagli interni. Non calcolare una percentuale lineare: gli scaglioni hanno pesi molto diversi e S3–S5 possono richiedere più micro-passi ciascuno.

## 3. Sequenza unica di lavoro

### Fase A — Baseline, confini e sicurezza

1. Confrontare lo stato reale di `posta` con la specifica del 27/10; classificare ogni componente come presente e verificato, presente ma da testare, mancante o da rimuovere.
2. Verificare l’accesso all’API: autenticazione, token dedicati, scope per agente/modello, revoca, gestione Origin/CSRF e risposte agli accessi non autorizzati.
3. Verificare il confine di rete: preferire bind locale; se serve accesso LAN/remoto, fermarsi finché non esiste una scelta esplicita e un disegno sicuro.
4. Controllare che log e statistiche non contengano chiavi, prompt o dati personali; per default registrare solo metadati tecnici.

**Uscita:** inventario affidabile e rischi bloccanti risolti o esplicitamente accettati; nessuna chiamata a provider necessaria.

### Fase B — Contratto API e router proprio

1. Verificare `GET /v1/models`: ID non ambigui (`provider/modello` o equivalente), solo modelli consentiti, metadati di compatibilità disponibili.
2. Verificare `POST /v1/chat/completions`: modello esplicito, `auto`, errori, streaming e tool calling supportati dichiarati correttamente.
3. Per modello esplicito, rispettare la scelta o restituire l’errore; per `auto`, consentire fallback tracciato e spiegabile.
4. Niente chiamata di salute prima di ogni richiesta. Aggiornare stato/cooldown usando gli esiti reali e cache; applicare `Retry-After` e back-off con limiti documentati.
5. Il router proprio dell’Hub chiama direttamente i provider autorizzati con le chiavi locali. OmniRoute può essere una sorgente OpenAI-compatibile opzionale, solo dopo verifica; non è il router obbligatorio né il custode delle chiavi.

**Uscita:** test mock per modello esplicito, `auto`, fallback, modello vietato/non disponibile, 401/403, 402/429, timeout e revoca. Nessuna chiamata reale finché non autorizzata e a costo zero verificato.

### Fase C — Catalogo, provider e portachiavi locale

1. Rendere il catalogo dinamico, non hardcoded: provider, ID canonico e alias, modalità supportate, contesto, costo/condizione free verificata e compatibilità (`stream`, tool calling, immagini/JSON se effettivamente supportati).
2. Mantenere adapter separati per provider e un adapter OpenAI-compatible per i provider standard; registrare i “quirks” e gli errori noti per evitare regressioni.
3. Cache del catalogo con data/TTL e aggiornamento manuale; deduplicare per provider+ID e distinguere chiaramente modelli diretti da eventuali sorgenti OmniRoute.
4. Portachiavi locale: aggiunta e test **su richiesta esplicita dell’utente**, stato/salute, quota e reset solo quando documentati; nessuna scansione o raffica automatica di sonde.
5. Budget e quote per chiave/provider solo dai limiti verificati. Rilevare 402/429 e cooldown; non presentare stime o un aggregato come “uso reale” se la fonte non lo prova.
6. Eventuale import/export di configurazione e backup cifrato solo in locale, con permessi stretti; mai esportare segreti nel repository o al gateway agente.

**Uscita:** catalogo coerente con le risposte reali e prove offline dei parser; una prova live per volta solo su autorizzazione.

### Fase D — Pulizia e guida dell’interfaccia

1. Togliere dal selettore chat agenti locali, alias e promesse che li fanno sembrare lanciabili dall’Hub; eliminare “Libero — parla di tutto” e relative mappature.
2. Nel pannello Motori presentare **Router dell’Hub** come primario. OmniRoute, se verificato, compare come sorgente opzionale.
3. Rimuovere il contatore grafico ambiguo “Uso reale del router dell’hub”; preservare il router e il catalogo. Una futura vista d’uso può mostrare soltanto dati verificabili per agente/provider/modello.
4. Mantenere le funzioni chat già utili: ricerca web e fonti, allegati, cronologia, streaming/Stop, fusion, riassunto e mosse. **Focus** è l’unico tasto di controverifica; niente duplicato Approfondisci.
5. Rimuovere nel prossimo aggiornamento della Centrale il badge fisso di anteprima in basso (già rimosso nel file workspace). Non eliminare le indicazioni necessarie a distinguere una demo mock da una funzione live.
6. Aggiungere una configurazione guidata per l’agente: endpoint, token dedicato, modelli disponibili e snippet copiabile, senza mostrare chiavi upstream.
7. Nelle risposte mostrare modello/provider effettivo e motivo del fallback; non simulare stato operativo o disponibilità.

**Uscita:** anteprima workspace verificata con l’utente; nessun comando agente deve partire dalla GUI dell’Hub.

### Fase E — Preparare gli agenti, uno alla volta

Completare prima il funzionamento standalone secondo `PIANO_AGENTI_STANDALONE_GITHUB_COLLAB_HUB.md`:

1. Avvio manuale, versione registrata, niente autostart indesiderato; provider/modello gratuiti e compatibili; prova innocua di Internet e file; workspace e permessi verificati.
2. Usare la radice comune `C:\Users\giopi\Documents\AgentWorkspace`, con cartelle per progetto e `STATO.md` (obiettivo, decisioni, file, avanzamento, prossima azione). Un solo agente scrive alla volta; non spostare vecchie cartelle senza richiesta.
3. Ordine operativo registrato: completare la verifica post-riavvio di Hermes al prossimo riavvio ordinario; non cambiare Goose già completato; poi Secondhand/Open Interpreter, Antigravity e OpenClaw secondo i rispettivi controlli e permessi.
4. **OpenCode:** configurazione standalone già verificata, ma per scelta dell’utente niente accesso GitHub, comandi sul PC o task di modifica codice.
5. GitHub: autorizzazioni per repository specifici e privilegi minimi; prima read-only su repo non critica. Scrittura/PR solo dopo approvazione esplicita.
6. Skills: inventariare prima quelle native/esistenti; installare solo skills pertinenti, ufficiali/verificate e gratuite, una alla volta. Browser, GUI e subagenti restano disabilitati finché non sono valutati.

**Uscita:** checklist standalone completata per l’agente coinvolto; nessun avvio o test massivo.

### Fase F — Collegamento agenti → Hub e collaborazione

1. Configurare un token separato per agente, limitato ai modelli/azioni necessari, revocabile senza ruotare le chiavi upstream.
2. L’agente interroga `/v1/models` e usa `/v1/chat/completions`; non riceve le chiavi del provider.
3. Iniziare con una prova read-only e mock; poi un task innocuo su repo di prova, con approvazioni/log visibili.
4. Solo dopo le prove singole: definire ruoli (regista, ricerca, esecuzione, verifica), formato del task, handoff, cartella di scambio e log. Vietate scritture concorrenti; nessuna operazione distruttiva senza conferma.
5. La scansione dedicata del PC è una fase successiva, read-only e mirata, riutilizzando l’inventario già presente invece di rifare scansioni generali.

**Uscita:** un agente alla volta passa le prove di accesso e autorizzazione; nessun tunnel o endpoint pubblico automatico.

### Fase G — Osservabilità e capacità

1. Stato e salute per provider/modello basati su risposte reali e cache, con timestamp; distinguere “chiave valida” da “chat effettivamente riuscita”.
2. Metriche tecniche essenziali: richieste, esiti, latenza, token quando restituiti, cooldown e motivo del fallback; aggregazione per agente/provider/modello senza prompt o segreti.
3. Capacità giornaliera/mensile per chiave solo dove i limiti sono verificati; separare limiti dichiarati da misure osservate e stime. Niente valore inventato se una fonte è offline.
4. Log essenziale e consultabile; retention limitata. Nessun contatore aggregato confuso con il numero di agenti o con l’effettiva raggiungibilità.

### Fase H — Ricerca, file e memoria (dopo il gateway)

1. Ricerca web attiva di default con fonti consultabili; se il motore fallisce, la chat prosegue se possibile e segnala che non ha verificato online.
2. Parser locale per allegati e PDF; dichiarare limiti per scansioni/immagini e dimensione. Conservare cronologia/config in storage locale affidabile.
3. RAG come estensione separata: pipeline file → loader → embeddings → vector store; Jina/Qdrant sono candidati storici, da riutilizzare solo dopo verifica di gratuità, limiti e privacy.
4. Stima token leggera; compression/context hand-off per chat lunghe dopo il nucleo; export/import chat, copilots/preset e command palette come rifiniture successive.
5. OpenAI-compatible è la prima superficie. Anthropic-style, Gemini-style e MCP sono compatibilità di fase successiva, solo quando esistono casi d’uso e test dedicati.

### Fase I — Moduli media e video (traccia separata, differita)

1. Conservare l’idea storica del modulo video: contatore dei minuti disponibili, scadenza delle quote, fonti, coda e libreria delle clip con fonte/prompt/durata.
2. Ripartire da zero sui numeri del piano 16/10: quote/provider/crediti e date sono snapshot storici, non dati attuali. Includere solo servizi gratuiti verificati, niente carte o crediti pagati.
3. Flow senza API resta manuale-assistito finché non è verificata un’automazione autorizzata; nessun controllo browser automatizzato per aggirare limiti.
4. Immagini, audio/STT, trascrizione e montaggio PyAV/ffmpeg restano moduli separati, con licenze, costo, requisiti hardware e limiti dichiarati.

**Uscita:** avviare questa traccia solo dopo una decisione di priorità, fonti e capacità gratuite correnti.

### Fase J — Accesso remoto e deploy (non blocca il locale)

1. La Centrale locale resta la modalità primaria. La vecchia decisione Vercel non autorizza a trasferire il portachiavi locale nel cloud.
2. Vercel può restare specchio/read-only; un gateway remoto richiede nuova decisione su dove risiedono le chiavi, autenticazione, rete, logging, costi e modello di minaccia.
3. Niente Cloudflare Tunnel, VPS pubblico o GitHub Actions che operano sul PC finché non sono scelti, configurati e autorizzati. Non assumere che `localhost` sia raggiungibile dal deploy.

## 3. Collaudo e criteri comuni di accettazione

- Mock offline per route, autorizzazioni, catalogo, fallback, back-off, modello esplicito/auto, streaming/tool calling e revoca.
- Verificare in modo esplicito che una richiesta non effettui ping LLM preventivi e che `model=...` non venga sostituito in silenzio.
- Test di sicurezza: accesso senza token, token revocato, modello non permesso, Origin non valido, CSRF, prompt assenti dai log e nessuna chiave in output.
- Prove provider reali solo su richiesta, una alla volta e con costo zero verificato; nessun test live dal workspace se raggiunge il PC o consuma credito.
- Anteprima visibile prima del push. L’utente conferma l’aspetto e il comportamento; poi si applica solo il diff approvato.

## 4. Idee conservate ma non ancora approvate come lavori

| Idea storica | Stato in questa roadmap |
|---|---|
| Fusion multi-modello, giudice, riserve e diversità di modelli | Funzione da preservare; eventuali nuove strategie dopo il gateway e test mock. |
| Drag-and-drop della catena, budget per chiave, salute/cooldown, quirk per provider, import provider | Da adattare al router proprio; iniziare semplice e solo su dati verificati. |
| Forecast quote e grafici analytics | Solo quando esistono dati affidabili; non inventare quote o consumi. |
| RAG Jina/Qdrant, embeddings e memoria delle chat | Differiti; verificarne limiti e costo prima della scelta. |
| Video/immagini/audio/voce/trascrizione | Traccia media separata e differita; quote vecchie da riverificare. |
| CLIProxyAPI, codebase-memory-mcp, Windows-MCP, DesktopCommanderMCP | Candidati storici; nessun innesto automatico. Valutare uno per volta e solo dopo sicurezza/compatibilità. |
| Pi come agente aggiuntivo e skill BehiSecc/book-to-skill | Candidati non approvati; non installare finché non sono valutati costo, licenza e permessi. |
| Vercel/remote gateway | Fase J, scelta architetturale ancora da riconfermare; non mettere chiavi locali in cloud. |

## 6. Decisioni escluse o superate — non riaprire come attività

1. **Hub → agenti locali:** avvio, stop e selezione di agenti CLI dalla chat dell’Hub; direzione superata il 27/10. Gli agenti sono client del gateway.
2. **“Libero — parla di tutto” e alias:** esclusi perché la promessa non è vera e le policy del provider non si aggirano con un prompt.
3. **Contatore grafico “Uso reale del router dell’hub”:** escluso perché aggregato/ambiguo; non equivale a disponibilità o utilizzo reale. Non rimuovere per questo il router o i suoi contatori interni verificati.
4. **FreeLLMAPI come dipendenza obbligatoria o unico custode delle chiavi:** superato dalla decisione del 16/10 e confermato il 27/10. Resta fonte di studio/adapters e banco opzionale, con attribuzione MIT ove si riusi codice.
5. **OmniRoute/CLIProxyAPI come router obbligatorio:** non approvato; solo sorgenti opzionali dopo verifica.
6. **Sonda LLM prima di ogni richiesta** e fallback silenzioso su un modello esplicito: esclusi dal principio tecnico del 27/10.
7. **Premium, abbonamenti, prove con carta o crediti a pagamento** (compresi budget AgentRouter a pagamento): esclusi dal vincolo zero spesa.
8. **Vercel come gateway già approvato per custodire chiavi locali**, tunnel o VPS pubblico: la proposta Vercel del 16/10 è supersata/differita dal modello locale del 27/10; serve una nuova decisione per esporre segreti o endpoint.
9. **Autostart Windows, servizi permanenti, scansione generale immediata del PC, installazioni/azioni distruttive autonome:** esclusi dalle scelte operative successive; avvio manuale, controlli mirati, approvazioni.
10. **OpenCode con accesso GitHub, comandi PC o scrittura codice:** esplicitamente escluso dalla scelta corrente dell’utente.
11. **Provider/modelli o quote datati presentati come attuali:** esclusi; tutti i roster e limiti del 10–21/10 sono fotografie storiche. Un provider entra solo dopo verifica autorizzata e gratuita.
12. **Freely MAP, Poe, Strata e candidati “uncensored” come integrazioni già decise:** non sono scelte approvate; alcuni sono scartati, altri da valutare solo se l’utente li ripropone. Non diventano task automatici.

## 6. Fonti assorbite e regola di conservazione

- `HUB_CENTRALE.md`: decisioni più recenti del 27/10, direzione architetturale, pulizia GUI e scaletta agenti.
- `FREELLM_HUB.md`: implementazioni e prove storiche del router, decisioni 16–21/10, backlog e confini tra Hub/FreeLLMAPI/Chatbox.
- `FASE2_PIANO.md`, `TAPPA0_AUDIT.md`, `SPEC_caselle_e_tendina.md`: modello dati, portachiavi/catalogo, fallback, capacità, fusion, ricerca/memoria e video; le proposte incompatibili sono supersate o differite sopra.
- `PIANO_AGENTI_STANDALONE_GITHUB_COLLAB_HUB.md`: ordine di verifica degli agenti, workspace, permessi, GitHub, skills e collaborazione.
- `SCALETTA_OPERATIVA.md` e `AGENTI_H24.md`: riusate solo le regole e le idee ancora pertinenti a Hub/agenti; attività di altri cantieri restano nei loro documenti.

I documenti originali non si cancellano e non si riscrivono: servono come archivio e prova delle decisioni. Le nuove attività e i cambi di stato si aggiornano **solo qui**; se emerge una nuova decisione dell’utente, si aggiorna questa roadmap e si registra la data.
