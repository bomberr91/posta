#!/usr/bin/env bash
# github_models_prova.sh — GitHub Models dal PC: l'inference e' gratis col PAT.
# La chiave non viene MAI stampata.
set -u
cd "$HOME/posta" || exit 1

# PAT "GitHub Models" = quello con prefisso diverso da quello del repo posta
PAT=$(python3 - << 'PY'
import re
txt = open("/home/giopi/CHIAVI_LOCALI.md", encoding="utf-8", errors="replace").read()
line = ""
for l in txt.splitlines():
    if "GitHub Models" in l:
        line = l
        break
m = re.search(r"ghp_[A-Za-z0-9]{20,}", line)
print(m.group(0) if m else "")
PY
)
if [ -z "$PAT" ]; then
  echo "PAT GitHub Models non trovato nel portachiavi"
  exit 0
fi
echo "PAT GitHub Models trovato (non stampato)"

GHKEY="$PAT" python3 - << 'PY'
import os, json, urllib.request, urllib.error
key = os.environ["GHKEY"]
BASE = "https://models.github.ai/inference"

def call(method, path, body=None):
    h = {"Authorization": "Bearer " + key, "Accept": "application/json", "User-Agent": "Mozilla/5.0"}
    d = None
    if body is not None:
        d = json.dumps(body).encode(); h["Content-Type"] = "application/json"
    req = urllib.request.Request(BASE + path, data=d, headers=h, method=method)
    try:
        with urllib.request.urlopen(req, timeout=45) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return 0, "ERR %s" % e

s, b = call("GET", "/models")
print("GET /models ->", s, b[:300].replace("\n", " "))

for mod in ("openai/gpt-4.1", "openai/gpt-4o", "gpt-4.1", "openai/Llama-3.3-70B-Instruct",
            "openai/deepseek-R1", "mistral-ai/Ministral-3B"):
    s, b = call("POST", "/chat/completions",
                {"model": mod, "messages": [{"role": "user", "content": "Say OK"}], "max_tokens": 32})
    txt = b[:200].replace("\n", " ")
    print("chat %-34s -> %s %s" % (mod, s, txt))
PY
echo "Fine."
