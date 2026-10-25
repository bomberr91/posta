#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""raccogli.py — raccoglitore di link a parole chiave, con controllo di vitalità.

COSA FA
  1. tu scrivi una o più parole/frasi nel riquadro (una per riga)
  2. lo script fa DIVERSE ricerche per ogni frase (Bing, più pagine, più varianti;
     se Bing non risponde ripiega su DuckDuckGo e sulle notizie)
  3. raccoglie i link, toglie i doppioni (stesso sito/percorso, niente www, niente
     parametri di tracciamento) e limita a quanti ne chiedi tu
  4. controlla quali sono davvero online — con le TRE categorie che contano:
        VIVO      = risponde 200
        BLOCCATO  = 401/403/429/503 → NON è morto, è un sito che non gradisce i robot
        MORTO     = il nome non esiste (DNS), 404/410, o timeout dopo 2 tentativi
  5. scrive i file in Liste/ (vedi sotto) e ti mostra tutto a schermo

FILES
  Liste/ultima.txt            solo i VIVI, un link per riga (il file da usare)
  Liste/ultima_bloccati.txt   i BLOCCATI (da ricontrollare a mano: spesso sono vivi)
  Liste/ultima_morti.txt      i MORTO
  Liste/ultima_report.txt     riepilogo leggibile con i conteggi
  Liste/AAAA-MM-GG_HHMM_*.txt copia datata di ogni giro (per non perdere lo storico)
  cache.json                  esiti recenti (24 h) per non rifare le stesse prove
  visti.json                  i siti già visti nei giri precedenti (opzione «salta i già visti»)

USO
  doppio clic su AVVIA_RACCOGLI_LINK.bat   → finestra
  python raccogli.py --cli "frase uno" "frase due" --max 40
  python raccogli.py --cli "frase" --max 20 --senza-controllo

