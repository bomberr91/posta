"""Offline contract tests for the local Hub gateway.

These tests intentionally import the handler without starting an HTTP server and
mock all provider/router transports. They must never read the real keyring or make
network calls.
"""
from __future__ import annotations

import email.message
import hashlib
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
        self.registry_path = Path(self.temp.name) / "agent-tokens.json"
        self.old_registry_path = hub.TOKEN_REGISTRY
        hub.TOKEN_REGISTRY = str(self.registry_path)
        self.addCleanup(setattr, hub, "TOKEN_REGISTRY", self.old_registry_path)
        hub._scrivi_registry_token({"tokens": [{"id": "test-agent", "name": "test agent",
            "sha256": hashlib.sha256(b"unit-test-token").hexdigest(),
            "models": ["test/test-model", "provider/model-a", "provider/model-b"]}]})
        self.old_hub_token = os.environ.pop("HUB_TOKEN", None)
        self.addCleanup(self._restore_hub_token)
        no_network = patch("urllib.request.urlopen", side_effect=AssertionError("offline test attempted urlopen"))
        no_network.start()
        self.addCleanup(no_network.stop)
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

    def test_registry_revocation_invalidates_token_immediately(self):
        self.assertTrue(hub.agente_autorizzato("Bearer unit-test-token"))
        self.assertTrue(hub.revoca_token_agente("test-agent"))
        self.assertFalse(hub.agente_autorizzato("Bearer unit-test-token"))

    def test_legacy_environment_global_token_is_not_accepted(self):
        os.environ["HUB_TOKEN"] = "environment-test-token"
        self.assertFalse(hub.agente_autorizzato("Bearer environment-test-token"))
        self.assertTrue(hub.agente_autorizzato("Bearer unit-test-token"))

    def test_hub_model_catalog_surfaces_configured_free_alias_for_teams(self):
        base = [{"id": "nara", "provider": "NaraRouter", "modello": "auto",
                 "verificato": True, "stato": "risponde"}]
        alias = {"id": "nara", "provider": "NaraRouter", "modello": "laguna-s-2.1",
                 "verificato": True, "api_id": "nara/laguna-s-2.1"}
        handler = FakeHandler("/api/modelli")
        with (patch.object(hub, "modelli_nostri", side_effect=[base, base]),
              patch.object(hub, "modelli_agente_ammessi", return_value=[alias]),
              patch.object(hub, "lista_portiere", return_value={}),
              patch.object(hub, "appello_dati", return_value={"quando": "", "voci": []})):
            hub.H.do_GET(handler)
        code, payload = self.response(handler)
        self.assertEqual(code, 200)
        self.assertEqual([x["modello"] for x in payload["data"]], ["auto", "laguna-s-2.1"])

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







    def test_legacy_global_token_copy_endpoint_is_retired(self):
        handler = FakeHandler("/api/agente-token", {"Host": "localhost:20200"})
        hub.H.do_GET(handler)
        code, payload = self.response(handler)
        self.assertEqual(code, 410)
        self.assertNotIn("token", payload)

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

    def test_fusion_honors_explicit_team_and_judge_and_reports_events(self):
        models = [
            {"id": "a", "provider": "A", "modello": "model-a", "verificato": True},
            {"id": "b", "provider": "B", "modello": "model-b", "verificato": True},
            {"id": "c", "provider": "C", "modello": "model-c", "verificato": True},
        ]
        calls = []
        events = []
        def direct(model, messages, *args):
            calls.append(model["id"])
            return "fusion answer" if model["id"] == "c" else "panel " + model["id"]
        with (patch.object(hub, "modelli_nostri", side_effect=lambda ready: models),
              patch.object(hub, "modelli_agente_ammessi", return_value=[]),
              patch.object(hub, "chiama_diretto", side_effect=direct)):
            result = hub.fusion_nostra(
                [{"role": "user", "content": "question"}], 3,
                ["a/model-a", "b/model-b"], "c/model-c", events.append)
        self.assertEqual(set(calls), {"a", "b", "c"})
        self.assertEqual(result[0], "fusion answer")
        self.assertEqual(result[2], ["a/model-a", "b/model-b"])
        self.assertEqual([e["_fusion"]["event"] for e in events].count("panel"), 2)
        self.assertEqual([e["_fusion"]["event"] for e in events].count("judge"), 1)

    def test_fusion_does_not_replace_missing_explicit_team_members(self):
        models = [
            {"id": "a", "provider": "A", "modello": "model-a", "verificato": True},
            {"id": "b", "provider": "B", "modello": "model-b", "verificato": True},
        ]
        with (patch.object(hub, "modelli_nostri", side_effect=lambda ready: models),
              patch.object(hub, "modelli_agente_ammessi", return_value=[]),
              patch.object(hub, "chiama_diretto", side_effect=AssertionError("must not call a fallback"))):
            self.assertIsNone(hub.fusion_nostra(
                [{"role": "user", "content": "question"}], 3,
                ["a/model-a", "missing/model-x"], None))

    def test_chat_riposta_passes_team_to_fusion(self):
        with patch.object(hub, "fusion_nostra", return_value=("fused", "A + B", ["a/model-a", "b/model-b"])) as run:
            result = hub.chat_riposta([], "fusion", {"models": ["a/model-a", "b/model-b"], "judge": "c/model-c"})
        run.assert_called_once_with([], 3, ["a/model-a", "b/model-b"], "c/model-c", None)
        self.assertEqual(result[0], "fused")
        with patch.object(hub, "fusion_nostra", return_value=None):
            self.assertIn("Fusion non disponibile", hub.chat_riposta([], "fusion", {"models": ["bad"]})[0])

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
        messages = [{"role": "user", "content": "offline"}]
        with patch.object(hub, "chat_diretta", return_value=None) as direct:
            result = hub.chat_riposta(messages, "explicit-id")
        direct.assert_called_once_with(messages, "explicit-id", 900, 4, 70)
        self.assertIn("Non è stato usato un router alternativo", result[0])


    def test_auto_smart_is_sent_once_to_the_local_router_without_alias_fallback(self):
        messages = [{"role": "user", "content": "offline"}]
        with patch.object(hub, "chat_diretta", return_value=None) as direct:
            result = hub.chat_riposta(messages, "auto:smart")
        direct.assert_called_once_with(messages, "auto:smart", 900, 4, 70)
        self.assertIn("Nessun provider diretto", result[0])


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

    def test_revocable_agent_token_is_hashed_scoped_and_revoked(self):
        models = [
            {"api_id": "provider/model-a", "id": "provider", "provider": "Provider",
             "modello": "model-a", "verificato": True},
            {"api_id": "provider/model-b", "id": "provider", "provider": "Provider",
             "modello": "model-b", "verificato": True},
        ]
        with patch.object(hub, "modelli_agente_ammessi", return_value=models):
            created = hub.crea_token_agente("agent test", ["provider/model-a"])
        self.assertTrue(created["token"].startswith("huba-"))
        self.assertEqual(["provider/model-a"], created["models"])
        stored = self.registry_path.read_text(encoding="utf-8")
        self.assertNotIn(created["token"], stored)
        self.assertEqual(stat.S_IMODE(self.registry_path.stat().st_mode), 0o600)
        self.assertIn(created["id"], [x["id"] for x in hub.lista_token_agente()])
        header = "Bearer " + created["token"]
        self.assertEqual(["provider/model-a"], hub.dettaglio_token_agente(header)["models"])
        self.assertTrue(hub.revoca_token_agente(created["id"]))
        self.assertIsNone(hub.dettaglio_token_agente(header))
        self.assertFalse(hub.revoca_token_agente(created["id"]))

    def test_token_creation_rejects_unverified_or_unavailable_models(self):
        with patch.object(hub, "modelli_agente_ammessi", return_value=[]):
            with self.assertRaises(ValueError):
                hub.crea_token_agente("agent", ["provider/model-a"])

    def test_scoped_token_models_route_only_lists_its_models(self):
        models = [
            {"api_id": "provider/model-a", "id": "provider", "provider": "Provider", "modello": "model-a"},
            {"api_id": "provider/model-b", "id": "provider", "provider": "Provider", "modello": "model-b"},
        ]
        with patch.object(hub, "modelli_agente_ammessi", return_value=models):
            created = hub.crea_token_agente("agent", ["provider/model-a"])
        handler = FakeHandler("/v1/models", {"Authorization": "Bearer " + created["token"]})
        with patch.object(hub, "modelli_agente_ammessi", return_value=models):
            hub.H.do_GET(handler)
        code, payload = self.response(handler)
        self.assertEqual(code, 200)
        self.assertEqual(["provider/model-a"], [m["id"] for m in payload["data"]])

    def test_local_management_endpoint_creates_and_revokes_token(self):
        models = [{"api_id": "provider/model-a", "id": "provider", "provider": "Provider",
                   "modello": "model-a", "verificato": True}]
        headers = {"Host": "localhost:20200", "Origin": "http://localhost:20200",
                   "Content-Type": "application/json"}
        with patch.object(hub, "modelli_agente_ammessi", return_value=models):
            create = FakeHandler("/api/agent-tokens", headers, {"name": "manual agent", "models": ["provider/model-a"]})
            hub.H._do_POST(create)
        code, payload = self.response(create)
        self.assertEqual(code, 200)
        token = payload["token"]
        revoke = FakeHandler("/api/agent-tokens/revoke", headers, {"id": payload["id"]})
        hub.H._do_POST(revoke)
        self.assertEqual(200, self.response(revoke)[0])
        self.assertIsNone(hub.dettaglio_token_agente("Bearer " + token))

    def test_token_management_endpoint_blocks_remote_peer(self):
        headers = {"Host": "localhost:20200", "Origin": "http://localhost:20200",
                   "Content-Type": "application/json"}
        handler = FakeHandler("/api/agent-tokens", headers, {"name": "remote", "models": ["x/y"]})
        handler.client_address = ("203.0.113.10", 1234)
        with patch.object(hub, "crea_token_agente", side_effect=AssertionError("must not create")):
            hub.H._do_POST(handler)
        self.assertEqual(403, self.response(handler)[0])

    def test_free_allowlisted_alias_uses_configured_verified_provider(self):
        provider = {"id": "nara", "provider": "NaraRouter", "modello": "auto",
                    "base": "https://router.bynara.id/v1", "verificato": True, "stato": "strano"}
        with patch.object(hub, "HUB_AGENT_FREE_MODELS_VERIFIED", ("nara/laguna-s-2.1",)), \
             patch.object(hub, "modelli_nostri", return_value=[provider]), \
             patch.object(hub, "chiave_provider", return_value="test-provider-key"):
            allowed = hub.modelli_agente_ammessi()
        self.assertEqual(["nara/laguna-s-2.1"], [m["api_id"] for m in allowed])
        self.assertEqual("laguna-s-2.1", allowed[0]["modello"])

    def test_unconfigured_provider_is_not_enabled_by_free_alias_allowlist(self):
        with patch.object(hub, "HUB_AGENT_FREE_MODELS_VERIFIED", ("nara/laguna-s-2.1",)), \
             patch.object(hub, "modelli_nostri", return_value=[]):
            self.assertEqual([], hub.modelli_agente_ammessi())

    def test_scoped_token_cannot_call_model_outside_its_scope(self):
        models = [
            {"api_id": "provider/model-a", "id": "provider", "provider": "Provider", "modello": "model-a"},
            {"api_id": "provider/model-b", "id": "provider", "provider": "Provider", "modello": "model-b"},
        ]
        with patch.object(hub, "modelli_agente_ammessi", return_value=models):
            created = hub.crea_token_agente("agent", ["provider/model-a"])
        handler = FakeHandler("/v1/chat/completions", {
            "Content-Type": "application/json", "Authorization": "Bearer " + created["token"]},
            {"model": "provider/model-b", "messages": [{"role": "user", "content": "offline"}]})
        with patch.object(hub, "modelli_agente_ammessi", return_value=models), \
             patch.object(hub, "_posta_diretta") as upstream:
            hub.H._do_POST(handler)
        code, payload = self.response(handler)
        self.assertEqual(code, 403)
        self.assertIn("modello non allowlisted", payload["error"]["message"])
        upstream.assert_not_called()

    def test_retry_after_seconds_are_parsed_without_transport(self):
        headers = email.message.Message()
        headers["Retry-After"] = "37"
        error = urllib.error.HTTPError("https://unused.invalid", 429, "rate limited", headers, io.BytesIO(b""))
        self.assertEqual(hub._retry_after(error), 37)


if __name__ == "__main__":
    unittest.main()
