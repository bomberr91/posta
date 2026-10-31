#!/usr/bin/env python3
"""cervello.py — il PORTIERE (motore di riserva, porta 20129).  [FASE 1]

Perché esiste: tutti gli agenti parlano con UNA porta sola. Questo programma
sta sulla 20129 e fa da portiere:

  - se OmniRoute (20128) è vivo  → passa tutto a lui;
  - se OmniRoute è morto         → usa le chiavi dell'appello (la riserva).

FASE 1 (31/10/2026) — cosa è stato aggiunto, con il numero dell'idea:
   6  modelli-politica: "auto" / "gratis" / "veloce" / "migliore"
  10  hot-reload: portiere_lista.txt ricaricata da sola quando cambia
  14  disabilitazione automatica del canale malato (pagella)
  17  castigo per (chiave, modello): un 429 riposa solo quel modello
  18  tassonomia errori: 404/410 pensionato · 429 breve/quota · 401/403 chiave
      · 413/contesto failover senza castigo · 5xx passeggero
  20  castighi e pagella PERSISTENTI su disco (portiere_stato.json)
  21  guardia solo-gratis: modelli a pagamento rifiutati
  22  quota giornaliera finita → la chiave riposa 1 ora
  25  timeout per richiesta (numeri collaudati, CONFIG)
  27  salute = tasso di successo (soglia 0.8), non solo errori secchi
  32  errore di contesto → failover alla catena, senza punire nessuno
  33  numeri LiteLLM collaudati + drop_params gentile (parametri sicuri passano)
  39  tassonomia del gratis: campo "classe" nella lista (keyless/free/trial)
  46  richieste banali (titoli, ping) risposte in casa: 0 token spesi
  50  log glass-box: ogni richiesta → riga JSON con rotta, modello, ms, esito
  52  --sonda: verifica le chiavi con GET /models (costo zero token)
  58  sessione stabile: x-opencode-session inoltrato/generato per agente
  (23/34/35: motori keyless nuovi → vanno nella LISTA, vedi README_FASE1)

Aggiunte del saggio: cooldown statici, retry con jitter, log chiari, timeout brevi.

  python3 cervello.py            resta acceso sulla porta 20129
  python3 cervello.py --stato    dice chi sta rispondendo adesso
  python3 cervello.py --sonda    controlla le chiavi senza spendere token
  python3 cervello.py --perdona  amnistia: azzera tutti i castighi
"""
import hashlib
import json
import os
import random
import re
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

# ── FASE 1 · CONFIG: i numeri collaudati (idea 33 + saggio: statici, niente tuning) ──
CONFIG = {
    "cooldown_breve": 45,        # 429 semplice: quel (chiave,modello) riposa 45s
    "cooldown_quota": 3600,      # quota giornaliera finita: la chiave riposa 1 ora (idea 22)
    "cooldown_chiave": 1800,     # 401/403: chiave rifiutata, riposa 30 min
    "cooldown_pensionato": 21600,# 404/410: modello pensionato, 6 ore per tutti
    "cooldown_passeggero": 30,   # 5xx: incidente passeggero
    "timeout_riserva": 60,       # secondi per ogni provider di riserva (idea 25)
    "timeout_motore": 180,       # secondi per OmniRoute
    "soglia_successo": 0.8,      # sotto questo tasso il canale è malato (idea 27)
    "min_prove": 5,              # prima di giudicare servono almeno 5 prove
    "riposo_malato": 120,        # il canale malato riprova ogni 2 minuti
    "intercetta_banali": True,   # idea 46 (metti False per spegnere)
    "solo_gratis": True,         # idea 21: guardia anti-spesa
}

# ── LA LISTA SUA (portiere_lista.txt) ─────────────────────────────────────────
# formato: id|etichetta|nome portachiavi|indirizzo API|modello|modo|tipo|classe
# classe (idea 39): keyless · free-ricorrente · trial · pin-only (vuoto = free-ricorrente)
LISTA = os.path.join(QUI, "portiere_lista.txt")
_lista_mtime = [0.0]


