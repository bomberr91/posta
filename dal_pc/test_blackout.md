# Risposta a «test_blackout»

_31/10/2026 16:24 · FilippoPC_

## TEST DEL BLACKOUT: IL CERVELLO DA SOLO — 16:24

### 1. Spengo OmniRoute
spento
✓ porta 20128 MORTA — il cervello e' solo

### 2. auto (deve rispondere la RISERVA)
openai-fast (riserva Pollinations) → Sono qui, pronto a darti una risposta anche quando il motore è morta.

### 3. migliore (senza motore → riserva coi modelli FORTI)
@cf/meta/llama-3.3-70b-instruct-fp8-fast (riserva Cloudflare Workers AI) → 391

### 4. gratis (solo keyless)
? → Nessun provider della politica 'gratis' ha risposto. Prova con 'auto'.

### 5. ping in casa + cache (2 volte stessa domanda)
cervello/locale (ping: risposta in casa, 0 token)
1ª: @cf/meta/llama-3.3-70b-instruct-fp8-fast (riserva Cloudflare Workers AI)
2ª: @cf/meta/llama-3.3-70b-instruct-fp8-fast (riserva Cloudflare Workers AI) (cache)

### 6. Chi ha lavorato (glass-box, ultime 8)
{"tipo": "richiesta", "agente": "cervello-2de5c12e398bc6e0", "politica": "auto", "rotta": "riserva", "provider": "pollinations", "modello": "openai-fast", "ms": 6572, "tentativi": 1, "quando": "2026-10-31 16:24:34"}
{"tipo": "errore-riserva", "provider": "pollinations", "modello": "openai-fast", "errore": "breve", "codice": 402, "tentativo": 2, "quando": "2026-10-31 16:24:37"}
{"tipo": "richiesta", "agente": "cervello-2de5c12e398bc6e0", "politica": "migliore", "rotta": "riserva", "provider": "cloudflare", "modello": "@cf/meta/llama-3.3-70b-instruct-fp8-fast", "ms": 3461, "tentativi": 3, "quando": "2026-10-31 16:24:38"}
{"tipo": "errore-riserva", "provider": "pollinationsfree", "modello": "openai-fast", "errore": "breve", "codice": 402, "tentativo": 2, "quando": "2026-10-31 16:24:41"}
{"tipo": "fallita", "agente": "cervello-2de5c12e398bc6e0", "politica": "gratis", "rotta": "riserva", "quando": "2026-10-31 16:24:41"}
{"tipo": "banale", "agente": "cervello-2de5c12e398bc6e0", "rotta": "locale", "ms": 0, "quando": "2026-10-31 16:24:41"}
{"tipo": "richiesta", "agente": "cervello-2de5c12e398bc6e0", "politica": "auto", "rotta": "riserva", "provider": "cloudflare", "modello": "@cf/meta/llama-3.3-70b-instruct-fp8-fast", "ms": 7855, "tentativi": 1, "quando": "2026-10-31 16:24:49"}
{"tipo": "cache", "agente": "cervello-2de5c12e398bc6e0", "rotta": "cache", "ms": 0, "quando": "2026-10-31 16:24:51"}

### 7. /cervello
motore: False · adesso: Pollinations (senza chiave) · riserve pronte: 7

<!-- fine test_blackout -->
