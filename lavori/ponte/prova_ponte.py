# prova_ponte.py — crea una issue di prova e verifica il ciclo completo.
# Uso (in WSL, dalla cartella del ponte):
#   python3 prova_ponte.py crea     → apre la issue di test
#   python3 prova_ponte.py verifica → legge stato, commenti e consegna
import json
import sys
import urllib.parse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import poller  # noqa: E402  (usa api(), REPO, CFG della cartella locale)

CORPO = """target: test
consegna: /consegne/issue-TEST/

compito:
Test end-to-end del ponte: esegui il comando di prova e riporta l'output.

contesto:
Non toccare file. È il collaudo del canale.
"""

AZIONE = sys.argv[1] if len(sys.argv) > 1 else "crea"

if AZIONE == "crea":
    st, out = poller.api("POST", "issues", {
        "title": "PONTE: test end-to-end",
        "body": CORPO,
        "labels": ["inbox"],
    })
    print("creata" if st == 201 else f"errore {st}: {out}")
    if st == 201:
        print("issue #" + str(out["number"]))

elif AZIONE == "verifica":
    st, out = poller.api("GET", "issues?state=all&per_page=10")
    issue = next((i for i in out if i["title"].startswith("PONTE:")), None)
    if not issue:
        print("nessuna issue PONTE trovata")
        sys.exit(1)
    n = issue["number"]
    print(f"issue #{n} — stato: {issue['state']} — etichette: {[l['name'] for l in issue['labels']]}")
    st, com = poller.api("GET", f"issues/{n}/comments")
    if com:
        print("--- commenti:", len(com), "--- ultimo (inizio) ---")
        print(com[-1]["body"][:600])
    # consegna locale o nel repo
    st, _ = poller.api("GET", f"contents/consegne/{n}-test-end-to-end")
    if st == 200:
        print(f"consegna presente nel repo: /consegne/{n}-test-end-to-end/")
    else:
        locale = Path(__file__).resolve().parent / "consegne"
        print("consegna nel repo: NO — controllo locale:", list(locale.glob(f"{n}-*")))
