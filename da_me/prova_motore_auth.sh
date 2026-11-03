#!/bin/bash
# prova_motore_auth.sh — il motore risponde su 20128 (root OK) ma GET
# /v1/models va in errore. Il sospetto: OmniRoute vuole l'header Authorization
# e il portiere (cervello.py, funzione inoltra) NON lo manda.
# Verifica mirata: stessa chat, con e senza Authorization.
# Parla solo con lo stdout: il referto arriva in dal_pc/prova_motore_auth.md

echo "## Chiave OmniRoute in giro (chiavi_env.sh / env)"
for F in "$HOME/posta/chiavi_env.sh" "$HOME/chiavi_env.sh"; do
  if [ -f "$F" ]; then
    echo "- $F:"
    grep -E "OMNIROUTE_API_KEY|OM_KEY" "$F" 2>/dev/null | sed -E 's/(sk-[A-Za-z0-9]{6})[A-Za-z0-9]*/\1…/g' | sed 's/^/    /'
  fi
done

echo ""
echo "## Chat sul motore: SENZA e CON Authorization"
python3 - <<'PY'
import json, urllib.request, urllib.error, os, re

URL = "http://127.0.0.1:20128/v1/chat/completions"
CORPO = json.dumps({"model": "auto/best-reasoning",
                    "messages": [{"role": "user", "content": "Rispondi solo: OK"}],
                    "max_tokens": 64}).encode()

def chiave():
    for f in (os.path.expanduser("~/posta/chiavi_env.sh"), os.path.expanduser("~/chiavi_env.sh")):
        try:
            d = open(f, encoding="utf-8", errors="replace").read()
        except Exception:
            continue
        m = re.search(r'OMNIROUTE_API_KEY="\$\{OM_KEY:-([^"]+)\}"', d)
        if m and m.group(1):
            return m.group(1)
        m = re.search(r'OM_KEY=([^"\'\s]+)', d)
        if m:
            return m.group(1)
    return os.environ.get("OMNIROUTE_API_KEY", "")

def prova(nome, headers):
    req = urllib.request.Request(URL, data=CORPO, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=60) as f:
            d = f.read().decode(errors="replace")
            try:
                j = json.loads(d)
                cont = ""
                try:
                    cont = (j["choices"][0]["message"].get("content") or "")[:60]
                except Exception:
                    cont = d[:120]
                print(f"- {nome}: HTTP {f.status} | modello={j.get('model')} | contenuto={cont!r}")
            except Exception:
                print(f"- {nome}: HTTP {f.status} | {len(d)} byte | {d[:150]}")
    except urllib.error.HTTPError as e:
        corpo = e.read().decode(errors="replace")[:200]
        print(f"- {nome}: HTTP {e.code} {e.reason} | {corpo}")
    except Exception as e:
        print(f"- {nome}: {type(e).__name__}: {e}")

base = {"Content-Type": "application/json"}
prova("SENZA Authorization", dict(base))
k = chiave()
print(f"- chiave trovata: {'si (' + str(len(k)) + ' caratteri)' if k else 'NO'}")
if k:
    h = dict(base); h["Authorization"] = "Bearer " + k
    prova("CON Authorization Bearer", h)
PY

echo ""
echo "## GET /v1/models con e senza chiave"
python3 - <<'PY'
import urllib.request, urllib.error, os, re
def chiave():
    for f in (os.path.expanduser("~/posta/chiavi_env.sh"), os.path.expanduser("~/chiavi_env.sh")):
        try:
            d = open(f, encoding="utf-8", errors="replace").read()
        except Exception:
            continue
        m = re.search(r'OMNIROUTE_API_KEY="\$\{OM_KEY:-([^"]+)\}"', d)
        if m and m.group(1): return m.group(1)
    return os.environ.get("OMNIROUTE_API_KEY", "")
k = chiave()
for nome, h in (("senza", {}), ("con Bearer", {"Authorization": "Bearer " + k} if k else {})):
    try:
        with urllib.request.urlopen(urllib.request.Request("http://127.0.0.1:20128/v1/models", headers=h), timeout=15) as f:
            d = f.read().decode(errors="replace")
            print(f"- /v1/models {nome}: HTTP {f.status}, {len(d)} byte")
    except urllib.error.HTTPError as e:
        print(f"- /v1/models {nome}: HTTP {e.code} {e.reason}")
    except Exception as e:
        print(f"- /v1/models {nome}: {type(e).__name__}")
PY

echo ""
echo "## Il portiere manda l'Authorization al motore?"
grep -n -A6 'def inoltra' "$HOME/posta/cervello.py" 2>/dev/null | sed -n '1,14p' | sed 's/^/    /'
