# cura_cervello.py — 3 patch a deep_research/config.py per il provider locale cervello.
# Ogni vecchia stringa DEVE comparire esattamente una volta: se no, si ferma senza scrivere.
import io
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
PERCORSO = sys.argv[1] if len(sys.argv) > 1 else r"C:\Users\giopi\Documents\AgentWorkspace\deepdog\deep_research\config.py"
src = open(PERCORSO, encoding="utf-8").read()

RAMO_GET_MODEL = '''    # Provider LOCALE "cervello" (il portiere 20129): nessuna chiave nostra.
    if "cervello" in model_lower or model_lower == "auto":
        kwargs = {
            "model": model_name,
            "api_key": os.environ.get("CERVELLO_API_KEY", "sk-cervello"),
            "base_url": os.environ.get("CERVELLO_BASE_URL", "http://127.0.0.1:20129/v1"),
            "temperature": temperature,
        }
        if max_tokens is not None:
            kwargs["max_tokens"] = max_tokens
        return ChatOpenAI(**kwargs)

'''

PATCH = [
    ("model_required_keys: cervello non richiede chiavi",
     "    model_lower = model_name.lower()\n    if route_via_openrouter:",
     "    model_lower = model_name.lower()\n"
     "    if \"cervello\" in model_lower or model_lower == \"auto\":\n"
     "        return []\n"
     "    if route_via_openrouter:"),
    ("_model_key_available: cervello sempre disponibile",
     "    environment.\n    \"\"\"\n    if resolver is None:",
     "    environment.\n    \"\"\"\n"
     "    if \"cervello\" in model_name.lower() or model_name.lower() == \"auto\":\n"
     "        return True\n"
     "    if resolver is None:"),
    ("get_model: ramo cervello (ChatOpenAI sul portiere)",
     "    # ROUTE_VIA_OPENROUTER: send known direct-API models through OpenRouter so a",
     RAMO_GET_MODEL + "    # ROUTE_VIA_OPENROUTER: send known direct-API models through OpenRouter so a"),
]

ok = 0
for nome, vecchia, nuova in PATCH:
    n = src.count(vecchia)
    if n != 1:
        print(f"✗ '{nome}': trovate {n} occorrenze (attesa 1) — MI FERMO, nessuna modifica")
        sys.exit(1)
    src = src.replace(vecchia, nuova)
    ok += 1
    print(f"✓ {nome}")

tmp = PERCORSO + ".tmp_cura"
open(tmp, "w", encoding="utf-8").write(src)
os.replace(tmp, PERCORSO)
print(f"applicate {ok}/{len(PATCH)} patch, scrittura atomica OK")
