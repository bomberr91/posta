#!/usr/bin/env bash
# verifica_agent_provider.sh - stato REALE dei provider degli agenti sul PC.
#
# Perche' esiste: la "leggenda" del workspace descrive come gli agenti sono
# stati impostati, ma il capo li ha impostati (e cambiati) sul PC: l'unica
# verita' e' leggere i file di configurazione come sono adesso.
#
# Non stampa mai una chiave: solo il nome della variabile d'ambiente,
# l'endpoint, il modello e se la variabile e' impostata o no.
set -u
DIR="$HOME/posta"
[ -d "$DIR" ] || DIR="$HOME/posta_ponte"
cd "$DIR" || { echo "non trovo il clone del repo"; exit 1; }

python3 - << 'PYEOF'
import os, re, json, glob

HOME = os.path.expanduser("~")
WIN = "/mnt/c/Users/giopi"

CAND = {
    "OpenCode": ["~/.config/opencode/opencode.json", "~/.config/opencode/opencode.jsonc",
                 WIN + "/.config/opencode/opencode.json", WIN + "/.config/opencode/opencode.jsonc"],
    "Goose": ["~/.config/goose/config.yaml", "~/.config/goose/config.yml",
              WIN + "/.config/goose/config.yaml", WIN + "/.config/goose/config.yml"],
    "Secondhand / Open Interpreter": ["~/.openinterpreter/config.toml",
                                      WIN + "/.openinterpreter/config.toml",
                                      WIN + "/Documents/AgentWorkspace/.openinterpreter/config.toml"],
    "Hermes": ["~/.hermes/config.yaml", "~/.hermes/config.json", "~/.hermes/config.toml",
                WIN + "/.hermes/config.yaml", WIN + "/.hermes/config.json"],
    "OpenClaw": ["~/.openclaw/config.json", "~/.openclaw/config.yaml", "~/.openclaw/config.toml",
                 WIN + "/.openclaw/config.json", WIN + "/.openclaw/config.yaml"],
    "Antigravity": ["~/.antigravity/config.json", "~/.antigravity/settings.json",
                    WIN + "/.antigravity/config.json", WIN + "/AppData/Roaming/Antigravity/config.json"],
    "Freebuff": ["~/.freebuff/config.json", "~/.freebuff/config.yaml", "~/.freebuff/settings.json",
                 WIN + "/.freebuff/config.json"],
}

KEYS = ("model", "model_provider", "provider", "base_url", "api_base", "baseurl",
        "env_key", "api_key", "apikey", "wire_api", "endpoint", "url")

def expand(p):
    return os.path.expanduser(p)

def grep_val(txt, name):
    # TOML/JSON/YAML: cerca "name": "valore" o name = "valore"
    m = re.search(r'["\']?%s["\']?\s*[:=]\s*["\']([^"\']{1,120})["\']' % re.escape(name), txt, re.I)
    return m.group(1) if m else None

def dump_toml_blocks(txt):
    out = []
    for m in re.finditer(r"(?ms)^\[model_providers\.([^\]]+)\][^\[]*", txt):
        blocco = m.group(0)
        out.append((m.group(1), grep_val(blocco, "base_url"), grep_val(blocco, "env_key"),
                    grep_val(blocco, "wire_api")))
    return out

righe = []
usate = {}
for agente, paths in CAND.items():
    trovato = None
    for p in paths:
        p = expand(p)
        if os.path.isfile(p):
            trovato = p
            break
    if not trovato:
        righe.append((agente, "CONFIG NON TROVATO", "", "", "", "", ""))
        continue
    try:
        txt = open(trovato, encoding="utf-8", errors="replace").read()
    except Exception as e:
        righe.append((agente, trovato, "lettura fallita: %s" % e, "", "", "", ""))
        continue
    modello = grep_val(txt, "model")
    provider = grep_val(txt, "model_provider") or grep_val(txt, "provider")
    base = grep_val(txt, "base_url") or grep_val(txt, "api_base") or grep_val(txt, "endpoint")
    envk = grep_val(txt, "env_key")
    apik = grep_val(txt, "api_key") or grep_val(txt, "apikey")
    # OpenCode: il provider spesso sta nel prefisso del modello ("opencode/xxx")
    if not provider and modello and "/" in modello:
        provider = modello.split("/")[0]
    secret = "inline" if apik else (envk or "-")
    blocks = dump_toml_blocks(txt)
    if blocks:
        for (nid, b, e, w) in blocks:
            righe.append((agente, trovato, nid, modello or "", b or "", e or w or "", "variabile: " + (e or "-")))
    righe.append((agente, trovato, provider or "-", modello or "-", base or "-", secret,
                  ("variabile impostata: " + ("SI" if envk and os.environ.get(envk) else "NO")) if envk else ""))
    chiave_id = (envk or apik or provider or "-")
    usate.setdefault(chiave_id, []).append(agente)

print("=" * 78)
print("STATO REALE DEGLI AGENTI SUL PC (nessuna chiave stampata)")
print("=" * 78)
for r in righe:
    print("  %-30s | %s" % (r[0], r[1]))
    if r[2]:
        print("      provider/modello: %s | %s" % (r[2], r[3]))
    if r[4]:
        print("      endpoint: %s" % r[4])
    if r[5]:
        print("      segreto: %s" % r[5])
    if r[6]:
        print("      %s" % r[6])
print("-" * 78)
print("RIEPILOGO CHIAVI (stessa variabile = stessa chiave)")
for k, ags in sorted(usate.items()):
    flag = "  <== STESSA CHIAVE PER PIU' AGENTI" if len(ags) > 1 and k != "-" else ""
    print("  %-28s -> %s%s" % (k, ", ".join(ags), flag))
print("-" * 78)
print("Altre cartelle di agenti trovate in home:")
for pat in [HOME + "/.*", WIN + "/.*"]:
    for d in sorted(glob.glob(pat)):
        b = os.path.basename(d)
        if b.lower() in ("opencode", "goose", "hermes", "openclaw", "antigravity",
                         "freebuff", "openinterpreter", "open-interpreter", "gemini"):
            print("   ", d)
PYEOF
