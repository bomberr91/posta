#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
assegnazioni_vedi.py — LEGGE il libro mastro delle chiavi e dice se una chiave è libera.

Il libro mastro è `lavori/assegnazioni_provider.tsv` (questo repo, pubblico:
solo nomi e quote, nessun segreto). Il portachiavi è `CHIAVI_LOCALI.md`
(privato): serve solo per l'elenco dei nomi, non viene stampato.

Uso:
  python3 lavori/assegnazioni_vedi.py              # quadro completo
  python3 lavori/assegnazioni_vedi.py NVIDIA       # che ne fa di questa chiave
  python3 lavori/assegnazioni_vedi.py --vault /home/agenti/CHIAVI_LOCALI.md

Esito: 0 se tutto sta in piedi; 1 se ci sono conflitti (una chiave a due
strumenti attivi) — cosi si può usarlo come controllo.
"""
import os
import re
import sys

QUI = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(QUI)
TSV = os.path.join(QUI, "assegnazioni_provider.tsv")
LISTA = os.path.join(REPO, "portiere_lista.txt")
QUOTE = os.path.join(REPO, "portiere_quote.txt")

# chi è "l'allocatore/il lettore": per queste righe la sovrapposizione è voluta
RUOLI_SPECIALI = ("Cervello", "Motore locale", "Appello")


def chiavi_di_riga(r, roster):
    """Le chiavi (nomi esatti del portachiavi) che la riga usa."""
    grezzo = r.get("chiavi", "").strip()
    if grezzo in ("", "-"):
        return []
    if grezzo == "*roster*":
        return sorted(roster.keys())
    return [x.strip() for x in grezzo.split(";") if x.strip() and x.strip() != "-"]


def leggi_tsv():
    righe = []
    if not os.path.exists(TSV):
        return righe
    for riga in open(TSV, encoding="utf-8"):
        r = riga.rstrip("\n")
        if not r.strip() or r.startswith("#"):
            continue
        if r.split("\t")[0].strip() == "strumento":
            continue   # intestazione delle colonne
        p = r.split("\t")
        p += [""] * (7 - len(p))
        righe.append({
            "strumento": p[0].strip(), "ambiente": p[1].strip(), "chiavi": p[2].strip(),
            "via": p[3].strip(), "esclusivita": p[4].strip(), "stato": p[5].strip(),
            "note": p[6].strip(),
        })
    return righe


def leggi_roster():
    """provider del cervello: nome nel portachiavi -> id nel roster"""
    out = {}
    if not os.path.exists(LISTA):
        return out
    for riga in open(LISTA, encoding="utf-8"):
        r = riga.strip()
        if not r or r.startswith("#"):
            continue
        p = r.split("|")
        if len(p) < 3:
            continue
        nome = p[2].strip()
        if nome and nome != "SENZA":
            out.setdefault(nome, []).append(p[0].strip())
    return out


def leggi_quote():
    out = {}
    if not os.path.exists(QUOTE):
        return out
    for riga in open(QUOTE, encoding="utf-8"):
        r = riga.strip()
        if not r or r.startswith("#"):
            continue
        p = r.split("|")
        if len(p) >= 3:
            out[p[0].strip()] = "%s/min, %s/giorno" % (p[1].strip(), p[2].strip())
    return out


def leggi_vault(percorso):
    """nomi delle righe del portachiavi, per sezione (2 = strumenti, 3 = provider)"""
    out = {"strumenti": [], "provider": [], "altro": []}
    if not percorso or not os.path.exists(percorso):
        return None
    sezione = ""
    for riga in open(percorso, encoding="utf-8", errors="replace"):
        if riga.startswith("## "):
            sezione = riga.strip()
            continue
        m = re.match(r"\s*(\d+)\.\s*\*\*(.+?)\*\*", riga)
        if not m:
            continue
        nome = m.group(2).strip()
        if sezione.startswith("## 2"):
            out["strumenti"].append(nome)
        elif sezione.startswith("## 3"):
            out["provider"].append(nome)
        else:
            out["altro"].append(nome)
    return out


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    vault_path = None
    for a in sys.argv[1:]:
        if a.startswith("--vault"):
            vault_path = a.split("=", 1)[1] if "=" in a else None
    if vault_path is None and args and args[0].startswith("/"):
        vault_path = args.pop(0)
    if vault_path is None:
        vault_path = os.environ.get("CHIAVI_FILE") or os.path.join(os.path.expanduser("~"), "CHIAVI_LOCALI.md")

    righe = leggi_tsv()
    roster = leggi_roster()
    quote = leggi_quote()
    # la quota è per pid (nvidia); il libro mastro parla per nome (NVIDIA)
    for nome, pids in roster.items():
        for pid in pids:
            if pid in quote:
                quote[nome] = quote[pid]
    vault = leggi_vault(vault_path)

    print("=" * 100)
    print(" LIBRO MASTRO DELLE CHIAVI — %s" % os.path.relpath(TSV, REPO))
    print("=" * 100)
    for r in righe:
        print("  %-34s %-10s %-46s %s" % (r["strumento"][:34], r["ambiente"][:10], r["chiavi"][:46], r["stato"]))
        print("      via        : %s · esclusivita: %s" % (r["via"], r["esclusivita"]))
        if r["note"]:
            print("      note       : %s" % r["note"])

    # ---- chi usa cosa
    print()
    print("-" * 100)
    print(" CHIAVI PROVIDER: chi le usa")
    print("-" * 100)
    uso = {}
    for r in righe:
        if r["stato"].upper() == "SOSPESO":
            continue
        for nome in chiavi_di_riga(r, roster):
            uso.setdefault(nome, []).append(r["strumento"])
    for nome, chi in sorted(uso.items()):
        agenti = [c for c in chi if not any(c.startswith(s) for s in RUOLI_SPECIALI)]
        if not agenti:
            continue
        tag = ""
        if len(agenti) > 1:
            tag = "   <<< DUE STRUMENTI SULLA STESSA CHIAVE"
        elif nome in roster:
            tag = "   ⚠ anche nel roster del cervello (l'appello la prova ogni giorno)"
        print("  %-34s %s%s" % (nome[:34], ", ".join(agenti), tag))

    # ---- chiavi libere (nel vault, non nel roster, non assegnate)
    print()
    print("-" * 100)
    print(" CHIAVI LIBERE (nel portachiavi, non nel roster del cervello, non assegnate a nessuno)")
    print("-" * 100)
    if vault is None:
        print("  (portachiavi non trovato: %s)" % vault_path)
        print("  passa --vault /percorso/CHIAVI_LOCALI.md per la lista completa")
    else:
        assegnate = set(n.lower() for n in uso)
        for r in righe:
            for nome in chiavi_di_riga(r, roster):
                assegnate.add(nome.lower())
        libere = []
        for nome in vault["provider"]:
            if nome.lower() in assegnate:
                continue
            if nome in roster:
                continue
            libere.append(nome)
        if libere:
            for nome in libere:
                print("  LIBERA: %s" % nome)
        else:
            print("  nessuna: TUTTE le chiavi provider del portachiavi sono gia' in uso")
            print("  (per un nuovo strumento: passare dal cervello locale, non prendere una chiave)")
        print("  chiavi strumento (non provider, condivise): %d" % len(vault["strumenti"]))

    # ---- risposta puntuale
    if args:
        nome = args[0].strip()
        print()
        print("-" * 100)
        print(" VERDETTO PER: %s" % nome)
        print("-" * 100)
        trovato = False
        for r in righe:
            if nome.lower() in r["chiavi"].lower():
                trovato = True
                print("  %-34s %-10s %s" % (r["strumento"], r["ambiente"], r["stato"]))
                print("      esclusivita: %s" % r["esclusivita"])
        if nome in roster:
            print("  ⚠ e' NEL ROSTER del cervello: l'appello la prova ogni giorno (quota: %s)" % quote.get(nome, "?"))
        if not trovato and nome not in roster:
            print("  nessuno strumento la usa e non e' nel roster: CHIAVE LIBERA")
        elif nome in roster:
            print("  ⚠ CHIAVE OCCUPATA dal cervello (allocatore) — non darla in giro")
        else:
            print("  ⚠ CHIAVE OCCUPATA — non darla in giro")

    # ---- conflitti (solo fra strumenti attivi, esclusi allocator/lettori)
    conflitti = []
    for nome, chi in uso.items():
        attivi = [c for c in chi if not any(c.startswith(s) for s in RUOLI_SPECIALI)]
        if len(attivi) > 1:
            conflitti.append((nome, attivi, "due strumenti sulla stessa chiave"))
    for r in righe:
        if r["esclusivita"].strip().upper().startswith("DA-SISTEMARE"):
            conflitti.append((r["chiavi"], [r["strumento"]], "accavalla con il roster del cervello"))
    print()
    print("-" * 100)
    print(" CONFLITTI DA SISTEMARE: %d" % len(conflitti))
    print("-" * 100)
    for nome, chi, perche in conflitti:
        print("  %-40s <- %s   (%s)" % (str(nome)[:40], ", ".join(chi), perche))
    if not conflitti:
        print("  nessuno")
    return 1 if conflitti else 0


if __name__ == "__main__":
    sys.exit(main())
