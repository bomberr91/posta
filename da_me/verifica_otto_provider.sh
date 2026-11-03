#!/usr/bin/env bash
# verifica_otto_provider.sh — verifica mirata (una chat vera per ciascuno) sui
# provider che non rispondono, per decidere con dati freschi se toglierli.
# SOLO LETTURA: nessuna chiave viene stampata.
set -u
cd "$HOME/posta" || exit 1

cat > /tmp/_verifica_otto.py << 'PY'
import json, os, subprocess, urllib.request, urllib.error, re

LISTA = "typhoon tokenharbor waterfall navy anyapi gizmo aihorde longcat".split()

righe = {}
for l in open("portiere_lista.txt", encoding="utf-8"):
    l = l.strip()
    if not l or l.startswith("#"):
        continue
    p = (l + "||||||||||").split("|")
    if re.match(r"^[a-z0-9_-]+$", p[0]):
        righe[p[0]] = p

def chiave(etichetta):
    if not etichetta or etichetta.upper() == "SENZA":
        return ""
    out = subprocess.run(["python3", "chiave_di.py", etichetta],
                         capture_output=True, text=True).stdout.strip().splitlines()
    return out[0].strip() if out else ""

def prova(url, body, key, hdr_extra=None, timeout=40):
    h = {"User-Agent": "Mozilla/5.0", "Accept": "application/json"}
    if key:
        h["Authorization"] = "Bearer " + key
    if hdr_extra:
        h.update(hdr_extra)
    d = None
    if body is not None:
        d = json.dumps(body).encode(); h["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=d, headers=h, method="POST" if body is not None else "GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return 0, "ERR %s" % e

for pid in LISTA:
    r = righe.get(pid)
    if not r:
        print("%-14s NON C'E' NEL ROSTER" % pid); continue
    etichetta, base, modello, modo = r[2], r[3], r[4], r[5]
    key = chiave(etichetta)
    print("=" * 70)
    print("%s (%s)  base=%s  modello=%s  chiave=%s" % (pid, etichetta, base, modello, "SI" if key else "NO"))
    s, b = prova(base.rstrip("/") + "/models", None, key)
    print("   /models -> %s %s" % (s, b[:110].replace("\n", " ")))
    body = {"model": modello, "messages": [{"role": "user", "content": "Say OK"}], "max_tokens": 128}
    s, b = prova(base.rstrip("/") + "/chat/completions", body, key)
    if s == 200:
        try:
            j = json.loads(b)
            txt = (j.get("choices") or [{}])[0].get("message", {}).get("content")
            if not txt:
                txt = (j.get("choices") or [{}])[0].get("text") or "(content vuoto)"
        except Exception:
            txt = b[:120]
        print("   CHAT -> 200  risposta: %r" % (txt or "")[:160])
    else:
        print("   CHAT -> %s  %s" % (s, b[:180].replace("\n", " ")))
PY
python3 /tmp/_verifica_otto.py
rm -f /tmp/_verifica_otto.py
echo "FINE"
