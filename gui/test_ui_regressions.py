"""Offline regression checks for the integrated historical dashboard and local APIs."""
from __future__ import annotations

import http.client
import os
import sys
import threading
import unittest
from http.server import ThreadingHTTPServer
from pathlib import Path
from unittest.mock import patch

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

    def test_main_routes_serve_the_integrated_historical_dashboard(self):
        expected = (GUI / "hub.html").read_bytes()
        for path in ("/", "/index.html", "/hub", "/api/hub"):
            with self.subTest(path=path):
                status, headers, body = self.get(path)
                self.assertEqual(200, status)
                self.assertIn("text/html", headers.get("Content-Type", ""))
                self.assertEqual(expected, body)
                self.assertIn(b"Dashboard storica Posta", body)

    def test_ui_preserves_chat_history_fusion_focus_attachments_and_search(self):
        source = (GUI / "hub.html").read_text(encoding="utf-8")
        for marker in ("fh_chats", "fh_teams", "bFocus", "addFiles", "/api/search",
                       "fusionArchive", "/api/risultati"):
            with self.subTest(marker=marker):
                self.assertIn(marker, source)

    def test_ui_keeps_manual_browser_controls_and_real_settings_endpoints(self):
        source = (GUI / "hub.html").read_text(encoding="utf-8")
        for marker in ("Mostra browser", "Nascondi browser", "/api/browser",
                       "/api/modelli", "/api/agent-tokens", "/api/agent-tokens/revoke",
                       "/api/capacita", "/api/contabilita", "/api/salute",
                       "/api/ponte", "/api/checkin/stato", "/api/checkin/segna",
                       "/api/pc/aggiorna", "/api/appello"):
            with self.subTest(marker=marker):
                self.assertIn(marker, source)
        self.assertIn("confirm(", source)
        self.assertIn('details class="prov"><summary>🤳 Agenti → Router Hub', source)

    def test_ui_has_no_hub_to_agent_actions_or_freellmapi_routes(self):
        source = (GUI / "hub.html").read_text(encoding="utf-8").lower()
        for marker in ("/api/agenti", "/api/agente/stop", "/api/openclaw",
                       "/api/freellmapi", "freellmapi/models", "freellmapi/usage",
                       "free llm api"):
            with self.subTest(marker=marker):
                self.assertNotIn(marker, source)
        self.assertIn("agenti → router hub", source)

    def test_tokens_list_is_loopback_only_and_does_not_call_keyring(self):
        with patch.object(server, "modelli_agente_ammessi", return_value=[
                {"api_id": "nara/laguna-s-2.1"}]), \
             patch.object(server, "lista_token_agente", return_value=[
                {"id": "id1", "name": "test", "models": ["nara/laguna-s-2.1"]}]) as listed:
            status, _, body = self.get("/api/agent-tokens")
        self.assertEqual(200, status)
        self.assertIn(b"nara/laguna-s-2.1", body)
        self.assertNotIn(b"token\"", body)
        listed.assert_called_once_with()

    def test_removed_runner_and_service_routes_do_not_execute_processes(self):
        source = (GUI / "server.py").read_text(encoding="utf-8")
        for route in ("/api/agente\"", "/api/agente/stop", "/api/agenti/prova",
                      "/api/agenti/installa", "/api/openclaw", "/api/omniroute",
                      "/api/cervello", "/api/fusion"):
            with self.subTest(route=route):
                self.assertNotIn(route, source)
        self.assertNotIn("postino_bg()", source)
        self.assertNotIn("sveglia_checkin", source)


if __name__ == "__main__":
    unittest.main()
