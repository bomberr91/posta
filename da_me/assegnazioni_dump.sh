#!/usr/bin/env bash
# assegnazioni_dump.sh — chi usa QUALE chiave provider, su questo PC.
#
# Perche' serve (4/11): gli agenti e gli altri strumenti attivi possono
# finire sulla stessa chiave (accavallamento) e consumare insieme la quota
# dello stesso provider. Qui si raccolge il FATTO: per ogni strumento
# attivo, il provider, l'indirizzo, il modello e da dove arriva la chiave.
#
# REGOLA ASSOLUTA: nessuna chiave viene stampata. I valori che sembrano
# segreti diventano «presente (N caratteri)».
set -uo pipefail

echo "=============================================================="
echo " DUMP ASSEGNAZIONI — $(date '+%d/%m/%Y %H:%M')"
echo " utente: $(whoami)   home: $HOME"
echo "=============================================================="
echo

python3 - << 'PYEOF'
import json, os, re, glob

HOME = os.path.expanduser("~")
SEGRETI = re.compile(r"(key|token|secret|password|passwd|api_?key|credential)", re.I)
INTERESSA = re.compile(r"(provider|model|base_?url|baseurl|host|url|endpoint|env|type|mode|agent|motore|cervello)", re.I)

def maschera(v):
    if isinstance(v, bool) or isinstance(v, (int, float)) or v is None:
        return v
    t = str(v)
    if len(t) >= 12 and not t.startswith("http") and " " not in t and "/" not in t and ":" not in t:
        return "«presente (%d caratteri)»" % len(t)
    return t

def ricerca_json(oggetto, percorso=""):
    for k, v in oggetto.items():
        p = (percorso + "." + str(k)).strip(".")
        if isinstance(v, dict):
            ricerca_json(v, p)
        elif isinstance(v, list):
            for i, x in enumerate(v):
                if isinstance(x, dict):
                    ricerca_json(x, "%s[%d]" % (p, i))
                else:
                    print("   %-46s = %s" % (p + "[%d]" % i, maschera(x)))
        else:
            if SEGRETI.search(str(k)):
                print("   %-46s = %s" % (p, maschera(v)))
            elif INTERESSA.search(str(k)):
                print("   %-46s = %s" % (p, maschera(v)))

def mostra_file(percorso, etichetta):
    if not os.path.exists(percorso):
        return False
    print("--- %s" % etichetta)
    print("    file: %s" % percorso)
    try:
        testo = open(percorso, encoding="utf-8", errors="replace").read()
    except Exception as e:
        print("    (non leggibile: %s)" % str(e)[:80])
        return True
    if percorso.endswith((".json", ".jsonc")):
        pulito = re.sub(r"//[^\n\"]*", "", testo)
        try:
            ricerca_json(json.loads(pulito))
            return True
        except Exception as e:
            print("    (JSON non valido: %s)" % str(e)[:80])
    righe = 0
    for riga in testo.splitlines():
        s = riga.strip()
        if not s or s.startswith("#"):
            continue
        if ":" not in s and "=" not in s:
            continue
        if SEGRETI.search(s):
            k = re.split(r"[:=]", s, 1)[0].strip()
            print("   %-46s = %s" % (k, "«presente (non stampata)»"))
        elif INTERESSA.search(s):
            if len(s) > 220:
                s = s[:220] + "…"
            print("   %-46s = %s" % (s.split(":", 1)[0].strip()[:46], s.split(":", 1)[1].strip()[:150] if ":" in s else s))
            righe += 1
    return True

print("### A. CONFIG DEGLI AGENTI (sul PC)")
targets = [
    ("OPENCODE", os.path.join(HOME, ".config/opencode/opencode.jsonc")),
    ("OPENCODE (altro)", os.path.join(HOME, ".config/opencode/opencode.json")),
    ("GOOSE", os.path.join(HOME, ".config/goose/config.yaml")),
    ("INTERPRETER (secondhand)", os.path.join(HOME, ".config/interpreter/config.toml")),
    ("INTERPRETER (altro)", os.path.join(HOME, ".interpreter/config.toml")),
    ("HERMES", os.path.join(HOME, ".hermes/config.yaml")),
    ("HERMES (settings)", os.path.join(HOME, ".hermes/settings.json")),
    ("ANTIGRAVITY", os.path.join(HOME, ".agy/config.json")),
    ("ANTIGRAVITY (altro)", os.path.join(HOME, ".antigravity/config.json")),
    ("OPENCLAW", os.path.join(HOME, ".openclaw/openclaw.json")),
]
for etichetta, percorso in targets:
    mostra_file(percorso, etichetta)

