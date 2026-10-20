#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
checkin_agentrouter.py — v2 (20/10/2026)

Riscatta il bonus giornaliero di agentrouter.org (+25$) guidando il BROWSER_AGENTI via CDP (:9222).
Flusso: verifica sessione GitHub -> verifica sessione AgentRouter -> logout -> login GitHub
        -> SEGUE il giro OAuth (anche se apre una scheda nuova) -> verifica -> saldo prima/dopo.

Novita' della v2 rispetto alla v1 (che si piantava su "rientrato: NO"):
  1. Non fa piu' logout a cuor leggero: prima controlla che la sessione GitHub sia viva
     (meta[name=user-login] su github.com). Se non c'e', esce con codice 3 = SERVE LOGIN MANUALE,
     senza toccare la sessione AgentRouter (cosi' non resta sloggato).
  2. Dopo il click su "GitHub" NON resta sulla scheda originale: interroga /json/list ogni 1.5s
     e si aggancia a QUALSIASI scheda che torna su agentrouter.org, anche nuova.
  3. Se compare la pagina di autorizzazione OAuth di GitHub, prova a premere "Authorize".
  4. Il saldo lo legge DENTRO il browser (stessa origine, credentials:'include'):
     /dashboard/billing/subscription + /usage, con fallback su /api/user/self (quota/500000).
     Il WAF Aliyun, chiamato da curl/server, restituisce HTML: per questo il saldo era "non letto".
  5. Flag --verifica: controlla sessione e saldo SENZA fare logout (diagnostica veloce).

Codici di uscita: 0 = ok (riscattato o sessione valida) · 1 = errore/giro non completato
                  2 = browser spento · 3 = serve login manuale (GitHub sloggato)
Solo stdlib.
"""
import base64, json, os, re, socket, struct, sys, time, urllib.request

CDP_HOST, CDP_PORT = "127.0.0.1", 9222
BASE = os.environ.get("AR_BASE", "https://agentrouter.org").rstrip("/")
GH = os.environ.get("AR_GH", "https://github.com")
GH_NETLOC = re.sub(r"^https?://", "", GH).split("/")[0].lower()
ATTESA_OAUTH = int(os.environ.get("AR_ATTESA_OAUTH", "70"))   # secondi di pazienza per il giro OAuth


# ─────────────────────────────── CDP minimale ────────────────────────────────
def http_json(path, method="GET"):
    req = urllib.request.Request(f"http://{CDP_HOST}:{CDP_PORT}{path}", method=method)
    with urllib.request.urlopen(req, timeout=10) as r:
        body = r.read().decode()
        return json.loads(body) if body.strip() else {}


class WS:
    def __init__(self, url):
        m = re.match(r"ws://([^:/]+):(\d+)(/.*)", url)
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
        self.buf = b""
        self.mid = 0

    def _exact(self, n):
        while len(self.buf) < n:
            c = self.s.recv(65536)
            if not c:
                raise ConnectionError("ws chiuso")
            self.buf += c
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

    def send(self, obj):
        data = json.dumps(obj).encode()
        hdr = b"\x81"
        n = len(data)
        if n < 126:
            hdr += bytes([0x80 | n])
        elif n < 65536:
            hdr += bytes([0x80 | 126]) + struct.pack(">H", n)
        else:
            hdr += bytes([0x80 | 127]) + struct.pack(">Q", n)
        mask = os.urandom(4)
        self.s.sendall(hdr + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

    def recv(self):
        while True:
            h = self._exact(2)
            op = h[0] & 0x0F
            ln = h[1] & 0x7F
            if ln == 126:
                ln = struct.unpack(">H", self._exact(2))[0]
            elif ln == 127:
                ln = struct.unpack(">Q", self._exact(8))[0]
            data = self._exact(ln)
            if op == 1:
                try:
                    return json.loads(data.decode())
                except Exception:
                    continue
            if op == 8:
                raise ConnectionError("close frame")

    def call(self, method, params=None, timeout=45):
        self.mid += 1
        mid = self.mid
        self.send({"id": mid, "method": method, "params": params or {}})
        t0 = time.time()
        while time.time() - t0 < timeout:
            msg = self.recv()
            if msg.get("id") == mid:
                if "error" in msg:
                    raise RuntimeError(f"{method}: {msg['error']}")
                return msg.get("result", {})
        raise TimeoutError(method)

    def close(self):
        try:
            self.s.close()
        except Exception:
            pass


def js(ws, expr, timeout=45):
    r = ws.call("Runtime.evaluate",
                {"expression": expr, "returnByValue": True, "awaitPromise": True}, timeout)
    return r.get("result", {}).get("value")


def nav(ws, url, attesa=3.0):
    try:
        ws.call("Page.navigate", {"url": url}, 20)
    except Exception:
        pass
    time.sleep(attesa)


def target_pagine():
    try:
        return [t for t in http_json("/json/list") if t.get("type") == "page"]
    except Exception:
        return []


def aggancia(target):
    ultimo = None
    for tentativo in range(2):
        try:
            ws = WS(target["webSocketDebuggerUrl"])
            ws.call("Page.enable")
            ws.call("Runtime.enable")
            return ws
        except Exception as e:
            ultimo = e
            time.sleep(1.0)
    raise ConnectionError(f"scheda non raggiungibile: {ultimo}")


def nuova_scheda(url="about:blank"):
    tab = None
    for metodo in ("PUT", "GET"):
        try:
            tab = http_json("/json/new?" + url, method=metodo)
            break
        except Exception:
            continue
    if not tab or "webSocketDebuggerUrl" not in tab:
        raise RuntimeError("impossibile aprire una scheda via CDP")
    return aggancia(tab), tab


def chiudi_scheda(tab):
    try:
        http_json("/json/close/" + tab["id"])
    except Exception:
        try:
            http_json("/json/close/" + tab["id"], "PUT")
        except Exception:
            pass


# ─────────────────────────── letture dentro il browser ───────────────────────
SALDO_JS = r"""
(async () => {
  const out = {ok:false, saldo:null, fonte:null, debug:[]};
  const num = v => { const n = Number(v); return Number.isFinite(n) ? n : null; };
  // 1) endpoint billing (new-api): hard_limit_usd - total_usage/100
  try {
    const a = await fetch('/dashboard/billing/subscription', {credentials:'include'});
    const b = await fetch('/dashboard/billing/usage', {credentials:'include'});
    const ta = await a.text(), tb = await b.text();
    out.debug.push('sub '+a.status+' '+ta.slice(0,60));
    if (a.status===200 && b.status===200 && ta.trim().startsWith('{') && tb.trim().startsWith('{')) {
      const sub = JSON.parse(ta), use = JSON.parse(tb);
      const tot = num(sub.hard_limit_usd), used = (num(use.total_usage)||0)/100.0;
      if (tot !== null) { out.saldo = tot - used; out.fonte = 'billing'; }
    }
  } catch(e) { out.debug.push('billing err '+e); }
  // 2) /api/user/self : quota (500000 = 1$)
  if (out.saldo === null) {
    try {
      const r = await fetch('/api/user/self', {credentials:'include'});
      const t = await r.text();
      out.debug.push('self '+r.status+' '+t.slice(0,80));
      if (t.trim().startsWith('{')) {
        const d = JSON.parse(t);
        if (d && d.success && d.data) {
          out.loggato = true;
          const q = num(d.data.quota);
          if (q !== null) { out.saldo = q / 500000.0; out.fonte = 'quota/500000'; }
          out.utente = d.data.username || d.data.display_name || null;
        } else out.loggato = false;
      }
    } catch(e) { out.debug.push('self err '+e); }
  }
  if (out.saldo !== null) out.saldo = Math.round(out.saldo*100)/100;
  out.ok = true;
  return out;
})()
"""


def leggi_saldo(ws):
    try:
        d = js(ws, SALDO_JS, 40) or {}
    except Exception as e:
        return {"saldo": None, "loggato": None, "debug": [f"eccezione {e}"]}
    return d


def aggiorna_saldo_fuori_ws(ws):  # alias storico usato in vecchi import
    return leggi_saldo(ws)


def loggato_su_agentrouter(ws):
    """True/False/None: interroga /api/user/self dall'interno della pagina."""
    try:
        return js(ws, """(async()=>{try{const r=await fetch('/api/user/self',{credentials:'include'});
            const t=await r.text(); if(!t.trim().startsWith('{')) return null;
            const d=JSON.parse(t); return !!(d&&d.success&&d.data);}catch(e){return null}})()""", 25)
    except Exception:
        return None


def sessione_github_viva(ws):
    """Guarda meta[name=user-login] su github.com (GitHub la mette solo se sei loggato)."""
    nav(ws, GH + "/", 3.5)
    utente = js(ws, "(()=>{const m=document.querySelector('meta[name=user-login]');"
                    "return m?m.content:null})()")
    return utente


def probabile_pagina_autorizzazione(ws):
    """Se GitHub mostra 'Authorize', lo preme (l'app e' gia' nostra, nessun rischio)."""
    try:
        return js(ws, r"""(()=>{
          const b=[...document.querySelectorAll('button,input[type=submit],a')]
            .find(e=>/authori[sz]e|autorizza|授权/i.test((e.textContent||'')+(e.value||''))&&e.offsetParent!==null);
          if(b){b.click();return 'click-authorize'} return null})()""")
    except Exception:
        return None


def mostra_schede(etichetta=""):
    if os.environ.get("AR_DEBUG"):
        print(f"[debug] schede {etichetta}:")
        for t in target_pagine():
            print("   -", (t.get("url") or "")[:90])


def attendi_rientro(schede_iniziali, tmax=ATTESA_OAUTH):
    """Aspetta che una scheda torni su agentrouter.org con sessione valida. Ritorna (ws, tab) o (None, None)."""
    t0 = time.time()
    id_iniziali = {t["id"] for t in schede_iniziali}
    viste = set()
    while time.time() - t0 < tmax:
        for t in target_pagine():
            url = t.get("url") or ""
            if not url.startswith(BASE):
                if GH_NETLOC in url.lower():
                    viste.add(t["id"])
                    try:
                        ws = aggancia(t)
                        esito = probabile_pagina_autorizzazione(ws)
                        if esito:
                            print(f"[checkin] {esito}")
                            time.sleep(2)
                        ws.close()
                    except Exception:
                        pass
                continue
            if "/login" in url or url.rstrip("/") == BASE:
                continue
            try:
                ws = aggancia(t)
            except Exception:
                continue
            if loggato_su_agentrouter(ws) is True:
                nuovo = t["id"] not in id_iniziali
                print(f"[checkin] rientro OK su scheda {'NUOVA' if nuovo else 'originale'}: {url[:70]}")
                return ws, t
            ws.close()
        time.sleep(1.5)
    return None, None


# ────────────────────────────────── flusso ───────────────────────────────────
def main(argv):
    sola_verifica = "--verifica" in argv
    print(f"[checkin] {time.strftime('%d/%m/%Y %H:%M')} · base={BASE} · modo={'VERIFICA' if sola_verifica else 'RISCATTO'}")
    try:
        http_json("/json/version")
    except Exception:
        print("ERRORE: BROWSER_AGENTI spento o porta 9222 chiusa — apri BROWSER_AGENTI.bat e riprova.")
        return 2

    schede0 = target_pagine()
    mostra_schede("iniziali")
    ws_gh, tab_gh = nuova_scheda("about:blank")
    ws_ar, tab_ar = nuova_scheda("about:blank")
    tab_da_chiudere = [tab_gh, tab_ar]
    ok_sessione = None
    try:
        # 1) La sessione GitHub e' la chiave di tutto: senza quella, logout = restare fuori
        utente_gh = sessione_github_viva(ws_gh)
        print(f"[checkin] sessione GitHub: {utente_gh or 'NON LOGGATO'}")
        if not utente_gh:
            print("[checkin] ⛔ GitHub e' sloggato: NON faccio logout (ti lascerei fuori).")
            print("[checkin] 👉 apri BROWSER_AGENTI, fai login su github.com (una volta sola) e rilancia.")
            print("[login_manuale] servono le credenziali nel BROWSER_AGENTI")
            return 3

        # 2) stato attuale di AgentRouter
        nav(ws_ar, BASE + "/console", 5)
        stato = leggi_saldo(ws_ar)
        saldo_prima = stato.get("saldo")
        dentro = loggato_su_agentrouter(ws_ar)
        print(f"[checkin] AgentRouter: {'dentro' if dentro else 'fuori'} · saldo prima: "
              f"{saldo_prima if saldo_prima is not None else 'non letto'}")
        if dentro is None:
            print("[checkin] ⚠ pagina illeggibile (WAF?): " + " | ".join(stato.get("debug", [])[:3]))

        # 3) se siamo fuori, prima provo a rientrare (senza aver sloggato nessuno)
        if dentro is not True:
            print("[checkin] provo il rientro dal login…")
            nav(ws_ar, BASE + "/login", 3)
            click = js(ws_ar, """(()=>{
 const cands=[...document.querySelectorAll('a[href],button,[role=button],input[type=submit]')]
   .filter(e=>e.offsetParent!==null||e.getClientRects().length);
 const t=cands.find(e=>/github/i.test((e.textContent||'')+' '+(e.innerHTML||'')));
 if(!t) return 'NON-TROVATO';
 const a=t.closest('a[href]');
 const href=a&&a.getAttribute('href');
 if(href && !href.startsWith('#') && !/^javascript:/i.test(href)){location.href=href;return 'nav-href:'+href.slice(0,60);}
 (t.closest('a,button')||t).click(); return 'click-github';
})()""")
            print(f"[checkin] bottone GitHub: {click}")
            ws2, _ = attendi_rientro(schede0)
            if ws2:
                ws_ar.close()
                ws_ar = ws2
                dentro = True
                nav(ws_ar, BASE + "/console", 4)   # pagina fresca: il saldo si legge da qui
                time.sleep(1)
                stato = leggi_saldo(ws_ar)
                saldo_prima = stato.get("saldo")
                print(f"[checkin] saldo prima (dopo rientro): "
                      f"{saldo_prima if saldo_prima is not None else 'non letto'}")
            else:
                print("[checkin] ⚠ rientro non riuscito (GitHub loggato ma l'OAuth non e' tornato)")
                print("[checkin] 👉 serve un login manuale una volta nel BROWSER_AGENTI")
                print("[login_manuale] OAuth non tornato")
                return 3

        # 4) ora il giro che riscatta: logout -> login (senza logout non c'e' accredito)
        if sola_verifica:
            print("[checkin] ✅ (modo verifica) sessione valida, nessun logout fatto.")
            return 0

        print("[checkin] eseguo logout → login (e' il giro che accredita il bonus)…")
        code = js(ws_ar, """fetch('/api/user/logout',{credentials:'include'})
            .then(r=>r.status).catch(e=>'ERR:'+e)""")
        print(f"[checkin] logout http: {code}")
        time.sleep(2)
        nav(ws_ar, BASE + "/login", 3)
        click = js(ws_ar, """(()=>{
 const cands=[...document.querySelectorAll('a[href],button,[role=button],input[type=submit]')]
   .filter(e=>e.offsetParent!==null||e.getClientRects().length);
 const t=cands.find(e=>/github/i.test((e.textContent||'')+' '+(e.innerHTML||'')));
 if(!t) return 'NON-TROVATO';
 const a=t.closest('a[href]');
 const href=a&&a.getAttribute('href');
 if(href && !href.startsWith('#') && !/^javascript:/i.test(href)){location.href=href;return 'nav-href:'+href.slice(0,60);}
 (t.closest('a,button')||t).click(); return 'click-github';
})()""")
        print(f"[checkin] bottone GitHub: {click}")
        if click == "NON-TROVATO":
            print("[checkin] ⚠ la pagina di login non mostra il bottone GitHub (layout cambiato?)")
            print("[login_manuale] bottone GitHub non trovato")
            return 3

        ws2, _ = attendi_rientro(schede0)
        if not ws2:
            print("[checkin] ⚠ il giro logout→login non e' tornato entro " + str(ATTESA_OAUTH) + "s")
            print("[login_manuale] logout fatto, rientro non riuscito")
            return 3
        ws_ar.close()
        ws_ar = ws2
        mostra_schede("dopo il giro")

        # 5) saldo dopo
        nav(ws_ar, BASE + "/console", 4)
        time.sleep(2)
        stato2 = leggi_saldo(ws_ar)
        saldo_dopo = stato2.get("saldo")
        delta = None
        if saldo_prima is not None and saldo_dopo is not None:
            delta = round(saldo_dopo - saldo_prima, 2)
        print(f"[checkin] saldo dopo: {saldo_dopo if saldo_dopo is not None else 'non letto'}"
              + (f" · delta: {'+' if (delta or 0) >= 0 else ''}{delta}$" if delta is not None else ""))
        if delta is not None and delta >= 20:
            print(f"[checkin] ✅ BONUS INCASSATO: +{delta}$ (il +25$ giornaliero)")
        elif delta is not None and abs(delta) < 0.01:
            print("[checkin] ✅ giro completato, ma nessun accredito: probabile bonus gia' riscattato oggi")
        else:
            print("[checkin] ✅ giro logout→login completato (accredito non misurabile: saldo non leggibile)")
        return 0
    finally:
        for t in tab_da_chiudere:
            chiudi_scheda(t)
        try:
            ws_gh.close()
        except Exception:
            pass
        try:
            ws_ar.close()
        except Exception:
            pass


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except ConnectionError as e:
        print(f"[checkin] ⚠ connessione CDP persa ({e}): il BROWSER_AGENTI si e' chiuso o e' stato riavviato")
        sys.exit(1)
    except Exception as e:
        print(f"[checkin] ⚠ errore imprevisto: {type(e).__name__}: {e}")
        sys.exit(1)
