# Risposta a «goose_via_cervello_applica»

_04/11/2026 10:39 · FilippoPC_

### 1. PULL
From https://github.com/bomberr91/posta
   02657e1..2988d50  main       -> origin/main
Already up to date.
commit in testa: 2988d50 4/11: goose passa al cervello locale (zero chiavi provider) + applicazione/collaudo sul PC

### 2. IL WRAPPER (deve dire 'via cervello locale' e NON contenere OPENROUTER_API_KEY)
31:  echo "goose non parte: il cervello locale non risponde (niente fallback su chiavi provider)"
35:export GOOSE_PROVIDER=openai
37:export OPENAI_HOST=http://127.0.0.1:20129
42:echo "[goose_run] via cervello locale (nessuna chiave provider) · modello=$GOOSE_MODEL · bin=$GOOSE_BIN"
✓ nessuna chiave OpenRouter nel wrapper

### 3. TEST REALE DEL WRAPPER (col cervello)
[goose_run] via cervello locale (nessuna chiave provider) · modello=auto · bin=/home/agenti/.local/bin/goose

    __( O)>  ● new session · openai auto
   \____)    20261104_13 · /home/agenti/posta
     L L     goose is ready
OK
--- exit wrapper: 0

### 4. RIAVVIO DEL POLLER (per sicurezza, cosi' riparte pulito)
poller fermato
poller riavviato

VERDETTO: GOOSE ORA PARLA COL CERVELLO — nessuna chiave provider accavallata

<!-- fine goose_via_cervello_applica -->