def carica_lista():
    """Legge la lista del Portiere. Ritorna (base, etichette, nomi, modi, tipi, classi)."""
    base, etichette, nomi, modi, tipi, classi = {}, {}, {}, {}, {}, {}
    try:
        righe = open(LISTA, encoding="utf-8", errors="replace").read().splitlines()
    except Exception:
        return base, etichette, nomi, modi, tipi, classi
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
        tipo = (pezzi[6] if len(pezzi) > 6 else "chat").strip() or "chat"
        classe = (pezzi[7] if len(pezzi) > 7 else "").strip() or \
                 ("keyless" if nome == "SENZA" else "free-ricorrente")
        base[pid] = (url.rstrip("/"), modello)
        etichette[pid] = eti
        nomi[pid] = nome
        modi[pid] = modo
        tipi[pid] = tipo
        classi[pid] = classe
    return base, etichette, nomi, modi, tipi, classi


BASE, ETICHETTE, NOMI, MODI, TIPI, CLASSI = carica_lista()


def ricarica():
    """Idea 10 · hot-reload: se portiere_lista.txt è cambiata, la ricarica da sola."""
    global BASE, ETICHETTE, NOMI, MODI, TIPI, CLASSI
    try:
        m = os.path.getmtime(LISTA)
    except Exception:
        return
    if m != _lista_mtime[0]:
        _lista_mtime[0] = m
        BASE, ETICHETTE, NOMI, MODI, TIPI, CLASSI = carica_lista()
        logga(tipo="hot-reload", nota="lista ricaricata: %d provider" % len(BASE))


try:
    _lista_mtime[0] = os.path.getmtime(LISTA)
except Exception:
    pass


def indirizzo(pid, k):
    """Indirizzo e intestazioni per quel provider (Cloudflare ha un formato suo)."""
    url, _ = BASE[pid]
    if url == "SPECIALE-CLOUDFLARE":
        acc, _, tok = (k or "").partition(":")
        return ("https://api.cloudflare.com/client/v4/accounts/%s/ai/v1" % acc,
                {"Authorization": "Bearer " + tok})
    return url, {"Authorization": "Bearer " + k}

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
    """La chiave di quel provider, dal portachiavi (chiave_di.py). SENZA = gratis."""
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


# ── FASE 1 · STATO PERSISTENTE: castighi e pagella (idee 17-22-27, 20) ───────
STATO_FILE = os.path.join(QUI, "portiere_stato.json")
STATO = {"castighi": {}, "pagella": {}}
_ultimo_salvataggio = [0.0]


def stato_carica():
    global STATO
    try:
        d = json.load(open(STATO_FILE, encoding="utf-8"))
        if isinstance(d, dict):
            STATO = d
    except Exception:
        pass
    STATO.setdefault("castighi", {})
    STATO.setdefault("pagella", {})


def stato_salva(forza=False):
    """Scrive su disco al massimo ogni 2 secondi (idea 20: sopravvive al riavvio)."""
    if not forza and time.time() - _ultimo_salvataggio[0] < 2:
        return
    _ultimo_salvataggio[0] = time.time()
    try:
        ora = time.time()
        STATO["castighi"] = {k: v for k, v in STATO["castighi"].items() if v > ora}
        json.dump(STATO, open(STATO_FILE, "w", encoding="utf-8"))
    except Exception:
        pass


def castiga(pid, modello, secondi, globale=False):
    """Idea 17: il castigo colpisce la coppia (chiave, modello), non tutta la chiave.
    modello=None → tutta la chiave. globale=True → quel modello per TUTTI (pensionato)."""
    if globale:
        k = "*|" + (modello or "")
    elif modello is None:
        k = pid + "|*"
    else:
        k = pid + "|" + modello
    STATO["castighi"][k] = time.time() + secondi
    stato_salva(forza=True)              # i castighi DEVONO sopravvivere al riavvio


def punito(pid, modello):
    c = STATO["castighi"]
    ora = time.time()
    for k in (pid + "|" + (modello or ""), pid + "|*", "*|" + (modello or "")):
        if c.get(k, 0) > ora:
            return True
    return False


