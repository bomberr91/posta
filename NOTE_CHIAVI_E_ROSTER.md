# NOTE CHIAVI & ROSTER — la regola della casa (4/11 notte)

> **Questo file sta QUI, accanto a `cervello.py`, perché è la regola che il
> cervello deve rispettare quando legge una chiave, chiama un provider e
> decide se è morto.** È nato dalla nota sulle interpretazioni delle chiavi e
> dal lavoro della notte del 4/11 (sweep della riserva, LongCat, NaraRouter,
> i falsi 403 di Cloudflare, i falsi errori in `portiere_stato.json`).
> **Se stai per toccare `portiere_lista.txt`, leggi prima questo file.**

---

## 0. LE REGOLE DELLA CASA (non si discutono, non si scavalcano)

1. **Nessuna chiave fuori dal portachiavi.** Le chiavi vivono solo in
   `CHIAVI_LOCALI.md` (repo privato `vault-chiavi`) e mai nel repo pubblico
   `posta`.
2. **Nessuna rimozione in autonomia.** Provider, chiavi, file, account: prima
   si chiede il via al capo, poi si esegue. Un provider esce dal roster **solo
   con il suo "sì"**.
3. **Niente provider a pagamento o con carta.** Solo gratis/keyless/trial.
4. **Prima di ogni misura, il via.** Sweep, sonde, collaudi automatici,
   script di misura: si chiede prima. (4/11: due sweep di fila senza il via
   ⇒ il capo non ne vuole più senza conferma.)
5. **Niente falsi verdi.** Un test che può solo dire "sì" non è un dato: la
   prova è la **risposta vera** del provider, non l'exit 0 dello script.
6. **Chi è sotto sentinella resta FUORI dal roster** finché la sentinella non
   dice "ora vai" (vedi §4).

---

## 1. COME SI LEGGE UNA CHIAVE (le interpretazioni, una per una)

La riga del roster è:

```
id|etichetta|nome nel portachiavi|indirizzo API|modello di partenza|modo|tipo|classe|extra|auth
```

| campo | cosa vuol dire | trappola |
|---|---|---|
| `id` | nome interno usato nei log e nei castighi | non può contenere spazi |
| `etichetta` | nome leggibile | — |
| `nome nel portachiavi` | **deve corrispondere ESATTAMENTE** a una voce di `CHIAVI_LOCALI.md` (o `SENZA` = keyless) | se non coincide, `chiave_di.py` non trova niente ⇒ il provider viene chiamato **senza chiave** ⇒ errore ⇒ "morto" **falso**. Il contratto è il nome, non la chiave. |
| `indirizzo API` | la **base** (il cervello aggiunge `/chat/completions` se manca) | `.../v1` va bene, `.../v1/chat/completions` anche (non lo raddoppia) |
| `modello di partenza` | il modello con cui si prova | se il provider ha cambiato i nomi ⇒ **404 "model not found"** ⇒ non è morto, è il roster sbagliato |
| `modo` | `chat` (si fa una domanda vera) o `modelli` (solo elenco) | un provider `modelli` **non** va chiamato come chat |
| `tipo` | `chat` (default) · `immagini` · `video` · `voce` · `embedding` · `visione` · `db` | un non-chat messo come chat ⇒ errore di forma, non di chiave |
| `classe` | `keyless` · `free-ricorrente` · `trial` · `pin-only` | `free-ricorrente` = gratis e si rinnova ⇒ è la classe buona |
| `extra` | lista di modelli (`a;b;c`) | serve a riprovare con un altro modello quando il primo non esiste |
| `auth` | (libero) | — |

**Tipi di chiave che si incontrano davvero:**
- chiave API normale → header `Authorization: Bearer <chiave>` (la default)
- PAT GitHub → stesso header, ma il PAT GitHub **non** è la PAT "GitHub Models":
  sono due voci diverse del portachiavi (`GitHub (bomberr91)` e `GitHub Models`)
