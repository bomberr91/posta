# Risposta a «deepdog_fix»

_01/11/2026 20:31 · FilippoPC_

## 🐕 IL CEROTTO DI DEEP DOG — 01/11 20:31
### 1. Lo stato PRIMA (le prove sul posto)
— le tre catene che il wrapper scrive:
127:        supervisor...=[os.environ.get("SUPERVISOR_MODEL", "deepseek-v4-flash")],
128:        subagent_m...=[os.environ.get("SUBAGENT_MODEL", "deepseek-v4-flash")],
129:        draft_repo...=[os.environ.get("DRAFT_REPORT_MODEL", "deepseek-v4-flash")],
— la mappa OpenRouter di Deep Dog (i nomi che CONOSCE):
714:_OPENROUTE... = {
715-    "deepseek-v4-pro": "deepseek/deepseek-v4-pro",
716-    "deepseek-v4-flash": "deepseek/deepseek-v4-flash",
717-    "mimo-v2.5": "xiaomi/mimo-v2.5",
718-    "mimo-v2.5-pro": "xiaomi/mimo-v2.5-pro",
719-}
720-
— il default del provider nel Setup:
59:    model_provider: str = "openrouter" if os.environ.get("OPENROUTER_API_KEY") else "deepseek"
— ROUTE_VIA_OPENROUTER nel .env:
EXA_API_KEY=
OPENROUTER_API_KEY=sk-or-v1-8...…(mascherata)
TAVILY_API_KEY=tvly-dev-1...…(mascherata)
ROUTE_VIA_OPENROUTER=true
WEB_SEARCH_ENGINE=both
EXA_API_KEY=cc3a11cf-c...…(mascherata)

### 2. Applico il cerotto (idempotente, con backup)
   il cerotto c'è già: non lo tocco (idempotente)
— il file adesso:
127:        supervisor...=[os.environ.get("SUPERVISOR_MODEL", "deepseek-v4-flash")],
128:        subagent_m...=[os.environ.get("SUBAGENT_MODEL", "deepseek-v4-flash")],
129:        draft_repo...=[os.environ.get("DRAFT_REPORT_MODEL", "deepseek-v4-flash")],
59:    model_provider: str = "openrouter" if os.environ.get("OPENROUTER_API_KEY") else "deepseek"

— compila?
   ✓ web_app.py compila

### 3. Collaudo dal vivo
— server di collaudo avviato (pid 954) sulla porta 8766, aspetto…
   ✓ porta 8766 aperta
— /api/setup (la configurazione):
   {"configured": {"DEEPSEEK_API_KEY": false, "EXA_API_KEY": true, "OPENROUTER_API_KEY": true, "TAVILY_API_KEY": true}, "model_provider": "openrouter", "search_provider": "exa", "speed_profile": "fast", "ready": true, "missing": []}

   ✓ missing: NESSUNA · provider: openrouter

— una MICRO-ricerca vera (deve rispondere, niente 402):
   stato: completed
   eventi:
     - Ricerca avviata
     - Configurazione verificata
     - Preparazione del piano di ricerca
     - Piano di ricerca completato
     - Creazione della prima bozza
     - Prima bozza completata
     - Il supervisore coordina gli agenti
     - Il supervisore coordina gli agenti
     - Scrittura del report finale
     - Citazioni verificate
     - Ricerca completata
   estratto del report:
      Roma è la capitale d'Italia.

✅ CEROTTO APPLICATO E COLLAUDATO — la ricerca è uscita pulita (niente 402)
   il TUO server sulla 8765 non è stato toccato: riavvialo col .bat
   (la scelta del Setup ora resta su disco: setup_state.json)

<!-- fine deepdog_fix -->
