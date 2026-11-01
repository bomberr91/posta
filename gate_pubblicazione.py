#!/usr/bin/env python3
"""gate_pubblicazione.py — CURA-AUDIT (1/11 sera).

IL GUARDIANO. Prima che il postino pubblichi qualcosa su GitHub, ogni file
Python modificato deve almeno compilare, e cervello.py deve passare
l'autoprova (prova strutturale + prova viva reale).

PERCHÉ ESISTE. Il 1/11 alle 16:24 la commit di CURA-AUDIT pubblicò un
cervello.py con due difetti: `_sessione()` era stato annidato dentro
`_rispondi()` per un'indentazione sbagliata (H._sessione non esisteva più →
ogni richiesta chat moriva con "empty reply from server") e la riga
`NOME = "Portiere"` era stata cancellata (→ /cervello e /portiere.json
crashavano). Il collaudo di quel deploy non poté accorgersene: i curl hanno
un timeout (5-20s) molto più corto del budget del motore (180s + 5×60s), lo
script non aveva `set -e`, e il postino scriveva il `.done` senza guardare il
codice di uscita. Risultato: "deploy riuscito" con il Portiere morto.

Questo file chiude quella porta. Non modifica niente: dice solo quali file
NON vanno pubblicati.

Uso:
    python3 gate_pubblicazione.py              # verifica e stampa
    python3 gate_pubblicazione.py --escludi    # stampa solo i file da escludere
Exit code: 0 = tutto pubblicabile, 1 = c'è qualcosa di rotto.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys

QUI = os.path.dirname(os.path.abspath(__file__))


def file_modificati():
    """I file che il postino sta per pubblicare (.py soltanto: gli altri non
    possono rompere niente)."""
    try:
        grezzo = subprocess.run(["git", "status", "--porcelain", "-z"],
                                cwd=QUI, capture_output=True, timeout=30).stdout
    except Exception:
        return []
    campi = grezzo.split(b"\0")
    fuori = []
    i = 0
    while i < len(campi):
        voce = campi[i].decode("utf-8", "replace")
        if not voce:
            i += 1
            continue
        stato = voce[:2]
        nome = voce[3:]
        i += 1
        if "R" in stato or "C" in stato:      # rinominato/copiato: c'è il nome nuovo
            i += 1
        if nome.endswith(".py"):
            fuori.append(nome)
    return fuori


def non_compila(nome):
    try:
        p = subprocess.run([sys.executable, "-m", "py_compile", nome],
                           cwd=QUI, capture_output=True, timeout=60)
        return p.returncode != 0
    except Exception:
        return True


def autoprova_cervello():
    """cervello.py deve superare l'autoprova. Restituisce l'output se fallisce."""
    if not os.path.exists(os.path.join(QUI, "cervello.py")):
        return None
    try:
        p = subprocess.run([sys.executable, "cervello.py", "--autoprova"],
                           cwd=QUI, capture_output=True, text=True, timeout=180)
    except Exception as e:
        return "autoprova non eseguibile: %s" % e
    if p.returncode == 0:
        return None
    return (p.stdout or "") + (p.stderr or "")


def main():
    solo_escludi = "--escludi" in sys.argv
    rotte = []
    dettagli = []

    for nome in file_modificati():
        if not os.path.exists(os.path.join(QUI, nome)):
            continue
        if non_compila(nome):
            rotte.append(nome)
            dettagli.append("%s: non compila" % nome)

    esito = autoprova_cervello()
    if esito:
        rotte.append("cervello.py")
        dettagli.append("cervello.py: autoprova FALLITA\n" +
                        "\n".join("    " + r for r in esito.strip().splitlines()[-15:]))

    if solo_escludi:
        for nome in rotte:
            print(nome)
        return 1 if rotte else 0

    if rotte:
        print("⛔ GATE: questi file NON vanno pubblicati:")
        for d in dettagli:
            print("   -", d)
        print("   (il lavoro resta in locale: nessuna perdita)")
        # lascia traccia per il capo
        try:
            with open(os.path.join(QUI, "dal_pc", "gate_pubblicazione.txt"), "w",
                      encoding="utf-8") as f:
                f.write("gate: %d file bloccati\n" % len(rotte))
                for d in dettagli:
                    f.write(d + "\n")
        except Exception:
            pass
        return 1

    print("✓ gate: tutto pubblicabile")
    return 0


if __name__ == "__main__":
    sys.exit(main())
