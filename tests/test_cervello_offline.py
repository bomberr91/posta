"""Test di regressione del Portiere (cervello.py) — tutto offline, zero rete.

Perché questo file esiste (1/11 sera):
  il commit di CURA-AUDIT aveva annidato `_sessione()` dentro `_rispondi()`
  per un'indentazione sbagliata. Sintassi Python valida, ma `H._sessione`
  non esisteva più → ogni richiesta chat moriva con "empty reply from server"
  e il collaudo non poteva accorgersene. Erano due bug nello stesso commit:
  anche `NOME = "Portiere"` era stato cancellato → /cervello e /portiere.json
  crashavano.

Ogni test qui dentro è una rete: se qualcuno rifà lo stesso errore, la rete
si chiude. Il file NON deve mai fare richieste di rete e NON deve leggere il
portachiavi vero.
"""
from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import shutil
import tempfile
import threading
import unittest
import urllib.request
from http.server import ThreadingHTTPServer


ROOT = Path(__file__).resolve().parents[1]


def carica_cervello():
    """Importa cervello.py come modulo, senza avviare il server."""
    spec = importlib.util.spec_from_file_location("cervello_sotto_test", ROOT / "cervello.py")
    if spec is None or spec.loader is None:
        raise RuntimeError("cervello.py non caricabile")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


cerv = carica_cervello()


class ProvaStrutturaleTests(unittest.TestCase):
    """Il controllo strutturale: ogni self.X() chiamato deve esistere."""

    def test_la_classe_h_ha_il_metodo_sessione(self):
        # la regressione vera: _sessione era DENTRO _rispondi, quindi
        # H._sessione non esisteva e ogni richiesta chat moriva.
        self.assertTrue(hasattr(cerv.H, "_sessione"),
                        "H._sessione manca: il Portiere non risponde piu' alle chat")
        self.assertTrue(callable(cerv.H._sessione))

    def test_il_controllo_non_trovano_problemi_su_cervello_reale(self):
        self.assertEqual(cerv.controlla_struttura(), [])

    def test_il_controllo_scopre_un_metodo_annidato_per_sbaglio(self):
        """Il file rotto (metodo annidato) deve essere segnalato."""
        tmp = Path(tempfile.mkdtemp(prefix="cervello-rotto-"))
        try:
            src = (ROOT / "cervello.py").read_text(encoding="utf-8")
            buono = (
                "    def _sessione(self):\n"
                '        """Idea 58: un ID di sessione stabile per agente (o quello che manda lui)."""\n'
                '        s = self.headers.get("x-opencode-session") or ""\n'
                '        s = "".join(s.split())[:64]\n'
                '        if s:\n'
                '            return s\n'
                '        ua = self.headers.get("user-agent", "") or "agente"\n'
                '        return "cervello-" + hashlib.sha1(ua.encode()).hexdigest()[:16]\n'
            )
            self.assertIn(buono, src, "cervello.py non ha piu' il blocco atteso")
            rotto = "".join(("    " + riga if riga.strip() else riga) + "\n"
                            for riga in buono.rstrip("\n").split("\n"))
            (tmp / "cervello.py").write_text(src.replace(buono, rotto), encoding="utf-8")
            spec = importlib.util.spec_from_file_location("cervello_rotto", tmp / "cervello.py")
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            problemi = mod.controlla_struttura()
            self.assertTrue(problemi, "il controllo NON ha visto il metodo annidato")
            self.assertTrue(any("_sessione" in p for p in problemi),
                            "il problema segnalato non riguarda _sessione: %s" % problemi)
        finally:
            shutil.rmtree(tmp, ignore_errors=True)


