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

    def test_root_redirects_to_hub_not_legacy_centrale(self):
        status, headers, body = self.get("/")
        self.assertEqual(status, 302)
        self.assertEqual(headers.get("Location"), "/hub")
        self.assertEqual(body, b"")

    def test_hub_route_contains_model_selector_and_settings_controls(self):
        status, _, body = self.get("/hub")
        html = body.decode("utf-8")
        self.assertEqual(status, 200)
        self.assertIn("<title>⚡ Free LLM Hub</title>", html)
        for element_id in ("model", "gear", "gear2"):
            self.assertIn(f'id="{element_id}"', html)

    def test_selector_has_offline_defaults_and_fetches_live_models(self):
        html = (GUI / "hub.html").read_text(encoding="utf-8")
        self.assertIn("['auto:smart','automatico · migliore']", html)
        self.assertIn("['auto:fast','automatico · più veloce']", html)
        self.assertIn("fetch('/api/modelli', { cache:'no-store' })", html)
        self.assertIn("width:min(320px,100%)", html)

    def test_redundant_agents_card_is_removed_but_status_poll_remains(self):
        html = (GUI / "hub.html").read_text(encoding="utf-8")
        self.assertNotIn('id="agAgentiCard"', html)
        self.assertNotIn('id="agListaAgenti"', html)
        self.assertIn("window._agenti = Array.isArray(d.agenti)", html)

    def test_omniroute_has_no_background_autostart(self):
        source = (GUI / "server.py").read_text(encoding="utf-8")
        self.assertNotIn("def _sorveglianza", source)
        self.assertNotIn("Thread(target=_sorveglianza", source)
        self.assertIn("OmniRoute è opzionale: si avvia solo con un comando esplicito", source)

    def test_centrale_g_opens_hub_path(self):
        source = (ROOT / "centrale.sh").read_text(encoding="utf-8")
        self.assertIn('"http://localhost:20200/hub"', source)
        self.assertNotIn('"http://localhost:20200" 2>/dev/null', source)


if __name__ == "__main__":
    unittest.main()
