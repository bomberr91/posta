#!/usr/bin/env python3
"""cervello.py — il PORTIERE (motore di riserva, porta 20129).

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

# ── LA LISTA SUA (portiere_lista.txt) ─────────────────────────────────────────
# formato: id|etichetta|nome nel portachiavi|indirizzo API|modello di partenza|modo
LISTA = os.path.join(QUI, "portiere_lista.txt")


def carica_lista():
    """Legge la lista del Portiere. Ritorna (base, etichette, nomi, modi)."""
    base, etichette, nomi, modi = {}, {}, {}, {}
    try:
        righe = open(LISTA, encoding="utf-8", errors="replace").read().splitlines()
    except Exception:
        return base, etichette, nomi, modi
    for riga in righe:
        r = riga.strip()
        if not r or r.startswith("#"):
            if r.startswith("##"):
                break                      # da qui in poi sono i "da confermare"
            continue
        pezzi = r.split("|")
        if len(pezzi) < 5:
            continue
        pid, eti, nome, url = pezzi[0], pezzi[1], pezzi[2], pezzi[3]
        modello = pezzi[4] if len(pezzi) > 4 else "auto"
        modo = pezzi[5] if len(pezzi) > 5 else "chat"
        base[pid] = (url.rstrip("/"), modello)
        etichette[pid] = eti
        nomi[pid] = nome
        modi[pid] = modo
    return base, etichette, nomi, modi


BASE, ETICHETTE, NOMI, MODI = carica_lista()

NOME = "Portiere"


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
    """La chiave di quel provider, presa dal portachiavi con lo stesso estrattore
    di tutto il resto (chiave_di.py). SENZA = provider che non vuole chiave."""
    if pid in _cache_chiavi and time.time() - _cache_chiavi[pid][0] < 600:
        return _cache_chiavi[pid][1]
    nome = NOMI.get(pid, "")
    if nome == "SENZA":
        _cache_chiavi[pid] = (time.time(), "free")
        return "free"
    k = ""
    if nome:
        try:
            p = subprocess.run(["python3", os.path.join(QUI, "chiave_di.py"), nome],
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



def da_confermare():
    """Le voci in fondo alla lista (indirizzo mai scritto / non-chat): non contano."""
    fuori, dentro = [], False
    try:
        for riga in open(LISTA, encoding="utf-8", errors="replace").read().splitlines():
            r = riga.strip()
            if r.startswith("##"):
                dentro = True
                continue
            if dentro and r and not r.startswith("#"):
                pezzi = r.split("|")
                if len(pezzi) >= 2:
                    fuori.append((pezzi[0], pezzi[1]))
    except Exception:
        pass
    return fuori


def pagina():
    """La pagina del Portiere: la SUA lista, provider per provider."""
    voci = {v.get("id"): v for v in appello()}
    su_motore = vivo(MOTORE)
    pronti = sum(1 for pid in BASE if (voci.get(pid) or {}).get("esito") == "risponde")
    corpo = []
    for pid, (url, modello) in BASE.items():
        v = voci.get(pid) or {}
        esito = v.get("esito", "")
        icona, colore = {"risponde": ("✅", "#39d98a"), "occupato": ("🟡", "#f5c451"),
                         "chiave-no": ("🔴", "#ff6b6b"), "rete": ("⚪", "#9aa4b2"),
                         "no-chiave": ("—", "#9aa4b2")}.get(esito, ("·", "#6b7280"))
        nota = v.get("nota") or ("mai provato: fai l'appello dalla Centrale" if not esito else esito)
        corpo.append(
            '<tr><td style="padding:7px 10px;border-bottom:1px solid #ffffff12">'
            f'<span style="color:{colore}">{icona}</span> <b>{ETICHETTE.get(pid, pid)}</b></td>'
            '<td style="padding:7px 10px;border-bottom:1px solid #ffffff12;color:#9aa4b2">'
            f'{url.replace("https://", "")} · {modello}</td>'
            '<td style="padding:7px 10px;border-bottom:1px solid #ffffff12;color:#c9d1d9">'
            f'{nota}</td></tr>')
    fuori = da_confermare()
    righe_fuori = "".join(
        '<div style="display:flex;justify-content:space-between;padding:5px 0;'
        'border-bottom:1px solid #ffffff0d"><b>' + n + '</b>'
        '<span style="color:#9aa4b2">' + m + '</span></div>' for n, m in fuori)
    html = f"""<!doctype html><html lang="it"><head><meta charset="utf-8">
<title>Portiere — la sua lista</title></head>
<body style="margin:0;background:#0d1117;color:#e6edf3;font:15px/1.5 -apple-system,Segoe UI,Roboto,sans-serif">
<div style="max-width:1000px;margin:0 auto;padding:26px 20px">
  <h1 style="margin:0 0 4px;font-size:22px">🚪 Portiere <span style="font-size:14px;color:#9aa4b2">porta 20129</span></h1>
  <div style="color:#9aa4b2;margin-bottom:16px">Il motore di riserva: fa passare tutto a OmniRoute
    quando è acceso, e se OmniRoute cade usa la sua lista qui sotto.</div>
  <div style="display:flex;gap:10px;flex-wrap:wrap;margin-bottom:18px">
    <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">
      <div style="color:#9aa4b2;font-size:12px">provider nella sua lista</div>
      <div style="font-size:20px"><b>{pronti}/{sum(1 for _ in BASE)}</b> rispondono</div></div>
    <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">
      <div style="color:#9aa4b2;font-size:12px">OmniRoute (20128)</div>
      <div style="font-size:20px">{'🟢 vivo' if su_motore else '🔴 spento'}</div></div>
    <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">
      <div style="color:#9aa4b2;font-size:12px">appello</div>
      <div style="font-size:20px">{len(voci) and str(len(voci)) + ' prove fatte' or 'non ancora fatto'}</div></div>
  </div>
  <table style="width:100%;border-collapse:collapse;background:#161b22;border:1px solid #ffffff14;border-radius:10px;overflow:hidden">
    <tr style="background:#1c2430;text-align:left;color:#9aa4b2;font-size:12px">
      <th style="padding:8px 10px">PROVIDER</th><th style="padding:8px 10px">INDIRIZZO · MODELLO</th>
      <th style="padding:8px 10px">STATO</th></tr>
    {''.join(corpo)}
  </table>
  <h2 style="font-size:16px;margin:24px 0 6px">Da confermare ({len(fuori)})</h2>
  <div style="color:#9aa4b2;margin-bottom:10px">Fuori dal numero qui sopra: gli indirizzi che non
    abbiamo mai scritto, più le chiavi che non sono modelli di chat (voce, immagini, video, database).</div>
  <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">{righe_fuori}</div>
</div></body></html>"""
    return html


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
        if self.path.startswith("/portiere") and not self.path.startswith("/portiere.json"):
            b = pagina().encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(b)))
            self.end_headers()
            self.wfile.write(b)
            return
        if self.path.startswith("/portiere.json"):
            self._json({"nome": NOME, "porta": PORTA, "totali": len(BASE),
                        "risponde": [v["id"] for v in appello()
                                     if v.get("esito") == "risponde" and v.get("id") in BASE],
                        "voci": [{"id": k, "nome": ETICHETTE.get(k, k),
                                  "indirizzo": v[0], "modello": v[1]} for k, v in BASE.items()],
                        "da_confermare": da_confermare()})
            return
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
    print("Portiere (motore di riserva) su http://127.0.0.1:%d/v1 — la sua lista: %d provider" % (PORTA, len(BASE)))
    ThreadingHTTPServer(("127.0.0.1", PORTA), H).serve_forever()
