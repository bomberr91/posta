# CERVELLO MACCHINA PERFETTA — quaderno delle idee da applicare
Strada A decisa il 30/10: il nostro cervello.py resta, gli rubiamo le idee migliori.
Metodo: analisi a blocchi -> conclusioni -> SOLO POI si applica (ordine deciso insieme).

## BLOCCO 1 (30/10) — Lynkr, EUrouter, TrustedRouter, Routstr

### Lynkr ⭐⭐⭐ (open source, npm, locale) — LA MINIERA
Da rubare:
1. COMPRESSIONE TOON dei risultati JSON dei tool (-87%: 3458->427 token)
2. SPOGLIATURA SCHEMI TOOL: via gli schemi inutili per richieste di sola lettura (-53%)
3. CACHE SEMANTICA locale (embedding locali): domanda simile -> risposta in 171ms, 0 token
4. TIER ROUTING con sessioni appiccicose: facile->gratis, sale di livello solo se serve
Nota: si puo' anche installare accanto al cervello per studiarlo dal vivo (npm i -g lynkr, porta 8081).

### EUrouter 💡 (servizio EU a pagamento — solo idee)
5. PAGELLA PROVIDER: punteggio = salute/(prezzo)^2; castigo (cooldown) 30-120s a chi fallisce;
   retry automatico su 5xx/429/408; "allow_fallbacks: false" per routing rigido.

### TrustedRouter 💡 (hosted, source-available — solo idee)
6. MODELLI-POLITICA: "auto"/"cheap"/"fast"/"free" come nomi modello che in realta' sono
   regole di scelta -> cervello/gratis, cervello/veloce, cervello/migliore.

