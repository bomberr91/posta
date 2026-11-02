"""L'estrattore deve trovare la chiave sia con le righe a pallino sia con
quelle numerate (2/11 sera: il portachiavi e' stato rinumerato)."""
import os
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHIAVE_DI = os.path.join(ROOT, "chiave_di.py")

RIGA_PALLINO = "- **Groq** — gsk_CHIAVE_FINTA_0123456789abcdefghij — https://api.groq.com/openai/v1"
RIGA_NUMERATA = "12. **Groq** — gsk_CHIAVE_FINTA_0123456789abcdefghij — https://api.groq.com/openai/v1"
CHIAVE = "gsk_CHIAVE_FINTA_0123456789abcdefghij"


class TestChiaveDi(unittest.TestCase):
    def _estrai(self, riga):
        with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as f:
            f.write(riga + "\n")
            percorso = f.name
        try:
            out = subprocess.run([sys.executable, CHIAVE_DI, "Groq"], capture_output=True, text=True,
                                 env={**os.environ, "CHIAVI_FILE": percorso}).stdout.strip()
        finally:
            os.unlink(percorso)
        return out

    def test_pallino(self):
        self.assertEqual(self._estrai(RIGA_PALLINO), CHIAVE)

    def test_numerata(self):
        self.assertEqual(self._estrai(RIGA_NUMERATA), CHIAVE)

    def test_non_trova_riga_stravisa(self):
        """Una riga numerata NON deve far pescare la chiave di un altro provider."""
        testo = ("1. **Altro** — sk-altro-altro-altro-altro-1234 — x\n"
                 "2. **Groq** — " + CHIAVE + " — y\n")
        with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as f:
            f.write(testo)
            percorso = f.name
        try:
            out = subprocess.run([sys.executable, CHIAVE_DI, "Groq"], capture_output=True, text=True,
                                 env={**os.environ, "CHIAVI_FILE": percorso}).stdout.strip()
        finally:
            os.unlink(percorso)
        self.assertEqual(out, CHIAVE)


if __name__ == "__main__":
    unittest.main()
