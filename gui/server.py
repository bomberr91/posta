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

def giorno_cina():
    # AgentRouter azzera il bonus a mezzanotte cinese (UTC+8) = 18:00 italiane (ora legale)
    return time.strftime("%Y-%m-%d", time.gmtime(time.time() + 8 * 3600))

def flag_checkin():
    return os.path.join(HOME, f".ar_checkin_{giorno_cina()}")

MAX_TENTATIVI = 3          # al giorno: dopo 3 giri falliti ci si ferma (niente spam di logout)

def file_tentativi():
    return os.path.join(HOME, f".ar_checkin_try_{giorno_cina()}")

def tentativi_oggi():
    try:
        return int((leggi(file_tentativi(), "0").strip() or "0"))
    except Exception:
        return 0

def segna_tentativo():
    try:
        open(file_tentativi(), "w").write(str(tentativi_oggi() + 1))
    except Exception:
        pass

def file_login_manuale():
    return os.path.join(HOME, ".ar_login_manuale")

def serve_login_manuale():
    return os.path.exists(file_login_manuale())

def segna_login_manuale(motivo):
    try:
        open(file_login_manuale(), "w", encoding="utf-8").write(
            time.strftime("%d/%m/%Y %H:%M") + " · " + (motivo or "")[:300])
    except Exception:
        pass

def pulisci_login_manuale():
    try:
        os.remove(file_login_manuale())
    except Exception:
        pass

_cache = {}

def chiave(riga_pat, key_pat):
    for r in leggi(os.path.join(HOME, "CHIAVI_LOCALI.md")).splitlines():
        if re.search(riga_pat, r, re.I):
            m = re.search(key_pat, r)
            if m:
                return m.group(0)
    return None

def saldo_live():
    """Saldo vero da agentrouter.org (API billing con la chiave sk-), cache 5 minuti."""
    v = _cache.get("saldo")
    if v and time.time() - v[0] < 600:      # 10 min: e' un'informazione, non un orologio
        return v[1]
    saldo = None
    key = chiave(r"agentrouter", r"sk-[A-Za-z0-9]{30,}")
    if key:
        import urllib.request
        try:
            def gj(p):
                req = urllib.request.Request("https://agentrouter.org" + p, headers={
                    "Authorization": "Bearer " + key, "User-Agent": "codex_cli_rs/0.149.1",
                    "Accept": "application/json"})
                raw = urllib.request.urlopen(req, timeout=15).read().decode("utf-8", "ignore")
                if not raw.lstrip().startswith("{"):
                    raise ValueError("risposta non-JSON (WAF Aliyun): il saldo si legge dal browser")
                return json.loads(raw)
            tot = float(gj("/dashboard/billing/subscription").get("hard_limit_usd") or 0)
            usato = float(gj("/dashboard/billing/usage").get("total_usage") or 0) / 100.0
            s_ = tot - usato
            if s_ > 50000:          # il sito conta in unita' interne (500000 = 1$)
                s_ = s_ / 500000.0
            if 0 < s_ < 50000:      # sanita': se resta assurdo, meglio l'ultimo saldo vero
                saldo = f"{s_:.2f}"
        except Exception:
            saldo = None
    _cache["saldo"] = (time.time(), saldo)
    return saldo

def modelli_omni():
    """Conta modelli e linee esposti ORA da OmniRoute, cache 60s."""
    v = _cache.get("mod")
    if v and time.time() - v[0] < 60:
        return v[1]
    r = {"modelli": 0, "linee": 0}
    if porta_viva(20128):
        try:
            import urllib.request
            key = chiave(r"^omniroute", r"sk-[A-Za-z0-9-]+") or ""
            req = urllib.request.Request("http://127.0.0.1:20128/v1/models",
                                         headers={"Authorization": "Bearer " + key})
            data = json.loads(urllib.request.urlopen(req, timeout=10).read().decode()).get("data", [])
            r["modelli"] = len(data)
            r["linee"] = len({(m.get("owned_by") or "?") for m in data})
        except Exception:
            pass
    _cache["mod"] = (time.time(), r)
    return r

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

_chk_lock = threading.Lock()
_ultimo_tentativo = [0.0]

def sveglia_checkin():
    """SVEGLIA INTERNA: appena scocca il giorno cinese (00:05 Pechino = 18:05 IT ora legale,
    17:05 ora solare) riscatta da sola. Se il PC era spento, riscatta all'accensione.
    Riprova ogni 30 min finche' non riesce."""
    while True:
        try:
            sh = time.gmtime(time.time() + 8 * 3600)
            if ((sh.tm_hour, sh.tm_min) >= (0, 5) and not os.path.exists(flag_checkin())
                    and not serve_login_manuale() and tentativi_oggi() < MAX_TENTATIVI
                    and time.time() - _ultimo_tentativo[0] > 1800):
                _ultimo_tentativo[0] = time.time()
                fai_checkin(forza=False)
        except Exception:
            pass
        time.sleep(60)

def fai_checkin(forza=False):
    if not _chk_lock.acquire(blocking=False):
        return {"stato": "in_corso", "msg": "⏳ Riscatto già in corso..."}
    try:
        return _fai_checkin(forza)
    finally:
        _chk_lock.release()

