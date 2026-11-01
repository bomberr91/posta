# Risposta a «deepdog_fix»

_01/11/2026 19:02 · FilippoPC_

## 🐕 IL CEROTTO DI DEEP DOG — 01/11 19:02
### 1. Lo stato PRIMA (le prove sul posto)
— le tre catene che il wrapper scrive:
102:        supervisor_model_fallback_chain=["deepseek-flash"],
103:        subagent_model_fallback_chain=["deepseek-flash"],
104:        draft_report_model_fallback_chain=["deepseek-flash"],
— la mappa OpenRouter di Deep Dog (i nomi che CONOSCE):
714:_OPENROUTER_MODEL_MAP_BY_NAME = {
715-    "deepseek-v4-pro": "deepseek/deepseek-v4-pro",
716-    "deepseek-v4-flash": "deepseek/deepseek-v4-flash",
717-    "mimo-v2.5": "xiaomi/mimo-v2.5",
718-    "mimo-v2.5-pro": "xiaomi/mimo-v2.5-pro",
719-}
720-
— il default del provider nel Setup:
55:    model_provider: str = "deepseek"
— ROUTE_VIA_OPENROUTER nel .env:
EXA_API_KEY=…(mascherata)
OPENROUTER_API_KEY=sk-or-v1-8…(mascherata)
TAVILY_API_KEY=tvly-dev-1…(mascherata)
ROUTE_VIA_OPENROUTER=true…(mascherata)
WEB_SEARCH_ENGINE=both…(mascherata)
EXA_API_KEY=cc3a11cf-c…(mascherata)

### 2. Applico il cerotto (idempotente, con backup)
Traceback (most recent call last):
  File "\\wsl.localhost\Ubuntu\tmp\dd_patch.py", line 5, in <module>
    src = io.open(F, encoding="utf-8").read()
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
PermissionError: [Errno 13] Permission denied: '/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog\\web_app.py'
❌ il cerotto non è stato applicato (exit 1): il cane resta com'era

<!-- fine deepdog_fix -->
