#!/usr/bin/env bash
# OpenClaw sul PC: browser isolato per l'agente + modello "cervello/migliore".
#
# 1) browser.defaultProfile = openclaw  -> l'agente smette di agganciare il
#    Chrome di lavoro (profilo "user", chrome-mcp) e usa il Chrome gestito,
#    isolato, con user-data-dir proprio (CDP 18800).
# 2) browser.headless = false           -> finestra visibile: ci fai il login
#    una volta sola e la sessione resta nel profilo.
# 3) browser.executablePath = Chrome    -> evita l'auto-detect che saltava a Edge.
# 4) provider cervello: aggiunge il modello "migliore" accanto ad "auto".
# 5) modello: default globale e agente "main" = cervello/migliore.
#
# Uso (dal PC):  wsl bash -lc "bash ~/posta/fatti/imposta_browser_openclaw.sh"
set -u
cd "$(dirname "$0")/.." || exit 1

OC="cmd.exe /c openclaw"

echo "== 1/6 defaultProfile -> openclaw (Chrome isolato) =="
$OC config set browser.defaultProfile openclaw || echo "   FALLITO"

echo "== 2/6 headless -> false (finestra visibile) =="
$OC config set browser.headless false || echo "   FALLITO"

echo "== 3/6 executablePath -> Chrome (niente auto-detect Edge) =="
CHROME='/mnt/c/Program Files/Google/Chrome/Application/chrome.exe'
if [ -f "$CHROME" ]; then
  $OC config set browser.executablePath 'C:\Program Files\Google\Chrome\Application\chrome.exe' || echo "   FALLITO"
else
  echo "   Chrome non trovato in $CHROME: lascio l'auto-detect"
fi

echo "== 4/6 modello 'migliore' nel provider cervello =="
WINUSER=$(cmd.exe /c echo %USERNAME% 2>/dev/null | tr -d '\r' | tail -1)
WIN_TMP="/mnt/c/Users/$WINUSER/AppData/Local/Temp"
PATCH_WIN="C:\\Users\\$WINUSER\\AppData\\Local\\Temp\\patch-cervello.json"
if [ -d "$WIN_TMP" ]; then
  python3 - "$WIN_TMP/patch-cervello.json" <<'PY'
import json, sys
auto = {"id": "auto", "name": "Cervello Portiere", "api": "openai-completions",
        "reasoning": False, "input": ["text"],
        "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
        "maxTokens": 8192}
mig = {"id": "migliore", "name": "Cervello migliore", "api": "openai-completions",
       "reasoning": False, "input": ["text"],
       "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
       "maxTokens": 8192}
patch = {"models": {"providers": {"cervello": {"models": [auto, mig]}}}}
open(sys.argv[1], "w", encoding="utf-8").write(json.dumps(patch))
print("   patch scritto:", sys.argv[1])
PY
  $OC config patch --file "$PATCH_WIN" || echo "   FALLITO patch"
else
  echo "   $WIN_TMP non trovato: salto il modello 'migliore'"
fi

echo "== 5/6 modello agente =="
$OC config set agents.defaults.model.primary "cervello/migliore" || echo "   FALLITO"
$OC config set agents.entries.main.model.primary "cervello/migliore" || echo "   FALLITO"

echo "== 6/6 verifica =="
$OC config get browser.defaultProfile
$OC config get browser.headless
$OC config get agents.defaults.model.primary
$OC config get agents.entries.main.model.primary
$OC browser profiles

cat <<'NOTE'

--- uso da qui in poi -----------------------------------------------
L'agente usa il Chrome gestito (finestra separata): tu accedi a mano una
volta sola dentro quella finestra e ci resta loggato. Il Chrome di lavoro
si richiede solo di proposito:  openclaw browser --browser-profile user start

Nella chat l'override di sessione ha la precedenza sul config: dopo questi
comandi l'override può essere ancora "auto". Cambialo con  /model  -> Cervello
migliore, oppure apri una chat nuova.

Verifica che la politica giusta sia arrivata al portiere:
  wsl bash -lc "tail -n 3 ~/posta/portiere_log.jsonl"
La riga deve mostrare  "politica": "migliore".
NOTE
