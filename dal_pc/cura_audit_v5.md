# 🔴 CURA-AUDIT v5 — 1/11 sera — IL PORTIERE ERA MORTO DA UN'ORA

_01/11/2026 17:30 · Arena (analista) · per il capo_

## 1. LA NOTIZIE IN UNA RIGA

**Il Portiere non rispondeva più a nessuna chat dalle 16:24 di oggi**, e ogni
segnale diceva "tutto verde". Non è un'ipotesi: l'ho riprodotto, l'ho
collaudato e l'ho corretto.

## 2. I DUE DIFETTI (stessa commit: `3164d7f`, 01/11 16:24, "CURA-AUDIT")

**① `_sessione()` annidato dentro `_rispondi()`** (8 spazi invece di 4).
`H._sessione` non esisteva più → `do_POST` moriva con
`AttributeError: 'H' object has no attribute '_sessione'`
→ il server chiudeva la connessione **senza rispondere**.
→ **ogni richiesta chat a :20129 moriva con "empty reply from server".**

**② `NOME = "Portiere"` era stato cancellato** → `NameError` su
`/cervello` e `/portiere.json` (la pagina del cruscotto).

*Prova:* ho reintrodotto il difetto in una copia e l'ho fatto girare →
`curl` esce **52 (empty reply from server)**, esattamente il sintomo.

## 3. PERCHÉ NESSUNO SE N'ERA ACCORTO

| Il collaudo prima | Perché non poteva vedere |
|---|---|
| `curl -s -m 10/15 ...` | il timeout del curl (5-20s) è **più corto del budget del motore** (`timeout_motore` 180s + 5×`timeout_riserva` 60s ≈ 480s): non distingue "rotto" da "lento" |
| `\| python3 -c "json.load(sys.stdin)"` | corpo vuoto → `JSONDecodeError`, ma **nessuno guardava l'uscita** |
| niente `set -e` negli script di deploy | l'errore non fermava nulla → il `.done` veniva scritto lo stesso |
| `postino.sh` non guardava il codice di uscita del job | **un job fallito veniva archiviato come fatto** |

Il risultato: `dal_pc/deploy_cura.md` mostra la prova del "deploy riuscito" con
la `JSONDecodeError` stampata sotto — e nessuno l'ha fermata.

## 4. COSA HO FATTO

### Le due reti di sicurezza (nuove)

**A. `python3 cervello.py --autoprova`** — due controlli:
1. **strutturale**: ogni `self.X()` chiamato deve esistere come metodo della
   classe (via AST). È il controllo **generico**: qualunque metodo annidato
   per sbaglio esce qui.
2. **vivo**: si fa parlare davvero il cervello su una porta libera
   (`/cervello`, `/portiere.json`, `/v1/models` e una **chat vera**).

**B. `gate_pubblicazione.py`** — prima di pubblicare, il postino controlla che
ogni `.py` modificato **compili** e che `cervello.py` **passi l'autoprova**.
Se no, il file **non sale su master** (il lavoro resta in locale: nessuna
perdita) e l'avviso finisce in `dal_pc/gate_pubblicazione.txt`.

**C. `GET /salute`** — il riscontro veloce: vivo? configurato? struttura pulita?

### Il collaudo riscritto

`fatti/collaudo_cervello.sh` (condiviso): timeout **coerenti col budget del
motore**, ogni passo **verifica davvero**, e l'uscita dice **NO** quando
qualcosa non torna. Lo usano ora:

- i deploy: `deploy_cura` · `deploy_f3` · `deploy_cors` · `deploy_json_ricco` ·
  `deploy_sentinella2` · `deploy_sent_pagine`
- i riti che verificano il cervello: `rito_nuovo` · `buongiorno_1_11` ·
  `stato_invisibili` · `collaudo_fase1` · `test_blackout`

### Il postino non mente più

`postino.sh`: il `.done` si scrive **solo se il job esce con 0**. Un fallimento
→ `fatti/<nome>.failito` + il compito **resta da fare** (3 tentativi, poi
`.abbandonato`). Nessun codice di uscita viene più ignorato.

