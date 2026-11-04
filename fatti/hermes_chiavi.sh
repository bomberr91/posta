#!/usr/bin/env bash
# hermes_chiavi.sh — 4/11: quante chiavi tiene davvero Hermes e QUALI.
#
# Il referto precedente (hermes_config_hunt) aveva trovato la config ma aveva
# MASCHERATO i valori: non si sapeva se la api_key fosse la chiave finta del
# cervello (sk-cervello) o una chiave vera del roster.
# Qui ogni segreto viene ridotto a: lunghezza + sha256[:12] + "e' sk-cervello?".
# NESSUNA chiave viene stampata. L'orchestratore (che ha il portachiavi)
# confronta le impronte e sa dire a quale provider appartiene.
#
# Niente pipe verso tail: un pipe che non chiude tiene appeso il postino.
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

echo "### 1. CONFIG.YAML DI HERMES (Windows)"
python3 - << 'PY'
import os, re, hashlib
W = "/mnt/c/Users/giopi/AppData/Local/hermes"

def fp(v):
    if v is None:
        return "assente"
    v = v.strip()
    if len(v) >= 2 and v[0] in "\"'" and v[-1] == v[0]:
        v = v[1:-1]
    if not v:
        return "vuoto"
    h = hashlib.sha256(v.encode("utf-8", "replace")).hexdigest()[:12]
    return "len=%d sha12=%s sk_cervello=%s" % (len(v), h, "SI" if v == "sk-cervello" else "no")

cfg = os.path.join(W, "config.yaml")
if os.path.exists(cfg):
    s = open(cfg, encoding="utf-8", errors="replace").read()
    for k in ("provider", "model", "base_url"):
        m = re.search(r"^\s*%s\s*:\s*(.+)$" % k, s, re.M)
        print("  %s = %s" % (k, m.group(1).strip() if m else "(assente)"))
    for m in re.finditer(r"^\s*api_key\s*:\s*(.+)$", s, re.M):
        print("  api_key -> %s" % fp(m.group(1)))
else:
    print("  config assente")
PY
echo

echo "### 2. AUTH.JSON (credential_pool)"
python3 - << 'PY'
import os, json, hashlib
W = "/mnt/c/Users/giopi/AppData/Local/hermes"

def fp(v):
    if not isinstance(v, str):
        return "assente"
    v = v.strip()
    if not v:
        return "vuoto"
    h = hashlib.sha256(v.encode("utf-8", "replace")).hexdigest()[:12]
    return "len=%d sha12=%s sk_cervello=%s" % (len(v), h, "SI" if v == "sk-cervello" else "no")

aj = os.path.join(W, "auth.json")
if not os.path.exists(aj):
    print("  assente")
else:
    try:
        d = json.load(open(aj, encoding="utf-8", errors="replace")) or {}
    except Exception as e:
        d = {}
        print("  json non leggibile: %s" % e)
    cp = d.get("credential_pool") or {}
    if not cp:
        print("  credential_pool vuoto")
    for prov, entries in cp.items():
        if not isinstance(entries, list):
            continue
        for e in entries:
            if not isinstance(e, dict):
                continue
            secret = ""
            for k in ("api_key", "secret", "key", "token", "value"):
                if isinstance(e.get(k), str) and e.get(k):
                    secret = e[k]
                    break
            print("  %s: auth_type=%s base_url=%s secret -> %s"
                  % (prov, e.get("auth_type"), e.get("base_url"), fp(secret)))
    for k, v in d.items():
        if k != "credential_pool" and isinstance(v, str) and len(v) >= 16:
            print("  (top-level) %s -> %s" % (k, fp(v)))
PY
echo

echo "### 3. .ENV DI HERMES (nomi + impronte)"
python3 - << 'PY'
import os, glob, hashlib
W = "/mnt/c/Users/giopi/AppData/Local/hermes"

def fp(v):
    h = hashlib.sha256(v.encode("utf-8", "replace")).hexdigest()[:12]
    return "len=%d sha12=%s sk_cervello=%s" % (len(v), h, "SI" if v == "sk-cervello" else "no")

NOISE = ("URL", "HOST", "PORT", "DIR", "PATH", "HOME", "MODEL", "TIMEOUT", "LEVEL",
         "LANG", "MODE", "TERM", "SHELL", "USER", "PROFILE", "PROXY", "PROMPT",
         "TEMPLATE", "COLOR", "EDITOR", "PYTHON", "NODE", "NPM", "LINES", "COLUMNS")
candidati = [os.path.join(W, ".env")]
candidati += sorted(glob.glob("/home/agenti/.hermes/**/.env", recursive=True))
for path in candidati:
    if not os.path.isfile(path):
        continue
    print("  --- %s" % path)
    try:
        testo = open(path, encoding="utf-8", errors="replace").read()
    except Exception as e:
        print("      non leggibile: %s" % e)
        continue
    for riga in testo.splitlines():
        riga = riga.strip()
        if not riga or riga.startswith("#") or "=" not in riga:
            continue
        nome, _, val = riga.partition("=")
        nome = nome.strip().strip('"').strip("'")
        val = val.strip().strip('"').strip("'")
        if len(val) < 16:
            continue
        alto = nome.upper()
        segreto = any(t in alto for t in ("KEY", "TOKEN", "SECRET", "PASSWORD", "API"))
        if not segreto and any(t in alto for t in NOISE):
            continue
        if not segreto:
            continue
        print("      %s -> %s" % (nome, fp(val)))
PY
echo

echo "### 4. VARIABILI D'AMBIENTE CON NOME DA CHIAVE (solo nel processo del postino)"
python3 - << 'PY'
import os, hashlib
def fp(v):
    h = hashlib.sha256(v.encode("utf-8", "replace")).hexdigest()[:12]
    return "len=%d sha12=%s sk_cervello=%s" % (len(v), h, "SI" if v == "sk-cervello" else "no")
n = 0
for k, v in sorted(os.environ.items()):
    if len(v) < 16:
        continue
    if any(t in k.upper() for t in ("KEY", "TOKEN", "SECRET", "API")):
        print("  %s -> %s" % (k, fp(v)))
        n += 1
if n == 0:
    print("  nessuna")
PY
echo
echo "FINE"
exit 0
