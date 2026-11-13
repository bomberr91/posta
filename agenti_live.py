#!/usr/bin/env python3
# agenti_live.py — IL PANNELLO AGENTI LIVE (da Paperclip, cucito a casa) — 127.0.0.1:20201
# mostra: chi sta facendo cosa (battiti), i servizi, il consumo per agente (dal cervello)
# solo stdlib · solo localhost (regola casa: niente esposto senza autenticazione)
import json, os, socket, time, datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

PORTA = 20201
STATO_DIR = os.path.expanduser("~/posta/stato_agenti")
APPR_DIR = os.path.expanduser("~/posta/approvazioni")
AGENTI_NOTI = ["opencode", "goose", "secondhand", "hermes", "openclaw", "gemini", "squadra"]
COLORI = {"running": "#22c55e", "blocked": "#ef4444", "idle": "#eab308",
          "paused": "#f97316", "offline": "#6b7280", "non-avviato": "#4b5563"}
SERVIZI = [("Cervello", 20129), ("OmniRoute", 20128), ("Hub GUI", 20200),
           ("Browser Agenti", 9222), ("Swarmchat", 8484)]

socket.setdefaulttimeout(1.2)

def porta_up(porta):
    try:
        s = socket.create_connection(("127.0.0.1", porta), timeout=1.2)
        s.close(); return True
    except Exception:
        return False

def vivi(pattern):
    try:
        out = os.popen("pgrep -f '%s' 2>/dev/null | head -1" % pattern).read().strip()
        return bool(out)
    except Exception:
        return False

def consumo_cervello():
    """prendi il consumo per agente da /portiere.json (difensivo: il cervello può dormire)"""
    try:
        with urllib.request.urlopen("http://127.0.0.1:20129/portiere.json", timeout=3) as r:
            d = json.loads(r.read().decode("utf-8", "replace"))
        oggi = time.strftime("%Y-%m-%d")
        cons = (d.get("consumo_7giorni") or {}).get(oggi) or {}
        castighi = len(d.get("castighi") or {})
        riserva = d.get("riserva_numero", "?")
        return cons, castighi, riserva, None
    except Exception as e:
        return {}, None, None, str(e)[:80]

import urllib.request