## 5. GLI ALTRI RILIEVI DELL'AUDIT v4 (chiusi)

- import: solo `ImportError` (un errore interno non spegne più F3 in silenzio)
- `vivo()`: la porta la decide lo schema (443 per https) e l'IPv6 va tra parentesi
- guardia solo-gratis: chiusa la **famiglia** dei piani Gemini pro/ultra
- `max_tokens`: tetto in CONFIG (8000); i valori non interi vengono scartati
- risposte: tetto di byte letti, sia sul motore sia sulla riserva
- quote: `freno()` e `batte()` atomici sotto lucchetto + tetto ai battiti
- stato su disco: **validato** (tipi sbagliati → ricostruiti, più `NameError`)
- regole per agente: vince il prefisso **più lungo**, le chiavi vuote **no**
- sessioni: sotto lucchetto (`min()` su una mappa che un altro thread svuota)

## 6. I COLLAUDI (fatti, non dichiarati)

- `python3 cervello.py --autoprova` → **SUPERATA** (uscita 0)
- collaudo sul codice **rotto** (bug reintrodotto) → **FALLITA** (uscita 1),
  con la diagnosi esatta: *"H: self._sessione() non è un metodo della classe"*
- `gate_pubblicazione.py` → blocca `.py` rotto e `cervello.py` rotto
- `postino.sh` in ambiente di test: job che esce con 3 → **nessun `.done`**,
  `.failito` scritto, contatore 1/3 → 2/3 → 3/3 → abbandonato; job che esce
  con 0 → `.done` regolare
- `deploy_cura.sh` → con il cervello **morto** esce **1** e dice "COLLAUDO
  FALLITO"; con il cervello **sano** esce **0**
- `stato_invisibili.sh` → vivo: exit 0 · morto: **exit 1**
- `buongiorno_1_11.sh` → morto: **exit 1**
- test suite: `tests/test_cervello_offline.py` **17 test + 17 subtest, tutti verdi**
  (regressione inclusa: il test reintroduce il bug e verifica che venga visto)
- suite completa del repo: **52 test + 24 subtest verdi**

## 7. COSA CHIEDO AL CAPO

1. **un `pull` + resurrezione** del cervello sul PC: era morto dalle 16:24.
   Con questa commit torna vivo e resta vivo (il gate lo impedisce).
2. **una regola nuova nel quaderno**: *"ogni collaudo deve poter dire FAILED"*.
   Un collaudo che può solo dire "ok" non è un collaudo.
3. **decidere il nome**: ho chiamato la cosa `--autoprova` e `gate_pubblicazione.py`.
   Se preferisci un altro nome (es. `--collaudo`, `portiere_gate.py`), si cambia
   in un attimo — dimmi tu.

## 8. LA LEZIONE (la metto in cima al quaderno)

> Il 1/11 un collaudo che non poteva fallire ha scritto "deploy riuscito" sopra
> un Portiere morto. Il guaio non era il bug: era il **collaudo che non poteva
> dire di no**. Da oggi ogni collaudo ha un'uscita che significa NO, e ogni
> file che non lo supera **non sale su master**.

> E il 1/11 sera, mentre riparavo, ho trovato lo stesso difetto **nel mio
> lavoro**: il collaudo condiviso, eseguito come programma, usciva 0 senza
> aver fatto niente. Tre script ci si reggevano sopra. La malattia è
> ereditaria: se il collaudo non lo testi in TUTTI i modi in cui lo usi, ti
> protegge solo da metà.
>
> Un agente che scrive codice a mezz'ora e un rito che lo pubblica ogni 45
> secondi, insieme, producono file spezzati che arrivano su master mentre
> tutto dice "verde". Da ogni lato due reti: **il codice si collauda da solo**
> (autoprova) e **il gate non lascia passare niente che non lo superi**.

---

## 9. AGGIORNAMENTO SERA (1/11) — round 2 e 3

### Le chiavi non stanno più nel repo (regola #3)

