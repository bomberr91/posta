# ☀️ DA FARE DOMANI MATTINA — provider (per il protocollo buongiorno)

Scritto la sera del 20/10/2026. Ogni voce è **verificata adesso**, non copiata a memoria.
Quando attivi il protocollo buongiorno, si parte da qui.

---

## A · Chiavi da SISTEMARE (ce l'hai, ma oggi non rispondono)

| # | Provider | Cosa succede | Cosa fare domani | Tempo |
|---|---|---|---|---|
| 1 | **AgentRouter** | la chiave è valida ma **risponde una pagina web (Cloudflare)**, non l'API | rifare il login OAuth su agentrouter.org (serve GitHub attivo da 1 anno) e riprovare con `prova_provider.sh` | 10 min |
| 2 | **HuggingFace** | `You have no remaining credits` | guardare se il credito gratuito torna o se serve un altro token (settings/tokens) | 5 min |
| 3 | **Mistral** | `Rate limit exceeded` | è il limite gratis giornaliero: si può solo aspettare. Se domani mattina è verde, è a posto così | 1 min |
| 4 | **OpenCode Zen** | `Insufficient account funds` | il piano free si è esaurito: **non serve ricaricare** (regola: niente soldi). Si lascia spento, ci sono le altre | 1 min |
| 5 | **Nscale** | chiave mai salvata (`in 06_hunt`) | se il token si trova, va nel portachiavi. Se no, si lascia fuori | 5 min |

## B · Chiavi da PRENDERE (nuove, senza carta — SOLO se al signup non chiedono la carta)

| # | Provider | Perché vale | Dove | Nota |
|---|---|---|---|---|
| 6 | **SambaNova** | free tier, modelli veloci | cloud.sambanova.ai | da verificare se chiede carta: se sì, si lascia |
| 7 | **Liquid AI** | free tier | liquid.ai | idem |
| 8 | **Novita AI** | crediti iniziali | novita.ai | idem |

**Regola tua (resta valida):** se al signup chiedono la carta, si abbandona subito e non si riprova.
Quindi: si prova solo se il form non chiede metodo di pagamento.

## C · Le 28 chiavi FUORI da tutti e due i contatori

OmniRoute non le conosce e il portiere (scorta) nemmeno. Sono:
Auray · BlockRun · CLōD · DreamPrompting · Gizmo · Inferbase · Moondream · OVH · Sail ·
Septor Labs · Token Harbor · TeamoRouter · Zhipu · Plugsky · SimpleLLM · LLMTR · Router9 ·
Waterfall · BlazeAPI · Lucidity · Speechify · fal.ai · WaveSpeedAI · Nscale · Nebius · AI21 ·
Jina AI · Qdrant Cloud

**Attenzione, non tutte servono per chattare:**
- **Non sono per la chat** (le lascerei stare): Speechify (voce), Qdrant (database vettoriale), Jina (embedding/lettura pagine), fal.ai e WaveSpeedAI (immagini/video), Moondream (visione)
- **Morte, non si recuperano**: AI21 (ritirato), Nebius (chiede carta)
- **Solo da valutare** (potrebbero entrare nella scorta se scopriamo l'indirizzo giusto): Auray, BlockRun, CLōD, DreamPrompting, Gizmo, Inferbase, Sail, Septor Labs, Token Harbor, TeamoRouter, Zhipu, Plugsky, SimpleLLM, LLMTR, Router9, Waterfall, BlazeAPI, Lucidity

Per queste serve **l'indirizzo API** (base URL) di ognuna: senza quello non si possono chiamare.
Domani si fa in 20 minuti se tu mi passi il link della loro documentazione (o dove l'hai presa).

## D · Cosa gira da solo, appena accendi (nessun clic)

1. il motore OmniRoute si accende;
2. se ha 0 modelli, innesta le chiavi da solo (35 provider in mappa);
3. parte il portiere (20129): gli agenti non restano fermi se il motore cade;
4. fa l'appello delle chiavi e scrive chi risponde;
5. **se trova qualcosa che non va, lo scrive subito nel riquadro in basso, in italiano.**

## E · Comandi pronti (domani mattina)

```
cd ~/posta && bash prova_provider.sh       # prova VERA dei 12 provider migliori (~20 s)
cd ~/posta && bash appello_chiavi.sh       # prova TUTTE le chiavi (1 min)
cd ~/posta && bash agenti_stato.sh         # chi è installato e chi risponde
cd ~/posta && bash prova_agenti.sh         # agli agenti si fa una domanda vera
```

---

## Contatori di ieri sera (20/10, 21:59)

| Contatore | Quanti | Cosa vuol dire |
|---|---|---|
| 🧠 lavorano in OmniRoute | **35** | il motore le conosce e le può usare |
| 🛟 nella scorta | **12** | se OmniRoute cade, rispondono queste (11 sono le stesse di sopra) |
| 📦 fuori da tutti e due | **28** | né OmniRoute né il portiere: per usarle serve l'indirizzo API |
| totale portachiavi | **64** | voci nel registro |