class ProvaVivaTests(unittest.TestCase):
    """La prova end-to-end: il cervello risponde davvero, come gli agenti."""

    @classmethod
    def setUpClass(cls):
        cls.mod = cerv
        cls.mod.AUTOPROVA[0] = True          # nessuna uscita su internet
        # il log di vetro è del PC: qui scriviamo in un file nostro, sennò i
        # test lasciano righe false nel glass-box di FilippoPC
        cls.log_prima = cls.mod.LOG_FILE
        fd, cls.log_proprio = tempfile.mkstemp(suffix=".jsonl", prefix="portiere-log-test-")
        os.close(fd)
        cls.mod.LOG_FILE = cls.log_proprio
        cls.srv = ThreadingHTTPServer(("127.0.0.1", 0), cls.mod.H)
        cls.porta = cls.srv.server_address[1]
        cls.th = threading.Thread(target=cls.srv.serve_forever, daemon=True)
        cls.th.start()
        cls.base = "http://127.0.0.1:%d" % cls.porta

    @classmethod
    def tearDownClass(cls):
        try:
            cls.srv.shutdown()
            cls.srv.server_close()
        finally:
            cls.mod.AUTOPROVA[0] = False
            cls.mod.LOG_FILE = cls.log_prima
            try:
                os.unlink(cls.log_proprio)
            except OSError:
                pass

    def _get(self, percorso):
        con = urllib.request.urlopen(self.base + percorso, timeout=10)
        return json.loads(con.read().decode())

    def _post(self, percorso, corpo):
        req = urllib.request.Request(
            self.base + percorso, data=json.dumps(corpo).encode(),
            headers={"Content-Type": "application/json"})
        con = urllib.request.urlopen(req, timeout=10)
        return json.loads(con.read().decode())

    def test_la_chat_risponde_con_scelte(self):
        """È la prova che il 1/11 falliva: la chat non deve morire in silenzio."""
        d = self._post("/v1/chat/completions",
                       {"model": "auto", "messages": [{"role": "user", "content": "ping"}]})
        self.assertTrue(d.get("choices"), "risposta senza scelte: %s" % d)
        self.assertTrue(d["choices"][0]["message"].get("content"))

    def test_cervello_json_rispone(self):
        d = self._get("/cervello")
        self.assertIn("nome", d)
        self.assertEqual(d["nome"], "Portiere")

    def test_portiere_json_rispone(self):
        d = self._get("/portiere.json")
        self.assertIn("porta", d)
        self.assertIn("pagelle", d)

    def test_salute_rispone_e_conosce_il_proprio_stato(self):
        d = self._get("/salute")
        self.assertTrue(d.get("ok"))
        self.assertEqual(d.get("struttura"), [], "la struttura non e' pulita")

    def test_il_ping_non_spende_token(self):
        d = self._post("/v1/chat/completions",
                       {"model": "auto", "messages": [{"role": "user", "content": "ping"}]})
        self.assertEqual((d.get("usage") or {}).get("total_tokens"), 0)


    def test_f1_il_body_malformato_risponde_e_non_muore(self):
        """F1: Content-Length non numerico, JSON non-oggetto, messaggi strani.

        PRIMA: eccezione non gestita -> il server chiudeva la connessione a
        vuoto ("empty reply"). ORA: deve SEMPRE arrivare una risposta HTTP.
        """
        import http.client
        from urllib.error import HTTPError

        # 1) JSON valido ma non un oggetto
        try:
            con = urllib.request.urlopen(urllib.request.Request(
                self.base + "/v1/chat/completions", data=b"[1,2]",
                headers={"Content-Type": "application/json"}), timeout=10)
            con.close()
            self.fail("un body non-oggetto deve dare 400")
        except HTTPError as e:
            self.assertEqual(e.code, 400)
            e.close()

        # 2) messages con elementi che non sono dizionari
        try:
            self._post("/v1/chat/completions", {"model": "auto", "messages": ["ciao"]})
            self.fail("messages non-dizionario: doveva essere 400")
        except HTTPError as e:
            self.assertEqual(e.code, 400)
            e.close()

        # 3) Content-Length non numerico (via http.client grezzo)
        c = http.client.HTTPConnection("127.0.0.1", self.porta, timeout=10)
        try:
            c.putrequest("POST", "/v1/chat/completions")
            c.putheader("Content-Type", "application/json")
            c.putheader("Content-Length", "abc")
            c.endheaders()
            c.send(b'{"model":"auto","messages":[{"role":"user","content":"ping"}]}')
            r = c.getresponse()
            self.assertIn(r.status, (200, 400, 413),
                          "Content-Length non numerico: la connessione e' caduta")
            r.read()
        finally:
            c.close()

