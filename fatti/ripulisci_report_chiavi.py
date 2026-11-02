#!/usr/bin/env python3
"""ripulisci_report_chiavi.py — toglie le chiavi dai report e riscrive i commit locali.

PERCHÉ ESISTE (2/11): il report di un agente (dal_pc/nomi_modelli_provider.md) conteneva
due chiavi vere (una Google API key e una Cohere). GitHub ha bloccato la push con
"GITHUB PUSH PROTECTION: Push cannot contain secrets". Il repo è PUBBLICO: quelle chiavi
non ci devono stare, e non si usa "allow the secret" (pubblicherebbe le chiavi).

Cosa fa:
  1. mette in pausa il postino (per non scrivere mentre si riscrive la storia)
  2. fa un backup dei file che tocca
  3. maschera in tutti i file del repo le stringhe che hanno l'aria di una chiave
  4. riscrive i commit locali (reset --soft sull'ultimo commit pubblicato + un commit
     nuovo con i file ripuliti): così le chiavi non arrivano MAI al remoto
  5. rimette in moto il postino

Uso:  bash ~/posta/fatti/ripulisci_report_chiavi.py
"""
import os
import re
import subprocess
import sys

REPO = os.path.expanduser("~/posta")
HOME = os.path.expanduser("~")

# formati di chiave noti (dal portachiavi) + stringhe lunghe a caso
MASCARE = [
    (re.compile(r"AIza[0-9A-Za-z_\-]{15,}"), "[CHIAVE-GOOGLE-RIMOSSA]"),
    (re.compile(r"\b(?:sk|gsk|ak|hf|nvapi|mstrl|cfut|ek|sk-or|sk-or-v1|sk-bl|sk-air|sk-nry|sk-navy|sk-xt|sk-speka|sk-free|oc_sk|cpk_)[A-Za-z0-9_\-\.]{12,}"), "[CHIAVE-RIMOSSA]"),
    (re.compile(r"\b[0-9a-f]{32}:[A-Za-z0-9_\-]{10,}"), "[CHIAVE-CLOUDFLARE-RIMOSSA]"),
    (re.compile(r"(?<![A-Za-z0-9_\-])[A-Za-z0-9_\-+/=]{32,}(?![A-Za-z0-9_\-])"), "[CHIAVE-RIMOSSA]"),
]
# gli hash dei commit (40 hex) NON sono segreti: non li mascheriamo
NON_MASKERARE = re.compile(r"^[0-9a-f]{40}$")


def sh(cmd, cwd=REPO):
    p = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    return (p.stdout + p.stderr).strip()


def maschera(testo):
    out = testo
    for rx, rimp in MASCARE:
        def sost(m):
            return rimp if not NON_MASKERARE.match(m.group(0)) else m.group(0)
        out = rx.sub(sost, out)
    return out


def main():
    os.chdir(REPO)
    print("1. fermo il postino (per 90 secondi)")
    sh("pkill -f 'postino\\.sh --loop'")

    print("2. stato del repo")
    print(sh("git status --short | head -10"))
    remoto = sh("git rev-parse origin/main").split("\n")[-1]
    print("   ultimo commit pubblicato:", remoto)

    print("3. backup dei report")
    bak = os.path.join(HOME, "posta_bak_0211")
    os.makedirs(bak, exist_ok=True)
    for root, _dirs, files in os.walk(REPO):
        if "/.git" in root:
            continue
        for f in files:
            if f.endswith(".md") or f.endswith(".json") or f.endswith(".txt"):
                src = os.path.join(root, f)
                try:
                    if os.path.getsize(src) > 4_000_000:
                        continue
                except OSError:
                    continue
                rel = os.path.relpath(src, REPO).replace(os.sep, "_")
                try:
                    with open(src, encoding="utf-8", errors="replace") as fh:
                        t = fh.read()
                except OSError:
                    continue
                if any(rx.search(t) for rx, _ in MASCARE):
                    with open(os.path.join(bak, rel), "w", encoding="utf-8") as fh:
                        fh.write(t)
                    print("   backup:", rel)

    print("4. maschero le chiavi nei file del repo")
    # Nei REPORT (quello che scrivono gli agenti) si maschera tutto quello che
    # ha l'aria di una chiave. Nel CODICE si maschera solo se c'e' un formato di
    # chiave noto: cosi' non si tocca una stringa lunga e legittima del programma.
    SOLO_REPORT = ("dal_pc", "fatti", "da_me", "RISPOSTE_AGENTI")
    toccati = []
    for root, dirs, files in os.walk(REPO):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules", "__pycache__")]
        for f in files:
            if not f.endswith((".md", ".txt", ".json", ".jsonl", ".py", ".sh")):
                continue
            src = os.path.join(root, f)
            rel = os.path.relpath(src, REPO)
            if rel.startswith(("posta_bak", "fatti/ripulisci")):
                continue
            e_report = rel.split(os.sep)[0] in SOLO_REPORT or rel.endswith(".md")
            try:
                if os.path.getsize(src) > 4_000_000:
                    continue
                with open(src, encoding="utf-8") as fh:
                    t = fh.read()
            except (OSError, UnicodeDecodeError):
                continue
            if e_report:
                t2 = maschera(t)
            else:
                # nel codice: solo i formati di chiave noti
                t2 = t
                for rx, rimp in MASCARE[:-1]:
                    t2 = rx.sub(rimp, t2)
            if t2 != t:
                with open(src, "w", encoding="utf-8") as fh:
                    fh.write(t2)
                toccati.append(rel)
                print("   ripulito:", rel)
    if not toccati:
        print("   (nessun file da ripulire: il problema era solo nella storia)")

    print("5. riscrivo i commit locali (le chiavi non arrivano mai al remoto)")
    sh(f"git reset --soft {remoto}")
    sh("git add -A dal_pc fatti da_me gui 2>/dev/null")
    sh("git add -A 2>/dev/null")
    if sh("git diff --cached --quiet"):
        print("   niente da committare")
    else:
        sh('git commit -q -m "postino: report ripuliti (chiavi mascherate) + risposta degli agenti"')
        print("   commit nuovo:", sh("git log --oneline -1"))

    print("6. push")
    out = sh("git push origin HEAD:main 2>&1 | tail -4")
    print("  ", out.replace("\n", "\n   "))

    print("7. riparto il postino")
    sh("nohup bash ~/posta/lavori/scorta_posta.sh >> /tmp/scorta_posta.log 2>&1 &")
    print("   guardiano rilanciato (il postino riparte entro un minuto)")

    print("8. verifica")
    print("   ultimo commit remoto:", sh("git rev-parse --short origin/main"))
    print("   file ripuliti:", len(toccati))
    return 0


if __name__ == "__main__":
    sys.exit(main())
