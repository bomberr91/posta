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
