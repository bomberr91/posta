# -*- coding: utf-8 -*-
"""Test offline dell'API agenti: nessuna rete e nessuna chiamata provider."""
import os
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import server


MODEL_A = {"id": "provider-a", "provider": "Provider A", "modello": "model-a",
           "api_id": "provider-a/model-a", "verificato": True, "ms": 10}
MODEL_B = {"id": "provider-b", "provider": "Provider B", "modello": "model-b",
           "api_id": "provider-b/model-b", "verificato": True, "ms": 20}


class AgentApiTests(unittest.TestCase):
    def setUp(self):
        self.old_allow = server.HUB_AGENT_FREE_MODELS_VERIFIED

    def tearDown(self):
        server.HUB_AGENT_FREE_MODELS_VERIFIED = self.old_allow

    def handler(self, path, body=None, headers=None):
        h = object.__new__(server.H)
        h.path = path
        h.headers = headers or {"Authorization": "Bearer test-token"}
        h._body = lambda: body or {}
        h.responses = []
        h._json = lambda obj, code=200: h.responses.append((code, obj))
        return h

    def test_allowlist_empty_exposes_no_models_or_calls(self):
        server.HUB_AGENT_FREE_MODELS_VERIFIED = ()
        with patch.object(server, "modelli_nostri") as models:
            self.assertEqual([], server.modelli_agente_ammessi())
            models.assert_not_called()
        h = self.handler("/v1/chat/completions", {"messages": [{"role": "user", "content": "hi"}]})
        with patch.object(server, "agente_autorizzato", return_value=True), \
             patch.object(server, "_posta_diretta") as upstream:
            h._do_POST()
            self.assertEqual(403, h.responses[-1][0])
            upstream.assert_not_called()

    def test_allowlist_matches_canonical_id_and_requires_verified(self):
        server.HUB_AGENT_FREE_MODELS_VERIFIED = ("provider-a/model-a", "provider-b/model-b")
        unverified = dict(MODEL_B, verificato=False)
        with patch.object(server, "modelli_nostri", return_value=[MODEL_A, unverified]):
            allowed = server.modelli_agente_ammessi()
        self.assertEqual(["provider-a/model-a"], [m["api_id"] for m in allowed])

    def test_auto_candidates_are_subset_of_allowlist(self):
        allowed = [MODEL_A, MODEL_B]
        chosen = server.candidati_agente("auto", allowed)
        self.assertEqual({m["api_id"] for m in allowed}, {m["api_id"] for m in chosen})

    def test_explicit_model_first_then_allowlisted_fallback(self):
        chosen = server.candidati_agente("provider-b/model-b", [MODEL_A, MODEL_B])
        self.assertEqual("provider-b/model-b", chosen[0]["api_id"])
        self.assertEqual({"provider-a/model-a", "provider-b/model-b"}, {m["api_id"] for m in chosen})
        with self.assertRaises(ValueError):
            server.candidati_agente("paid/unknown", [MODEL_A, MODEL_B])

    def test_chat_explicit_fallback_is_visible_and_confined(self):
        h = self.handler("/v1/chat/completions", {
            "messages": [{"role": "user", "content": "hi"}],
            "model": "provider-a/model-a", "max_tokens": 77,
        })
        with patch.object(server, "agente_autorizzato", return_value=True), \
             patch.object(server, "modelli_agente_ammessi", return_value=[MODEL_A, MODEL_B]), \
             patch.object(server, "_posta_diretta", side_effect=[("", "unavailable", 0), ("ok", "", 0)]) as upstream:
            h._do_POST()
        self.assertEqual(200, h.responses[-1][0])
        payload = h.responses[-1][1]
        self.assertEqual("provider-b/model-b", payload["model"])
        self.assertIn("fallback allowlisted", payload["via"])
        self.assertEqual(2, upstream.call_count)
        self.assertEqual(77, upstream.call_args_list[0].kwargs["quanti"])

    def test_stream_and_tools_rejected_before_upstream(self):
        for extra in ({"stream": True}, {"tools": []}, {"tool_choice": "auto"}):
            body = {"messages": [{"role": "user", "content": "hi"}], "model": "provider-a/model-a", **extra}
            h = self.handler("/v1/chat/completions", body)
            with patch.object(server, "agente_autorizzato", return_value=True), \
                 patch.object(server, "modelli_agente_ammessi", return_value=[MODEL_A]), \
                 patch.object(server, "_posta_diretta") as upstream:
                h._do_POST()
                self.assertEqual(400, h.responses[-1][0])
                upstream.assert_not_called()

    def test_runner_endpoints_fail_closed(self):
        for path in ("/api/agente", "/api/agente/stop"):
            h = self.handler(path)
            h._do_POST()
            self.assertEqual(403, h.responses[-1][0])

    def test_bearer_parsing_is_strict(self):
        with patch.object(server, "token_agente", return_value="test-token"), \
             patch.dict(os.environ, {"HUB_TOKEN": ""}):
            self.assertTrue(server.agente_autorizzato("Bearer test-token"))
            self.assertTrue(server.agente_autorizzato("bearer test-token"))
            self.assertFalse(server.agente_autorizzato("test-token"))
            self.assertFalse(server.agente_autorizzato("BearerX test-token"))
            self.assertFalse(server.agente_autorizzato("Bearer wrong"))


if __name__ == "__main__":
    unittest.main()