class GuardiaSoloGratisTests(unittest.TestCase):
    """La guardia anti-spesa: i modelli a pagamento non passano."""

    def test_i_modelli_a_pagamento_sono_rifiutati(self):
        for m in ("gpt-5", "gpt-4o", "claude-opus-4", "o3-mini",
                  "gemini-2.5-pro", "gemini-1.5-pro", "gemini-3-ultra"):
            with self.subTest(modello=m):
                self.assertTrue(cerv.a_pagamento(m))

    def test_i_modelli_gratis_passano(self):
        for m in ("gemini-2.0-flash", "gemini-2.5-flash", "llama-3.3-70b-versatile",
                  "deepseek-v4-flash", "auto", "", "glm-4.7-flash"):
            with self.subTest(modello=m):
                self.assertFalse(cerv.a_pagamento(m))

    def test_la_scappatoia_free_vince_sempre(self):
        for m in ("gpt-5-free", "gemini-2.5-pro-free", "claude-opus-4:free"):
            with self.subTest(modello=m):
                self.assertFalse(cerv.a_pagamento(m))


class RegoleAgenteTests(unittest.TestCase):
    """Le regole per agente: vince il prefisso piu' lungo, le chiavi vuote no."""

    def setUp(self):
        self.prima = cerv.REGOLE
        cerv.REGOLE = {
            "": {"politiche": ["gratis"]},
            "cervello-": {"politiche": ["auto"]},
            "cervello-abc": {"politiche": ["migliore"]},
        }

    def tearDown(self):
        cerv.REGOLE = self.prima

    def test_vince_il_prefisso_piu_lungo(self):
        regola = cerv.regola_di("cervello-abc-xyz")
        self.assertEqual(regola["politiche"], ["migliore"])

    def test_una_chiave_vuota_non_si_applica_a_tutti(self):
        regola = cerv.regola_di("altro-agente")
        self.assertIsNone(regola)


