#!/usr/bin/env python3
"""Collaudo REALE di un provider: una richiesta di chat vera, non un /models.

La chiave non viene stampata e non sta in questo file: si legge dal
portachiavi (~/CHIAVI_LOCALI.md) con l'estrattore del repo (chiave_di.py).

Uso:
  python3 fatti/collaudo_provider.py NVIDIA
  python3 fatti/collaudo_provider.py NVIDIA deepseek-ai/deepseek-v4.1-flash
  python3 fatti/collaudo_provider.py Groq openai/gpt-oss-120b https://api.groq.com/openai/v1

Non usa curl: in WSL sul PC curl non c'e' e il suo stderr era nascosto, quindi
il collaudo falliva in silenzio con "HTTP 000".
"""
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

BASE_DEFAULT = {
    "NVIDIA": "https://integrate.api.nvidia.com/v1",
    "Groq": "https://api.groq.com/openai/v1",
    "Mistral": "https://api.mistral.ai/v1",
}

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def dal_portachiavi(nome):
    """Estrae la chiave del provider indicato: prima l'estrattore, poi il vault."""
    try:
        out = subprocess.run(
            [sys.executable, os.path.join(ROOT, "chiave_di.py"), nome],
            capture_output=True, text=True, timeout=30,
        )
        for line in (out.stdout or "").splitlines():
            line = line.strip()
            if line and " " not in line.strip("`"):
                return line
    except Exception:
        pass
    # fallback: riga del vault che nomina il provider
    for p in (os.path.expanduser("~/CHIAVI_LOCALI.md"),
              os.path.join(ROOT, "CHIAVI_LOCALI.md"),
              os.path.expanduser("~/posta/CHIAVI_LOCALI.md")):
        try:
            txt = open(p, encoding="utf-8").read()
        except OSError:
            continue
        for line in txt.splitlines():
            if nome.lower() in line.lower():
                m = re.search(r"nvapi-[A-Za-z0-9_\-]+", line)
                if m:
                    return m.group(0)
    return None


def main():
    nome = sys.argv[1] if len(sys.argv) > 1 else "NVIDIA"
    modello = sys.argv[2] if len(sys.argv) > 2 else {
        "NVIDIA": "deepseek-ai/deepseek-v4.1-flash",
        "Groq": "openai/gpt-oss-120b",
        "Mistral": "codestral-latest",
    }.get(nome, "")
    base = sys.argv[3] if len(sys.argv) > 3 else BASE_DEFAULT.get(nome, "")
    if not modello or not base:
        print("uso: collaudo_provider.py <Provider> [modello] [base_url]")
        return 2

    chiave = dal_portachiavi(nome)
    if not chiave:
        print("%s: nessuna chiave nel portachiavi" % nome)
        return 1
    print("provider: %s | modello: %s | chiave: %d caratteri" % (nome, modello, len(chiave)))

    corpo = json.dumps({
        "model": modello,
        "messages": [{"role": "user", "content": "Rispondi solo con OK"}],
        "max_tokens": 64,
    }).encode()
    req = urllib.request.Request(
        base.rstrip("/") + "/chat/completions",
        data=corpo,
        headers={"Authorization": "Bearer " + chiave, "Content-Type": "application/json"},
    )
    try:
        r = urllib.request.urlopen(req, timeout=60)
        txt = r.read().decode("utf-8", "replace").replace("\n", " ")
        print("HTTP %s :: %s" % (r.status, txt[:220]))
    except urllib.error.HTTPError as e:
        print("HTTP %s :: %s" % (e.code, e.read().decode("utf-8", "replace")[:300].replace("\n", " ")))
    except Exception as e:
        print("ERRORE: %s: %s" % (type(e).__name__, e))
    return 0


if __name__ == "__main__":
    sys.exit(main())
