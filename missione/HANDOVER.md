# 🔁 HANDOVER — CERVELLO MACCHINA PERFETTA

**Ultimo aggiornamento: 1/11/2026 sera (Arena, per il capo)**
Leggi questo file **prima** di toccare `cervello.py`, `postino.sh` o i `fatti/deploy_*.sh`.
Se un altro agente ti passa il progetto, comincia da qui.

---

## 0. LA NOTIZIE IN TRE RIGHE

Il 1/11 alle 16:24 una commit ha rotto il Portiere in due punti. **Il cervello
non rispondeva a nessuna chat** e nessun collaudo poteva accorgersene, perché
i collaudi non potevano dire "FALLITO". Tutto è stato corretto il 1/11 sera.
**Se leggi solo una cosa: la sezione 5 (le due reti di sicurezza).**

---

## 1. COSA ERA ROTTO (e come si era rotto)

Commit `3164d7f` ("CURA-AUDIT applicata…", 1/11 **16:24**), cioè un rito
di "cura" che riscriveva funzioni del cervello.

| # | Difetto | Effetto |
|---|---|---|
| ① | `_sessione()` **annidato dentro `_rispondi()`** (8 spazi invece di 4) | `H._sessione` non esisteva → `AttributeError` → il server chiudeva la connessione **senza rispondere** → **ogni** chat a `:20129` moriva con "empty reply from server" |
| ② | `NOME = "Portiere"` **cancellata** | `NameError` su `/cervello` e `/portiere.json` (il cruscotto di ZCode) |

In tutti i commit precedenti `_sessione` era al posto giusto. La causa era
un'indentazione sbagliata in una riscrittura: **sintassi Python valida,
semantica sbagliata** — il tipo di difetto che nessun `py_compile` vede.

**Quanto è stato morto:** dalle 16:24 alle 17:26 (l'ora del push della
correzione). Tutti gli agenti che parlavano col Portiere in quel lasso non
ricevevano nulla.

## 2. PERCHÉ NESSUNO SE N'ERA ACCORTO

| Il collaudo di prima | Il buco |
|---|---|
| `curl -s -m 10/15 ...` | timeout 5-20s **contro il budget del motore** (`timeout_motore` 180s + 5×`timeout_riserva` 60s ≈ 480s): **non distingue "rotto" da "lento"** |
| `\| python3 -c "json.load(sys.stdin)"` | corpo vuoto → `JSONDecodeError` → ma **nessuno guardava il codice di uscita** |
| script di deploy senza `set -e` | l'errore non fermava nulla → il `.done` veniva scritto lo stesso |
| `postino.sh` | **non guardava MAI l'uscita del job** → un job fallito era archiviato come fatto |

La prova è in `dal_pc/deploy_cura.md` (1/11 17:24): la `JSONDecodeError` era
stampata **sotto** la riga "deploy riuscito".

## 3. COSA HO CORRETTO (file per file)

### `cervello.py`
- **`_sessione()`** riportato a metodo di classe `H` (il bug ①).
- **`NOME = "Portiere"`** ripristinato (il bug ②).
- `stato_carica()`: **valida** lo stato su disco (tipi sbagliati → ricostruiti)
  e **conserva tutto**, `sentinella` compresa (se no, a ogni riavvio gli occhi
  ripartono da zero → falsi allarmi promo).
- `vivo()`: la porta la decide lo schema (**443** per https, non 80) e l'IPv6
  va fra parentesi.
- `a_pagamento()`: chiusa la **famiglia** dei piani Gemini `pro`/`ultra`
  (prima bloccava solo `gemini-2.5-pro`); la scappatoia `:free`/`-free`/`oss`
  vince sempre.
- `max_tokens`: tetto in `CONFIG["max_tokens"]` (8000); i valori non interi
  vengono scartati.
- `inoltra()` e la riserva: **tetto di byte letti** (`CONFIG["risposta_max"]`).
- `freno()` / `batte()`: **atomici** sotto `LOCK`, e i battiti hanno un tetto
  (`CONFIG["battiti_max"]`) invece di crescere all'infinito.
- `regola_di()`: vince il prefisso **più lungo**; le chiavi vuote non valgono
  per tutti.
- `castiga()` e le sessioni: sotto `LOCK` (`min()` su una mappa che un altro
  thread svuota = `RuntimeError` a caso).
- import dei moduli F3: **solo `ImportError`** (un errore interno non deve
  spegnere compressione e profili in silenzio).
- `GET /salute`: il riscontro veloce (vivo? configurato? struttura pulita?).

### `postino.sh`
- Il `.done` si scrive **solo** con uscita 0. Altrimenti: `.failito` + il
  compito **resta da fare**, fino a 3 tentativi, poi `.abbandonato`.
