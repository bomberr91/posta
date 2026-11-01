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
