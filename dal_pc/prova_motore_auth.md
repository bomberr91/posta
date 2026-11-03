# Risposta a «prova_motore_auth»

_03/11/2026 09:56 · FilippoPC_

## Chiave OmniRoute in giro (chiavi_env.sh / env)
- /home/agenti/posta/chiavi_env.sh:
    OM_KEY=$(chiave_di '^[[:space:]]*[-*].*[Oo]mniroute|omniroute' 'sk-[A-Za-z0-9-]{16,}')  # OmniRoute (centralino locale)
    export OPENAI_API_KEY="${OM_KEY:-sk-omniro…}"
    export OMNIROUTE_API_KEY="${OM_KEY:-sk-omniro…}"
      printf '  %-22s %s\n' "OmniRoute"      "$([ -n "${OM_KEY:-}" ] && echo '✓ trovata' || echo '— assente (il motore usa la sua)')"

## Chat sul motore: SENZA e CON Authorization
- SENZA Authorization: HTTP 200 | modello=command-a-reasoning-08-2025 | contenuto='Okay, the user wants me to respond with just "OK". Let me ma'
- chiave trovata: si (12 caratteri)
- CON Authorization Bearer: HTTP 200 | modello=command-a-reasoning-08-2025 | contenuto='Okay, the user wants me to respond with just "OK". Let me ma'

## GET /v1/models con e senza chiave
- /v1/models senza: HTTP 401 Unauthorized
- /v1/models con Bearer: HTTP 401 Unauthorized

## Il portiere manda l'Authorization al motore?
    1060:def inoltra(corpo, percorso="chat/completions", secondi=None, sessione=""):
    1061-    """Passa la richiesta al motore. Ritorna il JSON o None.
    1062-    CURA-AUDIT: la risposta si legge fino a un tetto: un provider rotto o
    1063-    ostile non deve poterci svuotare la memoria."""
    1064-    try:
    1065-        intestazioni = {"Content-Type": "application/json"}
    1066-        if sessione:

<!-- fine prova_motore_auth -->