class StatoTests(unittest.TestCase):
    """Lo stato su disco: se e' rovinato, il cervello si ricostruisce."""

    def test_uno_stato_con_tipi_sbagliati_viene_ricostruito(self):
        # ATTENZIONE: questo test scrive su un file PROPRIO e non tocca mai
        # portiere_stato.json (una prima versione faceva os.unlink sul file
        # vero e lo cancellava: mai più).
        prima_stato = cerv.STATO
        prima_file = cerv.STATO_FILE
        provvisorio = None
        try:
            fd, provvisorio = tempfile.mkstemp(suffix=".json", prefix="stato-rotto-")
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump({"castighi": {"a": "non un numero"},
                           "pagella": "non una mappa",
                           "uso": [], "agenti": {}, "sessioni": {}}, f)
            cerv.STATO_FILE = provvisorio
            cerv.stato_carica()
            self.assertIsInstance(cerv.STATO["castighi"], dict)
            self.assertNotIn("a", cerv.STATO["castighi"])
            self.assertIsInstance(cerv.STATO["pagella"], dict)
            self.assertIsInstance(cerv.STATO["uso"], dict)
        finally:
            cerv.STATO = prima_stato
            cerv.STATO_FILE = prima_file
            if provvisorio:
                try:
                    os.unlink(provvisorio)
                except OSError:
                    pass

    def test_la_sentinella_sopravvive_al_riavvio(self):
        """La sentinella tiene le baseline degli occhi: se lo stato le perde a
        ogni avvio, urla 'hanno pubblicato qualcosa' ogni volta (false allarmi)."""
        prima_stato = cerv.STATO
        prima_file = cerv.STATO_FILE
        provvisorio = None
        try:
            fd, provvisorio = tempfile.mkstemp(suffix=".json", prefix="stato-sentinella-")
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump({"sentinella": {"controllo": 123.5,
                                          "visti": {"CYBIRD-D/FREE-LLM-API-Provider": "2026-10-30"}},
                           "castighi": {}, "pagella": {}}, f)
            cerv.STATO_FILE = provvisorio
            cerv.stato_carica()
            self.assertIn("sentinella", cerv.STATO)
            self.assertEqual(cerv.STATO["sentinella"]["controllo"], 123.5)
            self.assertIn("CYBIRD-D/FREE-LLM-API-Provider", cerv.STATO["sentinella"]["visti"])
        finally:
            cerv.STATO = prima_stato
            cerv.STATO_FILE = prima_file
            if provvisorio:
                try:
                    os.unlink(provvisorio)
                except OSError:
                    pass

    def test_una_sezione_ignota_viene_conservata(self):
        """Una sezione nuova (che un agente aggiunge) non deve sparire."""
        prima_stato = cerv.STATO
        prima_file = cerv.STATO_FILE
        provvisorio = None
        try:
            fd, provvisorio = tempfile.mkstemp(suffix=".json", prefix="stato-extra-")
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump({"sezione_che_non_conosciamo": {"a": 1},
                           "rifiuto": "spazzatura"}, f)
            cerv.STATO_FILE = provvisorio
            cerv.stato_carica()
            self.assertEqual(cerv.STATO["sezione_che_non_conosciamo"], {"a": 1})
            self.assertNotIn("rifiuto", cerv.STATO)
        finally:
            cerv.STATO = prima_stato
            cerv.STATO_FILE = prima_file
            if provvisorio:
                try:
                    os.unlink(provvisorio)
                except OSError:
                    pass

    def test_i_battiti_non_crescono_all_infinito(self):
        cerv._battiti.clear()
        for _ in range(500):
            cerv.batte("provider-di-prova")
        self.assertLessEqual(len(cerv._battiti.get("provider-di-prova", [])),
                             cerv.CONFIG["battiti_max"])


class VivoTests(unittest.TestCase):
    """La porta giusta: https = 443, http = 80."""

    def test_un_indirizzo_inesistente_non_e_vivo(self):
        self.assertFalse(cerv.vivo("http://127.0.0.1:1", secondi=1))


class MaxTokensTests(unittest.TestCase):
    def test_il_tetto_e_in_config(self):
        self.assertIsInstance(cerv.CONFIG.get("max_tokens"), int)
        self.assertGreater(cerv.CONFIG["max_tokens"], 0)


if __name__ == "__main__":
    unittest.main()


# ─────────────────────────────────────────────────────────────────────────
# CURA-AUDIT (1/11 sera): i test che SAZIONO dire NO.
#
# Vengono dal secondo audit (ZCode, modello diverso): hanno trovato la
# classe di bug che ci ha fatto perdere la serata del 1/11 — l'"empty
# reply", cioe' la connessione chiusa a vuoto senza nessun errore.
# Prima di queste correzioni (F1/F2/F3) questi test FALLIScono.
# ─────────────────────────────────────────────────────────────────────────

