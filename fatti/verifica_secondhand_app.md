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