Il repo `bomberr91/posta` è **pubblico**. La chiave del gateway OmniRoute era
scritta **a mano** in 7 script. Ora si legge dal portachiavi
(`chiavi_env.sh` → `$OM_KEY`), e `collaudo_f2b4.sh` la prende
dall'ambiente dentro il blocco Python.

| file | prima | adesso |
|---|---|---|
| `fatti/accendi_omniroute_e_rilancia.sh` | chiave in chiaro | `${OM_KEY}` |
| `fatti/accendi_omniroute_2.sh` | chiave in chiaro | `${OM_KEY}` |
| `fatti/controlla_omni.sh` | chiave in chiaro | `${OM_KEY}` |
| `fatti/diagnosi_cervello.sh` | chiave in chiaro | `${OM_KEY}` |
| `fatti/consigliere_saggio.sh` | chiave in chiaro | `${OM_KEY}` |
| `fatti/motore_collaudo.sh` | chiave in chiaro | `${OM_KEY}` |
| `fatti/collaudo_f2b4.sh` | chiave in chiaro | `os.environ` |

> 🔴 **DA FARE TU (capo): ruota la chiave del gateway OmniRoute.**
> `sk-be31…` è stata pubblica — anche nella storia git. Io ho tolto la chiave
> dai file, ma **una chiave già pubblicata non si "togli"**: va cambiata.
> Tutte le altre chiavi del portachiavi non sono mai state nel repo.

### Due bug miei, trovati e corretti oggi

1. **`stato_carica()` perdeva la sezione `"sentinella"`** → a ogni riavvio gli
   occhi ripartivano da zero → falsi allarmi "promo pubblicata". Ora lo stato
   conserva **tutte** le sezioni (più quelle sconosciute), e scarta solo la
   spazzatura non-dict. Due test di regressione nuovi.
2. **i miei test vive scrivevano sul `portiere_log.jsonl` del PC** (il
   `logga()` scrive sul file vero). Ora i test di prova viva redirigono il log
   su un file temporaneo. Verificato: dopo la suite, i file runtime del PC
   hanno **md5 identico** a `HEAD`.

### Il gate ora è leggero

L'autoprova gira **solo se `cervello.py` è davvero cambiato** (il postino
girava ogni 45 s: non ha senso rifare un collaudo da 1,5 s quando non c'è
niente di nuovo).

### Altro collaudo ora condiviso

Anche `rito_nuovo`, `buongiorno_1_11`, `stato_invisibili`, `collaudo_fase1`
e `test_blackout` usano `fatti/collaudo_cervello.sh` e restituiscono un
codice di uscita che **vuol dire qualcosa**.

### Stato finale

- suite: **54 test + 24 subtest verdi** (19 + 17 nel file nuovo)
- `--autoprova`: **SUPERATA**

---

## 9b. AGGIORNAMENTO NOTTE (1/11) — round 4 e 5

**Il collaudo condiviso era MUTO in un modo.** `fatti/collaudo_cervello.sh`
definiva le funzioni ma **non le chiamava mai** quando veniva eseguito come
programma: usciva 0 senza aver fatto niente. I 6 deploy lo fanno con `.`
(sourced) e poi chiamano `collaudo` → quelli erano corretti. Ma **tre script
lo eseguivano** (`sveglia_sentinella`, `kilo_finale`, `prova_opencode2`) e
per loro il collaudo passava a vuoto: il cervello poteva restare morto e lo
script dire "tutto bene". Ora, se il file viene eseguito, il collaudo parte
da solo; se viene sourced, espone le funzioni. Entrambi i modi verificati.

**E i tre script che ammazzavano il cervello** ora chiamano il collaudo e
escono 1 se non torna (`prova_opencode2` dice NO anche se il *push* fallisce).

**Il workspace duplicava il repo.** Avevo fatto un secondo clone
(`~/posta_lavoro`) perché `~/posta_ponte` sembrava non poter pushare (lo
snapshot esclude `.git/config`). Ma `~/ponte.sh` ricuce la config: il ponte
era già un clone valido. Ora c'è **un solo clone** in `~/posta_ponte` e il
workspace è tornato da 47 a 39,5 MB.

## 10. LE DUE RETI DI SICUREZZA (le usa anche chi arriva dopo)

