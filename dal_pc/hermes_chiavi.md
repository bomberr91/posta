# Risposta a «hermes_chiavi»

_04/11/2026 11:35 · FilippoPC_

### 1. CONFIG.YAML DI HERMES (Windows)
  provider = "custom"
  model = # Default model to use (can be overridden with --model flag)
  base_url = "http://127.0.0.1:20129/v1"
  api_key -> len=54 sha12=c48a3514bbbd sk_cervello=no

### 2. AUTH.JSON (credential_pool)
  gemini: auth_type=api_key base_url=https://generativelanguage.googleapis.com/v1beta secret -> vuoto
  (top-level) updated_at -> len=32 sha12=c2d0ceaf3590 sk_cervello=no

### 3. .ENV DI HERMES (nomi + impronte)
  --- /mnt/c/Users/giopi/AppData/Local/hermes/.env
      GOOGLE_API_KEY -> len=53 sha12=ce0dea903a90 sk_cervello=no

### 4. VARIABILI D'AMBIENTE CON NOME DA CHIAVE (solo nel processo del postino)
  OPENCODE_API_KEY -> len=51 sha12=d825653e297b sk_cervello=no

FINE

<!-- fine hermes_chiavi -->
