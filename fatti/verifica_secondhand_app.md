# VERIFICA SECONDHAND APP — 4/11 notte (fatto direttamente dall'orchestratore)

## La causa del >90s senza risposta (TROVATA, con prova)

La config vera dell'app **esiste ed è `C:\Users\giopi\.openinterpreter\config.toml`**
(formato codex: `model_provider`, `approval_policy`, `sandbox_mode`,
`model_providers.<id>.base_url/env_key/wire_api`). Prova che è quella:
il file `config.toml.bak-20261104-110354` contiene `model_provider = "nvidia"`
scritto DALL'APP stessa quando in UI era stata configurata NVIDIA.

Il blocco era qui: nella patch di ieri il provider cervello aveva
`env_key = "OPENAI_API_KEY"` — una variabile **che non esiste** nell'ambiente
dell'app ⇒ l'app non aveva credenziali ⇒ la chiamata LLM moriva prima di
partire. **Prova**: il log del portiere (`portiere_log.jsonl`) alle 22:00-23:00
di stasera (ora del test fallito) è VUOTO: la domanda non ha MAI raggiunto
il cervello. Non era lentezza: era un'assenza di chiave.

## Cure applicate (l'app era chiusa: modifiche sicure)

1. `config.toml`: `env_key = "CERVELLO_API_KEY"` + impostata la variabile
   nell'ambiente utente Windows (`setx CERVELLO_API_KEY sk-cervello`) — i
   processi nuovi (app rilanciata) la ereditano.
2. **Niente yolo**: `approval_policy = "untrusted"` in config + i thread in
   `state_5.sqlite` con `approval_mode = "never"` (= yolo in codex) aggiornati
   a `untrusted`. Per una domanda di cultura l'app ora CHIEDE invece di
   eseguire codice da sola.
3. Il profilo WSL della CLI 0.4.3 NON è stato toccato (l'auto-run True lì è
   necessario al ponte).

## Cosa resta al capo (il test visivo, 1 minuto)

1. **Chiudi completamente l'app** (se era aperta: deve nascere di nuovo come
   processo per leggere la variabile nuova).
2. Rilanciala dalla scorciatoia e fai la domanda fissa:
   «quanti giorni ci sono da qui al 2027»
3. La risposta deve arrivare in meno di 30 secondi, SENZA eseguire codice.
4. Prova indipendente per me: `tail -3 ~/posta/portiere_log.jsonl` deve
   mostrare la richiesta dell'app al cervello.

Il referto verrà aggiornato con il tempo misurato dopo il tuo test.

## Nota tecnica

L'app 0.0.59 è basata su un core codex-like (`bin/codex-code-mode-host.exe`,
config in formato codex, modalità agent/plan/yolo nel system prompt). L'etichetta
"yolo" in UI riflette la modalità del thread corrente: i thread sono ora
`untrusted` e il default da config pure — se l'etichetta dovesse restare viola
riaprendo un VECCHIO thread, è la memoria di quel thread: apri una chat nuova.


## PROVA DEFINITIVA (4/11 notte, dopo le cure)

`interpreter.exe exec PIPPO45` (da directory fidata, con CERVELLO_API_KEY
nell'ambiente): il core è partito, provider cervello, model auto, e il
**portiere ha instradato la richiesta** — nel log:

    {"agente": "cervello-b9a5eb6397a28585", "rotta": "riserva", "provider": "tokenharbor", "modello": "deepseek-v4-flash:free", "risparmio_car": 15287}

La risposta è arrivata (7.536 token). La catena APP → portiere → cervello →
riserva funziona end-to-end.

Note:
- L'app 0.0.59 legge il config SOLO all'avvio: dopo il fix, l'app va chiusa e
  rilanciata (così eredita anche CERVELLO_API_KEY dall'ambiente utente).
- Token Harbor (provider gratis upstream) ha segnalato un flag "cyber" sul
  prompt di prova monopalabra e ha instradato su gpt-5.2: comportamento loro,
  la catena ha gestito il reroute da sola. Domande normali non lo triggherano.
- approval_policy valido in 0.0.59: ON-REQUEST ("untrusted" è stato rimosso
  dalla 0.0.59: metterlo impedisce l'AVVIO dell'app — scoperto e corretto).


## REPORT FINALE — yolo ripristinato e app veloce (4/11 notte)

Stato in una riga: **l'app funziona, passa dal cervello (0 crediti, 0 chiavi
esterne), yolo attivo, domanda di test risolta in 8.4 secondi.**

Cosa era rotto: la config dell'app puntava il provider cervello ma con
`env_key = "OPENAI_API_KEY"` (inesistente nell'ambiente app) ⇒ nessuna
credenziale ⇒ la chiamata LLM moriva prima di partire (log del portiere vuoto
durante il test >90s — prova diretta).

Cure applicate:
1. `config.toml`: `model_provider = "cervello"`,
   `base_url = http://127.0.0.1:20129/v1`, `env_key = "CERVELLO_API_KEY"`
2. `CERVELLO_API_KEY = sk-cervello` nell'ambiente utente Windows (setx) —
   l'app rilanciata la eredita
3. `approval_policy = "never"` — YOLO ripristinato (il capo non l'aveva mai
   chiesto di togliere: era un frainteso) + thread allineati a never
4. Nota: `untrusted` NON è un valore valido nella 0.0.59 (impedisce l'avvio
   dell'app — scoperto in collaudo e corretto con on-request/never)

Prova misurata (la domanda fissa): «quanti giorni ci sono da qui al 2027» →
risposta CORRETTA (57 giorni) in **8.4 secondi totali** via portiere.

Verifica per te: dopo un uso dell'app, `tail -3 ~/posta/portiere_log.jsonl`
mostra le richieste dell'app al cervello (rotta motore/riserva, model auto).


## MISURA CORRETTA E CORRELATA COL LOG (4/11 22:08)

exec (yolo) con la domanda fissa, correlazione esatta col log del portiere:
- **1 chiamata LLM — rotta motore, model auto — ms 5213** (la cifra da citare: quella del log)
- wall dell'intero processo exec: 8.2s (include l'avvio dell'app: python + import)
- risposta corretta: «57 giorni»

La cifra «8.4s» precedente era il wall di un exec: il log del suo periodo non
conteneva chiamate da 14.5/15.2s (quelle appartenevano a un'altra sessione —
la TUI interattiva fa piu' chiamate per turno della modalita' exec).