```bash
# 1) il cervello è vivo e sano? (struttura + prova vera, senza rete)
python3 cervello.py --autoprova        # exit 1 se qualcosa non torna

# 2) questo file può salire su master? (compila + autoprova)
python3 gate_pubblicazione.py           # exit 1 se qualcosa non torna
python3 gate_pubblicazione.py --escludi # i file da NON pubblicare
```

`--autoprova` fa due cose:
1. **controllo strutturale** (AST): ogni `self.X()` chiamato dentro una
   classe deve esistere come metodo (o ereditato da `BaseHTTPRequestHandler`).
   È il controllo **generico**: qualunque metodo annidato per sbaglio esce
   qui, prima di girare.
2. **prova viva**: avvia il cervello su una porta libera e gli fa una
   **richiesta chat vera** (il "ping" è risposto in casa: istantaneo, 0 token,
   ma attraversa comunque il codice che era rotto).

## 11. COME VERIFICARE TUTTO (60 secondi)

```bash
cd ~/posta
python3 cervello.py --autoprova     # deve dire "AUTOPROVA SUPERATA"
python3 -m pytest tests/ -q         # deve dire "54 passed, 24 subtests"
bash fatti/collaudo_cervello.sh     # deve dire "COLLAUDO OK"
```

## 12. COSA NON HO FATTO (aperto per il prossimo)

- **NON ho ruotato la chiave OmniRoute** (`sk-be31…`): è stata tolta dal repo
  ma è **stata pubblica** per un po'. → **il capo deve ruotarla** nel
  portachiavi e nel gateway locale. *(le altre chiavi del portachiavi non
  sono mai state nel repo)*
- **NON ho toccato** `portiere_quote.txt`, `portiere_regole.txt` e
  `portiere_profili.json`: restano da compilare col capo (è il pezzo 3 della
  `LISTA_LAVORI_FINALE`).
- **NON ho unito** i due `fatti/deploy_*` in un unico script: ho tenuto la
  forma attuale e ho messo il collaudo in comune.
- `deepdog_antiveleno.sh` e `scaglione1_applica_innesti.sh` **non parlano col
  cervello** (lavorano su beads/GitHub): non li ho toccati.

## 13. GLI SCRIPT CHE UCCIDEVANO IL CERVELLO (fatti)

Tre script facevano `pkill` del cervello e poi **non verificavano** che
tornasse: potevano lasciare il PC morto senza dirlo.

| script | prima | adesso |
|---|---|---|
| `sveglia_sentinella.sh` | kill + attesa + `curl` senza controllo | kill + `collaudo_cervello.sh` → **exit 1** se non torna |
| `kilo_finale.sh` | kill + attesa, niente | kill + `collaudo_cervello.sh` → **exit 1** se non torna |
| `prova_opencode2.sh` | kill + `sleep 3` + `grep` debole | kill + collaudo vero; e il **push** adesso dice NO se fallisce |

## 14. I COLLAUDI DIAGNOSTICI (fatti)

`fatti/collaudo_f2b1..4.sh` e `fatti/collaudo_gruppi_kilo.sh` leggevano le
chat con `curl … | python3 -c "json.load(sys.stdin)"`: **corpo vuoto =
traccia di errore**, e nessuno guardava l'uscita.

Ora usano il nuovo **`fatti/chat_leggi.sh`**:

```bash
bash fatti/chat_leggi.sh <timeout> <body-json> [espressione-python]
```

Che esce **1** e dice perché se la chat non risponde, e **0** con il campo
richiesto se risponde. Ogni collaudo diagnostico ha ora un contatore dei
problemi e finisce con `✅ … OK` (exit 0) o `❌ … FALLITO` (exit 1).

Nota: il controllo di **versione** (`FASE 2·B1`) è diventato un *avviso*: il
motore è a FASE 3 e non è un errore. La verifica vera è che la **targa
risponda**.

## 15. COME LAVORARE QUI (dal quaderno, in breve)

- **Strada A**: `cervello.py` RESTA il motore. Le idee si copiano dentro, non
  si sostituisce il motore.