def pagina():
    ora = datetime.datetime.now().strftime("%H:%M:%S")
    # agenti: il union dei battiti conosciuti e degli agenti noti
    battiti = {}
    if os.path.isdir(STATO_DIR):
        for f in os.listdir(STATO_DIR):
            if f.endswith(".json"):
                try:
                    d = json.load(open(os.path.join(STATO_DIR, f), encoding="utf-8"))
                    battiti[d.get("agente", f[:-5])] = d
                except Exception:
                    pass
    nomi = sorted(set(AGENTI_NOTI) | set(battiti))
    righe_agenti, problemi = [], 0
    adesso = int(time.time())
    for nome in nomi:
        d = battiti.get(nome)
        if d is None:
            righe_agenti.append(f"<tr><td><b>{nome}</b></td><td style='color:#4b5563'>⚫ non avviato</td><td>—</td><td>—</td></tr>")
            continue
        eta = adesso - int(d.get("epoch", 0))
        stato = d.get("stato", "offline")
        if eta > 900:
            stato = "offline"; d["nota"] = "senza battito da %d min" % (eta // 60)
        colore = COLORI.get(stato, "#6b7280")
        if stato in ("blocked",):
            problemi += 1
        righe_agenti.append(
            f"<tr><td><b>{nome}</b></td><td style='color:{colore}'>● {stato}</td>"
            f"<td>{d.get('nota','') or '—'}</td><td style='font-family:monospace'>{d.get('ts','')}</td></tr>")
    # servizi
    righe_servizi = []
    for nome, porta in SERVIZI:
        up = porta_up(porta)
        if not up and nome != "Browser Agenti":  # il browser si accende a comando: non è un problema
            if nome not in ("Browser Agenti",):
                problemi += 1
        colore = "#22c55e" if up else "#6b7280"
        righe_servizi.append(f"<tr><td>{nome}</td><td>: {porta}</td>"
                             f"<td style='color:{colore}'>● {'acceso' if up else 'spento'}</td></tr>")
    up_postino = vivi("postino[.]sh"); up_magpie = vivi("magpie serve")
    if not up_postino: problemi += 1
    colore_p = "#22c55e" if up_postino else "#ef4444"
    colore_m = "#22c55e" if up_magpie else "#6b7280"
    righe_servizi.append(f"<tr><td>Postino</td><td>—</td><td style='color:{colore_p}'>● {'attivo' if up_postino else 'FERMO'}</td></tr>")
    righe_servizi.append(f"<tr><td>Magpie</td><td>—</td><td style='color:{colore_m}'>● {'attivo' if up_magpie else 'spento'}</td></tr>")
    # consumo dal cervello
    cons, castighi, riserva, errore = consumo_cervello()
    righe_consumo = []
    if errore:
        righe_consumo.append(f"<tr><td colspan=4 style='color:#ef4444'>cervello irraggiungibile ({errore})</td></tr>")
    elif not cons:
        righe_consumo.append("<tr><td colspan=4 style='color:#6b7280'>nessun consumo oggi (i battiti partono dalla prima richiesta)</td></tr>")
    else:
        for agente in sorted(cons):
            v = cons[agente] or {}
            righe_consumo.append(f"<tr><td><b>{agente}</b></td><td style='font-family:monospace'>{v.get('richieste','?')}</td>"
                                 f"<td style='font-family:monospace'>{v.get('token','?')}</td><td>oggi</td></tr>")
    linea_giudizio = "🟢 Tutto scorre." if problemi == 0 else f"🟡 {problemi} cosa(e) da guardare — vedi i rosso/giallo."
    return f"""<!doctype html><html lang="it"><head><meta charset="utf-8">
<meta http-equiv="refresh" content="15"><title>Agenti Live — FilippoPC</title>
<style>body{{background:#0b0f14;color:#e5e7eb;font-family:system-ui,sans-serif;margin:24px}}
table{{border-collapse:collapse;width:100%}}td{{padding:5px 10px;border-bottom:1px solid #1f2937}}
h2{{margin:28px 0 8px;font-size:15px;color:#93c5fd;text-transform:uppercase;letter-spacing:1px}}
.giud{{font-size:18px;margin:10px 0}}</style></head><body>
<h1 style="font-size:20px">⚡ AGENTI LIVE — FilippoPC <span style="color:#6b7280;font-size:12px">aggiornato {ora} · ricarica ogni 15s</span></h1>
<div class="giud">{linea_giudizio}</div>
<h2>Agenti — chi sta facendo cosa</h2>
<table><tr><td><b>Agente</b></td><td><b>Stato</b></td><td><b>Cosa / nota</b></td><td><b>Ultimo battito</b></td></tr>
{''.join(righe_agenti)}</table>
<h2>Servizi</h2>
<table><tr><td><b>Servizio</b></td><td><b>Porta</b></td><td><b>Stato</b></td></tr>
{''.join(righe_servizi)}</table>
<h2>Consumo di oggi per agente (dal cervello){f' · castighi attivi: {castighi}' if castighi is not None else ''}{f' · riserva: {riserva}' if riserva not in (None,'?') else ''}</h2>
<table><tr><td><b>Agente</b></td><td><b>Richieste</b></td><td><b>Token</b></td><td><b>Giorno</b></td></tr>
{''.join(righe_consumo)}</table>
<p style="color:#6b7280;font-size:12px">battiti: ogni agente lanciato dalla Centrale scrive in ~/posta/stato_agenti/ · vocabolario: running blocked idle paused offline</p>
</body></html>"""

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass  # niente log a schermo
    def do_GET(self):
        u = urlparse(self.path)
        if u.path == "/":
            corpo = pagina().encode("utf-8")
            self.send_response(200); self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(corpo))); self.end_headers()
            self.wfile.write(corpo)
        elif u.path == "/salute":
            self.send_response(200); self.end_headers()
            self.wfile.write(b"OK")
        else:
            self.send_response(404); self.end_headers()

if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORTA), H).serve_forever()
