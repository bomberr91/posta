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