class CorrezioniCriticheTests(unittest.TestCase):
    """F1, F2, F3: i tre bug che potevano spegnere il Portiere."""

    def test_f2_una_riga_sbagliata_non_ammazza_la_richiesta(self):
        """F2: indirizzo() lanciava ValueError FUORI dal try della riserva.

        Una sola riga con "http://" in portiere_lista.txt ammazzava TUTTA la
        richiesta invece di saltare quel provider e fare failover.
        """
        salva = {n: getattr(cerv, n) for n in
                 ("indirizzo", "chiave", "in_salute", "punito", "freno", "a_pagamento")}
        salva_base = dict(cerv.BASE)
        try:
            def indirizzo_rotto(pid, k):
                raise ValueError("chiave su http in chiaro rifiutata")
            cerv.indirizzo = indirizzo_rotto
            cerv.chiave = lambda pid: "chiave-finta"
            cerv.in_salute = lambda pid: True
            cerv.punito = lambda pid, modello: False
            cerv.freno = lambda pid: False
            cerv.a_pagamento = lambda modello: False
            cerv.BASE["pippo-test"] = ("http://esempio.invalido", "modello-test")
            # non deve sollevare: deve semplicemente saltare quel provider
            risultato = cerv.riserva({"model": "auto", "messages": []})
            self.assertIsNotNone(risultato, "la riserva deve rispondere qualcosa")
        finally:
            for n, v in salva.items():
                setattr(cerv, n, v)
            cerv.BASE.clear()
            cerv.BASE.update(salva_base)

    def test_f3_uno_stato_corrotto_non_ammazza_le_chat(self):
        """F3: stato_carica() non validava i tipi annidati.

        Un solo campo corrotto (ms_ewma) faceva TypeError nel sort della
        riserva -> ogni chat "auto" in empty reply.
        """
        prima_stato = cerv.STATO
        prima_file = cerv.STATO_FILE
        provvisorio = None
        try:
            fd, provvisorio = tempfile.mkstemp(suffix=".json", prefix="stato-annidato-")
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump({"castighi": {},
                           "pagella": {"p1": {"ok": 3, "ko": 0, "ms_ewma": "abc",
                                              "ms_quando": "ieri", "fila_ko": "x"}},
                           "uso": {"p1": {"n": "non un numero", "token": 5}},
                           "sessioni": {"s1": {"pid": 3, "quando": "adesso"}},
                           "agenti": {}}, f)
            cerv.STATO_FILE = provvisorio
            cerv.stato_carica()
            p = cerv.STATO["pagella"].get("p1", {})
            self.assertNotIn("ms_ewma", p, "ms_ewma non numerico deve essere scartato")
            self.assertNotIn("ms_quando", p, "ms_quando non numerico deve essere scartato")
            self.assertEqual(p.get("fila_ko"), 0)
            self.assertNotIn("p1", cerv.STATO.get("uso", {}))
            self.assertNotIn("s1", cerv.STATO.get("sessioni", {}))
        finally:
            cerv.STATO = prima_stato
            cerv.STATO_FILE = prima_file
            if provvisorio:
                try:
                    os.unlink(provvisorio)
                except OSError:
                    pass


class ProfiliAgenteTests(unittest.TestCase):
    """F5: un profilo non-dizionario non deve ammazzare l'agente."""

    def test_un_profilo_non_dizionario_non_ammazza_la_chat(self):
        salva = cerv.PROFILI
        try:
            cerv.PROFILI = {"x-": "stringa invece di un dizionario"}
            # non deve sollevare: il profilo va ignorato
            try:
                cerv.profilo_di("x-1", cerv.PROFILI)
            except Exception as e:
                self.fail("profilo_di doveva tollerare un profilo non-dizionario: %r" % (e,))
        finally:
            cerv.PROFILI = salva


class ConcorrenzaTests(unittest.TestCase):
    """F9/F10/F11: molti thread insieme non devono far esplodere nulla."""

    def test_la_concorrenza_non_produce_nessuna_eccezione(self):
        errori = []

        def lavoro():
            try:
                for i in range(20):
                    cerv.batte("p-test")
                    cerv.segna("p-test", True, 120)
                    cerv.cache_scrivi("chiave-test-%d" % i, {"d": i})
                    cerv.cache_chiave({"model": "auto",
                                       "messages": [{"role": "user", "content": "x"}]})
            except Exception as e:                     # noqa: BLE001
                errori.append(repr(e))

        threads = [threading.Thread(target=lavoro) for _ in range(20)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=60)
        self.assertEqual(errori, [], "eccezioni in concorrenza: %s" % errori[:3])
