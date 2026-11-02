#!/usr/bin/env python3
"""aggiorna_vault_chiavi.py — scrive nel portachiavi le chiavi INTERE.

Il file di input ha una riga per chiave:
    Etichetta | chiave
(esempio:  TeamoRouter | sk-teamo-...)

Uso:
    python3 fatti/aggiorna_vault_chiavi.py ~/chiavi_da_inserire.txt
    python3 fatti/aggiorna_vault_chiavi.py ~/chiavi_da_inserire.txt ~/CHIAVI_LOCALI.md

Cosa fa, in ordine:
  1. backup del vault con data e ora (non sovrascrive mai il vault originale)
  2. cerca la riga "- **Etichetta** ..." dentro il vault e sostituisce il primo
     token fra apici inversi che NON sia un percorso (le chiavi stanno li)
  3. rilancia l'estrattore chiave_di.py e dice per ogni provider se la chiave
     adesso esce INTERA (stessa lunghezza di quella data)

Non scrive MAI la chiave su stdout, ne' su file del repo: resta nel vault.
"""

import datetime
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def vault_default():
    return os.environ.get("CHIAVI_FILE") or os.path.join(os.path.expanduser("~"), "CHIAVI_LOCALI.md")


def leggi_input(path):
    coppie = []
    with open(path, encoding="utf-8") as f:
        for riga in f:
            riga = riga.rstrip("\n").rstrip("\r")
            if not riga.strip() or riga.lstrip().startswith("#"):
                continue
            m = re.split(r"\s*::|\s*\|", riga, maxsplit=1)
            if len(m) != 2:
                print("  riga saltata (manca il separatore): " + riga[:40])
                continue
            et, ch = m[0], m[1]
            coppie.append((et.strip(), ch.strip()))
    return coppie


def sostituisci(sorgente, etichetta, chiave):
    """Ritorna (testo_nuovo, riga_numero) con la chiave intera al posto di quella corta."""
    righe = sorgente.split("\n")
    for n, riga in enumerate(righe):
        if not riga.lstrip().startswith("- **"):
            continue
        if etichetta.lower() not in riga.lower():
            continue
        span = re.search(r"`([^`]+)`", riga)
        if not span:
            continue
        vecchio = span.group(1)
        if "/" in vecchio or " " in vecchio:
            continue  # e' un percorso o una frase, non una chiave
        righe[n] = riga[: span.start(1)] + chiave + riga[span.end(1):]
        return "\n".join(righe), n + 1, vecchio
    return sorgente, 0, ""


def main():
    inp = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/chiavi_da_inserire.txt")
    vault = sys.argv[2] if len(sys.argv) > 2 else vault_default()

    if not os.path.exists(inp):
        print("MANCA il file di input: " + inp)
        return 1
    if not os.path.exists(vault):
        print("MANCA il portachiavi: " + vault)
        return 1

    coppie = leggi_input(inp)
    if not coppie:
        print("nel file di input non c'e' nessuna riga Etichetta | chiave")
        return 1

    ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    bak = vault + ".bak-" + ts
    shutil.copy2(vault, bak)
    print("backup: " + bak)

    testo = open(vault, encoding="utf-8").read()
    for et, ch in coppie:
        nuovo, n, vecchio = sostituisci(testo, et, ch)
        if n == 0:
            print("  " + et + ": riga non trovata nel vault (nessuna modifica)")
            testo = nuovo
            continue
        testo = nuovo
        print("  " + et + ": riga " + str(n) + " aggiornata (prima era " + str(len(vecchio)) +
              " caratteri, ora " + str(len(ch)) + ")")

    with open(vault, "w", encoding="utf-8") as f:
        f.write(testo)

    estrattore = os.path.join(ROOT, "chiave_di.py")
    if os.path.exists(estrattore):
        print("controllo con l'estrattore:")
        for et, ch in coppie:
            got = subprocess.run([sys.executable, estrattore, et], capture_output=True, text=True).stdout.strip()
            if got == ch:
                print("  " + et + ": chiave INTERA e corretta (" + str(len(got)) + " caratteri)")
            elif got and got in ch:
                print("  " + et + ": ATTENZIONE, l'estrattore restituisce solo " + str(len(got)) +
                      " caratteri invece di " + str(len(ch)))
            else:
                print("  " + et + ": l'estrattore NON trova la chiave (controlla la riga)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
