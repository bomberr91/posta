#!/usr/bin/env python3
"""cervello.py — il cervello di scorta.

Perché esiste: oggi tutti gli agenti (OpenCode, Goose, Secondhand, Hermes, Gemini CLI)
parlano con UNA porta sola: 20128, dove gira OmniRoute. Se OmniRoute cade, gli agenti
restano fermi. Questo programma sta su un'altra porta (20129) e fa da portiere:

  - se OmniRoute è vivo  → passa tutto a lui (risposta identica a prima);
  - se OmniRoute è morto → usa le chiavi che hanno risposto all'appello
                            (appello_chiavi.sh), così gli agenti continuano a lavorare.

Non tocca niente di suo: nessuna chiave scritta qui dentro, le legge dal portachiavi
con lo stesso sistema del resto (appello_chiavi.sh --chiave <provider>).

  python3 cervello.py          resta acceso sulla porta 20129
  python3 cervello.py --stato  dice chi sta rispondendo adesso
"""
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

QUI = os.path.dirname(os.path.abspath(__file__))
MOTORE = "http://127.0.0.1:20128/v1"
PORTA = 20129
APPELLO = os.path.join(os.path.expanduser("~"), ".posta_appello.json")

# dove sta ogni provider e un modello di scorta (il modello vero lo dice l'appello)
BASE = {
    "groq": ("https://api.groq.com/openai/v1", "allam-2-7b"),
    "gemini": ("https://generativelanguage.googleapis.com/v1beta/openai", "gemma-4-31b-it"),
    "mistral": ("https://api.mistral.ai/v1", "mistral-small-latest"),
    "cohere": ("https://api.cohere.ai/compatibility/v1", "command-r-plus-08-2024"),
    "openrouter": ("https://openrouter.ai/api/v1", "openrouter/auto"),
    "nvidia": ("https://integrate.api.nvidia.com/v1", "z-ai/glm-5.3"),
    "huggingface": ("https://router.huggingface.co/v1", "Qwen/Qwen3-8B"),
    "pollinations": ("https://text.pollinations.ai/openai", "openai-fast"),
    "githubmodels": ("https://models.github.ai/inference", "openai/gpt-4o-mini"),
    "agentrouter": ("https://agentrouter.org/v1", "auto"),
    "opencode": ("https://opencode.ai/zen/v1", "glm-5.3"),
}


def vivo(url, secondi=1):
    import socket
    da = url.split("//")[-1].split("/")[0]
    host, _, porta = da.partition(":")
    try:
        s = socket.create_connection((host, int(porta or 80)), timeout=secondi)
        s.close()
        return True
    except Exception:
        return False


def appello():
    try:
        d = json.loads(open(APPELLO, encoding="utf-8").read())
        return d.get("voci", [])
    except Exception:
        return []


_cache_chiavi = {}


def chiave(pid):
    if pid in _cache_chiavi and time.time() - _cache_chiavi[pid][0] < 600:
        return _cache_chiavi[pid][1]
    try:
        p = subprocess.run(["bash", os.path.join(QUI, "appello_chiavi.sh"), "--chiave", pid],
                           capture_output=True, text=True, timeout=20)
        k = (p.stdout or "").strip()
    except Exception:
        k = ""
    _cache_chiavi[pid] = (time.time(), k)
    return k


def inoltra(corpo, percorso="chat/completions", secondi=180):
    """Passa la richiesta al motore. Ritorna il JSON o None."""
    try:
        req = urllib.request.Request(MOTORE + "/" + percorso, data=corpo,
                                     headers={"Content-Type": "application/json"})
        return json.loads(urllib.request.urlopen(req, timeout=secondi).read().decode())
    except Exception:
        return None


def riserva(payload):
    """Chiama il primo provider dell'appello che risponde. Ritorna JSON formato OpenAI."""
    messaggi = payload.get("messages") or []
    for v in appello():
        if v.get("esito") != "risponde":
            continue
        pid = v.get("id")
        if pid not in BASE:
            continue
        base, modello = BASE[pid]
        modello = v.get("modello") or modello
        k = chiave(pid)
        if not k:
            continue
        corpo = json.dumps({"model": modello, "messages": messaggi,
                            "max_tokens": payload.get("max_tokens", 1200)}).encode()
        try:
            req = urllib.request.Request(base + "/chat/completions", data=corpo,
                                         headers={"Authorization": "Bearer " + k,
                                                  "Content-Type": "application/json"})
            d = json.loads(urllib.request.urlopen(req, timeout=90).read().decode())
            if (d.get("choices") or [{}])[0].get("message", {}).get("content"):
                d["model"] = "%s (riserva %s)" % (modello, v.get("nome") or pid)
                return d
        except Exception:
            continue
    return None


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _json(self, dati, codice=200):
        corpo = json.dumps(dati, ensure_ascii=False).encode()
        self.send_response(codice)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(corpo)))
        self.end_headers()
        self.wfile.write(corpo)

    def do_GET(self):
        if self.path.startswith("/cervello"):
            su = vivo(MOTORE)
            self._json({"motore": su, "riserva": [v["id"] for v in appello()
                                                  if v.get("esito") == "risponde"],
                        "adesso": "motore" if su else "riserva"})
            return
        if self.path.startswith("/v1/models"):
            d = inoltra(None, "models", secondi=10) if vivo(MOTORE) else None
            if d:
                self._json(d)
                return
            modelli = [{"id": v.get("modello") or BASE.get(v.get("id"), ("", "auto"))[1],
                        "object": "model", "owned_by": "riserva"}
                       for v in appello() if v.get("esito") == "risponde" and v.get("id") in BASE]
            self._json({"object": "list", "data": modelli})
            return
        self._json({"errore": "usa /v1/chat/completions oppure /cervello"}, 404)

    def do_POST(self):
        if not self.path.startswith("/v1/chat/completions"):
            self._json({"errore": "solo /v1/chat/completions"}, 404)
            return
        n = int(self.headers.get("Content-Length") or 0)
        try:
            payload = json.loads(self.rfile.read(n).decode() or "{}")
        except Exception:
            self._json({"error": {"message": "corpo non valido"}}, 400)
            return
        corpo = json.dumps(payload).encode()
        if vivo(MOTORE):
            d = inoltra(corpo)
            if d:
                self._json(d)
                return
        d = riserva(payload)
        if d:
            self._json(d)
            return
        self._json({"error": {"message": "motore giù e nessuna chiave di riserva ha risposto. "
                                         "Apri la Centrale → 🤖 Agenti → 🗣️ Appello delle chiavi."}}, 503)


def stato():
    voci = appello()
    su = vivo(MOTORE)
    print("Motore OmniRoute (20128):", "🟢 vivo" if su else "🔴 spento")
    pronti = [v for v in voci if v.get("esito") == "risponde"]
    print("Riserva pronta:", len(pronti), "provider")
    for v in pronti:
        print("  ✓", v.get("nome"), "·", v.get("modello") or "")
    print("Portiere (20129):", "🟢 acceso" if vivo("http://127.0.0.1:%d" % PORTA) else "🔴 spento")


if __name__ == "__main__":
    if "--stato" in sys.argv:
        stato()
        sys.exit(0)
    print("Cervello di scorta su http://127.0.0.1:%d/v1  (passa al motore, e usa la riserva se cade)" % PORTA)
    ThreadingHTTPServer(("127.0.0.1", PORTA), H).serve_forever()
