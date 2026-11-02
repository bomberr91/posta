#!/usr/bin/env bash
# OpenClaw: l'agente smette di agganciare il Chrome di lavoro.
#
# Causa del "prendere possesso": browser.defaultProfile era "user", cioe' il
# profilo existing-session che si attacca via Chrome MCP al Chrome gia' aperto
# (con le tue schede e le tue login). Esiste gia' un profilo GESTITO isolato,
# "openclaw": lancia un Chrome suo, con user-data-dir proprio, sulla porta
# CDP 18800, e non tocca mai il tuo browser personale.
#
# Uso (dal PC):  wsl bash -lc "bash ~/posta/fatti/imposta_browser_openclaw.sh"
set -u
cd "$(dirname "$0")/.." || exit 1

OC="cmd.exe /c openclaw"

echo "== 1/5 defaultProfile -> openclaw (Chrome isolato) =="
$OC config set browser.defaultProfile openclaw || echo "   FALLITO: se 'openclaw' non e' in PATH, usa il percorso completo del .cmd"

echo "== 2/5 headless -> false (finestra visibile: ci fai il login una volta) =="
$OC config set browser.headless false || echo "   FALLITO"

echo "== 3/5 controllo override d'ambiente (ha precedenza sulla config) =="
printf 'OPENCLAW_BROWSER_HEADLESS='; cmd.exe /c echo %OPENCLAW_BROWSER_HEADLESS% 2>/dev/null | tr -d '\r'

echo "== 4/5 verifica =="
$OC config get browser.defaultProfile
$OC config get browser.headless

echo "== 5/5 profili disponibili =="
$OC browser profiles

cat <<'NOTE'

--- come si usa da qui in poi -------------------------------------------
L'agente OpenClaw ora parla con il Chrome isolato: finestra separata, tu
non perdi niente. Quando serve un sito loggato, accedi tu a mano nella
finestra dell'agente (headless false): la sessione resta in quel profilo e
i turni successivi la ritrovano gia' loggati.

CLI per pilotarlo a mano:
  openclaw browser --browser-profile openclaw start
  openclaw browser --browser-profile openclaw open https://example.com
  openclaw browser --browser-profile openclaw snapshot
  openclaw browser --browser-profile openclaw tabs

Se serve portare dentro solo i cookie di qualche sito (non la sessione
intera):  openclaw browser cookie-sync --domains google.com,youtube.com --into openclaw

Per tornare al Chrome di lavoro:  openclaw config set browser.defaultProfile user
NOTE
