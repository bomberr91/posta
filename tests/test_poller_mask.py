"""Test meccanico: il poller non deve mai pushare una chiave vera nel repo pubblico.

Perché (4/11, issue #31): l'agente ha stampato la config di Deep Dog con le
chiavi vere dentro la consegna; il repo `posta` è PUBBLICO e GitHub ha respinto
la push ("GH013 - Push cannot contain secrets"). Da lì ogni push dal PC è
fallito: il ponte era bloccato. Ora il poller maschera le chiavi prima di
committare.
"""
from __future__ import annotations

import importlib.util
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


def carica_poller():
    spec = importlib.util.spec_from_file_location("poller_sotto_test", ROOT / "lavori" / "ponte" / "poller.py")
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(mod)
    except SystemExit:
        pass
    return mod


class TestMascheraChiavi(unittest.TestCase):
    def setUp(self):
        self.p = carica_poller()

    def test_maschera_i_formati_noti(self):
        for finto in ("sk-or-v1-ABCDEFGHIJKLMNOPQRST1234",
                      "sk-ABCDEFGHIJKLMNOPQRSTUVWXYZ012345",
                      "tvly-dev-ABCDEFGHIJKLMNOPQRSTUV",
                      "ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123",
                      "github_pat_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123",
                      "AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ0123456"):
            out = self.p.maschera_chiavi("prima " + finto + " dopo")
            self.assertNotIn(finto, out, "la chiave finta è rimasta in chiaro: %s" % finto)
            self.assertIn("«chiave mascherata»", out)

    def test_non_tocca_url_ne_id(self):
        testo = ("http://www.youtube.com/channel/UC-ZuePAdIniJxvDCmZdBjqQ "
                 "https://github.com/bomberr91/posta/issues/31 "
                 "UC02VvEY6t-Z9urq5SPS6O-A")
        self.assertEqual(self.p.maschera_chiavi(testo), testo,
                         "il mascheramento ha toccato un URL o un id di canale")

    def test_la_consegna_e_mascherata_prima_del_commit(self):
        src = (ROOT / "lavori" / "ponte" / "poller.py").read_text(encoding="utf-8")
        i_mask = src.find("stdout_tail = maschera_chiavi(stdout_tail)")
        i_write = src.find('(d / "RISULTATO.md").write_text')
        self.assertNotEqual(i_mask, -1, "stdout/stderr non sono mascherati")
        self.assertNotEqual(i_write, -1, "RISULTATO.md non trovato")
        self.assertLess(i_mask, i_write, "la mascheratura deve venire PRIMA della scrittura")


if __name__ == "__main__":
    unittest.main()