def _fai_checkin(forza=False):
    if os.path.exists(flag_checkin()) and not forza:
        return {"stato": "gia_fatto", "saldo": saldo_ultimo(),
                "msg": "💰 Check-in di oggi già riscattato."}
    if not forza and serve_login_manuale():
        return {"stato": "serve_login_manuale", "saldo": saldo_ultimo(),
                "msg": "⚠️ Serve un login a mano nel BROWSER_AGENTI (GitHub): poi premi «Riscatta ora».",
                "login_manuale": True}
    if not forza and tentativi_oggi() >= MAX_TENTATIVI:
        return {"stato": "stop", "saldo": saldo_ultimo(),
                "msg": f"🛑 Già {MAX_TENTATIVI} tentativi oggi: mi fermo (niente logout a vuoto). Riprovo domani."}
    avviato_da_noi = False
    if not porta_viva(9222):
        if not chrome_headless_avvia():
            return {"stato": "errore", "msg": "Browser agenti non avviabile (Chrome non trovato?)"}
        avviato_da_noi = True
        time.sleep(3)
    try:
        p = subprocess.run(["python3", os.path.join(POSTA, "checkin_agentrouter.py")],
                           capture_output=True, text=True, timeout=300)
        out = (p.stdout or "") + (p.stderr or "")
        rc = p.returncode
    except Exception as e:
        out, rc = f"ERRORE: {e}", 1
    ok = (rc == 0)
    if avviato_da_noi:
        chrome_headless_chiudi()
    with open(os.path.join(POSTA, "dal_pc", "agentrouter_checkin.md"), "w", encoding="utf-8") as f:
        f.write(f"# 💰 Check-in AgentRouter (GUI) — {time.strftime('%d/%m/%Y %H:%M')}\n\n```\n{out}\n```\n")
    segna_tentativo()
    if ok:
        open(flag_checkin(), "w").write(time.strftime("%H:%M"))
        pulisci_login_manuale()
    elif rc == 3:
        riga = next((r for r in out.splitlines() if r.startswith("[login_manuale]")), "serve login manuale")
        segna_login_manuale(riga.replace("[login_manuale]", "").strip())
    # sul ponte si scrive solo quando c'e' qualcosa da dire: niente un commit ogni 30 minuti
    if ok or rc == 3 or tentativi_oggi() >= MAX_TENTATIVI:
        subprocess.Popen(["bash", "-c", f"cd '{POSTA}' && git add -A && git commit -qm 'checkin: esito {rc}' && git push -q origin main"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    m = re.search(r"saldo dopo: \$?([0-9][0-9.,]*)", out)
    d = re.search(r"delta:\s*([+-]?[0-9.]+)", out)
    if ok:
        msg = (f"✅ +{d.group(1)}$ riscattati!" if (d and float(d.group(1)) >= 20)
               else "✅ Giro completato (bonus già preso oggi o accredito in arrivo).")
    elif rc == 3:
        msg = "⚠️ Serve un login a mano nel BROWSER_AGENTI (GitHub) → poi «Riscatta ora»."
    elif rc == 2:
        msg = "⚠️ BROWSER_AGENTI spento: apri l'icona e riprova."
    else:
        msg = "⚠️ Giro non completato — vedi log."
    return {"stato": "ok" if ok else ("serve_login_manuale" if rc == 3 else "fallito"),
            "saldo": m.group(1) if m else saldo_ultimo(), "msg": msg,
            "tentativi": tentativi_oggi(), "max_tentativi": MAX_TENTATIVI,
            "login_manuale": serve_login_manuale(), "log": out[-1800:]}

def stato():
    fus = {}
    try:
        fus = json.loads(leggi(os.path.join(POSTA, "stato_fusion.json"), "{}"))
    except Exception:
        pass
    ris_dir = os.path.join(POSTA, "RISPOSTE_AGENTI")
    ultimi = sorted(os.listdir(ris_dir), reverse=True)[:5] if os.path.isdir(ris_dir) else []
    sv = saldo_live()
    mo = modelli_omni()
    return {"omniroute": porta_viva(20128), "browser_agenti": porta_viva(9222),
            "checkin_oggi": os.path.exists(flag_checkin()), "checkin_ora": leggi(flag_checkin(), "").strip(),
            "login_manuale": serve_login_manuale(), "login_motivo": leggi(file_login_manuale(), "").strip(),
            "tentativi": tentativi_oggi(), "max_tentativi": MAX_TENTATIVI, "saldo": sv or saldo_ultimo(),
            "saldo_vivo": bool(sv), "modelli": mo["modelli"], "linee": mo["linee"],
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
        elif self.path == "/api/chat":
            msgs = self._body().get("messaggi") or []
            if not msgs:
                self._json({"err": "vuoto"}, 400); return
            key = chiave(r"^omniroute", r"sk-[A-Za-z0-9-]+") or ""
            try:
                import urllib.request
                req = urllib.request.Request("http://127.0.0.1:20128/v1/chat/completions",
                    data=json.dumps({"model": "auto", "messages": msgs[-12:]}).encode(),
                    headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
                d = json.loads(urllib.request.urlopen(req, timeout=180).read().decode())
                self._json({"testo": d["choices"][0]["message"]["content"],
                            "modello": d.get("model") or "?"})
            except Exception as e:
                self._json({"testo": f"⚠️ Non riesco a parlare con OmniRoute: {e}", "modello": "-"})
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
    threading.Thread(target=sveglia_checkin, daemon=True).start()
    print("GUI CENTRALE su http://localhost:20200")
    ThreadingHTTPServer(("0.0.0.0", 20200), H).serve_forever()