- Una fase alla volta: **sandbox → anteprima al capo → ok → push**.
- `missione/REGOLE_VINCOLANTI.md` sono **vincolanti** (11 regole: costo zero,
  chiavi solo nel portachiavi, niente sonda LLM per ogni richiesta, porte
  20128/20129 intoccate, Python puro stdlib…).
- Il quaderno delle idee è in `missione/CERVELLO_MACCHINA_PERFETTA.md`
  (**64/64 idee chiuse** + la **idea 65** di questa sera).
- I risultati passano da `dal_pc/`, i comandi da `da_me/`.

---

## 16. LA NOTTE DEL POSTINO GELATO (1/11, ~19:02 → fine serata)

Il filo della sera: il capo ha chiesto di riprendere la giornata del morto.
Priorità al **mistero Deep Dog** (il 402 "Insufficient Balance"). La causa
è stata trovata e provata (vedi `dal_pc/deepdog_mistero.md`), il cerotto
scritto e consegnato al PC come job.

### Il vero ritrovamento della serata: **il postino si è GELATO**

Consegnato il primo cerotto, il postino ha risposto — ma la risposta era il
vecchio file di prima. Dopo **40 minuti** di coda muta, la diagnosi:

- il postino **non era morto**: era **appeso dentro un `git pull`** (classico
  prompt di credenziali su un TTY), con `flock -n` sul lock;
- nessuno poteva sostituirlo: il guardiano (`lavori/scorta_posta.sh`) usa
  `flock -n`, quindi saltava il giro;
- i compiti in coda (`da_me/`) **non arrivavano**, e non c'era una notizia.

La prova: il file di risposta di un compito non era nemmeno stato **troncato**
(la vecchia versione del postino scrive l'intestazione PRIMA di lanciare il
compito) → il ciclo dei compiti non era mai stato raggiunto.

**La regola che ne nasce: un canale che può fallire in silenzio è un canale
morto.** Il postino deve (a) non chiedere mai una password, (b) fallire in
fretta e dirlo, (c) essere guardato da qualcuno.

### Cosa è cambiato (commits `70563cb`, `ddafedc`)

| prima | adesso |
|---|---|
| `git pull` senza timeout, in silenzio | `timeout 120`, con `GIT_TERMINAL_PROMPT=0`, e se fallisce **lo dice** e rimedia (rebase/merge abort, stash drop, checkout dei file runtime) |
| nessuno guardava il postino | il guardiano legge `/tmp/postino_stato`: se resta sul pull oltre 3 minuti è **gelato** → lo ammazza e lo riavvia |
| il guardiano faceva `git pull -q` (niente `--rebase`) | `--rebase --autostash`, con timeout, e log in `/tmp/scorta_posta.log` |
| — | `fatti/sblocca_postino.sh`: **un comando solo** per sbloccare tutto e verificare che il postino sia vivo |

La lezione, come al solito: *anche il ponte verso il PC ha bisogno di un
collaudo che possa dire NO*. Il postino vecchio scriveva `.done` anche sui
compiti falliti — e i fallimenti scivolavano via senza rumore.

---

## 17. LA NOTTE DEL PONTE (1/11, 19:00 → 20:40) — quattro blocchi, zero bug di codice

Il capo ha chiesto: *"cervello, posta e postino: funzionano?"*. La risposta
onesta era **no**, e il motivo non era il codice. Quattro blocchi, in ordine:

