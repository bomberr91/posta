#!/usr/bin/env python3
"""modelli_aihorde.py — i modelli di AI Horde che hanno un worker ONLINE ADESSO.

AI Horde e' una rete di volontari: il roster cambia di ora in ora e un modello
puo' essere «not known» oppure noto ma senza nessuno che lo serva. L'unica
fonte affidabile e' il contatore dei worker:
    https://aihorde.net/api/v2/status/models?type=text
Stampa un id per riga, dal piu' servito al meno servito.
"""
import json
import sys
import urllib.request

URL = "https://aihorde.net/api/v2/status/models?type=text"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"


def main():
    try:
        req = urllib.request.Request(URL, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=25) as r:
            d = json.loads(r.read().decode("utf-8", "replace"))
    except Exception as e:
        print("roster non letto:", e, file=sys.stderr)
        return 1
    vivi = [m for m in d if isinstance(m, dict) and (m.get("count") or 0) > 0]
    vivi.sort(key=lambda m: -(m.get("count") or 0))
    for m in vivi[:8]:
        nome = m.get("name")
        if nome:
            print(nome)
    return 0


if __name__ == "__main__":
    sys.exit(main())