- `sync_up()` passa dal **gate** prima di pubblicare.

### `gate_pubblicazione.py` (NUOVO)
Prima di pubblicare: ogni `.py` modificato deve **compilare**, e `cervello.py`
deve **passare l'autoprova**. Se no → il file **non sale su master** (il
lavoro resta in locale, nessuna perdita) e l'avviso finisce in
`dal_pc/gate_pubblicazione.txt`.
L'autoprova gira **solo** se `cervello.py` è davvero cambiato.

### `fatti/collaudo_cervello.sh` (NUOVO) — il collaudo condiviso
Timeout coerenti col budget del motore, ogni passo verifica davvero,
l'uscita significa **NO** quando qualcosa non torna.
Lo usano: `deploy_cura` · `deploy_f3` · `deploy_cors` · `deploy_json_ricco` ·
`deploy_sentinella2` · `deploy_sent_pagine` · `rito_nuovo` ·
`buongiorno_1_11` · `stato_invisibili` · `collaudo_fase1` · `test_blackout`.

### `tests/test_cervello_offline.py` (NUOVO)
19 test + 17 subtest. Include la **regressione**: il test reintroduce il bug
originale e verifica che il controllo strutturale lo veda.

### Chiavi fuori dal repo
La chiave del gateway OmniRoute era **scritta a mano in 7 script** di un repo
**pubblico**. Ora si legge dal portachiavi (`chiavi_env.sh` → `OM_KEY`),
come dice la regola #3.

---

## 4. LA REGOLA NUOVA (mettila in cima al quaderno)

> **IDEA 65 — ogni collaudo deve poter dire "FALLITO".**
> Un collaudo che può solo dire "ok" non è un collaudo: è una stampa.
> E ogni file che non supera il suo collaudo **non sale su master**.

## 5. LE DUE RETI DI SICUREZZA (le usa anche chi arriva dopo)

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

## 6. COME VERIFICARE TUTTO (60 secondi)

```bash
cd ~/posta
python3 cervello.py --autoprova     # deve dire "AUTOPROVA SUPERATA"
python3 -m pytest tests/ -q         # deve dire "54 passed, 24 subtests"
bash fatti/collaudo_cervello.sh     # deve dire "COLLAUDO OK"
```

## 7. COSA NON HO FATTO (aperto per il prossimo)

- **NON ho ruotato la chiave OmniRoute** (`sk-be31…`): è stata tolta dal repo
  ma è **stata pubblica** per un po'. → **il capo deve ruotarla** nel
  portachiavi e nel gateway locale. *(le altre chiavi del portachiavi non
  sono mai state nel repo)*
- **NON ho toccato** `portiere_quote.txt`, `portiere_regole.txt` e
  `portiere_profili.json`: restano da compilare col capo (è il pezzo 3 della
  `LISTA_LAVORI_FINALE`).
- **NON ho unito** i due `fatti/deploy_*` in un unico script: ho tenuto la
  forma attuale e ho messo il collaudo in comune.
- Gli script storici (`collaudo_f2b1..4`, `kilo_finale`, `sveglia_sentinella`,
  `prova_opencode2`, `deepdog_antiveleno`, `scaglione1_applica_innesti`) **non
  usano** ancora il collaudo condiviso: verificano cose diverse dal
  funzionamento del cervello, ma se ne tocchi uno attenzione al pattern
  `curl … | python3 -c "json.load(sys.stdin)"` (corpo vuoto = errore
  silenzioso).

## 8. LA LEZIONE (da non dimenticare)

> Il guaio non era il bug: era **il collaudo che non poteva dire di no**.
> Un agente che scrive codice a mezz'ora e un rito che lo pubblica ogni 45
> secondi, insieme, producono questo: file spezzati che arrivano su master
> mentre tutto dice "verde". Da ogni lato ci sono due reti: **il codice si
> collauda da solo** (autoprova) e **il gate non lascia passare niente che non
> lo superi**.

## 9. COME LAVORARE QUI (dal quaderno, in breve)

- **Strada A**: `cervello.py` RESTA il motore. Le idee si copiano dentro, non
  si sostituisce il motore.
- Una fase alla volta: **sandbox → anteprima al capo → ok → push**.
- `missione/REGOLE_VINCOLANTI.md` sono **vincolanti** (11 regole: costo zero,
  chiavi solo nel portachiavi, niente sonda LLM per ogni richiesta, porte
  20128/20129 intoccate, Python puro stdlib…).
- Il quaderno delle idee è in `missione/CERVELLO_MACCHINA_PERFETTA.md`
  (**64/64 idee chiuse** + la **idea 65** di questa sera).
- I risultati passano da `dal_pc/`, i comandi da `da_me/`.
