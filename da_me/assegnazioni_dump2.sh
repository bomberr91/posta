#!/usr/bin/env bash
# assegnazioni_dump2.sh — le config LATO WINDOWS (la prima parte del dump non le vedeva).
#
# Secondhand (Open Interpreter), Hermes, Antigravity, OpenClaw e OpenCode hanno
# le config nella home di Windows (C:\Users\giopi\...), non in /home/agenti.
# Qui le leggo da /mnt/c e riporto SOLO nomi di provider, endpoint, modelli e
# nomi delle variabili d'ambiente: nessun valore di chiave viene stampato.
set -uo pipefail

WIN="/mnt/c/Users/giopi"

echo "=============================================================="
echo " DUMP ASSEGNAZIONI — LATO WINDOWS — $(date '+%d/%m/%Y %H:%M')"
echo "=============================================================="
echo

python3 - << PYEOF
import json, os, re, glob

WIN = "$WIN"
SEGRETI = re.compile(r"(key|token|secret|password|passwd|api_?key|credential)", re.I)
INTERESSA = re.compile(r"(provider|model|base_?url|baseurl|host|url|endpoint|env|type|mode|agent|cervello|motore|omni|gateway)", re.I)

def maschera(v):
    if isinstance(v, (bool, int, float)) or v is None:
        return v
    t = str(v)
    if len(t) >= 12 and not t.startswith("http") and " " not in t and "/" not in t and ":" not in t:
        return "«presente (%d caratteri)»" % len(t)
    return t

def mostra_json(percorso, etichetta):
    if not os.path.exists(percorso):
        print("--- %s" % etichetta); print("    (non c'è: %s)" % percorso); return
    print("--- %s" % etichetta); print("    file: %s" % percorso)
    testo = open(percorso, encoding="utf-8", errors="replace").read()
    pulito = re.sub(r"//[^\n\"]*", "", testo)
    try:
        dati = json.loads(pulito)
    except Exception as e:
        print("    (JSON non valido: %s)" % str(e)[:70]); return
    def walk(o, p=""):
        for k, v in o.items():
            q = (p + "." + str(k)).strip(".")
            if isinstance(v, dict):
                walk(v, q)
            elif isinstance(v, list):
                for i, x in enumerate(v):
                    if isinstance(x, dict): walk(x, "%s[%d]" % (q, i))
                    else: print("   %-44s = %s" % (("%s[%d]" % (q, i))[:44], maschera(x)))
            else:
                if SEGRETI.search(str(k)):
                    print("   %-44s = %s" % (q[:44], maschera(v)))
                elif INTERESSA.search(str(k)):
                    print("   %-44s = %s" % (q[:44], maschera(v)))
    walk(dati)

def mostra_testo(percorso, etichetta):
    if not os.path.exists(percorso):
        print("--- %s" % etichetta); print("    (non c'è: %s)" % percorso); return
    print("--- %s" % etichetta); print("    file: %s" % percorso)
    try:
        testo = open(percorso, encoding="utf-8", errors="replace").read()
    except Exception as e:
        print("    (non leggibile: %s)" % str(e)[:70]); return
    for riga in testo.splitlines():
        s = riga.strip()
        if not s or s.startswith("#") or (":" not in s and "=" not in s):
            continue
        if SEGRETI.search(s):
            k = re.split(r"[:=]", s, 1)[0].strip()
            print("   %-44s = «presente (non stampata)»" % k[:44])
        elif INTERESSA.search(s):
            print("   %-44s = %s" % (s[:44], s[45:][:140]))

targets = [
    ("SECONDHAND (openinterpreter config.toml)", WIN + "/.openinterpreter/config.toml"),
    ("HERMES (config.yaml)", WIN + "/.hermes/config.yaml"),
    ("HERMES (settings.json)", WIN + "/.hermes/settings.json"),
    ("HERMES (config.json)", WIN + "/.hermes/config.json"),
    ("ANTIGRAVITY (config.json)", WIN + "/.agy/config.json"),
    ("ANTIGRAVITY (settings.json)", WIN + "/.agy/settings.json"),
    ("OPENCLAW (openclaw.json)", WIN + "/.openclaw/openclaw.json"),
    ("OPENCODE win (opencode.jsonc)", WIN + "/.config/opencode/opencode.jsonc"),
    ("OPENCODE win (opencode.json)", WIN + "/.config/opencode/opencode.json"),
    ("GOOSE win (config.yaml)", WIN + "/.config/goose/config.yaml"),
]
for etichetta, p in targets:
    if p.endswith(".json") or p.endswith(".jsonc"):
        mostra_json(p, etichetta)
    else:
        mostra_testo(p, etichetta)

print()
print("--- altri file di config degli agenti (elenco, senza contenuto)")
for pattern in (WIN + "/.hermes/*", WIN + "/.agy/*", WIN + "/.openclaw/*.json",
                WIN + "/.openinterpreter/*", WIN + "/.config/opencode/*"):
    for f in sorted(glob.glob(pattern)):
        if os.path.isfile(f) and os.path.getsize(f) < 300000:
            print("   %s (%d byte)" % (f, os.path.getsize(f)))
PYEOF

echo
echo "### VARIABILI D'AMBIENTE DI WINDOWS (solo NOMI, valori mai stampati)"
echo "(le righe che contengono = indicano una variabile impostata con setx)"
cmd.exe /c set 2>/dev/null | grep -i -E "^[A-Z0-9_]*(API_KEY|API_BASE|BASE_URL|TOKEN|MODEL|PROVIDER|GOOSE|OPENAI|GEMINI|NVIDIA|OPENROUTER|ANTHROPIC|GROQ|OMNI|AR_KEY|EXA|TAVILY|FIRECRAWL)[A-Z0-9_]*=" \
  | sed -E 's/=.*/= (valore non stampato)/' | sort | head -60

echo
echo "### HOME DI WINDOWS: config per riga (nomi e valori non sensibili)"
for f in "$WIN/.openinterpreter/config.toml" "$WIN/.hermes/config.yaml" "$WIN/.agy/config.json" "$WIN/.openclaw/openclaw.json"; do
  [ -f "$f" ] && echo "   esiste: $f"
done

echo
echo "### AGENTI PRESENTI SUL PC (versioni)"
for exe in "/mnt/c/Users/giopi/AppData/Local/hermes/bin/hermes.exe" "/mnt/c/Users/giopi/AppData/Local/agy/bin/agy.exe"; do
  [ -f "$exe" ] && echo "   presente: $exe"
done
command -v opencode >/dev/null 2>&1 && echo "   opencode: $(command -v opencode)"
command -v goose >/dev/null 2>&1 && echo "   goose: $(command -v goose)"
command -v interpreter >/dev/null 2>&1 && echo "   interpreter: $(command -v interpreter)"

echo "FINE DUMP2"
