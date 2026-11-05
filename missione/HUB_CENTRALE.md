# 🧠 HUB CENTRALE — missione unica (Hub v2 + Agenti H24)
_Nata il 19/10/2026 dalla FUSIONE di `FREELLM_HUB` + `AGENTI_H24` (decisione utente: «sarà una cosa sola»). Le due cartelle originali vivono qui sotto, INTATTE: `./FREELLM_HUB/` e `./AGENTI_H24/`._

> **Scaletta operativa unica aggiornata il 28/10:** [`ROADMAP_UNICA.md`](ROADMAP_UNICA.md). Questo file conserva missione e decisioni; gli altri piani restano fonti storiche, non code di lavoro parallele.

## COS'È
**Una sola interfaccia** (GUI CENTRALE) che comanda tutto da una pagina web, senza terminale nero:
- **sede**: LOCALE su FilippoPC (`~/posta/gui/` → `http://localhost:20200`); versione Vercel in sola lettura = FASE 2
- **repo**: dentro `bomberr91/posta` (il ponte la porta sul PC da sola); `bomberr91/free-llm-hub` resta cava di pezzi UI
- **check-in AgentRouter**: all'apertura della pagina, browser agenti INVISIBILE → logout→login → +25$/gg → conferma → chiusura

## STATO AL 19/10 (v1 pushata, commit `00631b6`)
- ✅ Server stdlib `gui/server.py` (:20200) + `gui/index.html`: semafori OmniRoute/browser · saldo AgentRouter · check-in auto (headless, profilo `C:\AgentiH24\BrowserProfile`) · lancio Fusion con barra live da `stato_fusion.json` · lettura risultati `RISPOSTE_AGENTI/` · accendi/spegni OmniRoute · postino avviato in automatico
- ✅ Icona `8_CENTRALE_GUI.bat` (powershell hidden, NIENTE finestra nera) — copiata sul Desktop come `CENTRALE_GUI.bat` al prossimo `[8]` · tasto `[g]` nella Centrale testuale
- ✅ Motori sotto: OmniRoute 17 linee (10 noauth + groq/mistral/openrouter/gemini/cohere/nvidia/agentrouter) · FUSION 2.1 con Giudice Supremo a cascata (Opus5→Opus4.8→Sonnet→GPT5.6→DeepSeek via AgentRouter, harness EN) · check-in automatico agganciato anche al postino

## EREDITÀ DA NON PERDERE (dai due brief originali)
- **da FREELLM_HUB**: ricerca web + fonti come funzione centrale · endpoint OpenAI-compat per gli agenti · fusioni di modelli · UI ispirata a OpenMuse/LibreChat · 57 chiavi dirette senza limite 30gg (roster in CHIAVI_LOCALI §4) · FreeLLMAPI centralino locale (ora v0.16.3: decision models `/v1/decisions`, fix LLMTR) · Vercel 24/7 + GitHub Actions giri orari a PC spento (FASE 2) · Magpie group/free
- **da AGENTI_H24**: centrale.sh + ponte posta + BROWSER_AGENTI (:9222) · 28 skill · squadre/fusion · installer PC · ricerche canale10/forum/vaglio (in `./AGENTI_H24/`)

## ROADMAP
La coda storica è stata consolidata e riordinata nella **[Roadmap unica](ROADMAP_UNICA.md)**. CLIProxyAPI, MCP aggiuntivi, `pi`, skill e vista remota restano candidati differiti, non attività automatiche.

## REGOLE VIVE DELLA MISSIONE
- AgentRouter: solo missioni di pregio (giudice/review/debug) · richieste SOLO EN · niente raffiche · check-in quotidiano automatico
- free-llm-hub: discutere prima di toccare il codice (workflow utente storico)
- Qualità > tempo · costo 0 · niente carta