for pattern, etichetta in [
    (os.path.join(HOME, ".hermes/*.yaml"), "HERMES (yaml)"),
    (os.path.join(HOME, ".hermes/*.json"), "HERMES (json)"),
    (os.path.join(HOME, ".agy/*.json"), "ANTIGRAVITY (json)"),
    (os.path.join(HOME, ".config/opencode/*.jsonc"), "OPENCODE (jsonc)"),
]:
    for f in sorted(glob.glob(pattern)):
        if f.endswith(etichetta.split("(")[0].lower() + ".jsonc") or True:
            mostra_file(f, etichetta)

print()
print("### B. IL PORTIERE (cervello) — la sua lista e il modello 'cervello/migliore'")
mostra_file(os.path.join(HOME, "posta/portiere_lista.txt"), "PORTIERE (prime righe utili)")
for f in (os.path.join(HOME, "posta/lavori/ponte/ponte.json"),):
    mostra_file(f, "PONTE (comandi agenti)")

print()
print("### C. CHIAVI/AGENTI NEI SCRIPT DEL PC (quali provider sono usati da cosa)")
radici = [os.path.join(HOME, "posta/lavori"), os.path.join(HOME, "posta/da_me"),
          os.path.join(HOME, "posta/fatti"), os.path.join(HOME, ".agents"),
          os.path.join(HOME, ".config/opencode")]
nomi_provider = re.compile(r"(OpenRouter|NVIDIA|Sail|Groq|Mistral|Gemini|Tavily|Exa|Firecrawl|AgentRouter|Token Harbor|AI Horde|OmniRoute|LongCat|NaraRouter|Anthropic|DeepSeek|AnyAPI|Gizmo|Typhoon|Hugging ?Face|Cerebras|Cloudflare|Jina|Speechify|Moondream|WaveSpeed|Polllinatio?n?s|Polllinations|Qdrant|Waterfall|NavyAI|Linkup|UptimeRobot|Clo ?ud|Cohere|BlazeAPI|Speka|Logfare|Lucidity|OrcaRouter|Requesty|Router9|Routeway|SimpleLLM|SeaLION|Septor|Plugsky|UnoRouter|xKiro|Zhipu|LLM7|LLMTR|Kilo|OVH|Inferbase|Kilo|Speka)", re.I)
for radice in radici:
    if not os.path.isdir(radice):
        continue
    for f in sorted(glob.glob(os.path.join(radice, "**", "*"), recursive=True)):
        if not os.path.isfile(f) or os.path.getsize(f) > 400000:
            continue
        if not re.search(r"\.(sh|py|toml|json|jsonc|yaml|yml|md)$", f):
            continue
        try:
            testo = open(f, encoding="utf-8", errors="replace").read()
        except Exception:
            continue
        trovati = sorted(set(nomi_provider.findall(testo)))
        if trovati:
            print("   %-58s -> %s" % (f.replace(HOME, "~"), ", ".join(sorted(set(trovati)))))

print()
print("### D. CHIAVI NEI FILE DI CONFIG (quali portachiavi/richiamano)")
for f in sorted(glob.glob(os.path.join(HOME, "**", "chiavi_env.sh"), recursive=True)):
    mostra_file(f, "CHIAVI_ENV (script di caricamento chiavi)")
print("FINE DUMP")
PYEOF

echo
echo "### E. PROCESSI ATTIVI (chi gira adesso)"
ps -eo pid,etimes,cmd 2>/dev/null | grep -E "cervello|motore|poller|postino|opencode|goose|hermes|agy|openclaw|interpreter|chrome" | grep -v grep | head -40

echo
echo "### F. PORTE APERTE (servizi nostri)"
(ss -ltnp 2>/dev/null || netstat -ltnp 2>/dev/null) | head -25