Note oneste: le ricerche sono «best effort» — Bing/DuckDuckGo possono limitare le
richieste. Se Bing risponde vuoto si aspetta, si riprova una volta e poi si passa
al ripiego sulle notizie; se risponde una pagina che non parla della nostra frase
la si scarta invece di riempire la lista di roba a caso (1.1). Niente chiavi API, niente servizi a pagamento. Solo libreria standard.
"""
import base64
import concurrent.futures as cf
import datetime
import json
import os
import random
import re
import socket
import ssl
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

VERSIONE = "1.1"
BASE = os.path.dirname(os.path.abspath(__file__))
LISTE = os.path.join(BASE, "Liste")
CACHE = os.path.join(BASE, "cache.json")
VISTI = os.path.join(BASE, "visti.json")
PAROLE = os.path.join(BASE, "parole.txt")

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/126.0 Safari/537.36")
INTESTAZIONI = {
    "User-Agent": UA,
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "it-IT,it;q=0.9,en;q=0.7",
}
SSL_APERTO = ssl.create_default_context()
SSL_APERTO.check_hostname = False
SSL_APERTO.verify_mode = ssl.CERT_NONE       # molti siti hanno certificati scaduti

# ── cosa non raccogliere: motori di ricerca, social, accorciatori, file inutili ──
SCARTA_HOST = {
    "bing.com", "google.com", "google.it", "duckduckgo.com", "yahoo.com", "search.yahoo.com",
    "yandex.com", "yandex.ru", "baidu.com", "ecosia.org", "qwant.com", "startpage.com",
    "brave.com", "ask.com", "aol.com", "microsoft.com", "support.microsoft.com",
    "facebook.com", "instagram.com", "twitter.com", "x.com", "tiktok.com", "pinterest.com",
    "linkedin.com", "youtube.com", "youtu.be", "twitch.tv", "t.me", "telegram.me",
    "whatsapp.com", "threads.net", "reddit.com", "quora.com",
    "bit.ly", "tinyurl.com", "t.co", "goo.gl", "ow.ly", "cutt.ly", "is.gd",
    "wordpress.com", "blogspot.com", "googleusercontent.com", "gstatic.com",
    "bing.net", "msn.com", "amazon.com", "ebay.com", "aliexpress.com",
    "w3.org", "schema.org", "creativecommons.org",
}
SCARTA_EST = (".jpg", ".jpeg", ".png", ".gif", ".svg", ".webp", ".ico", ".css", ".js",
              ".woff", ".woff2", ".ttf", ".zip", ".rar", ".7z", ".exe", ".msi",
              ".apk", ".dmg", ".mp3", ".mp4", ".avi", ".mkv", ".torrent")
TRACKING = ("utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
            "fbclid", "gclid", "yclid", "msockid", "ref", "ref_src", "igshid", "spm")

MAX_PER_SITO = 2          # quanti link tenere per ogni singolo sito
PAROLE_VUOTE = {"della", "delle", "degli", "dello", "come", "cosa", "quale", "quali",
                "sono", "essere", "fare", "fatto", "piu", "più", "anche", "senza", "dopo",
                "prima", "molto", "tutto", "tutti", "dove", "quando", "perche", "perché",
                "the", "and", "for", "with", "that", "this", "from", "your", "you", "are"}
BING_KO = {"vuoti": 0, "spento": False}   # Bing a volte fa lo gnorri: dopo 4 vuoti si smette
BLOCCATO_CODICI = (401, 403, 407, 429, 451, 503, 999)
MORTO_CODICI = (404, 410)

# ─────────────────────────── utilità ────────────────────────────────────────


def adesso():
    return datetime.datetime.now()


def leggi_json(percorso, vuoto):
    try:
        with open(percorso, encoding="utf-8") as f:
            d = json.load(f)
            return d if isinstance(d, type(vuoto)) else vuoto
    except Exception:
        return vuoto


def scrivi_json(percorso, dati):
    try:
        tmp = percorso + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(dati, f, ensure_ascii=False, indent=1)
        os.replace(tmp, percorso)
    except Exception:
        pass


def scarica(url, timeout=25):
    """Pagina come testo. Ritorna '' se non si riesce."""
    req = urllib.request.Request(url, headers=INTESTAZIONI)
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=SSL_APERTO) as r:
            return r.read().decode("utf-8", "replace")
    except Exception:
        return ""


def normalizza(url):
    """Stesso sito = stesso link: toglie www, barre finali, #frammenti e parametri
    di tracciamento. Ritorna '' se il link non va tenuto."""
    url = (url or "").strip().strip('"\'')
    if not url.lower().startswith(("http://", "https://")):
        return ""
    try:
        p = urllib.parse.urlsplit(url)
    except Exception:
        return ""
    host = p.netloc.lower()
    if host.startswith("www."):
        host = host[4:]
    if host in SCARTA_HOST or any(host.endswith("." + s) for s in SCARTA_HOST):
        return ""
    percorso = (p.path or "").rstrip("/")
    if percorso.lower().endswith(SCARTA_EST):
        return ""
    pezzi = []
    for k, v in urllib.parse.parse_qsl(p.query, keep_blank_values=True):
        if k.lower() in TRACKING:
            continue
        pezzi.append((k, v))
    query = urllib.parse.urlencode(pezzi) if pezzi else ""
    pulito = "https://" + host + percorso
    if query:
        pulito += "?" + query
    return pulito


def chiave_doppione(url):
    """Per togliere i doppioni basta sito + percorso."""
    p = urllib.parse.urlsplit(url)
    return (p.netloc.lower().replace("www.", ""), (p.path or "").rstrip("/").lower())


# ─────────────────────────── ricerche ───────────────────────────────────────

def decodifica_bing(href):
    """Bing nasconde i risultati: ...&u=a1<base64> → indirizzo vero."""
    href = href.replace("&amp;", "&")
    m = re.search(r"[?&]u=a1([^&]+)", href)
    if not m:
        return ""
    s = urllib.parse.unquote(m.group(1))
    try:
        return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4)).decode("utf-8", "replace")
    except Exception:
        return ""


def parole_chiave(frase):
    """Le parole della frase che contano (per capire se un risultato c'entra)."""
    fuori = []
    for p in re.split(r"[^\wàèéìòùáíóú]+", frase.lower()):
        if len(p) >= 4 and p not in PAROLE_VUOTE:
            fuori.append(p)
    return fuori


def c_entra(url, testo, chiavi):
    """Il risultato parla della nostra frase? Basta una parola chiave."""
    if not chiavi:
        return True
    tutto = (url + " " + re.sub(r"<[^>]+>", " ", testo)).lower()
    return any(k in tutto for k in chiavi)


def cerca_bing(frase, pagina=1, log=None):
    """Una pagina di risultati Bing (10 link)."""
    if BING_KO["spento"]:
        return []
    prima = 1 + max(0, pagina - 1) * 10
    url = ("https://www.bing.com/search?q=" + urllib.parse.quote_plus(frase)
           + "&count=10&first=%d&setlang=it" % prima)
    html = scarica(url)
    if not html:
        return []
    trovati = []
    if 'b_algo' not in html and pagina == 1 and not BING_KO["spento"]:
        if log:
            log("   Bing vuoto, aspetto 3 s e riprovo")
        time.sleep(3)
        html = scarica(url) or html
    for blocco in re.findall(r'<li class="b_algo".*?(?=<li class="b_algo"|</ol>)', html, re.S):
        m = re.search(r'<a[^>]+href="([^"]+)"', blocco)
        if not m:
            continue
        u = decodifica_bing(m.group(1))
        if not u:
            # ripiego: il testo del risultato contiene il sito («esempio.com › pagina»)
            t = re.sub(r"<[^>]+>", " ", blocco)
            mm = re.search(r"\b((?:[\w-]+\.)+[a-z]{2,})(?:\s*[›>]\s*([\w\-/]+))?", t, re.I)
            if not mm:
                continue
            u = "https://" + mm.group(1)
            if mm.group(2):
                u += "/" + mm.group(2)
        trovati.append((u, blocco))

    # pertinenza: Bing a volte risponde con una pagina che non c'entra niente
    chiavi = parole_chiave(frase)
    buoni = [u for u, blocco in trovati if c_entra(u, blocco, chiavi)]
    if trovati and len(buoni) * 2 < len(trovati):
        if log:
            log("   Bing ha risposto una pagina che non c'entra: la salto")
        return []
    trovati = buoni
    if trovati:
        BING_KO["vuoti"] = 0
    else:
        BING_KO["vuoti"] += 1
        if BING_KO["vuoti"] >= 4 and not BING_KO["spento"]:
            BING_KO["spento"] = True
            if log:
                log("   Bing sta rispondendo vuoto: per questo giro uso il ripiego notizie")
    if log:
        log("   Bing pagina %d: %d risultati" % (pagina, len(trovati)))
    return trovati


def cerca_ddg(frase, log=None):
    """Ripiego: DuckDuckGo in versione leggera (a volte risponde 202 e non serve)."""
    urls = ["https://html.duckduckgo.com/html/?q=" + urllib.parse.quote_plus(frase),
            "https://lite.duckduckgo.com/lite/?q=" + urllib.parse.quote_plus(frase)]
    for u in urls:
        html = scarica(u)
        if not html or len(html) < 2000:
            continue
        trovati = []
        for m in re.finditer(r'href="(https?://[^"]+)"', html):
            href = m.group(1).replace("&amp;", "&")
            if "uddg=" in href:
                q = urllib.parse.parse_qs(urllib.parse.urlsplit(href).query)
                if "uddg" in q:
                    href = q["uddg"][0]
            elif "duckduckgo.com" in href:
                continue
            trovati.append(href)
        if trovati:
            if log:
                log("   DuckDuckGo: %d risultati" % len(trovati))
            return trovati
    return []


def cerca_notizie(frase, log=None):
    """Ripiego per le frasi «di attualità»: il feed RSS delle notizie di Bing."""
    url = ("https://www.bing.com/news/search?format=RSS&setlang=it&q="
           + urllib.parse.quote_plus(frase))
    xml = scarica(url)
    if not xml:
        return []
    link = re.findall(r"<link>(.*?)</link>", xml, re.S)[1:]      # il primo è il feed stesso
    trovati = []
    for l in link:
        l = l.strip().replace("&amp;", "&")                       # senza questo il ?url= non si legge
        if "url=" in l:                                          # il sito vero sta in ?url=
            q = urllib.parse.parse_qs(urllib.parse.urlsplit(l).query)
            l = (q.get("url") or [l])[0]
        if l.startswith("http") and "bing.com" not in l:
            trovati.append(l)
    if trovati and log:
        log("   Notizie: %d risultati" % len(trovati))
    return trovati


def varianti(frase, con_anno=True):
    """La stessa frase in più modi: è così che si trovano più risultati."""
    v = [frase]
    if " " in frase:
        v.append('"%s"' % frase)
    if con_anno:
        v.append("%s %d" % (frase, adesso().year))
        v.append("%s %s" % (frase, MESI[adesso().month - 1]))
    return v


MESI = ("gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio",
        "agosto", "settembre", "ottobre", "novembre", "dicembre")


def raccogli(frasi, quanti=40, pagine=2, espandi=True, log=print, per_sito=None):
    """Tutte le ricerche, poi pulizia e doppioni. Ritorna la lista di link unici."""
    BING_KO["vuoti"], BING_KO["spento"] = 0, False
    link = []
    for frase in frasi:
        frase = frase.strip()
        if not frase:
            continue
        query = varianti(frase) if espandi else [frase]
        for q in query:
            log("cerco «%s»" % q)
            presi = []
            for pagina in range(1, max(1, pagine) + 1):
                presi += cerca_bing(q, pagina, log)
                if len(presi) >= 10 * pagine:
                    break
                time.sleep(1.2 + random.random() * 0.8)      # gentili con il motore: meno blocchi
            if not presi:
                log("   Bing niente: provo il ripiego")
                presi = cerca_ddg(q, log)
            if not presi:
                presi = cerca_notizie(q, log)
            link += presi
            if len(link) >= quanti * 8:                      # abbastanza materiale
                break
        if len(link) >= quanti * 8:
            break

    # pulizia + doppioni + al massimo 2 link per sito
    visti, per_host, finale = set(), {}, []
    for u in link:
        n = normalizza(u)
        if not n:
            continue
        k = chiave_doppione(n)
        if k in visti:
            continue
        host = k[0]
        if per_host.get(host, 0) >= (per_sito or MAX_PER_SITO):
            continue
        visti.add(k)
        per_host[host] = per_host.get(host, 0) + 1
        finale.append(n)
        if len(finale) >= quanti:
            break
    return finale


# ─────────────────────────── controllo di vitalità ──────────────────────────

def controlla(url, timeout=12, tentativi=2):
    """VIVO / BLOCCATO / MORTO, col motivo."""
    host = urllib.parse.urlsplit(url).netloc.split(":")[0]
    try:
        socket.getaddrinfo(host, None)
    except Exception:
        return "MORTO", "il nome non esiste (DNS)"
    motivo = ""
    for giro in range(1, tentativi + 1):
        # la seconda volta ci si presenta in modo più «umano»
        h = dict(INTESTAZIONI)
        if giro > 1:
            h["Referer"] = "https://www.google.com/"
            h["Cache-Control"] = "no-cache"
        try:
            req = urllib.request.Request(url, headers=h)
            req.add_header("Range", "bytes=0-4096")   # solo l'inizio: non scaricare tutto
            with urllib.request.urlopen(req, timeout=timeout, context=SSL_APERTO) as r:
                return "VIVO", "risponde %s" % r.status
        except urllib.error.HTTPError as e:
            if e.code in BLOCCATO_CODICI:
                return "BLOCCATO", "il sito risponde %s (non gradisce i robot, NON è morto)" % e.code
            if e.code in MORTO_CODICI:
                return "MORTO", "pagina non trovata (%s)" % e.code
            motivo = "risposta %s" % e.code
        except (socket.timeout, TimeoutError):
            motivo = "non risponde entro %ds" % timeout
        except urllib.error.URLError as e:
            motivo = "connessione fallita (%s)" % (getattr(e, "reason", e).__str__()[:60])
        except Exception as e:
            motivo = type(e).__name__
        if giro < tentativi:
            time.sleep(1.2)
    return "MORTO", motivo


def controlla_tutti(urls, lavoratori=12, usa_cache=True, log=print, avanzamento=None):
    """Controlla in parallelo, con la memoria di 24 ore."""
    cache = leggi_json(CACHE, {}) if usa_cache else {}
    esiti, da_fare = {}, []
    adesso_ts = time.time()
    for u in urls:
        c = cache.get(u) if usa_cache else None
        if c and (adesso_ts - c.get("quando", 0)) < 24 * 3600 and c.get("stato") in ("VIVO", "BLOCCATO", "MORTO"):
            esiti[u] = (c["stato"], c.get("motivo", "") + " · dalla memoria di 24h")
        else:
            da_fare.append(u)
    if esiti:
        log("   %d link già controllati nelle ultime 24 ore: non li rifaccio" % len(esiti))

    fatti = [0]
    def uno(u):
        r = controlla(u)
        fatti[0] += 1
        if avanzamento:
            avanzamento(fatti[0], len(da_fare))
        log("   %-11s %s" % (r[0], u))
        return u, r

    if da_fare:
        with cf.ThreadPoolExecutor(max_workers=max(1, lavoratori)) as ex:
            for u, r in ex.map(uno, da_fare):
                esiti[u] = r
                cache[u] = {"stato": r[0], "motivo": r[1], "quando": time.time()}
    if usa_cache:
        taglia = {k: v for k, v in cache.items() if time.time() - v.get("quando", 0) < 7 * 86400}
        scrivi_json(CACHE, taglia)
    return esiti


# ─────────────────────────── salvataggio ───────────────────────────────────

def salva(esiti, frasi, quanti):
    os.makedirs(LISTE, exist_ok=True)
    vivi = [u for u, (s, _) in esiti.items() if s == "VIVO"]
    bloccati = [u for u, (s, _) in esiti.items() if s == "BLOCCATO"]
    morti = [u for u, (s, _) in esiti.items() if s == "MORTO"]
    quando = adesso()
    timbro = quando.strftime("%Y-%m-%d_%H%M")

    def scrivi(nome, righe):
        p = os.path.join(LISTE, nome)
        with open(p, "w", encoding="utf-8") as f:
            f.write("\n".join(righe).rstrip("\n") + ("\n" if righe else ""))
        return p

    scrivi("ultima.txt", vivi)
    scrivi("ultima_bloccati.txt", ["%s  (%s)" % (u, m) for u, (s, m) in esiti.items() if s == "BLOCCATO"])
    scrivi("ultima_morti.txt", ["%s  (%s)" % (u, m) for u, (s, m) in esiti.items() if s == "MORTO"])
    scrivi("%s_vivi.txt" % timbro, vivi)

    righe = ["RACCOGLITORE DI LINK — %s" % quando.strftime("%d/%m/%Y %H:%M"),
             "",
             "Parole cercate: " + " · ".join(frasi),
             "Link chiesti: %d · raccolti e controllati: %d" % (quanti, len(esiti)),
             "   VIVI       %d" % len(vivi),
             "   BLOCCATI   %d   (401/403/429/503: spesso sono vivi, li guardo io)" % len(bloccati),
             "   MORTI      %d   (nome inesistente, 404, o timeout dopo 2 tentativi)" % len(morti),
             ""]
    if bloccati:
        righe.append("BLOCCATI, da ricontrollare a mano:")
        righe += ["  %s  → %s" % (u, esiti[u][1]) for u in sorted(bloccati)]
        righe.append("")
    if morti:
        righe.append("MORTI:")
        righe += ["  %s  → %s" % (u, esiti[u][1]) for u in sorted(morti)]
        righe.append("")
    scrivi("ultima_report.txt", righe)

    # chi è già passato dai giri precedenti
    visti = leggi_json(VISTI, {})
    for u in esiti:
        visti[chiave_doppione(u)[0]] = quando.strftime("%Y-%m-%d")
    scrivi_json(VISTI, visti)
    return vivi, bloccati, morti


# ──────────────────── modalità lista pronta (--file) ────────────────────────

def leggi_lista(percorso):
    """Tira fuori i link da un file: un link per riga, ma va bene anche con
    numeri davanti, trattini, o righe tipo «1. esempio.com/pagina»."""
    testo = ""
    for codifica in ("utf-8-sig", "utf-8", "latin-1"):
        try:
            with open(percorso, encoding=codifica) as f:
                testo = f.read()
            break
        except UnicodeDecodeError:
            continue
    if not testo:
        return []
    link, visti = [], set()
    for riga in testo.splitlines():
        riga = riga.strip()
        if not riga or riga.startswith("#"):
            continue
        trovati = re.findall(r"https?://[^\s<>\"'|,;]+", riga)
        if not trovati:
            # riga senza http: se sembra un dominio, lo prendo lo stesso
            pezzo = re.split(r"[\s|,;]+", riga.strip("-.–—0123456789) "))[0]
            if re.match(r"^[\w.-]+\.[a-z]{2,}(/.*)?$", pezzo, re.I):
                trovati = ["https://" + pezzo]
        for u in trovati:
            u = u.rstrip('.,;:)"\'')
            n = normalizza(u)
            if not n or n in visti:
                continue
            visti.add(n)
            link.append(n)
    return link


def controlla_lista(percorso, log=print):
    """Controlla i link di un file e scrive i validi. Ritorna (validi, bloccati, morti)."""
    os.makedirs(LISTE, exist_ok=True)
    link = leggi_lista(percorso)
    if not link:
        print("Nel file non ho trovato link: %s" % percorso)
        return [], [], []
    print("Link letti dal file: %d (doppioni già tolti)" % len(link))
    print("\nCONTROLLO...")
    esiti = controlla_tutti(link, log=log)
    vivi = [u for u in link if esiti.get(u, ("", ""))[0] == "VIVO"]
    bloccati = [u for u in link if esiti.get(u, ("", ""))[0] == "BLOCCATO"]
    morti = [u for u in link if esiti.get(u, ("", ""))[0] == "MORTO"]

    def scrivi(nome, righe, con_motivo=None):
        out = []
        for u in righe:
            out.append("%s  (%s)" % (u, esiti[u][1]) if con_motivo else u)
        with open(os.path.join(LISTE, nome), "w", encoding="utf-8") as f:
            f.write("\n".join(out).rstrip("\n") + ("\n" if out else ""))

    # validi.txt = tutti quelli che esistono, nell'ordine del file di partenza.
    # I bloccati restano dentro ma col motivo accanto, così si vede quali sono.
    tenuti = [u for u in link if esiti.get(u, ("", ""))[0] in ("VIVO", "BLOCCATO")]
    righe_validi = []
    for u in tenuti:                       # i vivi riga pulita, i bloccati col motivo accanto
        if esiti[u][0] == "BLOCCATO":
            codice = re.search(r"\b(4\d\d|5\d\d)\b", esiti[u][1])
            nota = ("%s — esiste, blocca i robot" % codice.group(1)) if codice else esiti[u][1]
            righe_validi.append("%s  (%s)" % (u, nota))
        else:
            righe_validi.append(u)
    with open(os.path.join(LISTE, "validi.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(righe_validi).rstrip("\n") + ("\n" if righe_validi else ""))
    scrivi("non_raggiungibili.txt", morti, con_motivo=True)
    scrivi("bloccati.txt", bloccati, con_motivo=True)

    righe = ["LISTA CONTROLLATA — %s" % adesso().strftime("%d/%m/%Y %H:%M"),
             "File di partenza: %s" % os.path.basename(percorso),
             "Link nel file: %d · doppioni tolti in automatico" % len(link),
             "",
             "   VALIDI               %d   rispondono 200" % len(vivi),
             "   BLOCCATI             %d   401/403/429/503: esistono ma rifiutano i robot" % len(bloccati),
             "   NON RAGGIUNGIBILI    %d   nome inesistente, 404/410, o timeout dopo 2 tentativi" % len(morti),
             "",
             "   validi.txt = %d link (validi + bloccati, ognuno col motivo accanto)" % len(tenuti),
             "",
             "File scritti:",
             "   Liste/validi.txt              tutti quelli che esistono, col motivo accanto",
             "                                 ai bloccati (sono tenuti dentro)",
             "   Liste/non_raggiungibili.txt   quelli tolti, col motivo accanto",
             "   Liste/bloccati.txt            solo i bloccati, col motivo accanto",
             ""]
    if bloccati:
        righe.append("BLOCCATI, da guardare col browser:")
        righe += ["  %s  → %s" % (u, esiti[u][1]) for u in bloccati]
        righe.append("")
    if morti:
        righe.append("NON RAGGIUNGIBILI:")
        righe += ["  %s  → %s" % (u, esiti[u][1]) for u in morti]
        righe.append("")
    with open(os.path.join(LISTE, "lista_report.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(righe))

    print("\nFATTO — validi %d (di cui %d bloccati, tenuti dentro) · non raggiungibili %d"
          % (len(tenuti), len(bloccati), len(morti)))
    print("  %s" % os.path.join(LISTE, "validi.txt"))
    print("  %s" % os.path.join(LISTE, "non_raggiungibili.txt"))
    return tenuti, bloccati, morti


def filtra_gia_visti(urls):
    visti = leggi_json(VISTI, {})
    tenuti, saltati = [], 0
    for u in urls:
        if chiave_doppione(u)[0] in visti:
            saltati += 1
            continue
        tenuti.append(u)
    return tenuti, saltati


def apri_cartella():
    try:
        if os.name == "nt":
            os.startfile(LISTE)
        elif sys.platform == "darwin":
            os.system('open "%s"' % LISTE)
        else:
            os.system('xdg-open "%s" 2>/dev/null &' % LISTE)
    except Exception:
        pass


# ─────────────────────────── finestra ──────────────────────────────────────

def finestra():
    import tkinter as tk
    from tkinter import scrolledtext, messagebox

    radice = tk.Tk()
    radice.title("Raccogli link %s" % VERSIONE)
    radice.geometry("900x680")
    radice.minsize(760, 560)

    tk.Label(radice, text="Parole o frasi da cercare (una per riga):",
             anchor="w", font=("Segoe UI", 10, "bold")).pack(fill="x", padx=10, pady=(10, 2))
    testo = tk.Text(radice, height=7, font=("Consolas", 10), wrap="word")
    testo.pack(fill="x", padx=10)
    if os.path.exists(PAROLE):
        try:
            testo.insert("1.0", open(PAROLE, encoding="utf-8").read().strip())
        except Exception:
            pass

    opzioni = tk.Frame(radice)
    opzioni.pack(fill="x", padx=10, pady=(8, 0))
    tk.Label(opzioni, text="Quanti link:").pack(side="left")
    quanti_var = tk.StringVar(value="40")
    tk.Spinbox(opzioni, from_=5, to=200, increment=5, width=5,
               textvariable=quanti_var).pack(side="left", padx=(4, 16))

    espandi_var = tk.BooleanVar(value=True)
    tk.Checkbutton(opzioni, text="più ricerche per frase (virgolette, anno, mese)",
                   variable=espandi_var).pack(side="left")
    opzioni2 = tk.Frame(radice)
    opzioni2.pack(fill="x", padx=10, pady=(2, 6))
    controlla_var = tk.BooleanVar(value=True)
    tk.Checkbutton(opzioni2, text="controlla se sono online",
                   variable=controlla_var).pack(side="left")
    salta_var = tk.BooleanVar(value=False)
    tk.Checkbutton(opzioni2, text="salta i siti già visti nei giri precedenti",
                   variable=salta_var).pack(side="left", padx=(24, 0))

    riga = tk.Frame(radice)
    riga.pack(fill="x", padx=10)
    stato = tk.Label(riga, text="pronto", anchor="w", fg="#555")
    stato.pack(side="left")

    log = scrolledtext.ScrolledText(radice, height=20, font=("Consolas", 9), wrap="word")
    log.pack(fill="both", expand=True, padx=10, pady=(6, 6))

    def scrivi_log(riga_testo):
        log.insert("end", riga_testo + "\n")
        log.see("end")
        radice.update_idletasks()

    def lavora():
        frasi = [r.strip() for r in testo.get("1.0", "end").splitlines() if r.strip()]
        if not frasi:
            messagebox.showinfo("Manca qualcosa", "Scrivi almeno una parola o frase.")
            return
        try:
            quanti = max(1, min(500, int(quanti_var.get())))
        except Exception:
            quanti = 40
        avvia.configure(state="disabled")
        log.delete("1.0", "end")
        stato.configure(text="sto cercando...")
        try:
            inizio = time.time()
            scrivi_log("CERCO. %d frase/i · obiettivo %d link" % (len(frasi), quanti))
            urls = raccogli(frasi, quanti=quanti, espandi=espandi_var.get(), log=scrivi_log)
            scrivi_log("\nRACCOLTI e puliti: %d link unici" % len(urls))
            if not urls:
                scrivi_log("ATTENZIONE: nessun link: il motore di ricerca non ha dato risultati "
                           "(riprova tra un minuto o cambia le parole).")
                stato.configure(text="nessun link trovato")
                return
            if salta_var.get():
                urls, saltati = filtra_gia_visti(urls)
                if saltati:
                    scrivi_log("   %d siti già visti in passato: scartati" % saltati)
            if controlla_var.get():
                scrivi_log("\nCONTROLLO se sono online (%d link)...\n" % len(urls))
                stato.configure(text="controllo i link 0/%d" % len(urls))
                esiti = controlla_tutti(urls, log=scrivi_log,
                                        avanzamento=lambda f, t: stato.configure(
                                            text="controllati %d/%d" % (f, t)))
            else:
                esiti = {u: ("VIVO", "non controllato") for u in urls}
            vivi, bloccati, morti = salva(esiti, frasi, quanti)
            for u in vivi:
                scrivi_log(u)
            scrivi_log("\nFATTO in %d s — vivi %d · bloccati %d · morti %d"
                       % (time.time() - inizio, len(vivi), len(bloccati), len(morti)))
            scrivi_log("Liste/ultima.txt = i vivi, uno per riga")
            scrivi_log("Liste/ultima_report.txt = il riepilogo")
            stato.configure(text="vivi %d · bloccati %d · morti %d" % (len(vivi), len(bloccati), len(morti)))
        except Exception as e:
            scrivi_log("\nERRORE: %s" % e)
            stato.configure(text="errore")
        finally:
            avvia.configure(state="normal")

    avvia = tk.Button(radice, text="CERCA E RACCOGLI", font=("Segoe UI", 11, "bold"),
                      height=2, command=lambda: threading.Thread(target=lavora, daemon=True).start())
    avvia.pack(fill="x", padx=10)
    giu = tk.Frame(radice)
    giu.pack(fill="x", padx=10, pady=8)
    tk.Button(giu, text="Apri la cartella Liste", command=apri_cartella).pack(side="left")
    tk.Label(giu, text="i file sono sempre in posta/raccoglilink/Liste",
             fg="#777").pack(side="left", padx=10)
    radice.mainloop()


# ─────────────────────────── riga di comando ───────────────────────────────

def console(argomenti):
    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass
    import argparse
    p = argparse.ArgumentParser(description="Raccoglitore di link a parole chiave")
    p.add_argument("frasi", nargs="*", help="parole o frasi da cercare")
    p.add_argument("--max", type=int, default=40, help="quanti link (default 40)")
    p.add_argument("--pagine", type=int, default=2, help="pagine di risultati per ricerca")
    p.add_argument("--senza-espansione", action="store_true", help="una sola ricerca per frase")
    p.add_argument("--senza-controllo", action="store_true", help="non controlla se sono online")
    p.add_argument("--salta-visti", action="store_true", help="salta i siti già visti")
    p.add_argument("--file", help="controlla i link di un file .txt invece di cercare")
    p.add_argument("--per-sito", type=int, default=MAX_PER_SITO,
                   help="quanti link tenere per ogni sito (default %d)" % MAX_PER_SITO)
    a = p.parse_args(argomenti)
    if a.file:
        if not os.path.exists(a.file):
            print("Non trovo il file: %s" % a.file)
            return 2
        controlla_lista(a.file)
        return 0
    frasi = a.frasi
    if not frasi and os.path.exists(PAROLE):
        frasi = [r.strip() for r in open(PAROLE, encoding="utf-8").read().splitlines() if r.strip()]
        if frasi:
            print("(nessuna frase scritta: uso parole.txt → %s)" % " · ".join(frasi))
    if not frasi:
        print("Scrivi le parole: python raccogli.py --cli \"frase uno\" \"frase due\" --max 40")
        return 2
    print("CERCO. %d frase/i · obiettivo %d link" % (len(frasi), a.max))
    urls = raccogli(frasi, quanti=a.max, pagine=a.pagine,
                    espandi=not a.senza_espansione, log=print, per_sito=a.per_sito)
    print("\nRACCOLTI: %d link unici" % len(urls))
    if a.salta_visti:
        urls, saltati = filtra_gia_visti(urls)
        print("   già visti, scartati: %d" % saltati)
    if a.senza_controllo:
        esiti = {u: ("VIVO", "non controllato") for u in urls}
    else:
        print("\nCONTROLLO...")
        def _log_console(riga):
            if riga.strip().startswith(("VIVO", "BLOCCATO", "MORTO")):
                print("   " + riga.strip())
            elif "già controllati" in riga:
                print(riga)
        esiti = controlla_tutti(urls, log=_log_console)
    vivi, bloccati, morti = salva(esiti, frasi, a.max)
    print("\nvivi %d · bloccati %d · morti %d" % (len(vivi), len(bloccati), len(morti)))
    print("%s" % os.path.join(LISTE, "ultima.txt"))
    for u in vivi:
        print("   " + u)
    return 0


if __name__ == "__main__":
    argomenti = sys.argv[1:]
    if argomenti and argomenti[0] == "--cli":
        sys.exit(console(argomenti[1:]))
    if argomenti and argomenti[0].startswith("-"):
        sys.exit(console(argomenti))          # python raccogli.py --file lista.txt
    try:
        finestra()
    except Exception as e:
        print("Finestra non disponibile (%s): passo alla riga di comando." % e)
        sys.exit(console(argomenti))
