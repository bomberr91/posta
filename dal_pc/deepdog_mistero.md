# Risposta a «deepdog_mistero»

_01/11/2026 17:09 · FilippoPC_

## 🕵️ IL MISTERO DEL CANE — 17:09
### 1. La logica del Setup (web_app.py, cuore della validazione)
HOST, PORT = "127.0.0.1", 8765
LOCK = threading.Lock()
SUPPORTED_KEYS = (
    "DEEPSEEK_API_KEY",
    "EXA_API_KEY",
    "OPENROUTER_API_KEY",
    "TAVILY_API_KEY",
)
@dataclass
class SetupState:
    keys: dict[str, str] = field(default_factory=dict)
    model_provider: str = "deepseek"
    search_provider: str = "exa"
    speed_profile: str = "fast"
@dataclass
class JobState:
    status: str = "idle"
    message: str = "Pronto per una nuova ricerca"
    prompt: str = ""
    report: str = ""
    error: str = ""
    events: list[str] = field(default_factory=list)
    started_at: float | None = None
    finished_at: float | None = None
    cancellation: CancellationToken | None = None
STATE = JobState()
SETUP = SetupState()
EVENT_LABELS = {
    "run_started": "Ricerca avviata",
    "config_validated": "Configurazione verificata",
    "scope_started": "Preparazione del piano di ricerca",
    "scope_completed": "Piano di ricerca completato",
    "draft_started": "Creazione della prima bozza",
    "draft_completed": "Prima bozza completata",
    "supervisor_iteration": "Il supervisore coordina gli agenti",
    "delegation_started": "Ricerca delegata a un agente",
    "subagent_started": "Agente di ricerca avviato",
    "subagent_completed": "Agente di ricerca completato",
    "subagent_failed": "Un agente ha segnalato un errore",
    "source_found": "Nuova fonte trovata",
    "source_read": "Analisi di una fonte",
    "source_saved": "Fonte salvata",
    "report_started": "Scrittura del report finale",
    "citations_validated": "Citazioni verificate",
    "run_completed": "Ricerca completata",
    "run_failed": "Ricerca non riuscita",
}
def app_config(setup: SetupState | None = None) -> RunConfig:
    selected = setup or SETUP
    fast = selected.speed_profile == "fast"
    use_openrouter = selected.model_provider == "openrouter"
    return RunConfig(
        supervisor_model_fallback_chain=["deepseek-flash"],
        subagent_model_fallback_chain=["deepseek-flash"],
        draft_report_model_fallback_chain=["deepseek-flash"],
        disable_model_fallback=True,
        route_via_openrouter=use_openrouter,
        supervisor_route_via_openrouter=use_openrouter,
        subagent_route_via_openrouter=use_openrouter,
        draft_route_via_openrouter=use_openrouter,

### 2. Dove salva la scelta? C'è un file di setup persistito?
74:SETUP = SetupState()
89:    "source_saved": "Fonte salvata",
98:    selected = setup or SETUP
123:        subagent_max_saves=6 if fast else 10,
129:        save_report_to_file=False,
138:            keys=dict(SETUP.keys),
139:            model_provider=SETUP.model_provider,
140:            search_provider=SETUP.search_provider,
141:            speed_profile=SETUP.speed_profile,
243:</div><div class="actions"><button id="saveSetup">Salva setup</button><span id="setupMessage" class="meta"></span></div><p class="setup-note">I campi vuoti mantengono le chiavi già caricate dal file .env o inserite in questa sessione. Deep Dog non mostra mai una chiave salvata.</p></div></section>

### 3. INTERROGO IL SERVER DAL VIVO (20 secondi)
— /api/status → {"status": "failed", "message": "Ricerca terminata: failed", "report": "", "error": "APIStatusError: Error code: 402 - Insufficient Balance (request_id: 19fc2736-cda0-4718-940f-43405a074d62)", "events": ["Ricerca avviata", "Configurazione verificata", "Preparazione del piano di ricerca", "Ricerca non riuscita"], "elapsed_seconds": 1}
— /api/setup → {"configured": {"DEEPSEEK_API_KEY": true, "EXA_API_KEY": true, "OPENROUTER_API_KEY": true, "TAVILY_API_KEY": true}, "model_provider": "openrouter", "search_provider": "both", "speed_profile": "fast", "ready": true, "missing": []}
— /status → {"error": "Risorsa non trovata"}
— /api/config → {"error": "Risorsa non trovata"}
— /api/state → {"error": "Risorsa non trovata"}

### 4. log d'avvio del server

<!-- fine deepdog_mistero -->

---

## 🔬 IL MISTERO È RISOLTO (1/11 sera, Arena) — la causa, provata

L'ipotesi che il Setup chiedesse `DEEPSEEK_API_KEY` anche con OpenRouter
selezionato era giusta, ma la **causa** era un'altra, e nessuna delle due
era nel `.env`.

### Il colpevole n.1 — un nome di modello che Deep Dog non conosce

`web_app.py` (il wrapper Windows) scriveva tre catene così:

```python
supervisor_model_fallback_chain=["deepseek-flash"],
subagent_model_fallback_chain=["deepseek-flash"],
draft_report_model_fallback_chain=["deepseek-flash"],
```

Ma in `deep_research/config.py` la mappa dei modelli instradabili su
OpenRouter è:

```python
_OPENROUTER_MODEL_MAP_BY_NAME = {
    "deepseek-v4-pro": "deepseek/deepseek-v4-pro",
    "deepseek-v4-flash": "deepseek/deepseek-v4-flash",
    "mimo-v2.5": "xiaomi/mimo-v2.5",
    "mimo-v2.5-pro": "xiaomi/mimo-v2.5-pro",
}
```

**`"deepseek-flash"` non c'è.** In `get_model()`, se il nome non è nella
mappa, il ramo OpenRouter viene saltato e si cade sul ramo **nativo
DeepSeek** (api.deepseek.com, a pagamento). Da lì il 402.

Le tre prove (eseguite davvero, non ragionate):

| prova | esito |
|---|---|
| OpenRouter con `deepseek/deepseek-v4-flash` | **200 · "OK" · 0,6s · 0,0000069 $** |
| OpenRouter con `deepseek-flash` (il nome del cane) | **400 · "deepseek-flash is not a valid model ID"** |
| DeepSeek nativo con la chiave del capo | **402 · "Insufficient Balance"** (identico al tuo errore) |

### Il colpevole n.2 — il toggle del `.env` era ignorato

`ROUTE_VIA_OPENROUTER=true` nel `.env` era letto da `config.py`, **ma il
wrapper non lo usava**: `app_config()` calcola
`use_openrouter = (SETUP.model_provider == "openrouter")` e mette quel valore
**esplicito** in `route_via_openrouter`. E `SetupState.model_provider` di
default è `"deepseek"` — e la scelta **non veniva salvata** (vive solo in
memoria). Al riavvio tornava a `"deepseek"` → route **spenta** → piattaforma
nativa → 402. Letto dal file patched e dall'originale, aPROOF:

| | ORIGINALE | PATCHATO |
|---|---|---|
| `model_provider` di default | `deepseek` | `openrouter` |
| catena supervisor | `['deepseek-flash']` | `['deepseek-v4-flash']` |
| `route_via_openrouter` | **False** | **True** |

### Il cerotto

5 modifiche minime a `web_app.py` (backup automatico, idempotente):
1. le tre catene → il nome che Deep Dog conosce, letto dall'ambiente
   (`SUPERVISOR_MODEL` ecc.) → si cambia il modello dal `.env`
2. `import os`
3. il default del provider → `openrouter` se c'è la chiave
4. la scelta del Setup **si salva su disco** (`setup_state.json`)
5. e si rilegge all'avvio

Consegnato al PC come job: `da_me/deepdog_fix.sh` (il postino lo esegue e
risponde in `dal_pc/deepdog_fix.md`). Il collaudo gira su una **porta
separata (8766)**: il tuo server sulla 8765 (che è un processo Windows, non
visibile da WSL) non viene toccato. Il collaudo esce 1 se il Setup chiede
ancora DEEPSEEK, se arriva un 402, o se il report resta vuoto.

### Cosa ti resta da fare
1. attendere `dal_pc/deepdog_fix.md` (il postino gira ogni 45s)
2. riavviare il cane col `.bat` → **Demo veloce**
3. la chiave DeepSeek nativa può restare nel `.env` (non viene più usata);
   per non confondere i futuri, si può anche togliere
