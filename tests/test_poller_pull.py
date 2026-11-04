"""Test meccanico del poller: la consegna deve tirare avanti il repo PRIMA di pushare.

Perché questo file esiste (4/11): il poller faceva `commit` + `push` senza
`pull`. Se nel frattempo arrivava un push dal sandbox, Git rispondeva
"rejected (fetch first)" e la consegna si perdeva: ripartiva al tentativo
successivo, con l'errore in mezzo. Il test è meccanico (legge il sorgente) e
non fa rete, come gli altri test del repo.
"""
from __future__ import annotations

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
SRC = (ROOT / "lavori" / "ponte" / "poller.py").read_text(encoding="utf-8")


def blocco_git_lock() -> str:
    m = re.search(r"with GIT_LOCK:(.*?)\n\s*commenta\(", SRC, re.S)
    assert m is not None, "blocco GIT_LOCK non trovato in poller.py"
    return m.group(1)


class TestPullPrimaDelPush(unittest.TestCase):
    def test_ordine_pull_add_commit_push(self):
        blocco = blocco_git_lock()
        i_pull = blocco.find('"pull"')
        i_add = blocco.find('"add"')
        i_commit = blocco.find('"commit"')
        i_push = blocco.find('"push"')
        for nome, i in (("pull", i_pull), ("add", i_add), ("commit", i_commit), ("push", i_push)):
            self.assertNotEqual(i, -1, "'%s' non trovato nel blocco GIT_LOCK" % nome)
        self.assertLess(i_pull, i_add, "il pull deve venire PRIMA dell'add")
        self.assertLess(i_pull, i_commit, "il pull deve venire PRIMA del commit")
        self.assertLess(i_pull, i_push, "il pull deve venire PRIMA del push")

    def test_pull_tollerata(self):
        blocco = blocco_git_lock()
        self.assertIn("except Exception", blocco,
                      "la pull deve essere tollerata: se fallisce non si perde la consegna")

    def test_git_ha_ancora_il_tetto_di_180s(self):
        self.assertIn("TIMEOUT dopo 180s", SRC, "il tetto dei 180s sui comandi git e' sparito")
        self.assertIn("GIT_TERMINAL_PROMPT", SRC, "manca GIT_TERMINAL_PROMPT=0")


if __name__ == "__main__":
    unittest.main()
