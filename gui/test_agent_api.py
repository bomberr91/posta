"""Contract tests for the current agents-as-clients gateway (offline only)."""
import os
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import server

MODEL_A = {"id": "nara", "provider": "NaraRouter", "modello": "laguna-s-2.1",
           "api_id": "nara/laguna-s-2.1", "verificato": True, "ms": 10}
MODEL_B = {"id": "provider-b", "provider": "Provider B", "modello": "free-b",
           "api_id": "provider-b/free-b", "verificato": True, "ms": 20}


class AgentApiTests(unittest.TestCase):
    def handler(self, path, body=None, headers=None):
        h = object.__new__(server.H)
        h.path = path
        h.headers = headers or {"Authorization": "Bearer test-token", "Content-Type": "application/json"}
        h._body = lambda: body or {}
        h.responses = []
        h._json = lambda obj, code=200: h.responses.append((code, obj))
        return h

    def test_empty_allowlist_exposes_no_models_and_prevents_provider_call(self):
        with patch.object(server, "HUB_AGENT_FREE_MODELS_VERIFIED", ()), \
             patch.object(server, "modelli_nostri", side_effect=AssertionError("empty allowlist must fail closed")):
            self.assertEqual([], server.modelli_agente_ammessi())
        h = self.handler("/v1/chat/completions", {"messages": [{"role": "user", "content": "hi"}]})
        with patch.object(server, "dettaglio_token_agente", return_value={"id": "test", "models": None}), \
             patch.object(server, "modelli_agente_ammessi", return_value=[]), \
             patch.object(server, "_posta_diretta") as upstream:
            h._do_POST()
        self.assertEqual(403, h.responses[-1][0])
        upstream.assert_not_called()

    def test_explicit_model_is_confined_to_token_scope(self):
        h = self.handler("/v1/chat/completions", {
            "model": MODEL_A["api_id"], "messages": [{"role": "user", "content": "hi"}]})
        with patch.object(server, "dettaglio_token_agente", return_value={"id": "a", "models": [MODEL_A["api_id"]]}), \
             patch.object(server, "modelli_agente_ammessi", return_value=[MODEL_A, MODEL_B]), \
             patch.object(server, "_posta_diretta", return_value=("mock answer", "", 0)) as upstream:
            h._do_POST()
        self.assertEqual(200, h.responses[-1][0])
        self.assertEqual(MODEL_A["api_id"], h.responses[-1][1]["model"])
        upstream.assert_called_once_with(MODEL_A, [{"role": "user", "content": "hi"}], quanti=900, timeout=70)

    def test_explicit_model_outside_token_scope_is_denied(self):
        h = self.handler("/v1/chat/completions", {
            "model": MODEL_B["api_id"], "messages": [{"role": "user", "content": "hi"}]})
        with patch.object(server, "dettaglio_token_agente", return_value={"id": "a", "models": [MODEL_A["api_id"]]}), \
             patch.object(server, "modelli_agente_ammessi", return_value=[MODEL_A, MODEL_B]), \
             patch.object(server, "_posta_diretta") as upstream:
            h._do_POST()
        self.assertEqual(403, h.responses[-1][0])
        upstream.assert_not_called()

    def test_automatic_model_stays_within_scope(self):
        h = self.handler("/v1/chat/completions", {
            "model": "auto", "messages": [{"role": "user", "content": "hi"}]})
        with patch.object(server, "dettaglio_token_agente", return_value={"id": "a", "models": [MODEL_A["api_id"]]}), \
             patch.object(server, "modelli_agente_ammessi", return_value=[MODEL_A, MODEL_B]), \
             patch.object(server, "_posta_diretta", return_value=("ok", "", 0)) as upstream:
            h._do_POST()
        self.assertEqual(200, h.responses[-1][0])
        upstream.assert_called_once()
        self.assertEqual(MODEL_A["api_id"], upstream.call_args.args[0]["api_id"])

    def test_streaming_and_tools_are_rejected_before_provider_call(self):
        for extra in ({"stream": True}, {"tools": []}, {"tool_choice": "auto"}):
            body = {"messages": [{"role": "user", "content": "hi"}], "model": MODEL_A["api_id"], **extra}
            h = self.handler("/v1/chat/completions", body)
            with patch.object(server, "dettaglio_token_agente", return_value={"id": "a", "models": [MODEL_A["api_id"]]}), \
                 patch.object(server, "modelli_agente_ammessi", return_value=[MODEL_A]), \
                 patch.object(server, "_posta_diretta") as upstream:
                h._do_POST()
            self.assertEqual(400, h.responses[-1][0])
            upstream.assert_not_called()

    def test_old_runner_routes_are_not_present_or_executable(self):
        for path in ("/api/agente", "/api/agente/stop", "/api/agenti/prova", "/api/agenti/installa", "/api/openclaw"):
            h = self.handler(path, {})
            with patch.object(server.subprocess, "Popen", side_effect=AssertionError("runner route must not execute")), \
                 patch.object(server.subprocess, "run", side_effect=AssertionError("runner route must not execute")):
                h._do_POST()
            self.assertEqual(404, h.responses[-1][0])


if __name__ == "__main__":
    unittest.main()