| # | il blocco | la prova | la riparazione |
|---|---|---|---|
| 1 | **il postino gelato** in un `git pull` (prompt di credenziali), con `flock` tenuto: nessun compito visto, 40 minuti di coda muta | il file di risposta di un compito non era nemmeno stato **troncato** → il ciclo dei compiti non era mai stato raggiunto | `GIT_TERMINAL_PROMPT=0`, `timeout` su pull/push, **fallimento annunciato** e auto-rimedio, il guardiano legge `/tmp/postino_stato` e riconosce il gelo |
| 2 | **credenziali di push assenti** (`~/.posta_token`, `~/.posta_login`): le push del postino fallivano → il ramo locale divergeva → il pull entrava in rebase → conflitto | `warning: redirecting to https://github.com/bomberr91/posta.git/` (remote senza token) | token e login rimessi, remote con token, `rebase --abort` + `reset --hard` per riallineare |
| 3 | **push protection di GitHub**: una stringa-chiave dentro risposte e script archiviati → la commit intera respinta → il postino riprovava all'infinito | `push declined due to repository rule violations` (repo **senza** ruleset e **senza** branch protection: verificato via API → il problema era il contenuto) | filtro di pubblicazione nel postino (maschera ogni stringa lunga prima di committare, **mai** su `da_me/`), `fatti/sanifica_chiavi.sh` |
| 4 | **rebase interrotto** lasciato a metà → `reset` e `push` non potevano girare | `interactive rebase in progress; onto 50790bc` | `git rebase --abort` + `git reset --hard origin/main` |

### Cosa è rimasto, dopo

- **Cervello sul PC: SANO.** Il job `da_me/cervello_restart.sh` ha fatto
  pull → kill → risurrezione (25 s) → `/salute` → collaudo:
  `✓ targa: FASE 3 · ✓ salute: f3=True provider=62 motore=True · ✓ chat`
  → **COLLAUDO OK**. Risposta in `dal_pc/cervello_restart.md`.
- **Postino sul PC: VIVO.** Commit pushati da solo (`8328b8e`, `5581d33`).
- **Nessuna chiave pubblicata**: verificate su `origin/main` e su tutta la
  storia (OpenRouter, Exa, Tavily: mai uscite). Da ruotare resta **solo** la
  vecchia chiave OmniRoute, già segnalata.

### La regola che ne esce

*Un canale che può fallire in silenzio è un canale morto.* Per tre ore la
catena è stata ferma e sembrava un problema di permessi: in realtà era una
stringa in un file di testo. Ogni passaggio ha adesso un'uscita che significa
NO, e ogni fallimento **si annuncia** invece di scivolare via.

---

## 18. IL SECONDO AUDIT (ZCode, 1/11 sera) — 19 rilievi, 16 corretti

Un altro modello, un altro sguardo sugli stessi 3.000+ di `cervello.py`:
ha trovato la **stessa classe di bug** del 1/11 (l'*"empty reply"*: la
connessione chiusa a vuoto senza nessun errore) e l'ha chiamata per nome.

**Prima ondata — le 3 critiche** (F1, F2, F3): il body malformato ammazzava
la connessione; una riga con `http://` nella lista ammazzava **tutta** la
richiesta invece di fare failover; un campo corrotto in `portiere_stato.json`
metteva in empty reply **ogni** chat.

**Seconda onda — 13 rilievi** (F4, F5, F6, F7, F8, F9, F10, F11, F12, F13,
F14, F15, F16, F18): stato che si perde al riavvio; la sentinella che
blocca 32 secondi la prima richiesta del giorno (e il client che ritenta =
doppio costo); fino a **9 minuti fatturati per una richiesta** (timeout motore
180s + riserva 5×60s + retry su esito ignoto + risposte oltre il tetto
rimescolate come errori di rete); il freno preventivo che non frenava (corsa
fra controllo e registrazione); la cache e le iterazioni sui castighi che
facevano morire richieste **già riuscite**; la rotazione del log non atomica
che girava dentro la richiesta; catalogo e appello scritti a metà (JSON
tronco → routing sordo in silenzio).

**Restano due, e non sono bug:**
- **F17** — la politica "gratis" scarta le chiavi free vere e tiene solo le
  keyless: se i keyless sono giù, la policy "gratis" dà 503 anche con dieci
  chiavi free sane. **È una scelta, non un difetto**: se la intesa era
  "tutto ciò che non costa", va cambiata in `("keyless", "free-ricorrente")`.
- **F19** — igiene cosmetica (`open()` senza `with`): solo warning.

**Il metodo è quello che ha funzionato**: per ogni correzione c'è un test
che **fallisce sul codice vecchio** e passa su quello nuovo. La suite è
passata da 19 a **24 test**, autoprova e gate verdi.
