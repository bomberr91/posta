# Risposta a «deepdog_diagnosi»

_01/11/2026 14:59 · FilippoPC_

## 🐕 DIAGNOSI CONFIG — 14:59
### 1. .env reale (nomi attivi, valori mascherati)
OPENROUTER_API_KEY=sk-or-•••
TAVILY_API_KEY=tvly-d•••

### 2. Cosa controlla l'app per dire 'configurato'?
24:    reconfigure = getattr(stream, "reconfigure", None)
25:    if callable(reconfigure):
26:        reconfigure(encoding="utf-8", errors="replace")
45:    "DEEPSEEK_API_KEY",
47:    "OPENROUTER_API_KEY",
55:    model_provider: str = "deepseek"
77:    "config_validated": "Configurazione verificata",
100:    use_openrouter = selected.model_provider == "openrouter"
139:            model_provider=SETUP.model_provider,
151:        "configured": {name: credentials.has(name) for name in SUPPORTED_KEYS},
152:        "model_provider": selected.model_provider,
175:            STATE.message = "Configurazione incompleta"

9:Routing (OpenRouter vs native API) is controlled by the ROUTE_VIA_OPENROUTER
16:    - OpenRouter Nemotron: "nvidia/nemotron-3.5-lightning"
38:#   muse-glimmer-30b           open-weight, distilled (OpenRouter only)
47:#   gpt-5.2                    current default for OpenAI provider
51:# NVIDIA (via OpenRouter) — env: OPENROUTER_API_KEY
60:# OPENROUTER (single key covers all) — env: OPENROUTER_API_KEY
61:#   Set ROUTE_VIA_OPENROUTER=true to route deepseek/mimo/meta through OR.
62:#   Any slug from openrouter.ai/models works directly:
96:# ROUTE_VIA_OPENROUTER       Shared default: route deepseek/mimo/meta through
97:#                            OpenRouter for ALL roles unless a role flag below
100:#                            Env: ROUTE_VIA_OPENROUTER=true|1|yes|on
101:# SUBAGENT_ROUTE_VIA_OPENROUTER
103:#                            Unset = inherit ROUTE_VIA_OPENROUTER.
104:# SUPERVISOR_ROUTE_VIA_OPENROUTER
107:#                            Unset = inherit ROUTE_VIA_OPENROUTER.

### 3. Il .env viene letto da dove? (load_dotenv e percorso)
/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog/web_app.py:18:from dotenv import load_dotenv
/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog/web_app.py:29:load_dotenv(ROOT / ".env")

<!-- fine deepdog_diagnosi -->