def segna(pid, ok):
    """Idea 27: pagella col tasso di successo. La memoria sbiadisce (dimezza a 50 prove)."""
    p = STATO["pagella"].setdefault(pid, {"ok": 0, "ko": 0, "ultimo_ko": 0})
    p["ok" if ok else "ko"] += 1
    if not ok:
        p["ultimo_ko"] = time.time()
    if p["ok"] + p["ko"] > 50:
        p["ok"] //= 2
        p["ko"] //= 2
    stato_salva(forza=not ok)            # i voti negativi vanno su disco subito


def in_salute(pid):
    """Sotto soglia 0.8 (dopo almeno 5 prove) il canale è malato: riprova ogni 2 min."""
    p = STATO["pagella"].get(pid)
    if not p or p["ok"] + p["ko"] < CONFIG["min_prove"]:
        return True
    if p["ok"] / (p["ok"] + p["ko"]) >= CONFIG["soglia_successo"]:
        return True
    return time.time() - p.get("ultimo_ko", 0) > CONFIG["riposo_malato"]


def classifica_errore(codice, testo):
    """Idea 18 · tassonomia: ogni errore ha la sua medicina."""
    t = (testo or "").lower()
    if codice in (404, 410):
        return "pensionato"
    if codice == 413 or "context" in t or "too long" in t or "token limit" in t:
        return "contesto"
    if codice == 429:
        if any(s in t for s in ("day", "daily", "quota", "exceeded", "per-day")):
            return "quota"
        return "breve"
    if codice in (401, 403) or "unauthorized" in t or "no access" in t:
        return "chiave"
    if codice and codice >= 500:
        return "passeggero"
    return "altro"


# ── FASE 1 · LOG GLASS-BOX (idea 50 + logger del saggio) ─────────────────────
LOG_FILE = os.path.join(QUI, "portiere_log.jsonl")


def logga(**voce):
    """Una riga JSON per ogni evento: chi, cosa, rotta, quanto ci ha messo, esito."""
    voce["quando"] = time.strftime("%Y-%m-%d %H:%M:%S")
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(voce, ensure_ascii=False) + "\n")
        if os.path.getsize(LOG_FILE) > 3_000_000:
            righe = open(LOG_FILE, encoding="utf-8").read().splitlines()[-2000:]
            open(LOG_FILE, "w", encoding="utf-8").write("\n".join(righe) + "\n")
    except Exception:
        pass


# ── FASE 1 · RICHIESTE BANALI (idea 46): risposte in casa, 0 token ───────────
RE_TITOLO = re.compile(r"(generate|write|create|produce)[^.\n]{0,50}\btitle\b", re.I)


