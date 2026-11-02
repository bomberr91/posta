# Risposta a «deepdog_toggle»

_01/11/2026 15:12 · FilippoPC_

## 🐕 TOGGLE + VERITÀ SUI REQUISITI — 15:12
### 1. chiave deepseek-piattaforma nel portachiavi PC?

### 2. nomi esatti dei toggle (config.py)
191:# WEB_SEARCH_ENGINE          Which search tools to expose.
196:#                            Env: WEB_SEARCH_ENGINE
468:# only (paired with the default WEB_SEARCH_ENGINE="exa"). Per-run selection is
698:WEB_SEARCH_ENGINE = os.environ.get("WEB_SEARCH_ENGINE", "exa").strip().lower()
[CHIAVE-RIMOSSA].py:232:#   DEEPSEEK_API_KEY (or DEEPSEEK_KEY)   DeepSeek native API
[CHIAVE-RIMOSSA].py:770:    (e.g. DEEPSEEK_API_KEY or DEEPSEEK_KEY).
[CHIAVE-RIMOSSA].py:786:        return ["DEEPSEEK_API_KEY", "DEEPSEEK_KEY"]
156:        "missing": check.missing_required,
176:            STATE.error = "Apri Setup e configura: " + ", ".join(check.missing_required)

### 3. innesto toggle nel .env
OPENROUTER_API_KEY=sk-or-•••
TAVILY_API_KEY=tvly-d•••
ROUTE_VIA_OPENROUTER=true
WEB_SEARCH_ENGINE=tavily•••

<!-- fine deepdog_toggle -->
