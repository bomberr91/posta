#!/usr/bin/env python3
# checkin_agentrouter.py — riscatta il +25$/gg su agentrouter.org guidando il BROWSER_AGENTI (CDP :9222)
# Flusso: logout -> login con GitHub (sessione gia' autorizzata) -> lettura saldo. Solo stdlib.
import json, socket, base64, os, sys, time, struct, urllib.request, re

CDP_HOST, CDP_PORT = "127.0.0.1", 9222

def http_json(path, method="GET"):
    req = urllib.request.Request(f"http://{CDP_HOST}:{CDP_PORT}{path}", method=method)
    with urllib.request.urlopen(req, timeout=10) as r:
        body = r.read().decode()
        return json.loads(body) if body.strip() else {}

class WS:
    def __init__(self, url):
        m = re.match(r'ws://([^:/]+):(\d+)(/.*)', url)
        host, port, path = m.group(1), int(m.group(2)), m.group(3)
        self.s = socket.create_connection((host, port), timeout=60)
        key = base64.b64encode(os.urandom(16)).decode()
        hs = (f"GET {path} HTTP/1.1\r\nHost: {host}:{port}\r\nUpgrade: websocket\r\n"
              f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n")
        self.s.sendall(hs.encode())
        resp = b""
        while b"\r\n\r\n" not in resp:
            resp += self.s.recv(4096)
        if b"101" not in resp.split(b"\r\n")[0]:
            raise ConnectionError("handshake CDP fallito")
        self.buf = b""; self.mid = 0
    def _exact(self, n):
        while len(self.buf) < n:
            c = self.s.recv(65536)
            if not c: raise ConnectionError("ws chiuso")
            self.buf += c
        out, self.buf = self.buf[:n], self.buf[n:]
        return out
    def send(self, obj):
        data = json.dumps(obj).encode()
        hdr = b"\x81"; n = len(data)
        if n < 126: hdr += bytes([0x80 | n])
        elif n < 65536: hdr += bytes([0x80 | 126]) + struct.pack(">H", n)
        else: hdr += bytes([0x80 | 127]) + struct.pack(">Q", n)
        mask = os.urandom(4)
        self.s.sendall(hdr + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))
    def recv(self):
        while True:
            h = self._exact(2); op = h[0] & 0x0f; ln = h[1] & 0x7f
            if ln == 126: ln = struct.unpack(">H", self._exact(2))[0]
            elif ln == 127: ln = struct.unpack(">Q", self._exact(8))[0]
            data = self._exact(ln)
            if op == 1:
                try: return json.loads(data.decode())
                except Exception: continue
            if op == 8: raise ConnectionError("close frame")
    def call(self, method, params=None, timeout=45):
        self.mid += 1; mid = self.mid
        self.send({"id": mid, "method": method, "params": params or {}})
        t0 = time.time()
        while time.time() - t0 < timeout:
            msg = self.recv()
            if msg.get("id") == mid:
                return msg.get("result", {})
        raise TimeoutError(method)

def js(ws, expr, timeout=45):
    r = ws.call("Runtime.evaluate", {"expression": expr, "returnByValue": True, "awaitPromise": True}, timeout)
    return r.get("result", {}).get("value")

def nav(ws, url, attesa=6):
    ws.call("Page.navigate", {"url": url}); time.sleep(attesa)

def saldo_da_testo(txt):
    if not txt: return None
    m = re.search(r'\$\s*([0-9][0-9.,]*)', txt)
    return m.group(1) if m else None

def main():
    print(f"[checkin] {time.strftime('%d/%m/%Y %H:%M')}")
    try:
        http_json("/json/version")
    except Exception:
        print("ERRORE: BROWSER_AGENTI spento o porta 9222 chiusa — apri BROWSER_AGENTI.bat e riprova.")
        return 2
    # nuova scheda (Chrome nuovo vuole PUT, i vecchi GET)
    tab = None
    for metodo in ("PUT", "GET"):
        try:
            tab = http_json("/json/new?about:blank", method=metodo); break
        except Exception: continue
    if not tab or "webSocketDebuggerUrl" not in tab:
        print("ERRORE: impossibile aprire una scheda via CDP."); return 2
    ws = WS(tab["webSocketDebuggerUrl"])
    ws.call("Page.enable"); ws.call("Runtime.enable")
    try:
        nav(ws, "https://agentrouter.org/console", 8)
        testo = js(ws, "document.body.innerText") or ""
        saldo_prima = saldo_da_testo(testo)
        print(f"[checkin] saldo prima: {saldo_prima or 'non letto'}")
        # 1) logout (endpoint classico new-api, con fallback click)
        esito = js(ws, "fetch('/api/user/logout',{credentials:'include'}).then(r=>r.status).catch(e=>'ERR:'+e)")
        print(f"[checkin] logout http: {esito}")
        js(ws, """(()=>{const els=[...document.querySelectorAll('a,button,div,span')];
            const t=els.find(e=>/log\\s*out|esci|sign\\s*out|退出/i.test(e.textContent||'')&&e.offsetParent);
            if(t){t.click();return 'click-logout'}return 'nessun-bottone'})()""")
        time.sleep(4)
        # 2) pagina login -> bottone GitHub
        nav(ws, "https://agentrouter.org/login", 6)
        trovato = js(ws, """(()=>{const els=[...document.querySelectorAll('a,button,div,img,span')];
            const t=els.find(e=>/github/i.test((e.textContent||'')+(e.getAttribute&&e.getAttribute('alt')||''))&&(e.offsetParent||e.tagName==='IMG'));
            if(t){(t.closest('a,button')||t).click();return 'click-github'}return 'NON-TROVATO'})()""")
        print(f"[checkin] bottone GitHub: {trovato}")
        time.sleep(12)  # giro OAuth (GitHub gia' autorizzato = redirect automatico)
        # 3) verifica
        nav(ws, "https://agentrouter.org/console", 8)
        testo2 = js(ws, "document.body.innerText") or ""
        saldo_dopo = saldo_da_testo(testo2)
        loggato = bool(re.search(r'console|token|quota|\$', testo2, re.I)) and 'login' not in (js(ws, "location.pathname") or '')
        print(f"[checkin] saldo dopo: {saldo_dopo or 'non letto'} · rientrato: {'SI' if loggato else 'NO'}")
        if not loggato:
            print("[checkin] ⚠ il login automatico non e' rientrato: servira' un login manuale nel BROWSER_AGENTI")
            print("[checkin] primi 300 caratteri pagina: " + testo2[:300].replace("\n", " · "))
            return 1
        print("[checkin] ✅ giro logout→login completato (il credito si accredita al login; saldo visibile dopo qualche istante)")
        return 0
    finally:
        try: http_json("/json/close/" + tab["id"])
        except Exception: pass

if __name__ == "__main__":
    sys.exit(main())