- chiave locale/finta del cervello (`sk-cervello`) → serve solo per il 20129
- `SENZA` → keyless, nessuna chiave (si manda `free`)
- chiave che va letta da una variabile d'ambiente (`env_key`) → tipico delle app
  desktop (Open Interpreter 0.0.59: `CERVELLO_API_KEY`; con `OPENAI_API_KEY`
  la chiamata **non parte** e sembra che «l'app è lentissima»)
- chiave con header diverso (es. Anthropic: `x-api-key` + `/v1/messages`)

---

## 2. COME SI LEGGE UN CODICE DI RISPOSTA (la tabella che evita le interpretazioni sbagliate)

| cosa risponde | vuol dire | NON vuol dire | cosa fare |
|---|---|---|---|
| **200** con `choices` | vivo e risponde | — |-> verde: entra in squadra |
| 200 **senza** `choices` | non è una chat (o è un'altra API) | non è "morto" | correggi `modo`/`tipo`/`indirizzo` |
| **400** "model not found" / "modello inesistente" | il **modello** del roster non esiste più | non è morta la chiave | prova i modelli di `extra`, poi correggi la riga |
| **400** "max_tokens" troppo piccolo | il provider ha un minimo (AI Horde: ≥16) | non è morto | collauda con `max_tokens` ≥ 20 |
| **401** | chiave **sbagliata, scaduta o revocata** | non è "momentaneamente occupato" | sotto sentinella; **fuori dal roster** finché non si rinnova |
| **402** | quota esaurita / serve credito | non è morto: è in pausa | LongCat, HF: fuori dal roster, chiave nel portachiavi |
| **403** "error code: **1010**" | **Cloudflare ha bloccato la firma del client** | NON è morto | rimanda la richiesta **con User-Agent da browser** (il cervello lo fa già: `cervello.py` UA) |
| **403** piano/permesso | chiave valida, accesso negato (NavyAI, groq col blocco) | non è la chiave sbagliata | sotto sentinella |
| **404** endpoint | l'indirizzo nel roster non esiste più | non è un problema di chiave | correggi `indirizzo` |
| **429** | troppo richieste / free-pool saturo | NON è morto | frena (vedi `portiere_quote.txt`) e riprova più tardi |
| **5xx** (503 ecc.) | il provider è momentaneamente giù | non è morto | riprova, il cervello fa failover |
| **timeout** | lento o irraggiungibile | non è morto | misurare con timeout più generoso, poi decidere |
| **content-blocked** | filtro di sicurezza sul testo di prova | non è morta | cambiare il testo della prova |

**Regola d'oro:** una riga si dichiara «morta» solo se il **codice è 401/402
definitivo** (chiave/quota) **oppure** un timeout ripetuto **e** la prova è
stata fatta **con User-Agent da browser, `max_tokens` ≥ 20 e almeno un
modello alternativo** dalla lista `extra`.

---

## 3. COME SI INSERISCE BENE UN PROVIDER (checklist)

1. La chiave è **nel portachiavi** con un nome chiaro ⇒ nel roster la colonna
   `nome nel portachiavi` copia **quel nome identico**.
2. `indirizzo` = base corretta, `https`, **niente `http://` in chiaro**.
3. `modello` = un modello **provato** di quel provider (non ricordato a memoria).
4. `modo=chat` solo se è davvero una chat; se no `modo=modelli` e `tipo` giusto.
5. `classe` corretta (`free-ricorrente` se è gratis e si rinnova).
6. Se ha una quota conosciuta ⇒ una riga in `portiere_quote.txt`
   (`pid|al_minuto|al_giorno|distanza_secondi`).
7. **Prova reale** prima di accoglierlo in squadra: una richiesta minima con
   User-Agent da browser e `max_tokens` ≥ 20, e la risposta **con `choices`**.
8. Se è gratis ma con quota scarsa ⇒ **squadra di riserva** (`rinforzi`), non
   prima scelta: è il posto dove non si sprecano i crediti (es. GitHub Models:
   free 10 RPM/50 RPD sui modelli grandi, 15/150 sui piccoli ⇒ freno
   `ghmodels|6|40|3`).
9. Se è già **sotto sentinella** ⇒ **non entra nel roster** (vedi §4).
10. Il provider entra in una squadra solo **se risponde** ⇒ le squadre sono
    `code` (coding), `forte` (compiti pesanti), `rinforzi` (riserva).

---

## 4. L'APPELLO E LA SENTINELLA (chi chiama chi)

- Il **roster** (`portiere_lista.txt`) = il catalogo di chi può essere chiamato.
- L'**appello** = il momento in cui il cervello, se OmniRoute (20128) è morto,
  chiama la riserva in ordine di pagella (salute + velocità).
- La **sentinella** (`lavori/sentinella_chiavi.sh`, `lavori/sentinella_servizi.sh`)
  controlla **una volta al giorno** i provider sotto sorveglianza e scrive il
  referto in `dal_pc/sentinella_*.md`.
- **Regola:** un provider sotto sentinella **non sta nel roster** (non ha
  senso chiamare in appello chi sappiamo che non risponderà finché non cambia
  qualcosa). Quando la sentinella scrive **«ora vanno»**, si rimette nel roster
  e si ri-collauda.
- **4/11 (caso reale):** `waterfall` (401 chiave revocata) e `ovh` (403 «genera
  una nuova») erano già sotto sentinella ⇒ **tolti dal roster**, restano nel
  portachiavi e la sentinella continua a guardarli. `huggingface` tolto perché
  **non è più gratis** (crediti a pagamento, una riga di credito, niente
  gratis ⇒ escluso dalle regole).

---

## 5. GLI ERRORI CHE ABBIAMO GIÀ FATTO (non ripeterli)

- **Chiave trovata nel posto sbagliato** ⇒ si è giudicato un provider «morto»
  quando il problema era il nome nel portachiavi.
- **Prova senza User-Agent** ⇒ 12 provider sembravano morti (403 Cloudflare
  1010) e non lo erano.
- **`max_tokens` a 5** ⇒ AI Horde sembrava morto e rispondeva.
- **Modello vecchio nel roster** ⇒ 404 "model not found" su provider sani.
- **Chiave locale (`sk-cervello`) usata al posto di quella vera** ⇒ chiamata
  respinta al primo tentativo.
- **Chiave non esportata nell'ambiente dell'app** ⇒ la domanda non parte
  affatto e sembra un blocco (Secondhand 0.0.59: `env_key`).
- **Righe-commento senza `#`** nel roster ⇒ il cervello le carica come
  provider e si punisce da solo (5/11 notte: puliti i castighi).
- **Provider non-chat nel catalogo chat** ⇒ errori di forma che sembrano
  chiavi rotte.

---

*Tenuto aggiornato dall'orchestratore. Ogni volta che si scopre una nuova
interpretazione, si aggiunge qui — è più economico che riaprire la discussione.*
