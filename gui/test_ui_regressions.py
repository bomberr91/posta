"""Regression checks for the Free LLM Hub entry point and critical UI controls.

All tests are local/offline; no provider calls are made.
"""
from __future__ import annotations

import hashlib
import http.client
import os
import shutil
import socket
import subprocess
import sys
import tempfile
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
        helper = (ROOT / "apri_free_llm_hub.sh").read_text(encoding="utf-8")
        self.assertIn('FREE_LLM_HUB_DIR:-$HOME/posta/free-llm-hub', helper)
        self.assertIn('bash "$HOME/posta/apri_free_llm_hub.sh"', source)
        self.assertIn('FREE_LLM_HUB_PORT:-3000', helper)
        self.assertNotIn('nohup python3 "$HOME/posta/gui/server.py"', source)
        self.assertEqual((HUB / "SOURCE_COMMIT").read_text().strip(),
                         "1277fefc33ecd6b6fdd1db2e0568713bbd941b3a")
        self.assertTrue((HUB / "dev.js").is_file())

    def test_bundled_ui_is_the_selected_hub_centrale_preview(self):
        source = (HUB / "UI_SOURCE").read_text(encoding="utf-8")
        digest = hashlib.sha256((HUB / "index.html").read_bytes()).hexdigest()
        self.assertIn("HUB_CENTRALE/ANTEPRIME/ANTEPRIMA_HUB_AGENTI.html", source)
        self.assertEqual(digest, "83ed42a7f133b4a450a0d58e3b7fd712b3ad2dabdf6b8a1d89aaf6f627fd623a")

    def test_removed_model_and_24h_usage_counter_are_absent_from_ui_and_runtime(self):
        index = (HUB / "index.html").read_text(encoding="utf-8")
        dev = (HUB / "dev.js").read_text(encoding="utf-8")
        self.assertNotIn("['Libero'", index)
        self.assertNotIn("parla di tutto", index.lower())
        self.assertNotIn("indexOf('Libero')", index)
        for marker in ('id="usage"', 'usageN', 'refreshUsageReal', 'usageReal',
                       'bumpUsage', 'fh_usagereal', '/api/freellmapi/usage', 'Uso REALE'):
            self.assertNotIn(marker, index)
        self.assertNotIn('fllmUsage', dev)
        self.assertNotIn("/api/freellmapi/usage", dev)
        self.assertFalse((HUB / "api/freellmapi/usage.js").exists())

    def test_standalone_hub_starts_and_serves_real_dashboard_offline(self):
        index = (HUB / "index.html").read_text(encoding="utf-8")
        self.assertIn("<title>⚡ Free LLM Hub</title>", index)
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
            self.assertEqual(body, index)
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=3)

    def test_launcher_replaces_stale_hub_instead_of_opening_a_second_version(self):
        with tempfile.TemporaryDirectory(prefix="hub-stale-test-") as tmp:
            home = Path(tmp) / "home"
            stale = home / "free-llm-hub"
            home.mkdir()
            shutil.copytree(HUB, stale)
            stale_index = stale / "index.html"
            stale_index.write_text(stale_index.read_text(encoding="utf-8") + "\\n<!-- stale build -->\\n",
                                   encoding="utf-8")
            with socket.socket() as sock:
                sock.bind(("127.0.0.1", 0))
                port = sock.getsockname()[1]
            stale_env = os.environ.copy()
            stale_env.update({"HOME": str(home), "PORT": str(port)})
            old = subprocess.Popen(["node", "dev.js"], cwd=stale, env=stale_env,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            try:
                for _ in range(40):
                    if old.poll() is not None:
                        self.fail("il server Hub obsoleto è terminato prima del test")
                    try:
                        conn = http.client.HTTPConnection("127.0.0.1", port, timeout=1)
                        conn.request("GET", "/")
                        response = conn.getresponse()
                        response.read()
                        conn.close()
                        break
                    except OSError:
                        time.sleep(0.1)
                launcher_env = stale_env.copy()
                launcher_env.update({"FREE_LLM_HUB_DIR": str(HUB),
                                     "FREE_LLM_HUB_PORT": str(port),
                                     "FREE_LLM_HUB_NO_OPEN": "1"})
                subprocess.run(["bash", str(ROOT / "apri_free_llm_hub.sh")], env=launcher_env,
                               check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                               timeout=20)
                self.assertIsNotNone(old.poll(), "il processo obsoleto non è stato sostituito")
                conn = http.client.HTTPConnection("127.0.0.1", port, timeout=2)
                conn.request("GET", "/")
                response = conn.getresponse()
                body = response.read().decode("utf-8")
                conn.close()
                self.assertEqual(response.status, 200)
                self.assertEqual(body, (HUB / "index.html").read_text(encoding="utf-8"))
            finally:
                if old.poll() is None:
                    old.terminate()
                    old.wait(timeout=3)
                for proc in Path("/proc").glob("[0-9]*"):
                    try:
                        if os.path.realpath(proc / "cwd") == str(HUB) and "dev.js" in (proc / "cmdline").read_bytes().decode(errors="ignore"):
                            envtext = (proc / "environ").read_bytes().decode(errors="ignore")
                            if f"PORT={port}" in envtext:
                                os.kill(int(proc.name), 15)
                    except (OSError, ValueError, PermissionError):
                        pass

    def test_desktop_gui_shortcut_opens_pinned_standalone_hub(self):
        shortcut = (ROOT / "8_CENTRALE_GUI.bat").read_text(encoding="ascii")
        helper = (ROOT / "apri_free_llm_hub.sh").read_text(encoding="utf-8")
        self.assertIn("apri_free_llm_hub.sh", shortcut)
        self.assertNotIn("gui/server.py", shortcut)
        self.assertIn('HUB_REVISION="1277fefc33ecd6b6fdd1db2e0568713bbd941b3a"', helper)
        self.assertIn('FREE_LLM_HUB_PORT:-3000', helper)
        self.assertIn('EXPECTED_SHA=', helper)
        self.assertIn('LIVE_SHA="$(live_sha)"', helper)
        self.assertIn('SOURCE_COMMIT', helper)

    def test_omniroute_has_no_background_autostart(self):
        source = (GUI / "server.py").read_text(encoding="utf-8")
        self.assertNotIn("def _sorveglianza", source)
        self.assertNotIn("Thread(target=_sorveglianza", source)
        self.assertIn("OmniRoute è opzionale: si avvia solo con un comando esplicito", source)


if __name__ == "__main__":
    unittest.main()
