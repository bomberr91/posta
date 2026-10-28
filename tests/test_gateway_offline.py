"""Offline contract tests for the local Hub gateway.

These tests intentionally import the handler without starting an HTTP server and
mock all provider/router transports. They must never read the real keyring or make
network calls.
"""
from __future__ import annotations

import email.message
import importlib.util
import io
import json
import os
from pathlib import Path
import stat
import tempfile
import types
import unittest
from unittest.mock import patch
import urllib.error
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
_TEST_HOME = tempfile.TemporaryDirectory(prefix="hub-gateway-test-home-")
_OLD_HOME = os.environ.get("HOME")
_OLD_NO_POSTINO = os.environ.get("CENTRALE_NO_POSTINO")
os.environ["HOME"] = _TEST_HOME.name
os.environ["CENTRALE_NO_POSTINO"] = "1"
try:
    spec = importlib.util.spec_from_file_location("hub_gateway_test_module", ROOT / "gui" / "server.py")
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load gui/server.py")
    hub = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(hub)
finally:
    if _OLD_HOME is None:
        os.environ.pop("HOME", None)
    else:
        os.environ["HOME"] = _OLD_HOME
    if _OLD_NO_POSTINO is None:
        os.environ.pop("CENTRALE_NO_POSTINO", None)
    else:
        os.environ["CENTRALE_NO_POSTINO"] = _OLD_NO_POSTINO


class Headers:
    """Tiny case-insensitive stand-in for the HTTP message headers."""

    def __init__(self, values=None):
        self._values = {str(k).lower(): v for k, v in (values or {}).items()}

    def get(self, name, default=None):
        return self._values.get(str(name).lower(), default)


class FakeHandler:
    def __init__(self, path, headers=None, body=None):
        self.path = path
        self.headers = Headers(headers)
        self.body = body or {}
        self.responses = []
        self.client_address = ("127.0.0.1", 54321)

    def _json(self, obj, code=200):
        self.responses.append((code, obj))

    def _body(self):
        return self.body


class FakeResponse:
    def __init__(self, value):
        self.value = value

    def read(self):
        return json.dumps(self.value).encode("utf-8")


class GatewayOfflineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="hub-gateway-test-")
        self.addCleanup(self.temp.cleanup)
        self.token_path = Path(self.temp.name) / "agent-token.txt"
        self.token_path.write_text("unit-test-token", encoding="utf-8")
        self.old_token_path = hub.TOKEN_AGENTE
        hub.TOKEN_AGENTE = str(self.token_path)
        self.addCleanup(setattr, hub, "TOKEN_AGENTE", self.old_token_path)
        self.old_hub_token = os.environ.pop("HUB_TOKEN", None)
        self.addCleanup(self._restore_hub_token)
        no_network = patch("urllib.request.urlopen", side_effect=AssertionError("offline test attempted urlopen"))
        no_network.start()
        self.addCleanup(no_network.stop)
        self.old_key = hub.CHIAVE_HUB.get("k", "")
        self.addCleanup(hub.CHIAVE_HUB.__setitem__, "k", self.old_key)
        self.old_rota = hub._ROTA
        hub._ROTA = {"giorno": "", "provider": {}, "storia": {}}
        self.addCleanup(setattr, hub, "_ROTA", self.old_rota)
        hub._MOTIVI.clear()

    @staticmethod
    def _restore_hub_token():
        os.environ.pop("HUB_TOKEN", None)

    def response(self, handler):
        self.assertEqual(len(handler.responses), 1)
        return handler.responses[0]

    def test_token_generated_with_restrictive_file_permissions(self):
        self.token_path.unlink()
        token = hub.token_agente()
        self.assertTrue(token.startswith("hub-"))
        self.assertEqual(stat.S_IMODE(self.token_path.stat().st_mode), 0o600)
        self.assertEqual(hub.token_agente(), token)

    def test_bearer_auth_accepts_valid_token_and_case_insensitive_scheme(self):
        self.assertTrue(hub.agente_autorizzato("Bearer unit-test-token"))
        self.assertTrue(hub.agente_autorizzato("bEaReR   unit-test-token"))
        self.assertTrue(hub.agente_autorizzato("BEARER\tunit-test-token"))

    def test_bearer_auth_rejects_missing_wrong_and_malformed_headers(self):
        for header in (None, "", "Basic unit-test-token", "Bearer", "Bearer ",
                       "Bearer unit-test-token extra", "BearerBearer unit-test-token"):
            with self.subTest(header=header):
                self.assertFalse(hub.agente_autorizzato(header))
        self.assertFalse(hub.agente_autorizzato("Bearer other-token"))

    def test_token_file_replacement_revokes_old_token_immediately(self):
        self.assertTrue(hub.agente_autorizzato("Bearer unit-test-token"))
        self.token_path.write_text("rotated-test-token\n", encoding="utf-8")
        self.assertFalse(hub.agente_autorizzato("Bearer unit-test-token"))
        self.assertTrue(hub.agente_autorizzato("Bearer rotated-test-token"))

    def test_environment_token_overrides_file_token(self):
        os.environ["HUB_TOKEN"] = "environment-test-token"
        self.assertFalse(hub.agente_autorizzato("Bearer unit-test-token"))
        self.assertTrue(hub.agente_autorizzato("Bearer environment-test-token"))

    def test_models_route_requires_auth_before_listing_models(self):
        handler = FakeHandler("/v1/models")
        with patch.object(hub, "modelli_nostri", side_effect=AssertionError("must not list models")):
            hub.H.do_GET(handler)
        code, payload = self.response(handler)
        self.assertEqual(code, 401)
        self.assertIn("error", payload)

    def test_models_route_exposes_only_allowlisted_verified_models(self):
        eligible = [{"api_id": "test/test-model", "id": "test", "provider": "test",
                     "modello": "test-model"}]
        handler = FakeHandler("/v1/models", {"Authorization": "Bearer unit-test-token"})
        with patch.object(hub, "modelli_agente_ammessi", return_value=eligible) as listing:
            hub.H.do_GET(handler)
        code, payload = self.response(handler)
        self.assertEqual(code, 200)
        self.assertEqual({m["id"] for m in payload["data"]}, {"test/test-model"})
        listing.assert_called_once_with()

    def test_token_copy_endpoint_allows_local_same_origin_request(self):
        handler = FakeHandler("/api/agente-token", {
            "Host": "localhost:20200", "Origin": "http://localhost:20200"})
        hub.H.do_GET(handler)
        code, payload = self.response(handler)
        self.assertEqual(code, 200)
        self.assertEqual(payload["token"], "unit-test-token")

    def test_token_copy_endpoint_blocks_foreign_origin(self):
        handler = FakeHandler("/api/agente-token", {
            "Host": "localhost:20200", "Origin": "https://remote.invalid"})
        hub.H.do_GET(handler)
        code, _ = self.response(handler)
        self.assertEqual(code, 403)

    def test_token_copy_endpoint_blocks_remote_peer_even_with_forged_local_headers(self):
        handler = FakeHandler("/api/agente-token", {
            "Host": "localhost:20200", "Origin": "http://localhost:20200"})
        handler.client_address = ("203.0.113.9", 54321)
        hub.H.do_GET(handler)
        code, _ = self.response(handler)
        self.assertEqual(code, 403)

    def test_token_copy_endpoint_blocks_host_origin_mismatch(self):
        handler = FakeHandler("/api/agente-token", {
            "Host": "localhost:20200", "Origin": "http://127.0.0.1:20200"})
        hub.H.do_GET(handler)
        code, _ = self.response(handler)
        self.assertEqual(code, 403)

    def test_token_copy_endpoint_blocks_nonlocal_host_even_with_local_peer(self):
        handler = FakeHandler("/api/agente-token", {
            "Host": "attacker.invalid", "Origin": "http://attacker.invalid"})
        hub.H.do_GET(handler)
        code, _ = self.response(handler)
        self.assertEqual(code, 403)

    def test_token_copy_endpoint_normalizes_ipv4_mapped_loopback_peer(self):
        handler = FakeHandler("/api/agente-token", {
            "Host": "localhost:20200", "Origin": "http://localhost:20200"})
        handler.client_address = ("::ffff:127.0.0.1", 54321)
        hub.H.do_GET(handler)
        code, _ = self.response(handler)
        self.assertEqual(code, 200)

    def test_chat_route_rejects_unauthorized_request_without_calling_router(self):
        handler = FakeHandler("/v1/chat/completions", {"Content-Type": "application/json"},
                              {"messages": [{"role": "user", "content": "offline"}]})
        with patch.object(hub, "chat_riposta", side_effect=AssertionError("must not route")):
            hub.H._do_POST(handler)
        code, _ = self.response(handler)
        self.assertEqual(code, 401)

    def test_chat_route_rejects_empty_messages_without_calling_router(self):
        handler = FakeHandler("/v1/chat/completions", {
            "Content-Type": "application/json", "Authorization": "Bearer unit-test-token"}, {})
        with patch.object(hub, "chat_riposta", side_effect=AssertionError("must not route")):
            hub.H._do_POST(handler)
        code, payload = self.response(handler)
        self.assertEqual(code, 400)
        self.assertIn("messages", payload["error"]["message"])

    def test_chat_route_uses_allowlisted_router_response(self):
        messages = [{"role": "user", "content": "offline"}]
        candidate = {"api_id": "test/test-model", "id": "test", "provider": "test",
                     "modello": "test-model", "ms": 10}
        handler = FakeHandler("/v1/chat/completions", {
            "Content-Type": "application/json", "Authorization": "Bearer unit-test-token"},
            {"model": "test/test-model", "messages": messages})
        with (patch.object(hub, "modelli_agente_ammessi", return_value=[candidate]),
              patch.object(hub, "_posta_diretta", return_value=("mock answer", "", 0)) as route):
            hub.H._do_POST(handler)
        route.assert_called_once_with(candidate, messages, quanti=900, timeout=70)
        code, payload = self.response(handler)
        self.assertEqual(code, 200)
        self.assertEqual(payload["choices"][0]["message"]["content"], "mock answer")

    def test_wrong_post_content_type_is_rejected_before_body_parse(self):
        handler = FakeHandler("/v1/chat/completions", {"Content-Type": "text/plain"})
        handler._body = lambda: (_ for _ in ()).throw(AssertionError("body must not be parsed"))
        hub.H._do_POST(handler)
        code, _ = self.response(handler)
        self.assertEqual(code, 415)

    def test_foreign_post_origin_is_rejected_before_router_call(self):
        handler = FakeHandler("/v1/chat/completions", {
            "Content-Type": "application/json", "Origin": "https://remote.invalid",
            "Authorization": "Bearer unit-test-token"},
            {"model": "auto:smart", "messages": [{"role": "user", "content": "offline"}]})
        with patch.object(hub, "chat_riposta", side_effect=AssertionError("must not route")):
            hub.H._do_POST(handler)
        code, _ = self.response(handler)
        self.assertEqual(code, 403)

    def test_auto_candidate_orders_are_deterministic_and_limited(self):
        candidates = [
            {"id": "slow", "modello": "model-slow", "ms": 90, "stato": "risponde", "verificato": True},
            {"id": "fast", "modello": "model-fast", "ms": 10, "stato": "risponde", "verificato": True},
            {"id": "strong", "modello": "model-strong", "ms": 40, "stato": "risponde", "verificato": True},
        ]
        with patch.object(hub, "modelli_nostri", return_value=candidates), \
             patch.dict(hub.PESO, {"slow": 1, "fast": 2, "strong": 9}, clear=False):
            fast = hub._candidati("auto:fast", 2)
            smart = hub._candidati("auto:smart", 2)
        self.assertEqual([x["id"] for x in fast], ["fast", "strong"])
        self.assertEqual([x["id"] for x in smart], ["strong", "fast"])

    def test_explicit_candidate_does_not_fall_back_to_other_candidates(self):
        candidates = [
            {"id": "selected", "modello": "model-a", "ms": 10, "stato": "risponde", "verificato": True},
            {"id": "other", "modello": "model-b", "ms": 20, "stato": "risponde", "verificato": True},
        ]
        with patch.object(hub, "modelli_nostri", return_value=candidates):
            selected = hub._candidati("selected", 5)
        self.assertEqual([x["id"] for x in selected], ["selected"])

    def test_explicit_canonical_id_wins_over_other_entry_model_name(self):
        candidates = [
            {"id": "test/model-x", "modello": "different-a", "ms": 10},
            {"id": "other", "modello": "test/model-x", "ms": 20},
        ]
        with patch.object(hub, "modelli_nostri", return_value=candidates):
            selected = hub._candidati("test/model-x", 5)
        self.assertEqual([x["id"] for x in selected], ["test/model-x"])

    def test_unknown_explicit_candidate_does_not_expand_to_all_candidates(self):
        candidates = [{"id": "available", "modello": "model-a", "ms": 10, "stato": "risponde", "verificato": True}]
        with patch.object(hub, "modelli_nostri", return_value=candidates):
            self.assertEqual(hub._candidati("not-in-catalog", 5), [])
        allowlisted = [{"api_id": "test/model-a", "id": "test", "modello": "model-a"}]
        with self.assertRaises(ValueError):
            hub.candidati_agente("not-in-catalog", allowlisted)

    def test_explicit_api_id_is_single_candidate_while_auto_can_fallback(self):
        a = {"api_id": "test/a", "id": "test", "modello": "a", "ms": 1}
        b = {"api_id": "test/b", "id": "test", "modello": "b", "ms": 2}
        self.assertEqual(hub.candidati_agente("test/b", [a, b]), [b])
        self.assertEqual({m["api_id"] for m in hub.candidati_agente("auto", [a, b])},
                         {"test/a", "test/b"})

    def test_explicit_live_model_error_does_not_retry_as_auto(self):
        calls = []

        def fake_urlopen(request, timeout=None):
            model = json.loads(request.data.decode("utf-8"))["model"]
            calls.append(model)
            raise urllib.error.HTTPError(request.full_url, 400, "bad model", {}, io.BytesIO(b"{}"))

        with patch.object(hub, "fusion_nostra", return_value=None), \
             patch.object(hub, "MOTORI_CHAT", [("mock-motor", 9999)]), \
             patch.object(hub, "porta_viva", return_value=True), \
             patch.object(hub, "chiave", return_value=""), \
             patch.object(hub, "chiave_per_motore", return_value="mock-key"), \
             patch.object(hub, "chat_diretta", return_value=None), \
             patch.object(hub, "messaggio_motori", return_value="mock unavailable"), \
             patch.object(hub, "avvisa_agente"), \
             patch("urllib.request.urlopen", side_effect=fake_urlopen):
            hub.chat_riposta([{"role": "user", "content": "offline"}], "explicit-id")
        self.assertEqual(calls, ["explicit-id"])

    def test_auto_smart_may_fall_back_to_auto_after_mock_error(self):
        calls = []

        def fake_urlopen(request, timeout=None):
            model = json.loads(request.data.decode("utf-8"))["model"]
            calls.append(model)
            if model == "auto:smart":
                raise urllib.error.HTTPError(request.full_url, 503, "temporary", {}, io.BytesIO(b"{}"))
            return FakeResponse({"model": "auto", "choices": [{"message": {"content": "mock answer"}}]})

        with patch.object(hub, "fusion_nostra", return_value=None), \
             patch.object(hub, "MOTORI_CHAT", [("mock-motor", 9999)]), \
             patch.object(hub, "porta_viva", return_value=True), \
             patch.object(hub, "chiave", return_value=""), \
             patch.object(hub, "chiave_per_motore", return_value="mock-key"), \
             patch("urllib.request.urlopen", side_effect=fake_urlopen):
            answer = hub.chat_riposta([{"role": "user", "content": "offline"}], "auto:smart")
        self.assertEqual(calls, ["auto:smart", "auto"])
        self.assertEqual(answer[0], "mock answer")

    def test_cooldown_expires_without_sleeping(self):
        now = [1000.0]
        with patch.object(hub, "time", types.SimpleNamespace(time=lambda: now[0])):
            hub._congela("candidate", 30, "HTTP 429")
            self.assertEqual(hub._freddo("candidate"), 30)
            now[0] = 1030.0
            self.assertEqual(hub._freddo("candidate"), 0)

    def test_cooldown_duration_is_clamped(self):
        now = [2000.0]
        with patch.object(hub, "time", types.SimpleNamespace(time=lambda: now[0])):
            hub._congela("short", -10)
            hub._congela("long", 999999)
            self.assertEqual(hub._freddo("short"), 5)
            self.assertEqual(hub._freddo("long"), 24 * 3600)

    def test_cooldown_skips_key_lookup_and_transport(self):
        candidate = {"id": "cooling", "modello": "model-x", "base": "https://unused.invalid"}
        with patch.object(hub, "_freddo", return_value=12), \
             patch.object(hub, "chiave_provider", side_effect=AssertionError("no key lookup in cooldown")), \
             patch("urllib.request.urlopen", side_effect=AssertionError("no transport in cooldown")):
            text, error, seconds = hub._posta_diretta(candidate, [{"role": "user", "content": "x"}])
        self.assertEqual((text, seconds), ("", 12))
        self.assertIn("pausa", error)

    def test_retry_after_seconds_are_parsed_without_transport(self):
        headers = email.message.Message()
        headers["Retry-After"] = "37"
        error = urllib.error.HTTPError("https://unused.invalid", 429, "rate limited", headers, io.BytesIO(b""))
        self.assertEqual(hub._retry_after(error), 37)


if __name__ == "__main__":
    unittest.main()
