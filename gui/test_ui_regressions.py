"""Regression checks for the Free LLM Hub entry point and critical UI controls.

All tests are local/offline; no provider calls are made.
"""
from __future__ import annotations

import http.client
import sys
import threading
import unittest
from http.server import ThreadingHTTPServer
from pathlib import Path

GUI = Path(__file__).resolve().parent
ROOT = GUI.parent
sys.path.insert(0, str(GUI))
import server  # noqa: E402


class HubUiRegressionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.httpd = ThreadingHTTPServer(("127.0.0.1", 0), server.H)
        cls.thread = threading.Thread(target=cls.httpd.serve_forever, daemon=True)
        cls.thread.start()
        cls.port = cls.httpd.server_address[1]

    @classmethod
    def tearDownClass(cls):
        cls.httpd.shutdown()
        cls.httpd.server_close()
        cls.thread.join(timeout=2)

    def get(self, path):
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=3)
        conn.request("GET", path)
        response = conn.getresponse()
        status, headers, body = response.status, dict(response.getheaders()), response.read()
        conn.close()
        return status, headers, body

    def test_old_gui_urls_redirect_to_standalone_free_llm_hub(self):
        for path in ("/", "/index.html", "/hub", "/api/hub"):
            with self.subTest(path=path):
                status, headers, body = self.get(path)
                self.assertEqual(status, 302)
                self.assertEqual(headers.get("Location"), "http://localhost:3000/")
                self.assertEqual(body, b"")

    def test_centrale_g_starts_standalone_hub_not_legacy_gui(self):
        source = (ROOT / "centrale.sh").read_text(encoding="utf-8")
        self.assertIn('FREE_LLM_HUB_DIR:-$HOME/free-llm-hub', source)
        self.assertIn('"$HUB_NODE" dev.js', source)
        self.assertIn('"http://localhost:3000/"', source)
        self.assertNotIn('nohup python3 "$HOME/posta/gui/server.py"', source)

    def test_omniroute_has_no_background_autostart(self):
        source = (GUI / "server.py").read_text(encoding="utf-8")
        self.assertNotIn("def _sorveglianza", source)
        self.assertNotIn("Thread(target=_sorveglianza", source)
        self.assertIn("OmniRoute è opzionale: si avvia solo con un comando esplicito", source)


if __name__ == "__main__":
    unittest.main()
