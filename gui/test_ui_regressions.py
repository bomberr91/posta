"""Regression checks for the Free LLM Hub entry point and critical UI controls.

All tests are local/offline; no provider calls are made.
"""
from __future__ import annotations

import http.client
import os
import socket
import subprocess
import sys
import threading
import time
import unittest
from http.server import ThreadingHTTPServer
from pathlib import Path

GUI = Path(__file__).resolve().parent
ROOT = GUI.parent
HUB = ROOT / "free-llm-hub"
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

    def test_centrale_g_starts_bundled_standalone_hub(self):
        source = (ROOT / "centrale.sh").read_text(encoding="utf-8")
        self.assertIn('FREE_LLM_HUB_DIR:-$HOME/posta/free-llm-hub', source)
        self.assertIn('"$HUB_NODE" dev.js', source)
        self.assertIn('"http://localhost:3000/"', source)
        self.assertNotIn('nohup python3 "$HOME/posta/gui/server.py"', source)
        self.assertTrue((HUB / "dev.js").is_file())

    def test_standalone_hub_starts_and_serves_real_dashboard_offline(self):
        index = (HUB / "index.html").read_text(encoding="utf-8")
        self.assertIn("['auto:fast'", index)
        self.assertIn("['auto:smart'", index)
        self.assertIn("includes('parlalibero')", index)
        self.assertIn("function openSettings()", index)
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        env = os.environ.copy()
        env["PORT"] = str(port)
        proc = subprocess.Popen(["node", "dev.js"], cwd=HUB, env=env,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            response = None
            for _ in range(40):
                if proc.poll() is not None:
                    self.fail("Free LLM Hub dev.js è terminato prima di rispondere")
                try:
                    conn = http.client.HTTPConnection("127.0.0.1", port, timeout=1)
                    conn.request("GET", "/")
                    response = conn.getresponse()
                    body = response.read().decode("utf-8")
                    conn.close()
                    break
                except OSError:
                    time.sleep(0.1)
            self.assertIsNotNone(response, "Free LLM Hub non è diventato pronto")
            self.assertEqual(response.status, 200)
            self.assertIn("<title>⚡ Free LLM Hub</title>", body)
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=3)

    def test_omniroute_has_no_background_autostart(self):
        source = (GUI / "server.py").read_text(encoding="utf-8")
        self.assertNotIn("def _sorveglianza", source)
        self.assertNotIn("Thread(target=_sorveglianza", source)
        self.assertIn("OmniRoute è opzionale: si avvia solo con un comando esplicito", source)


if __name__ == "__main__":
    unittest.main()
