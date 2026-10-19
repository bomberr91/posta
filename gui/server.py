#!/usr/bin/env python3
# server.py — GUI CENTRALE (Hub + Agenti) su http://localhost:20200 · solo stdlib
import json, os, re, subprocess, sys, time, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from datetime import date

HOME = os.path.expanduser("~")
POSTA = os.path.join(HOME, "posta")
QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, POSTA)

CHROME_PATHS = [
    "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe",
    "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe",
    "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
    "/mnt/c/Program Files/Microsoft/Edge/Application/msedge.exe",
]
PROFILO_WIN = r"C:\AgentiH24\BrowserProfile"

def porta_viva(porta, host="127.0.0.1"):
    import socket
    try:
        with socket.create_connection((host, porta), timeout=2):
            return True
    except Exception:
        return False

def leggi(path, default=""):
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            return f.read()
    except Exception:
        return default

def flag_checkin():
    return os.path.join(HOME, f".ar_checkin_{date.today().isoformat()}")

def saldo_ultimo():
    txt = leggi(os.path.join(POSTA, "dal_pc", "agentrouter_checkin.md"))
    m = re.findall(r"saldo (?:dopo|prima): \$?([0-9][0-9.,]*)", txt)
    return m[-1] if m else None

def chrome_headless_avvia():
    for c in CHROME_PATHS:
        if os.path.exists(c):
            subprocess.Popen([c, "--headless=new", "--remote-debugging-port=9222",
                              f"--user-data-dir={PROFILO_WIN}", "--no-first-run",
                              "--disable-gpu", "about:blank"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            for _ in range(20):
                if porta_viva(9222): return True
                time.sleep(1)
    return porta_viva(9222)

def chrome_headless_chiudi():
    try:
        from checkin_agentrouter import WS, http_json
        info = http_json("/json/version")
        ws = WS(info["webSocketDebuggerUrl"])
        ws.call("Browser.close", timeout=10)
    except Exception:
        pass

def fai_checkin(forza=False):
    if os.path.exists(flag_checkin()) and not forza:
        return {"stato": "gia_fatto", "saldo": saldo_ultimo(),
                "msg": "💰 Check-in di oggi già riscattato."}
    avviato_da_noi = False
    if not porta_viva(9222):
        if not chrome_headless_avvia():
            return {"stato": "errore", "msg": "Browser agenti non avviabile (Chrome non trovato?)"}
        avviato_da_noi = True
        time.sleep(3)
    try:
        p = subprocess.run(["python3", os.path.join(POSTA, "checkin_agentrouter.py")],
                           capture_output=True, text=True, timeout=240)
        out = (p.stdout or "") + (p.stderr or "")
        ok = p.returncode == 0
    except Exception as e:
        out, ok = f"ERRORE: {e}", False
    finally:
        if avviato_da_noi:
            chrome_headless_chiudi()
    with open(os.path.join(POSTA, "dal_pc", "agentrouter_checkin.md"), "w", encoding="utf-8") as f:
        f.write(f"# 💰 Check-in AgentRouter (GUI) — {time.strftime('%d/%m/%Y %H:%M')}\n\n```\n{out}\n```\n")
    if ok:
        open(flag_checkin(), "w").write(time.strftime("%H:%M"))
    subprocess.Popen(["bash", "-c", f"cd '{POSTA}' && git add -A && git commit -qm 'checkin gui' && git push -q origin main"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    m = re.search(r"saldo dopo: \$?([0-9][0-9.,]*)", out)
    return {"stato": "ok" if ok else "fallito", "saldo": m.group(1) if m else saldo_ultimo(),
            "msg": ("✅ +25$ riscattati! Browser richiuso." if ok else "⚠️ Giro non completato — vedi log."),
            "log": out[-1500:]}

def stato():
    fus = {}
    try:
        fus = json.loads(leggi(os.path.join(POSTA, "stato_fusion.json"), "{}"))
    except Exception:
        pass
    ris_dir = os.path.join(POSTA, "RISPOSTE_AGENTI")
    ultimi = sorted(os.listdir(ris_dir), reverse=True)[:5] if os.path.isdir(ris_dir) else []
    return {"omniroute": porta_viva(20128), "browser_agenti": porta_viva(9222),
            "checkin_oggi": os.path.exists(flag_checkin()), "saldo": saldo_ultimo(),
            "fusion": fus, "risultati": ultimi, "ora": time.strftime("%H:%M:%S")}

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def _json(self, obj, code=200):
        b = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers(); self.wfile.write(b)
    def _body(self):
        n = int(self.headers.get("Content-Length") or 0)
        try: return json.loads(self.rfile.read(n).decode()) if n else {}
        except Exception: return {}
    def do_GET(self):
        if self.path in ("/", "/index.html"):
            b = leggi(os.path.join(QUI, "index.html"), "<h1>index mancante</h1>").encode()
            self.send_response(200); self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
        elif self.path == "/api/stato":
            self._json(stato())
        elif self.path.startswith("/api/risultato"):
            import urllib.parse
            q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            nome = os.path.basename((q.get("f") or [""])[0])
            self._json({"nome": nome, "testo": leggi(os.path.join(POSTA, "RISPOSTE_AGENTI", nome), "(vuoto)")})
        else:
            self._json({"err": "not found"}, 404)
    def do_POST(self):
        if self.path == "/api/checkin":
            self._json(fai_checkin(forza=bool(self._body().get("forza"))))
        elif self.path == "/api/fusion":
            missione = (self._body().get("missione") or "").strip()
            if len(missione) < 5:
                self._json({"stato": "errore", "msg": "missione troppo corta"}); return
            out = os.path.join(POSTA, "RISPOSTE_AGENTI", f"FUSION_GUI_{time.strftime('%Y%m%d_%H%M%S')}.md")
            try:
                json.dump({"percentuale": 1, "fase": "Avvio dalla GUI...", "stato": "in_corso"},
                          open(os.path.join(POSTA, "stato_fusion.json"), "w"))
            except Exception: pass
            subprocess.Popen(["bash", os.path.join(POSTA, "squadra.sh"), missione, out],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self._json({"stato": "avviata", "out": os.path.basename(out)})
        elif self.path == "/api/omniroute":
            az = self._body().get("azione")
            if az == "avvia":
                subprocess.Popen(["bash", "-lc", "export NVM_DIR=$HOME/.nvm; . $NVM_DIR/nvm.sh >/dev/null 2>&1; "
                                  "B=$(ls -d $HOME/.nvm/versions/node/v22*/bin 2>/dev/null | sort -V | tail -1); "
                                  "nohup $B/omniroute >/tmp/omniroute.log 2>&1 &"])
                self._json({"stato": "avvio richiesto"})
            elif az == "spegni":
                subprocess.run(["pkill", "-f", "omniroute"]); self._json({"stato": "spento"})
            else:
                self._json({"err": "azione?"}, 400)
        else:
            self._json({"err": "not found"}, 404)

def postino_bg():
    if subprocess.run(["pgrep", "-f", "postino.sh"], capture_output=True).returncode != 0:
        subprocess.Popen(["bash", os.path.join(POSTA, "postino.sh"), "--loop"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == "__main__":
    postino_bg()
    print("GUI CENTRALE su http://localhost:20200")
    ThreadingHTTPServer(("0.0.0.0", 20200), H).serve_forever()