## 😈 SENZA FILTRI & PILOTI LIBERI (censimento 19/10)
- **DECISIONE UTENTE**: 😈 sempre attivo dietro le quinte (toggle tolto dall'interfaccia). FATTO nel motore vero: `GOD_IT` nei prompt dei membri squadra + sintesi, `GOD_EN` nell'harness del Giudice (push odierno su posta).
- **Verità tecnica**: GOD_SYS toglie prediche/rifiuti da zelo; i filtri DURI stanno nei server dei provider → si aggirano SOLO scegliendo piloti (modelli) più liberi. MAI jailbreak su AgentRouter (rischio account).
- **CENSIMENTO PILOTI LIBERI**:
  - ❌ OpenRouter `dolphin-mistral-24b-venice-edition:free` — NON più gratis (verificato LIVE 19/10 col nostro catalogo: nessun modello 'libero' ha più `:free`). A pagamento costa poco ($0.20/$0.90 per Mtok) ma regola = niente carta.
  - 🎯 **Venice.ai diretto** — tier FREE senza carta: ~10 prompt testo/giorno del modello Venice Uncensored (2,2% rifiuti vs 71% Claude). CANDIDATO REGISTRAZIONE (poca quota ma pilota perfetto per i soli argomenti scomodi).
  - 🧪 **Da sondare con 3 domande-prova via OmniRoute** (gratis, già innestati): Pollinations · Cloudflare AI · Mistral (notoriamente poco filtrato con system prompt) · NVIDIA NIM (modelli aperti, filtri = solo quelli del modello).
- **🏆 SONDA DEL 19/10 (3 prove: insulti noir / blackjack / scena cruda, GOD in testa)**:
  - **Cohere command-r: 3/3 🟢 LIBERO** — zero rifiuti, zero prediche → ELETTO PILOTA LIBERO PROVVISORIO (già nostra linea!)
  - Mistral: 429 persistente dal sandbox (quota del momento) → ritestare dal PC
  - NVIDIA: catalogo ruotato (404/410 sui nomi noti) → ritestare dal PC via OmniRoute
  - Pollinations: 1 risposta ottenuta = 🟢 libera, poi 402 dal sandbox → dal PC è keyless, ritestare lì
- **REGOLA REGISTA (aggiornata)**: argomento scomodo → il Regista passa la palla al pilota libero: OGGI Cohere command-r (3/3 alla sonda); quando ci sarà Venice.ai diventa lui il primo, Cohere riserva con GOD_SYS già attivo.

## 🗳️ TENDINA — VERDETTO FINALE UTENTE (19/10 sera)
Formato: emoji + NOME AGENTE + titoletto corto, stop. Il sistema assegna ogni mattina (richiamo modelli) il pilota migliore a ogni agente, con riserve a cascata.
1. 🧠 **Regista** — il più intelligente  2. ⚡ **Lampo** — il più veloce  3. 💻 **Fabbro** — l'esperto di codice  4. 🔥 **Squadra** — la fusione di agenti  5. 😈 **Libero** — parla di tutto
- ❌ Esploratore ELIMINATO (navigazione già dentro tutti gli agenti) · ❌ Revisore ELIMINATO (il giudice c'è già nella fusion; per gli altri si useranno i tasti accanto alla tendina)
- 😈 **ZONA FRANCA**: chat che girano SOLO su piloti senza filtri di nascita (Venice.ai / modello locale Ollama). MAI chiavi corporate serie (AgentRouter/Gemini/Groq…): rischio ban. GOD resta iniettato ovunque come rifinitura, ma il "parla di tutto" vero lo fa il pilota giusto.

## DECISIONE UTENTE — DIREZIONE AGENTI ↔ HUB (27/10/2026)

- **Direzione principale approvata:** gli agenti usano l’Hub come gateway OpenAI-compatibile; non è l’Hub a lanciare gli agenti.
- Le chiavi dei provider restano nell’Hub. Gli agenti ricevono l’endpoint e un token dedicato, non le chiavi upstream.
- L’API dell’Hub deve permettere agli agenti di consultare i modelli disponibili (`/v1/models`) e chiedere un modello esplicito oppure una modalità automatica (`/v1/chat/completions`). Il routing automatico deve restare trasparente e limitato ai provider/modelli autorizzati e a costo zero.
- **Da rimuovere, dopo audit e approvazione della scaletta tecnica:** le funzioni inverse Hub→agente CLI (agenti locali nella tendina della chat, avvio/stop dei loro processi e contatori che li presentano come operativi/lanciabili dall’Hub). Il contatore attuale non prova l’effettiva utilizzabilità via Hub.
- **Da preservare:** il catalogo provider/modelli e il router dell’Hub, perché sono il servizio che gli agenti useranno; l’endpoint agenti e la sua autenticazione. Separare questi componenti da ogni configurazione nata per far scegliere o lanciare agenti locali dall’Hub.
- Questa è una decisione di direzione e documentazione, **non un’autorizzazione a cancellare o modificare codice adesso**. Prima: inventario delle parti da rimuovere, anteprima e piano di test; non eseguire chiamate a provider né leggere/esporre valori delle chiavi.

## PRINCIPIO TECNICO — ROUTER PROPRIO E CATALOGO PER AGENTI (27/10/2026)

- L’Hub mantiene le chiavi e instrada direttamente verso provider/modelli autorizzati; OmniRoute non è il router obbligatorio né il custode di tutte le chiavi.
- L’agente può richiedere un modello esplicito (`provider/modello`) oppure una modalità automatica. Gli ID esposti devono essere non ambigui e il catalogo deve indicare la compatibilità utile al client (per esempio tool calling, streaming, contesto e modalità supportate).
- **Niente chiamata LLM di sonda per ogni richiesta:** usare catalogo e stato di salute memorizzati; fare una sola chiamata effettiva al modello richiesto. Aggiornare lo stato in base al risultato. Un modello esplicitamente richiesto non va sostituito in silenzio; il fallback è ammesso nelle modalità automatiche o quando autorizzato.
- I modelli esposti agli agenti devono rispettare la politica di spesa zero e le autorizzazioni. L’Hub mantiene la credenziale upstream; l’agente riceve solo il token del gateway.
- **OmniRoute: sorgente opzionale compatibile OpenAI**, se e quando la verifica locale confermerà modelli utilizzabili e compatibilità; distinguerne chiaramente i modelli da quelli raggiunti direttamente, evitando duplicati o instradamenti ambigui. Il rapporto del 21/10 è una fotografia storica, non prova lo stato attuale.
- Prossime verifiche di progetto: catalogo effettivamente esposto da `/v1/models`, rispetto dei modelli espliciti in `/v1/chat/completions`, compatibilità per agente e fallback controllato. Nessun test live/provider è autorizzato da questa nota.

## SPECIFICA GRAFICA RICHIESTA (27/10/2026 — DA APPLICARE DOPO REVISIONE)

- Nella tendina della chat rimuovere le voci che avviano/selezionano agenti locali; rimuovere anche **«Libero — parla di tutto»** e i relativi alias/mappature, perché la promessa non è vera.
- Rimuovere il contatore visibile **«Uso reale del router dell’hub»** (`usage` / `usageN`) vicino alla spia nella dashboard: Filippo ritiene che, con la nuova architettura, non abbia utilità. Questa richiesta riguarda il widget/contatore grafico; l’eventuale contabilità interna del router resta da valutare separatamente. Non confonderlo con il `6/6` della scheda agenti.
- Nel pannello Agenti, sezione Motori, indicare come motore primario il **Router dell’Hub**; OmniRoute resta eventualmente una sorgente compatibile opzionale, non il router principale.
- Nota di ricognizione UI: nello snapshot locale di `posta/gui/hub.html` ho trovato righe di stato per OmniRoute e Portiere e un placeholder «Motore sito» (non una tendina funzionante con quel nome). Prima di intervenire, individuare il controllo esatto e tradurre la richiesta nel layout corrente.
- Queste sono direttive grafiche/prodotto da riportare nella scaletta; **nessun codice è stato ancora modificato**. Le modifiche restano soggette a revisione della bozza e dei file locali già modificati.

## SCALLETTA OPERATIVA — AGENTI CHE USANO L’HUB (27/10/2026)

1. **Architettura — approvata:** gli agenti chiamano l’API dell’Hub; le chiavi upstream restano nel portachiavi locale dell’Hub. OmniRoute non è obbligatorio.
2. **Pulizia della GUI — richiesta, non ancora applicata:** rimuovere dal selettore chat gli agenti locali e «Libero» con tutte le relative mappature; rimuovere il contatore grafico «Uso reale del router dell’hub»; presentare il Router dell’Hub come motore primario nel pannello Motori. Non eliminare il catalogo provider/modelli o il router proprio dell’Hub.
3. **API e catalogo agenti — da verificare/finire:** `GET /v1/models` deve mostrare ID non ambigui e solo modelli ammessi; `POST /v1/chat/completions` deve rispettare il modello esplicitamente richiesto o applicare `auto` secondo le regole documentate. Evitare una chiamata LLM di sonda prima di ogni richiesta.
4. **Compatibilità — da verificare per agente/modello:** annotare tool calling, streaming, contesto e altre capacità necessarie. Un modello non va presentato come compatibile solo perché risponde a una chat semplice.
5. **Sicurezza — prerequisito:** token per agente, autorizzazioni/modelli consentiti e revoca; credenziali provider mai consegnate all’agente. Verificare che l’endpoint non sia esposto alla LAN senza autenticazione adeguata e che i log non salvino prompt per default.
6. **Configurazione guidata — proposta da valutare:** mostrare endpoint, token dedicato e modelli disponibili; fornire istruzioni/configurazioni copiabili senza esporre chiavi upstream.
7. **Stato e contabilità — proposta da valutare:** cache e ultimo esito/cooldown dei provider; indicare modello/provider effettivo e motivo del fallback. Se servirà una vista d’uso, farla per agente e solo con dati verificati, non con un totale aggregato ambiguo.
8. **Test — prima mock, poi prova locale autorizzata:** testare modello esplicito, `auto`, fallback controllato, rifiuto di modelli non consentiti, streaming/tool calling e revoca token. Le prove con provider reali restano escluse finché non sono autorizzate e a costo zero verificato.
9. **OmniRoute — opzionale:** inserirlo come sorgente OpenAI-compatibile solo dopo una verifica locale dei modelli realmente disponibili; distinguerli nel catalogo dai provider diretti. Il rapporto del 21/10 non prova lo stato attuale.

## MIGLIORIE FUNZIONALI PROPOSTE (da ordinare dopo il nucleo)

- Configurazione guidata per collegare ciascun agente all’Hub con endpoint, token dedicato e modello iniziale.
- Catalogo filtrabile per provider a costo zero e capacità verificate (tool calling, streaming, contesto, immagini/JSON dove supportati).
- Routing trasparente: mostrare quale modello/provider ha risposto e il motivo del fallback; non sostituire di nascosto un modello esplicitamente chiesto.
- Token separati/revocabili e autorizzazioni per agente; uso e latenza per agente con soli metadati, senza registrare il testo dei prompt per default.
- Verifica mirata della compatibilità OpenAI-compatibile, in particolare streaming e tool calling, prima di dichiarare un agente/modello pronto.
- **Limite operativo dell’assistente:** l’ambiente di lavoro remoto non raggiunge il `localhost` del PC dell’utente e non può avviare direttamente gli agenti installati lì. Un test locale deve essere avviato dal PC o richiedere un canale remoto esplicitamente autorizzato e messo in sicurezza; nessun tunnel è attivo o autorizzato.
