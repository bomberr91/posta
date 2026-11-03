# prova_parallela.py — crea 3 issue lente per collaudare max_paralleli
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import poller  # noqa: E402

CORPO = "compito:\nDormi 8 secondi e riferisci.\n\ncontesto:\nCollaudo parallelo.\n"
for i, tgt in enumerate(["testlento", "testlento2", "testlento3"], 1):
    st, out = poller.api("POST", "issues", {
        "title": f"PONTE: prova parallela {i} ({tgt})",
        "body": f"target: {tgt}\n\n{CORPO}",
        "labels": ["inbox"],
    })
    print("creata #" + str(out["number"]) if st == 201 else f"errore {st}: {out}")