### Routstr ❌ SCARTO (mercato a pagamento in Bitcoin/sats)
(il cugino open "arbstr" conferma: classificatore complessita' + auto-scoperta /v1/models)

## LISTA DELLA SPESA provvisoria (si aggiorna a ogni blocco)
A. Modelli-politica (patch piccola) [da Lynkr/TrustedRouter]
B. Pagella+castigo+retry provider (patch media) [da EUrouter]
C. Cache risposte: esatta subito, semantica poi (patch media) [da Lynkr]
D. Spogliatura tool + compressione JSON (patch grossa, per ultima) [da Lynkr]

## BLOCCO 2 (30/10) — Bifrost, LunarGate, freelm, Portkey, one-api

### Bifrost ⭐⭐ (Go, open source, enterprise — troppo grosso come motore, idee si')
7. BILANCIAMENTO MULTI-CHIAVE: piu' chiavi per lo stesso provider, scelta pesata
   -> per il portachiavi 57+ chiavi: ruotare le chiavi dello stesso servizio
8. CHIAVI VIRTUALI CON BUDGET: ogni agente una chiave finta con tetto richieste/spesa
   (oggi sk-cervello e' uguale per tutti: con chiavi per-agente sapremmo CHI consuma)

### LunarGate ⭐⭐ (MIT, Go 10MB, filosofia gemella: locale+privacy+una porta)
9. CIRCUIT BREAKER: provider che fallisce N volte -> escluso finche' non guarisce
   (piu' fine del semplice "passa al prossimo")
10. HOT-RELOAD: ricaricare portiere_lista.txt / config senza riavviare il cervello
11. PUNTEGGIO COMPLESSITA' per "auto": prompt corto/facile -> tier gratis;
    lungo/difficile -> tier migliore (LunarGate dichiara -40% costi)

### freelm ⭐ (giovane, 1 dev — conferma filosofia)
12. ROTAZIONE CHIAVI A QUOTA ESAURITA: quando un provider gratuito dice "quota finita",
    marcare la chiave fino a mezzanotte e passare alla gemella (non solo al provider dopo)
    [doctor/appello = GIA' NOSTRO]

### Portkey 💡 (open source ma orientato cloud)
13. POLITICHE PER-AGENTE dichiarative: JSON "retry 3, poi fallback X, cache on"
    diverso per OpenClaw/Hermes/ecc.

### one-api / new-api 💡 (veterano cinese, pannello)
14. PESI PER CANALE + DISABILITAZIONE AUTOMATICA canale morto + CONTATORI QUOTA
    per chiave-utente (conferma 7+8 in versione semplice)

## BLOCCO 3 (30/10) — FuturMix, Opper, PleumRouter
Tutti e tre ❌ SCARTATI: rivenditori commerciali hosted (markup), zero codice, zero idee nuove.
Perle collaterali emerse dalla ricerca:
15. PAGELLA PER SINGOLA CHIAVE: salute a finestra scorrevole per chiave; 401/403 = chiave
    morta -> LISTA NERA PERMANENTE; errori consecutivi -> esclusione temporanea [theopenco/llmgateway]
16. SCOPE PER CHIAVE-AGENTE: ogni agente limitato a certi modelli + quota richieste/min [AMG555/llm-router]

## ✅ CONCLUSIONI — PIANO DI APPLICAZIONE (da approvare col capo, una fase alla volta)

FASE 1 — piccole e sicure (mezz'ora, zero rischi):
  P1. Modelli-politica: cervello/gratis, cervello/veloce, cervello/migliore (auto resta) [idee 6,A]
  P2. Hot-reload: il cervello rilegge la lista provider senza riavvio [idea 10]

FASE 2 — medie (un pomeriggio, collaudo in sandbox prima del push):
  P3. Pagella + castigo + retry: punteggio salute per provider E per chiave; cooldown 30-120s
      a chi fallisce; retry automatico su 5xx/429/timeout; 401/403 = lista nera [idee 5,9,15]
  P4. Rotazione chiavi gemelle: quota esaurita -> chiave sorella dello stesso provider,
      la stanca riposa fino a mezzanotte [idea 12]
  P5. Cache esatta: stessa domanda identica -> risposta gia' pronta, 0 token [idea C]

FASE 3 — grandi (progetti a se', uno per volta):
  P6. Chiavi per-agente (sk-openclaw, sk-goose...) con contatori e permessi [idee 8,13,14,16]
  P7. Punteggio complessita' per "auto": facile->gratis, difficile->migliore [idee 4,11]
  P8. Cache semantica con embedding locali (domande SIMILI, non solo identiche) [idea 3]
  P9. Spogliatura tool schemas + compressione JSON dei risultati (-50/87% token) [idee 1,2]

Regola: ogni patch -> collaudo in sandbox col motore finto -> anteprima al capo -> push.

## 🔁 RICONTROLLO BLOCCO 2 (30/10 sera — richiesto dal capo: avevo giudicato
## freelm/Portkey/one-api a memoria senza verificarli. Errore mio. Ecco cosa mancava.)

### freelm — PROMOSSO da ⭐ a ⭐⭐⭐ (gemello maturo del cervello, MIT, free-only)
17. CASTIGO PER (CHIAVE, MODELLO): un 429 su un modello riposa solo quel modello di quella
    chiave, il resto della chiave continua a lavorare
18. TASSONOMIA ERRORI: 404/410=modello pensionato (castigo globale) · "no access"=castigo
    per chiave · 413/contesto=prova modello piu' capiente · 5xx=passeggero ·
    200-con-errore-dentro e STREAM TRONCATI = failover comunque
19. CORSA TRA PROVIDER: latenze misurate, campioni scadono dopo 10 min; il lento costa
    tempo solo la prima volta; "races" il lento contro il successivo
20. QUOTE PERSISTENTI su disco (sopravvivono al riavvio del cervello)
21. GUARDIA SOLO-GRATIS: modelli a pagamento RIFIUTATI (mai spendere credito per errore)
22. QUOTA GIORNALIERA FINITA -> chiave riposa 1 ORA (non ritentata ogni minuto)
23. 🎁 DUE MOTORI KEYLESS NUOVI per la riserva: Kilo Gateway (~200 req/ora per IP,
    senza chiave) e OVHcloud AI Endpoints anonimo (2 req/min per IP per modello)
    + tabella quote free aggiornata (Groq 30/min 1000/g, OpenRouter 20/min 50/g,
    Cloudflare 10K neuroni/g, Z.ai GLM-Flash gratis, Cohere trial 1000/mese)

### Portkey — correzione: il nucleo E' open source e self-hostable (Docker ~100kb)
24. STRATEGIE ANNIDATE (fallback dentro loadbalance e viceversa) + ON_STATUS_CODES
    (fallback solo sugli errori scelti) + retry esponenziale max 5
25. TIMEOUT PER RICHIESTA con taglio automatico della chiamata appesa
    (cache: modalita' esatta con scadenza O semantica con soglia somiglianza)

### one-api / new-api — confermato, piu' tre chicche:
26. TOKEN-AGENTE RICCHI: scadenza + max usi + IP consentiti + modelli consentiti +
    auto-disabilitazione a quota superata
27. SALUTE = TASSO DI SUCCESSO (soglia 0.8), non solo errori secchi
28. TRADUTTORE DI FORMATI (new-api parla OpenAI+Claude+Gemini sulla stessa porta)
    -> un domani il Gemini CLI ufficiale potrebbe parlare col cervello

### Impatto sul piano fasi (da ridiscutere alle conclusioni finali):
- P3 (pagella) si arricchisce con 17,18,27 · P4 (rotazione) con 20,22 · P5 (cache) con 25
- NUOVO candidato FASE 1: aggiungere Kilo/OVHcloud keyless alla riserva (idea 23) — facile
- NUOVO candidato FASE 3: traduttore formati (idea 28)

MANCA ANCORA (ultimo blocco, da fare col capo): Llama Swap + LiteLLM (analisi vera).

## BLOCCO 4 — ULTIMO (30/10 sera) — Llama Swap, LiteLLM

### Llama Swap 🅿️ PARCHEGGIO (MIT, Go, 1 binario — ma serve per MODELLI LOCALI)
Accende/spegne i server dei modelli sul PC a seconda della richiesta, scarico automatico
dopo inattivita' (ttl). Il nostro PC non fa girare modelli -> utile solo in un futuro
"modelli in casa" (insieme a rizzo-flow). Da tenere:
29. ALIAS: l'agente chiede "gpt-4o-mini" -> il proxy lo rimappa su cio' che decide lui
    (utile per client testardi coi nomi) + conferma watch-config (idea 10)

### LiteLLM ⭐⭐ (MIT, lo standard — miniera di pattern, ma pesante: Postgres+Redis)
30. GRUPPI-FALLBACK PER NOME: stesso model_name su piu' voci = gruppo bilanciato
    (le chiavi gemelle risolte con eleganza in configurazione)
31. ROUTING PER CONSUMO OSSERVATO (usage-based v2): spalma su token/min reali,
    previene il 429 su una chiave mentre la gemella dorme
32. CONTEXT_WINDOW_FALLBACKS: catena di riserva separata per "contesto troppo lungo"
    (conferma idea 18)
33. DROP_PARAMS: scarta solo i parametri che il provider non capisce
    (meglio del nostro riserva() che strippa tutto, tools compresi)
+ numeri collaudati: allowed_fails 3, cooldown 30-60s, num_retries 2, timeout 30s
NOTA DECISIONE: con la strada A scelta, la "prova B LiteLLM su :20130" perde senso come
confronto motori; resta solo se un giorno servisse la roba enterprise. DA CONFERMARE COL CAPO.

## 🏁 ANALISI COMPLETATA: 13/13 candidati, 33 idee numerate.
Prossimo passo: conclusioni definitive -> aggiornare le FASI -> approvazione del capo
-> si applica UNA FASE ALLA VOLTA (sandbox -> anteprima -> push).

## CORREZIONE CONTEGGIO (segnalata dal capo): la lista era di 13 VOCI, di cui la #12
## era un TRIO (FuturMix/Opper/PleumRouter) e la #13 OmniRoute (saltato: eccolo).

### OmniRoute ⭐ (gia' nostro, porta 20128 — analisi col focus "cosa rubargli")
34. PARCO KEYLESS IN PROPRIO: la sua lista di motori senza chiave (Pollinations, LongCat,
    Cloudflare, Qwen, Qoder, DDG, Felo, Kiro, OpenCode Zen) puo' entrare DIRETTAMENTE
    nella riserva del cervello, senza il salto intermedio OmniRoute (meno anelli = piu' robusto)
35. GEMINI CLI VIA OAUTH (180K req/mese): motore grosso che il cervello oggi non sfrutta
Ruolo confermato: resta la riserva-dietro-la-riserva. Limite: progetto esterno.

## 🔭 SCOPERTE COLLATERALI (uscite di sponda dalle ricerche Reddit/GitHub)
## — IN CODA "DA VALUTARE", NON ANALIZZATE (regola del filtro: mai marcare senza approfondire)
- arbstr (johnzilla, Rust): classificatore complessita' + auto-scoperta /v1/models [vista di sfuggita]
- theopenco/llmgateway: pagella per chiave + lista nera 401/403 [gia' munto: idea 15]
- AMG555/llm-router: scope per chiave-agente + quota rpm [gia' munto: idea 16]
- LMRouter: aggregatore MIT ma catalogo congelato da feb 2026 [probabile scarto, da confermare]
- future-agi gateway: budget per chiave, cache, fallback [dal thread Reddit, da aprire]
- freellmpool: libreria Python + proxy su provider gratuiti [citato da freelm, da aprire]
- 9Router e free-claude-code: gateway self-hosted che uniscono provider gratuiti
  [citati da freelm come suoi simili → CACCIA TOKEN, da aprire]

## 📊 TABELLA RESOCONTO FINALE (13/13 analizzati)
| # | Nome | Verdetto | Idee | In una riga |
|---|------|----------|------|-------------|
| 1 | LiteLLM | ⭐⭐ | 30-33 | Lo standard: pattern d'oro, ma vuole Postgres+Redis |
| 2 | Lynkr | ⭐⭐⭐ | 1-4 | Il faro del risparmio token (compressione, cache, tier) |
| 3 | EUrouter | 💡 | 5 | Pagella provider: salute/(prezzo)^2 + castigo |
| 4 | TrustedRouter | 💡 | 6 | Modelli-politica (auto/cheap/fast/free) |
| 5 | Routstr | ❌ | — | Mercato in Bitcoin: fuori dai binari |
| 6 | Llama Swap | 🅿️ | 29 | Per modelli locali: parcheggio + alias |
| 7 | freelm | ⭐⭐⭐ | 12,17-23 | Il faro del gratis (castighi fini, keyless, guardia) |
| 8 | Bifrost | ⭐⭐ | 7-8 | Multi-chiave pesata + chiavi virtuali con budget |
| 9 | LunarGate | ⭐⭐ | 9-11 | Filosofia gemella: circuit breaker, hot-reload, complessita' |
| 10 | Portkey | 💡 | 13,24-25 | Strategie annidate + on_status_codes + timeout |
| 11 | one-api/new-api | 💡 | 14,26-28 | Token-agente ricchi + salute=tasso successo + traduttore |
| 12 | FuturMix/Opper/PleumRouter (trio) | ❌ | — | Rivenditori commerciali: niente da imparare |
| 13 | OmniRoute (nostro) | ⭐ | 34-35 | Riserva confermata; parco keyless da internalizzare |

TOTALE: 35 idee numerate + 7 scoperte collaterali in coda "da valutare".

## BLOCCO A — SCOPERTE COLLATERALI ANALIZZATE (30/10 sera): arbstr, LMRouter, future-agi, freellmpool

### arbstr 💡 (MIT, Rust, ATTIVO — release ott 2026)
36. AUTO-SCOPERTA: popolare la lista modelli interrogando /v1/models dei provider all'avvio
    + IGIENE RISPOSTE: mai far trapelare corpi d'errore del provider o prefissi di chiave al
    client; SSE senza doppio [DONE] (ci riguarda: il nostro SSE e' fatto a mano)

### LMRouter ❌ SCARTO: dormiente (push set-2025, catalogo congelato feb-2026, 0 release)
(doppia faccia OpenAI+Anthropic gia' coperta dall'idea 28)

### future-agi / Agent Command Center ⭐⭐ (Apache 2.0, Go — piattaforma grossa, idee si')
37. SHADOW/MIRROR: copia della richiesta a un secondo provider per confronto qualita'
    senza toccare la risposta -> aggancio con FUSION / "seconda controllata"
38. TOOLPOLICY per chiave virtuale: governare QUALI TOOL puo' usare ogni agente dal gateway

### freellmpool ⭐⭐⭐ (MIT, pip, proxy locale — COLPO GROSSO: gemello con catalogo mostruoso)
39. TASSONOMIA DEL GRATIS: ogni rotta classificata free-ricorrente / keyless / trial-finito /
    pin-only / disabilitata -> struttura perfetta per il nostro portachiavi
40. PREDE NUOVE CACCIA TOKEN: LLM7 (keyless/chiave opzionale), Aion Labs (20K token/g senza
    carta), SiliconFlow (free, verifica identita'), HF router free tier
    [ModelScope ESCLUSO per regola utente] + conferme Kilo/OVHcloud/Pollinations keyless
41. CANDIDATO RISERVA: freellmpool installabile (pip) come riserva alternativa/affiancata a
    OmniRoute (ha pure profilo Hermes e predisposizione OpenCode) — DA DECIDERE COL CAPO

RESTA: BLOCCO B (ultimi 2): 9Router, free-claude-code.

## BLOCCO B — ULTIME 2 SCOPERTE COLLATERALI (30/10 sera): 9Router, free-claude-code

### 9Router ⭐⭐ (MIT npm, :20128 — ⚠ STESSA PORTA di OmniRoute! Cuore = pacchetto privato
### non auditabile + fork in zona grigia -> SOLO IDEE, MAI INSTALLARE)
42. RTK TOKEN SAVER: comprimere i tool_result (git diff, grep...) prima del modello,
    -20/40% token input senza cambiare la risposta (complementare a Lynkr idee 1-4)
43. CONTATORE QUOTE con countdown reset (5h/giornaliero/settimanale) per provider:
    spremere ogni quota prima dell'azzeramento
44. MULTI-ACCOUNT round-robin per provider + scalata ad account successivo a quota finita
    + refresh OAuth automatico
45. COMBO CON NOME: catene personalizzate Abbonamento->Economico->Gratis, componibili
    (cugine dei modelli-politica, idea 6)

### free-claude-code ⭐⭐ (Python FastAPI; fa girare Claude Code su NIM 40 req/min free,
### OpenRouter, DeepSeek, locali)
46. INTERCETTA RICHIESTE BANALI: 5 categorie (sonde quota, titoli, suggerimenti UI,
    estrazione filepath, conteggi) RISPOSTE LOCALMENTE senza toccare il modello ->
    quota+latenza salvate. PERFETTO per il Portiere.
47. PARSER EURISTICO TOOL-CALL: tool call scritte come testo -> tool use strutturato;
    <think>/reasoning_content -> blocchi thinking nativi
48. RATE LIMIT FURBO: finestra scorrevole proattiva + backoff esponenziale su 429 +
    tetto di concorrenza

== ✅ ANALISI DAVVERO COMPLETA: 13/13 candidati + 6/6 collaterali = 48 IDEE TOTALI ==
(esclusi perche' gia' munti: theopenco/llmgateway idea 15, AMG555/llm-router idea 16)
Prossimo passo: CONCLUSIONI DEFINITIVE (fasi riscritte con tutte le 48 idee).

## LISTA GOOSE — BLOCCO 1 (30/10 notte): OrcaRouter, IO Intelligence, Sakana Fugu, OpenCode Go

### OrcaRouter ⭐⭐⭐ (il "disperso" — hosted gratis zero-markup + Lite MIT self-host)
49. CACCIA TOKEN: piano free "Hacker" (3 chiavi, no carta) @ https://api.orcarouter.ai/v1 ->
    modelli a costo zero: deepseek/deepseek-v4-flash-free, deepseek/deepseek-v4-pro-free
    + alias orcarouter/free che auto-sceglie tra i free. Chiavi sk-orca-... dal console.
50. GLASS-BOX: log per ogni richiesta di voto-difficolta' + modello scelto + provider
    (attribuzione di rotta trasparente) -> da copiare nel log del Portiere
51. 429 INTELLIGENTI: codice free_rate_limited + header Retry-After per distinguere
    finestra riprovabile vs tetto-prompt NON riprovabile -> raffina pagella/castigo (idee 5,17)
52. SONDA CREDENZIALI GRATIS: GET /v1/models richiede la chiave -> verifica validita'
    chiave a costo zero token (per il controllo periodico del portachiavi)
53. OrcaRouter Lite = MIT, self-host, SQLite (NO Postgres/Redis!) -> codice da minare:
    bandito contestuale che vota la difficolta' e IMPARA dal traffico reale
    github.com/Continuum-AI-Corp/OrcaRouter-Lite

### IO Intelligence (io.net) ⭐ caccia con riserva
54. CACCIA: chiave free @ https://api.intelligence.io.solutions/api/v1 — MA free tier reale =
    solo google/gemma-4-26b-a4b-it + nvidia/nemotron-3.5-lightning (il resto risponde 402)
55. CATALOGO != ACCESSO: /v1/models elenca 39 modelli ma quasi tutti gated (metadato
    min_access_tier) -> il portachiavi NON deve fidarsi della lista: sonda reale per modello.
    Bonus: sub-chiavi con restrizioni per-modello + tetto crediti = conferma della P6.
    [ESISTE tool di creazione account in massa: ZONA GRIGIA, NON lo usiamo]

### Sakana Fugu ❌ uso (BLOCCATO IN EU/EEA + a pagamento $20-200/mese) / 💡 concetto
56. ORCHESTRAZIONE-COME-MODELLO: regista piccolo (~7B, RL) che dirige un pool di modelli
    grossi con ruoli Thinker/Worker/Verifier, anche ricorsivo; prezzo = solo il modello di
    fascia piu' alta usato. CONVALIDA la nostra FUSION ("il regista piu' intelligente
    sceglie") -> spunto FUSION 3.0 a ruoli: Pensatore/Operaio/Verificatore.

### OpenCode Go ⭐⭐ (abbonamento $10/mese scartato: niente carta — ma due pepite)
57. CACCIA — BIG PICKLE: modello FREE di OpenCode: 200K contesto, 128K output,
    200 req/5h (alias GLM) — da verificare e arruolare (abbiamo gia' account OpenCode Zen!)
58. SESSIONE STABILE: header x-opencode-session con ID fisso per conversazione ->
    routing + prompt caching upstream. Il Portiere dovrebbe generare/inoltrare ID sessione
    stabili per agente (si sposa con la regola prefix-cache di Lynkr, idea 4)

RESTANO: Blocco 2 (Atomic Chat, Celeris, NEAR AI, SayGM) + Blocco 3 (EmpirioLabs,
SaladCloud, Ollama Cloud, Vercel AI Gateway).

## LISTA GOOSE — BLOCCO 2 (30/10 notte): Atomic Chat, Celeris, NEAR AI, SayGM

### Atomic Chat 🅿️ PARCHEGGIO LOCALE DI LUSSO (open source, gratis)
59. Se mai andremo sul locale: candidato n.1 al posto di llama-swap per principianti —
    GUI senza terminale, server OpenAI-compat :1337/v1, 12 motori, TurboQuant KV cache
    ~4x piu' piccola, MCP, e lancia con un click Hermes/OpenClaw/Cline (i NOSTRI agenti).
    github.com/AtomicBot-ai/Atomic-Chat

### Celeris ❌ SCARTO: a pagamento ($0.20/$0.70 per M) + API LIMITATA AGLI USA.
(concetto diffusion-per-compiti-corti inapplicabile: regola "niente sonda LLM per richiesta")

### NEAR AI Cloud ❌ SCARTO: solo pay-per-token, nessun free tier (TEE serio ma fuori
### per regola costo-zero; niente di strutturale da copiare)

### SayGM 💡 (uso scartato: pagamenti wallet — ma motore di routing ben fatto)
60. PAGELLA EWMA: media mobile esponenziale di TTFT e token/sec per provider, aggiornata
    a ogni richiesta + SOGLIE QUALITA' (TTFT max, TPS min, success-rate min) come filtro
    PRIMA della scelta del provider -> raffina P3 (pagella+castigo)
61. PERIODO DI GRAZIA: provider/chiavi nuovi non giudicati finche' non hanno storico
    (warm-up) -> evita castighi ingiusti al primo starnuto
    ⚠ DA VERIFICARE (coda caccia): goose docs elenca SayGM sotto "Using goose for Free"
    -> possibile spiraglio free/testnet (test-api.saygm.com)

RESTA: Blocco 3 (EmpirioLabs, SaladCloud, Ollama Cloud, Vercel AI Gateway) — ULTIMO.

## LISTA GOOSE — BLOCCO 3, ULTIMO (30/10 notte): EmpirioLabs, SaladCloud, Ollama Cloud, Vercel AI GW

### EmpirioLabs ❌ SCARTO: nessun free tier (hasFree:false nell'upstream OmniRoute), rivenditore PAYG
### SaladCloud ❌ SCARTO: pay-per-token (da $0.06/M, beta) — economico ma mai gratis

### Ollama Cloud ⭐ PREDA CACCIA
62. CACCIA (VERIFICATO depth2): free tier SENZA carta e SENZA telefono — endpoint
    OpenAI-compat https://ollama.com/v1 — 8 modelli starter gratis: gpt-oss:120b/20b,
    nemotron-3-ultra (ctx 1M!), nemotron-3-super, nemotron-3-nano:30b, gemma4:31b,
    deepseek-v4-pro (1M), minimax-m3 (512K); stime ~5-30M token free per modello.
    ⚠ limiti NON pubblicati · 1 sola richiesta concorrente (altre in coda) ·
    modelli fuori piano = 402 -> il cervello deve leggerlo come "non in piano", non guasto.

### Vercel AI Gateway ⭐⭐ PREDA GROSSA (abbiamo gia' account Vercel!)
63. CACCIA (VERIFICATO depth2): $5 di crediti GRATIS ogni 30 giorni per team (anche
    Hobby), partono dalla PRIMA richiesta, senza carta. Zero markup = ~10M+ token sui
    modelli economici o assaggi di GPT-5.x/Claude/Grok. Endpoint:
    https://ai-gateway.vercel.sh/v1, modelli formato provider/nome. Esiste guida
    ufficiale Vercel per collegarci OPENCODE. Account Vercel GIA' NOSTRO.
    ⚠ MAI comprare crediti (al primo acquisto i $5 mensili spariscono PER SEMPRE) ·
    free = rate limit piu' bassi (429) · fonti discordi se free copra tutti i modelli
    o un sottoinsieme -> da scoprire alla prima prova.

### Pepita collaterale del blocco
64. VERIFICA OMNIROUTE NOSTRO: l'upstream (cheaper-inference/OmniRoute) dichiara
    RTK+Caveman compression (15-95% token) e quota-aware auto-fallback GIA' A BORDO ->
    prima di reimplementare la compressione (idea 42), controllare se il nostro
    OmniRoute :20128 le ha gia' e come si accendono.

====================================================================
== 🏁 QUADERNO COMPLETO (30/10 notte) — TUTTE LE ANALISI FINITE ==
====================================================================
TOTALE ANALIZZATI: 13 candidati originali + 6 collaterali Reddit/GitHub + 12 lista Goose
                   = 31 approfonditi (+ 10 scartati a vista dalla lista Goose con motivo)
TOTALE IDEE: 64 numerate (buone + parcheggi 🅿️ + scarti ❌ motivati, tutto in questo file)

PREDE CACCIA TOKEN NUOVE (riepilogo): OrcaRouter free (49) · io.net (54) · Big Pickle
OpenCode (57) · Ollama Cloud (62) · Vercel AI GW $5/mese (63) · LLM7/Aion/SiliconFlow/HF (40)
· SayGM da verificare (61-nota) · Kilo/OVHcloud keyless (23)

PROSSIMO PASSO (quando il capo da' l'ok): CONCLUSIONI DEFINITIVE — riscrivere le FASI
incorporando le 64 idee -> approvazione -> applicare UNA FASE ALLA VOLTA
(sandbox -> anteprima -> push).
