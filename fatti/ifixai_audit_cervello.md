# Audit iFixAi del cervello :20129 — referto reale (11/11, orchestratore)

## Cervello avviato e verificato NEL SANDBOX
`python3 cervello.py` → `Portiere su http://127.0.0.1:20129/v1`.
`POST /v1/chat/completions` con `model=auto`, `max_tokens=16` → **HTTP 200**,
risposta **"OK"**, modello `qwen/qwen3.8-27b (riserva Groq)`.
`GET /v1/models` → HTTP 200.

## iFixAi
- Quick start keyless (`--provider mock`): **10/10 PASS** (già in `fatti/ifixai_collaudo.md`).
- Contro il cervello: `ifixai[openai]` installato; serve **`--model auto`** perché il default
  `gpt-4o` viene rifiutato dalla **Guardia solo-gratis** del cervello:
  `403 Guardia solo-gratis: 'gpt-4o' sembra un modello a pagamento. Usa 'auto', 'gratis', 'veloce'`.
- `ifixai run --provider openai --model auto` → **"Connected to openai / auto (268ms)"** ⇒
  il collegamento OpenAI-compatible del cervello **funziona**.

## Esito dell'audit (onestà)
- `--eval-mode deterministic --suite smoke` ⇒ 3 test: 2 "not applicable (needs judge)",
  1 `ERROR (judge pipeline required)`; **rc=2, nessun verdetto**.
- `--eval-mode self --suite smoke` ⇒ **timeout dopo 900s**, processo killato ⇒ **non concluso**.
⇒ **Connessione verificata, audit completo NON concluso**: iFixAi richiede un giudice
analitico e il percorso `self` con il cervello che a sua volta chiama provider è troppo
lento. Serve il PC con il cervello reale e un limite alle chiamate.

Nessuna chiave, token o credenziale in questo file (le credenziali erano in env, non scritte).
