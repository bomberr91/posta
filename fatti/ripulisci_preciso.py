#!/usr/bin/env python3
"""ripulisci_preciso.py — maschera SOLO le chiavi vere, senza toccare il resto.

PERCHÉ (2/11): la prima pulizia (ripulisci_report_chiavi.py) usava una regola
generica ("stringa lunga = chiave") e ha mascherato 119 file per errore (URL,
nomi di file, righe di separazione). Quelli sono già stati ripristinati.
Questo script fa la pulizia giusta: prende le chiavi VERE dal portachiavi e
sostituisce solo quelle, parola per parola. Niente falsi positivi.

Poi ripristina i report degli agenti dal backup completo del PC
(~/posta_bak_0211), che contiene le versioni ORIGINALI (con dentro le chiavi
vere, che appena vengono mascherate).

Uso:  python3 ~/posta/fatti/ripulisci_preciso.py
"""
import os
import re
import subprocess
import sys

REPO = os.path.expanduser("~/posta")
BAK = os.path.expanduser("~/posta_bak_0211")
HOME = os.path.expanduser("~")
sys.path.insert(0, REPO)
try:
    from chiave_di import FORMATI
except Exception:
    FORMATI = [r"[A-Za-z0-9_\-+/=]{24,}"]

REPORT = [
    "dal_pc/nomi_modelli_provider.md",
    "dal_pc/squadra_provider_morti.md",
    "RISPOSTE_AGENTI/FUSION_20261102_104256.md",
]
MASCHERA = "[CHIAVE-RIMOSSA]"


def sh(c, cwd=REPO):
    p = subprocess.run(c, shell=True, cwd=cwd, capture_output=True, text=True)
    return (p.stdout + p.stderr).strip()


def chiavi_del_vault():
    """Le chiavi vere del portachiavi: sono i valori, non le regex."""
    out = set()
    try:
        righe = open(os.path.join(HOME, "CHIAVI_LOCALI.md"), encoding="utf-8",
                     errors="replace").read().splitlines()
    except Exception as e:
        print("vault non letto:", e)
        return out
    for riga in righe:
        s = riga.strip()
        # i formati NOTI (sk_, gsk_, AIza, hf_, nvapi_, cfut_...) si cercano su
        # TUTTE le righe: sono abbastanza specifici da non fare danni
        for f in FORMATI:
            for t in re.findall(f, s):
                if len(t) >= 16:
                    out.add(t)
        # la regola generica ("stringa lunga") solo sulle righe dei provider
        if not s.startswith("- **"):
            continue
        for t in re.findall(r"[A-Za-z0-9_\-+/=]{24,}", s):
            if "/" in t and "://" not in t and not t.startswith(("sk-", "sk_")):
                continue
            out.add(t)
    return out


def main():
    os.chdir(REPO)
    print("1. chiavi vere del portachiavi")
    chiavi = chiavi_del_vault()
    print(f"   trovate {len(chiavi)} chiavi da mascare")

    print("2. ripristino i report dal backup completo del PC")
    for rel in REPORT:
        src = os.path.join(BAK, rel)
        dst = os.path.join(REPO, rel)
        if not os.path.exists(src):
            print(f"   {rel}: non nel backup, lascio com'e'")
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(src, encoding="utf-8", errors="replace") as f:
            testo = f.read()
        shutil_ok = True
        try:
            with open(dst, "w", encoding="utf-8") as f:
                f.write(testo)
        except Exception as e:
            shutil_ok = False
            print("   scrittura fallita:", e)
        if shutil_ok:
            print(f"   ripristinato: {rel} ({len(testo)} caratteri)")

    print("3. maschero SOLO le chiavi vere")
    for rel in REPORT:
        dst = os.path.join(REPO, rel)
        if not os.path.exists(dst):
            continue
        with open(dst, encoding="utf-8", errors="replace") as f:
            t = f.read()
        n = 0
        for k in sorted(chiavi, key=len, reverse=True):
            if k in t:
                n += t.count(k)
                t = t.replace(k, MASCHERA)
        if n:
            with open(dst, "w", encoding="utf-8") as f:
                f.write(t)
        print(f"   {rel}: {n} chiavi mascherate")

    print("4. controllo: nel repo ci sono ancora chiavi vere?")
    residui = []
    for rel in REPORT:
        dst = os.path.join(REPO, rel)
        if not os.path.exists(dst):
            continue
        t = open(dst, encoding="utf-8", errors="replace").read()
        for k in chiavi:
            if k in t:
                residui.append((rel, k[:6] + "..."))
    print("   residui:", residui if residui else "nessuno")

    print("5. commit e push")
    sh("git add -A dal_pc RISPOSTE_AGENTI fatti da_me")
    if not sh("git diff --cached --quiet"):
        sh('git commit -q -m "report degli agenti: mascherate solo le chiavi vere (dal portachiavi)"')
        print("   commit:", sh("git log --oneline -1"))
        out = sh("git push origin HEAD:main 2>&1 | tail -4")
        print("  ", out.replace("\n", "\n   "))
    else:
        print("   niente da committare")
    return 0


if __name__ == "__main__":
    sys.exit(main())