def risposta_locale(testo, perche):
    return {"id": "locale-%d" % int(time.time() * 1000), "object": "chat.completion",
            "created": int(time.time()),
            "model": "cervello/locale (%s: risposta in casa, 0 token)" % perche,
            "choices": [{"index": 0, "message": {"role": "assistant", "content": testo},
                         "finish_reason": "stop"}],
            "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0}}


def banale(payload):
    """Solo i casi SICURI: titoli di conversazione (max_tokens piccolo) e ping."""
    msgs = payload.get("messages") or []
    ultimo = ""
    for m in reversed(msgs):
        if m.get("role") == "user":
            ultimo = str(m.get("content", ""))
            break
    if ultimo.strip().lower() in ("ping", "test", "say ok"):
        return risposta_locale("OK", "ping")
    mt = payload.get("max_tokens")
    if not (isinstance(mt, int) and mt <= 120):
        return None                      # i titoli veri viaggiano con max_tokens piccolo
    testo = " ".join(str(m.get("content", ""))[:400] for m in msgs[:2] + msgs[-1:])
    if RE_TITOLO.search(testo) and len(testo) < 2000:
        parole = re.sub(r"[^\w\s\u00c0-\u00ff]", " ", ultimo).split()
        return risposta_locale(" ".join(parole[:6]) or "Conversazione", "titolo")
    return None


# ── FASE 1 · GUARDIA SOLO-GRATIS (idea 21) ───────────────────────────────────
A_PAGAMENTO = ("gpt-5", "gpt-4.1", "gpt-4o", "o3", "o4-", "claude-opus",
               "claude-sonnet", "claude-haiku", "gemini-2.5-pro", "grok-4")


def a_pagamento(modello):
    m = (modello or "").lower()
    if not m or "free" in m or "oss" in m or "mini" in m:
        return False
    return any(p in m for p in A_PAGAMENTO)


# ── FASE 1 · MODELLI-POLITICA (idea 6) ───────────────────────────────────────
POLITICHE = ("auto", "gratis", "keyless", "veloce", "migliore")
FORTI = ("deepseek-v4", "glm-5", "kimi-k", "qwen3", "deepseek", "glm", "llama-3.3-70b")


def ordina_per_politica(ordine, politica):
    if politica in ("gratis", "keyless"):
        return [v for v in ordine if CLASSI.get(v["id"]) == "keyless"]
    if politica == "migliore":
        def forza(v):
            m = (v.get("modello") or "").lower()
            for i, pat in enumerate(FORTI):
                if pat in m:
                    return i
            return len(FORTI)
        return sorted(ordine, key=forza)
    return ordine                        # auto e veloce: già in ordine di velocità


def inoltra(corpo, percorso="chat/completions", secondi=None, sessione=""):
    """Passa la richiesta al motore. Ritorna il JSON o None."""
    try:
        intestazioni = {"Content-Type": "application/json"}
        if sessione:
            intestazioni["x-opencode-session"] = sessione   # idea 58
        req = urllib.request.Request(MOTORE + "/" + percorso, data=corpo,
                                     headers=intestazioni)
        return json.loads(urllib.request.urlopen(
            req, timeout=secondi or CONFIG["timeout_motore"]).read().decode())
    except Exception:
        return None


PARAMETRI_SICURI = ("temperature", "top_p", "stop", "presence_penalty",
                    "frequency_penalty", "seed")


def riserva(payload, politica="auto", sessione=""):
    """Manda la richiesta alla riserva, in ordine di velocità e salute.
    Ritorna (risposta, rotta) — rotta dice chi ha risposto, per il log glass-box."""
    messaggi = payload.get("messages") or []
    capo, sostituti = classifica()
    ordine = ([capo] if capo else []) + sostituti
    ordine = ordina_per_politica(ordine, politica)
    chiesto = (payload.get("model") or "").strip().lower()
    if chiesto and chiesto not in POLITICHE and not chiesto.startswith("cervello/"):
        for v in ordine:
            if chiesto in (v["id"].lower(), v["nome"].lower()) or chiesto == (v["modello"] or "").lower():
                ordine.remove(v)
                ordine.insert(0, v)
                break
    for v in ordine:
        pid = v["id"]
        _, modello = BASE[pid]
        modello = v.get("modello") or modello
        if punito(pid, modello):                          # idea 17
            continue
        if not in_salute(pid):                            # idee 14+27
            continue
        if CONFIG["solo_gratis"] and a_pagamento(modello):  # idea 21
            continue
        k = chiave(pid)
        if not k:
            continue
        base, intestazioni = indirizzo(pid, k)
        intestazioni["Content-Type"] = "application/json"
        if sessione:
            intestazioni["x-opencode-session"] = sessione  # idea 58
        dati = {"model": modello, "messages": messaggi,
                "max_tokens": payload.get("max_tokens", 1200)}
        for p in PARAMETRI_SICURI:                        # idea 33: drop_params gentile
            if p in payload:
                dati[p] = payload[p]
        corpo = json.dumps(dati).encode()
        inizio = time.time()
        try:
            req = urllib.request.Request(base + "/chat/completions", data=corpo,
                                         headers=intestazioni)
            d = json.loads(urllib.request.urlopen(
                req, timeout=CONFIG["timeout_riserva"]).read().decode())
            if (d.get("choices") or [{}])[0].get("message", {}).get("content"):
                segna(pid, True)
                nome = v.get("nome") or pid
                d["model"] = "%s (riserva %s)" % (modello, nome)
                return d, {"provider": pid, "modello": modello,
                           "ms": int((time.time() - inizio) * 1000)}
            segna(pid, False)                             # 200 ma vuoto: failover (idea 18)
            castiga(pid, modello, CONFIG["cooldown_passeggero"])
        except urllib.error.HTTPError as e:
            try:
                testo = e.read(500).decode(errors="replace")
            except Exception:
                testo = ""
            tipo = classifica_errore(e.code, testo)
            jitter = random.randint(0, 10)                # il saggio: retry con jitter
            if tipo == "breve":
                castiga(pid, modello, CONFIG["cooldown_breve"] + jitter)
                segna(pid, False)
            elif tipo == "quota":                         # idea 22
                castiga(pid, None, CONFIG["cooldown_quota"] + jitter)
                segna(pid, False)
            elif tipo == "chiave":
                castiga(pid, None, CONFIG["cooldown_chiave"] + jitter)
                segna(pid, False)
            elif tipo == "pensionato":                    # idea 18
                castiga(pid, modello, CONFIG["cooldown_pensionato"], globale=True)
            elif tipo == "contesto":                      # idee 18+32: nessun castigo
                pass
            else:
                castiga(pid, modello, CONFIG["cooldown_passeggero"] + jitter)
                segna(pid, False)
            logga(tipo="errore-riserva", provider=pid, modello=modello,
                  errore=tipo, codice=e.code)
            continue
        except Exception as e:
            castiga(pid, modello, CONFIG["cooldown_passeggero"])
            segna(pid, False)
            logga(tipo="errore-riserva", provider=pid, modello=modello,
                  errore="rete", nota=str(e)[:120])
            continue
    return None, None


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


# ── IL CAPO DELLA GIORNATA ───────────────────────────────────────────────────
SOSTITUTI_MAX = 12


def _appello_fresco(ore=2):
    try:
        return (time.time() - os.path.getmtime(APPELLO)) < ore * 3600
    except Exception:
        return False


def appello_da_solo():
    """Se l'appello è vecchio o non c'è, lo fa il Portiere in proprio."""
    if _appello_fresco():
        return
    subprocess.Popen(["bash", os.path.join(QUI, "appello_chiavi.sh"), "--svelto"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def classifica():
    """(capo, sostituti): solo provider di chat che hanno risposto, dal più veloce."""
    buoni = []
    for v in appello():
        pid = v.get("id")
        if v.get("esito") != "risponde" or pid not in BASE:
            continue
        if TIPI.get(pid, "chat") != "chat":
            continue
        buoni.append({"id": pid, "nome": v.get("nome") or ETICHETTE.get(pid, pid),
                      "modello": v.get("modello") or BASE[pid][1], "ms": v.get("ms") or 9999})
    buoni.sort(key=lambda x: x["ms"])
    if not buoni:
        return None, []
    return buoni[0], buoni[1:SOSTITUTI_MAX + 1]


def immagini(prompt):
    """Le chiavi di immagini della lista: se ti serve una foto, il Portiere pesca qui."""
    import urllib.parse
    if not prompt:
        return None
    for pid, tipo in TIPI.items():
        if tipo != "immagini":
            continue
        url, modello = BASE[pid]
        if "image.pollinations.ai" in url:
            q = urllib.parse.urlencode({"width": 1024, "height": 1024, "nologo": "true",
                                        "model": modello or "flux", "seed": int(time.time()) % 999999})
            return {"created": int(time.time()),
                    "data": [{"url": "%s/prompt/%s?%s" % (url, urllib.parse.quote(prompt), q)}],
                    "provider": "Pollinations (senza chiave)"}
    return None


def sonda():
    """Idea 52: verifica le chiavi con GET /models — zero token spesi."""
    ricarica()
    print("Sonda credenziali (GET /models, nessun token speso):")
    for pid, (url, modello) in BASE.items():
        eti = ETICHETTE.get(pid, pid)
        if NOMI.get(pid) == "SENZA":
            print("  — %-22s senza chiave (keyless, salto)" % eti)
            continue
        k = chiave(pid)
        if not k:
            print("  🔴 %-22s chiave ASSENTE nel portachiavi" % eti)
            continue
        base, intest = indirizzo(pid, k)
        try:
            urllib.request.urlopen(urllib.request.Request(base + "/models",
                                   headers=intest), timeout=8).read(200)
            print("  ✅ %-22s chiave valida" % eti)
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                print("  🔴 %-22s chiave RIFIUTATA (%d)" % (eti, e.code))
            else:
                print("  🟡 %-22s risponde %d (endpoint diverso?)" % (eti, e.code))
        except Exception:
            print("  ⚪ %-22s non raggiungibile" % eti)


def pagina():
    """La pagina del Portiere: la SUA lista, provider per provider."""
    voci = {v.get("id"): v for v in appello()}
    su_motore = vivo(MOTORE)
    pronti = sum(1 for pid in BASE if (voci.get(pid) or {}).get("esito") == "risponde")
    ora = time.time()
    castigati = sum(1 for v in STATO["castighi"].values() if v > ora)
    corpo = []
    for pid, (url, modello) in BASE.items():
        v = voci.get(pid) or {}
        esito = v.get("esito", "")
        icona, colore = {"risponde": ("✅", "#39d98a"), "occupato": ("🟡", "#f5c451"),
                         "chiave-no": ("🔴", "#ff6b6b"), "rete": ("⚪", "#9aa4b2"),
                         "no-chiave": ("—", "#9aa4b2")}.get(esito, ("·", "#6b7280"))
        nota = v.get("nota") or ("mai provato: fai l'appello dalla Centrale" if not esito else esito)
        p = STATO["pagella"].get(pid)
        if p and p["ok"] + p["ko"] >= CONFIG["min_prove"]:
            nota += " · pagella %d%%" % round(100 * p["ok"] / (p["ok"] + p["ko"]))
        if punito(pid, modello):
            nota += " · ⏸ in castigo"
        corpo.append(
            '<tr><td style="padding:7px 10px;border-bottom:1px solid #ffffff12">'
            f'<span style="color:{colore}">{icona}</span> <b>{ETICHETTE.get(pid, pid)}</b> '
            f'<span style="color:#6b7280;font-size:12px">{TIPI.get(pid, "chat")} · {CLASSI.get(pid, "")}</span></td>'
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
  <h1 style="margin:0 0 4px;font-size:22px">🚪 Portiere <span style="font-size:14px;color:#9aa4b2">porta 20129 · FASE 1</span></h1>
  <div style="color:#9aa4b2;margin-bottom:16px">Il motore di riserva: fa passare tutto a OmniRoute
    quando è acceso, e se OmniRoute cade usa la sua lista qui sotto.
    Modelli-politica: <b>auto</b> · <b>gratis</b> · <b>veloce</b> · <b>migliore</b>.</div>
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
    <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">
      <div style="color:#9aa4b2;font-size:12px">in castigo adesso</div>
      <div style="font-size:20px">{castigati or '—'}</div></div>
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

    def _rispondi(self, d, stream):
        """Risposta normale, oppure confezionata in streaming (SSE) se il
        client l'ha chiesta cosi: alcuni agenti (OpenCode, ai-sdk) parlano
        SOLO a pezzetti e con la risposta in blocco restano appesi."""
        if not stream:
            self._json(d)
            return
        msg = (d.get("choices") or [{}])[0].get("message", {})
        delta = {"role": "assistant", "content": msg.get("content", "") or ""}
        tc = msg.get("tool_calls") or []
        if tc:
            delta["tool_calls"] = [dict(v, index=i) for i, v in enumerate(tc)]
        base = {"id": d.get("id", "cervello"), "object": "chat.completion.chunk",
                "created": d.get("created", int(time.time())), "model": d.get("model", "")}
        fine = (d.get("choices") or [{}])[0].get("finish_reason") or "stop"
        pezzo1 = dict(base, choices=[{"index": 0, "delta": delta, "finish_reason": None}])
        pezzo2 = dict(base, choices=[{"index": 0, "delta": {}, "finish_reason": fine}])
        if d.get("usage"):
            pezzo2["usage"] = d["usage"]
        corpo = ("data: %s\n\ndata: %s\n\ndata: [DONE]\n\n" % (
            json.dumps(pezzo1, ensure_ascii=False), json.dumps(pezzo2, ensure_ascii=False))).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Content-Length", str(len(corpo)))
        self.end_headers()
        self.wfile.write(corpo)

    def _sessione(self):
        """Idea 58: un ID di sessione stabile per agente (o quello che manda lui)."""
        s = self.headers.get("x-opencode-session")
        if s:
            return s
        ua = self.headers.get("user-agent", "") or "agente"
        return "cervello-" + hashlib.sha1(ua.encode()).hexdigest()[:16]

    def do_GET(self):
        ricarica()
        if self.path.startswith("/portiere") and not self.path.startswith("/portiere.json"):
            b = pagina().encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(b)))
            self.end_headers()
            self.wfile.write(b)
            return
        if self.path.startswith("/portiere.json"):
            capo, sost = classifica()
            self._json({"nome": NOME, "porta": PORTA, "totali": len(BASE),
                        "capo": capo, "sostituti": len(sost),
                        "risponde": [v["id"] for v in appello()
                                     if v.get("esito") == "risponde" and v.get("id") in BASE],
                        "voci": [{"id": k, "nome": ETICHETTE.get(k, k), "tipo": TIPI.get(k, "chat"),
                                  "classe": CLASSI.get(k, ""),
                                  "indirizzo": v[0], "modello": v[1]} for k, v in BASE.items()],
                        "da_confermare": da_confermare()})
            return
        if self.path.startswith("/cervello"):
            su = vivo(MOTORE)
            capo, sost = classifica()
            self._json({"motore": su, "nome": NOME,
                        "capo": capo, "sostituti": [v["nome"] for v in sost],
                        "riserva": [v["id"] for v in appello() if v.get("esito") == "risponde"],
                        "risponde": (len([1 for v in appello() if v.get("esito") == "risponde"])),
                        "adesso": "motore" if su else (capo["nome"] if capo else "nessuna chiave")})
            return
        if self.path.startswith("/v1/models"):
            politiche = [{"id": p, "object": "model", "owned_by": "cervello"}
                         for p in POLITICHE if p != "keyless"]
            d = inoltra(None, "models", secondi=10) if vivo(MOTORE) else None
            if d and isinstance(d.get("data"), list):
                d["data"] = politiche + d["data"]        # idea 6: le politiche in testa
                self._json(d)
                return
            modelli = politiche + [
                {"id": v.get("modello") or BASE.get(v.get("id"), ("", "auto"))[1],
                 "object": "model", "owned_by": "riserva"}
                for v in appello() if v.get("esito") == "risponde" and v.get("id") in BASE]
            self._json({"object": "list", "data": modelli})
            return
        self._json({"errore": "usa /v1/chat/completions oppure /cervello"}, 404)

    def do_POST(self):
        ricarica()                                        # idea 10
        inizio = time.time()
        if self.path.startswith("/v1/images/generations"):
            n = int(self.headers.get("Content-Length") or 0)
            try:
                corpo = json.loads(self.rfile.read(n).decode() or "{}")
            except Exception:
                corpo = {}
            d = immagini((corpo.get("prompt") or "").strip())
            if d:
                self._json(d)
            else:
                self._json({"error": {"message": "Nessuna chiave di immagini in grado di rispondere adesso: "
                                                 "le altre (fal.ai, WaveSpeedAI) hanno un formato loro, "
                                                 "vanno collegate una per una."}}, 503)
            return
        if not self.path.startswith("/v1/chat/completions"):
            self._json({"errore": "solo /v1/chat/completions"}, 404)
            return
        n = int(self.headers.get("Content-Length") or 0)
        try:
            payload = json.loads(self.rfile.read(n).decode() or "{}")
        except Exception:
            self._json({"error": {"message": "corpo non valido"}}, 400)
            return
        vuole_stream = bool(payload.pop("stream", False))
        payload.pop("stream_options", None)
        sess = self._sessione()
        modello_chiesto = (payload.get("model") or "").strip()
        politica = modello_chiesto.lower()
        if politica.startswith("cervello/"):
            politica = politica[len("cervello/"):]

        # idea 21: la guardia solo-gratis ferma i modelli a pagamento sul portone
        if CONFIG["solo_gratis"] and a_pagamento(modello_chiesto):
            logga(tipo="bloccato", agente=sess, modello=modello_chiesto, rotta="guardia")
            self._json({"error": {"message": "Guardia solo-gratis: '%s' sembra un modello "
                                             "a pagamento. Usa 'auto', 'gratis', 'veloce' o "
                                             "'migliore' (regola: costo zero)." % modello_chiesto}}, 403)
            return

        # idea 46: le richieste banali si rispondono in casa
        if CONFIG["intercetta_banali"]:
            d = banale(payload)
            if d:
                logga(tipo="banale", agente=sess, rotta="locale",
                      ms=int((time.time() - inizio) * 1000))
                self._rispondi(d, vuole_stream)
                return

        # idea 6: le politiche diverse da "auto" scelgono direttamente dalla riserva
        if politica in POLITICHE and politica != "auto":
            d, rotta = riserva(payload, politica, sess)
            if d:
                logga(tipo="richiesta", agente=sess, politica=politica, rotta="riserva",
                      **dict(rotta, ms=int((time.time() - inizio) * 1000)))
                self._rispondi(d, vuole_stream)
                return
            logga(tipo="fallita", agente=sess, politica=politica, rotta="riserva")
            self._json({"error": {"message": "Nessun provider della politica '%s' ha risposto. "
                                             "Prova con 'auto'." % politica}}, 503)
            return

        corpo = json.dumps(payload).encode()
        if vivo(MOTORE):
            d = inoltra(corpo, sessione=sess)
            if d:
                logga(tipo="richiesta", agente=sess, politica=politica or "auto",
                      rotta="motore", modello=modello_chiesto or "auto",
                      ms=int((time.time() - inizio) * 1000))
                self._rispondi(d, vuole_stream)
                return
        d, rotta = riserva(payload, "auto", sess)
        if d:
            logga(tipo="richiesta", agente=sess, politica="auto", rotta="riserva",
                  **dict(rotta, ms=int((time.time() - inizio) * 1000)))
            self._rispondi(d, vuole_stream)
            return
        logga(tipo="fallita", agente=sess, politica=politica or "auto", rotta="nessuna")
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
    ora = time.time()
    castigati = [(k, int(v - ora)) for k, v in STATO["castighi"].items() if v > ora]
    if castigati:
        print("In castigo:", ", ".join("%s (%ds)" % c for c in castigati))
    print("Portiere (20129):", "🟢 acceso" if vivo("http://127.0.0.1:%d" % PORTA) else "🔴 spento")


if __name__ == "__main__":
    stato_carica()                                        # idea 20
    if "--stato" in sys.argv:
        stato()
        sys.exit(0)
    if "--sonda" in sys.argv:                             # idea 52
        sonda()
        sys.exit(0)
    if "--perdona" in sys.argv:                           # amnistia: azzera i castighi
        quanti = len(STATO["castighi"])
        STATO["castighi"] = {}
        stato_salva(forza=True)
        print("Perdonati %d castighi. Se il Portiere è acceso, riavvialo per" % quanti)
        print("fargliela leggere (ACCENDI_CERVELLO.bat lo fa in un colpo).")
        sys.exit(0)
    print("Portiere FASE 1 su http://127.0.0.1:%d/v1 — %d chiavi · politiche: %s"
          % (PORTA, len(BASE), ", ".join(p for p in POLITICHE if p != "keyless")))
    appello_da_solo()
    ThreadingHTTPServer(("127.0.0.1", PORTA), H).serve_forever()
