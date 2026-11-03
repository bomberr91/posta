#!/usr/bin/env python3
"""Lettore di discussioni Reddit pubbliche, SENZA credenziali.

Come funziona (misurato il 3/11):
- le pagine HTML di Reddit chiedono il login (redirect a /login) e il WAF blocca
  i datacenter: NON usabili;
- i FEED .rss invece rispondono 200 anche da IP cloud, senza login, e contengono
  il post completo + tutti i commenti con l'autore.
Quindi: niente password, niente account bot, niente cookie.

Canali di scoperta (in ordine):
1. Tavily (se la chiave c'e'): cerca discussioni su reddit.com;
2. ricerca Reddit via .rss (se il WAF lo permette);
3. feed .rss dei subreddit (nuovi/top) filtrati per parole chiave;
4. listing old.reddit.com in HTML (funziona dal PC, non sempre dal sandbox).

Uso:
  python3 ~/posta/fatti/reddit_leggi.py --q "free llm api" --max 5
  python3 ~/posta/fatti/reddit_leggi.py --q "..." --max 3 --commenti
  python3 ~/posta/fatti/reddit_leggi.py --url "https://www.reddit.com/r/X/comments/..."
  python3 ~/posta/fatti/reddit_leggi.py --urls "url1,url2"
  python3 ~/posta/fatti/reddit_leggi.py --urls-file ~/link.txt
  python3 ~/posta/fatti/reddit_leggi.py --file /tmp/pagina.html      (prova offline)
"""
import argparse
import gzip
import html as htmllib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

PAUSA = 6.0            # secondi fra una richiesta e l'altra (logged-out: piano)
TIMEOUT = 30
MAX_CARATTERI = 4000   # per blocco di testo
MAX_ENTRATE = 40       # voci massime per feed

SUBS_PREDEFINITI = ["LLM", "LocalLLaMA", "GeminiAI", "ClaudeAI",
                    "openclaw", "MachineLearning", "ChatGPTCoding"]


def spiega_403():
    return ("HTTP 403: Reddit ha bloccato questo IP. I feed .rss di solito passano "
            "anche dai datacenter; se fallisce, prova dal PC (IP residenziale).")


def scarica(url, tentativi=4):
    """Scarica una pagina/feed e restituisce (testo, url_effettivo)."""
    for i in range(tentativi):
        req = urllib.request.Request(url, headers={
            "User-Agent": UA,
            "Accept": "application/atom+xml,application/xml,text/html,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip",
        })
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
                raw = r.read()
                if r.headers.get("Content-Encoding") == "gzip":
                    raw = gzip.decompress(raw)
                return raw.decode("utf-8", "replace"), r.geturl()
        except urllib.error.HTTPError as e:
            if e.code == 429:
                attesa = 20 * (i + 1)
                print("[back-off] 429, riprovo fra %ds" % attesa, file=sys.stderr)
                time.sleep(attesa)
                continue
            if e.code == 403:
                raise RuntimeError(spiega_403())
            if e.code in (500, 502, 503) and i < tentativi - 1:
                time.sleep(5)
                continue
            raise RuntimeError("HTTP %s (%s)" % (e.code, e.reason))
        except Exception as e:  # noqa: BLE001
            if i < tentativi - 1:
                time.sleep(5)
                continue
            raise RuntimeError("%s: %s" % (type(e).__name__, str(e)[:120]))
    raise RuntimeError("nessuna risposta")


def chiave_tavily():
    for k in ("TAVILY_API_KEY", "TVLY_API_KEY"):
        v = os.environ.get(k)
        if v:
            return v.strip()
    try:
        d = json.load(open(os.path.expanduser("~/.tavily/config.json"), encoding="utf-8"))
        v = d.get("api_key") or d.get("apiKey") or d.get("key")
        if v:
            return str(v).strip()
    except Exception:  # noqa: BLE001
        pass
    return None


# ----------------------------------------------------------------- testo

class TestoParser(HTMLParser):
    """HTML -> testo semplice, con a capo sui blocchi."""

    BLOCCHI = ("p", "div", "br", "li", "tr", "h1", "h2", "h3", "blockquote")
    SKIP = ("script", "style", "noscript", "svg")

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.pezzi = []
        self._skip = 0

    def handle_starttag(self, tag, attrs):
        if tag in self.SKIP:
            self._skip += 1
            return
        if not self._skip and tag in self.BLOCCHI:
            self.pezzi.append("\n")

    def handle_endtag(self, tag):
        if tag in self.SKIP:
            if self._skip:
                self._skip -= 1
            return
        if not self._skip and tag in self.BLOCCHI:
            self.pezzi.append("\n")

    def handle_data(self, data):
        if not self._skip:
            self.pezzi.append(data)

    def testo(self):
        s = "".join(self.pezzi)
        s = re.sub(r"[ \t]+", " ", s)
        s = re.sub(r"\n\s*\n+", "\n", s)
        return s.strip()


def html_a_testo(s):
    p = TestoParser()
    try:
        p.feed(s or "")
    except Exception:  # noqa: BLE001
        return re.sub(r"<[^>]+>", " ", s or "")
    return p.testo()


# ----------------------------------------------------------------- parser HTML

class RedditParser(HTMLParser):
    """Estrae da old.reddit.com: titoli/link, blocchi di testo, autori."""

    SKIP = ("script", "style", "noscript", "svg", "head")

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.titoli = []        # (href, testo)
        self.blocchi = []       # (autore, testo) post prima, poi commenti
        self._autore = None
        self._cattura = None
        self._buffer = []
        self._buf_link = None
        self._skip = 0

    def handle_starttag(self, tag, attrs):
        d = dict(attrs)
        cls = (d.get("class") or "").lower()
        if tag in self.SKIP:
            self._skip += 1
            return
        if self._skip:
            return
        if tag == "a":
            if "author" in cls:
                self._cattura = "author"
                self._buffer = []
            elif ("search-link" in cls or "search-title" in cls
                  or ("title" in cls and "may-blank" in cls)):
                self._cattura = "title"
                self._buffer = []
                self._buf_link = d.get("href")
        elif tag == "div" and "md" in cls.split():
            self._cattura = "md"
            self._buffer = []

    def handle_endtag(self, tag):
        if tag in self.SKIP:
            if self._skip:
                self._skip -= 1
            return
        if self._skip:
            return
        testo = " ".join("".join(self._buffer).split())
        if tag == "a" and self._cattura in ("author", "title"):
            if self._cattura == "author" and testo:
                self._autore = testo
            elif self._cattura == "title" and testo and self._buf_link:
                self.titoli.append((self._buf_link, testo))
            self._cattura = None
            self._buffer = []
            self._buf_link = None
        elif tag == "div" and self._cattura == "md":
            if testo:
                self.blocchi.append((self._autore, testo))
            self._cattura = None
            self._buffer = []

    def handle_data(self, data):
        if self._cattura and not self._skip:
            if self._buffer and not self._buffer[-1].endswith((" ", "\n")) \
                    and not data.startswith((" ", "\n")):
                self._buffer.append(" ")
            self._buffer.append(data)


def normalizza(href):
    if not href:
        return ""
    if href.startswith("//"):
        return "https:" + href
    if href.startswith("/"):
        return "https://old.reddit.com" + href
    return href


def in_old(url):
    return url.replace("https://www.reddit.com", "https://old.reddit.com")


def url_rss(url):
    """Link di discussione -> feed Atom .rss."""
    u = re.sub(r"\?.*$", "", url.strip()).rstrip("/")
    u = u.replace("https://old.reddit.com", "https://www.reddit.com")
    if u.endswith(".rss"):
        return u
    return u + "/.rss"


# ----------------------------------------------------------------- feed Atom

def parse_feed(xml):
    """Restituisce [(autore, titolo, testo), ...] dal feed Atom di Reddit."""
    voci = []
    for e in re.findall(r"<entry>(.*?)</entry>", xml, re.S)[:MAX_ENTRATE]:
        m = re.search(r"<title[^>]*>(.*?)</title>", e, re.S)
        titolo = html_a_testo(htmllib.unescape(m.group(1))) if m else ""
        m = re.search(r"<name>(.*?)</name>", e, re.S)
        autore = htmllib.unescape(m.group(1)).strip() if m else "?"
        m = re.search(r"<content[^>]*>(.*?)</content>", e, re.S)
        testo = html_a_testo(htmllib.unescape(m.group(1))) if m else ""
        voci.append((autore, titolo, testo))
    return voci


def leggi_rss(url):
    xml, effettivo = scarica(url_rss(url))
    voci = parse_feed(xml)
    out = ["URL: %s" % effettivo]
    if not voci:
        out.append("(feed vuoto: nessuna voce)")
        return "\n".join(out)
    out.append("TITOLO: %s" % voci[0][1])
    out.append("")
    out.append("--- POST ---")
    out.append(voci[0][2][:MAX_CARATTERI])
    if len(voci) > 1:
        out.append("")
        out.append("--- COMMENTI (%d) ---" % (len(voci) - 1))
        for i, (a, t, c) in enumerate(voci[1:], 1):
            out.append("[%d] %s: %s" % (i, a or "?", c[:MAX_CARATTERI]))
    return "\n".join(out)


# ----------------------------------------------------------------- ricerca

def cerca_tavily(query, max_risultati=5):
    chiave = chiave_tavily()
    if not chiave:
        return None
    corpo = json.dumps({
        "query": query,
        "include_domains": ["reddit.com"],
        "max_results": max(max_risultati * 2, 5),
        "search_depth": "advanced",
    }).encode("utf-8")
    req = urllib.request.Request(
        "https://api.tavily.com/search", data=corpo,
        headers={"Authorization": "Bearer " + chiave,
                 "Content-Type": "application/json",
                 "User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=40) as r:
            d = json.loads(r.read().decode("utf-8", "replace"))
    except Exception as e:  # noqa: BLE001
        print("[tavily] fallita: %s" % str(e)[:100], file=sys.stderr)
        return None
    out = []
    for r in d.get("results", []) or []:
        u = r.get("url") or ""
        if "/comments/" not in u:
            continue
        out.append((u, (r.get("title") or "").strip()))
        if len(out) >= max_risultati:
            break
    return out


def cerca_rss(query, max_risultati=5, sub=None):
    """Ricerca nativa di Reddit via feed .rss (se il WAF la lascia passare)."""
    q = urllib.parse.quote_plus(query)
    if sub:
        url = ("https://www.reddit.com/r/%s/search.rss?q=%s&restrict_sr=on"
               "&sort=relevance&t=all" % (urllib.parse.quote(sub), q))
    else:
        url = "https://www.reddit.com/search.rss?q=%s&sort=relevance&t=all" % q
    try:
        xml, _ = scarica(url)
    except RuntimeError:
        return []
    out = []
    for e in re.findall(r"<entry>(.*?)</entry>", xml, re.S)[:MAX_ENTRATE]:
        m = re.search(r"<title[^>]*>(.*?)</title>", e, re.S)
        titolo = html_a_testo(htmllib.unescape(m.group(1))) if m else ""
        m = re.search(r'<link[^>]*href="([^"]+)"', e)
        u = htmllib.unescape(m.group(1)) if m else ""
        if "/comments/" in u:
            out.append((u, titolo))
        if len(out) >= max_risultati:
            break
    return out


def cerca_feed_subreddit(query, max_risultati=5, subs=None):
    """Feed .rss dei subreddit (nuovi / top del mese), filtrati per parole."""
    parole = [p for p in re.split(r"\W+", query.lower()) if len(p) > 2]
    subs = subs or SUBS_PREDEFINITI
    trovati = []
    for sub in subs:
        for feed in ("new", "top?t=month"):
            url = "https://www.reddit.com/r/%s/%s/.rss" % (urllib.parse.quote(sub), feed)
            try:
                xml, _ = scarica(url)
            except RuntimeError as e:
                print("[%s] feed non disponibile: %s" % (sub, str(e)[:60]), file=sys.stderr)
                break
            for autore, titolo, testo in parse_feed(xml):
                t = titolo.lower()
                if parole and not any(w in t for w in parole):
                    continue
                m = re.search(r"(https?://www\.reddit\.com/r/[^\s]+/comments/[^\s]+)", xml)
                trovati.append((titolo, sub, autore))
                if len(trovati) >= max_risultati:
                    return [(u, t) for t, _, u in trovati][:max_risultati]
            time.sleep(PAUSA)
    return []


def cerca_subreddit_html(query, max_risultati=5, subs=None):
    """Listing old.reddit.com in HTML (funziona dal PC, non sempre dal sandbox)."""
    parole = [p for p in re.split(r"\W+", query.lower()) if len(p) > 2]
    subs = subs or SUBS_PREDEFINITI
    trovati = []
    for sub in subs:
        for pagina in ("new", "top?t=month"):
            url = "https://old.reddit.com/r/%s/%s/" % (urllib.parse.quote(sub), pagina)
            try:
                testo, _ = scarica(url)
            except RuntimeError as e:
                print("[%s] listing non leggibile: %s" % (sub, str(e)[:60]), file=sys.stderr)
                break
            p = RedditParser()
            p.feed(testo)
            for href, titolo in p.titoli:
                u = normalizza(href)
                if "/comments/" not in u:
                    continue
                t = titolo.lower()
                if parole and not any(w in t for w in parole):
                    continue
                if not any(u == x[0] for x in trovati):
                    trovati.append((u, titolo))
                if len(trovati) >= max_risultati:
                    return trovati
            time.sleep(PAUSA)
    return trovati


def cerca_old_html(query, max_risultati=5):
    q = urllib.parse.quote_plus(query)
    for url in ("https://old.reddit.com/search?q=%s&sort=relevance&t=all" % q,
                "https://old.reddit.com/r/all/search?q=%s&sort=relevance&t=all" % q):
        try:
            testo, _ = scarica(url)
        except RuntimeError:
            continue
        p = RedditParser()
        p.feed(testo)
        out = []
        for href, titolo in p.titoli:
            u = normalizza(href)
            if "/comments/" in u and not any(u == x[0] for x in out):
                out.append((u, titolo))
            if len(out) >= max_risultati:
                return out
        for m in re.finditer(r'href="(https?://[^"]*?/comments/[^"]+)"', testo):
            u = htmllib.unescape(m.group(1))
            if not any(u == x[0] for x in out):
                out.append((u, ""))
            if len(out) >= max_risultati:
                return out
    return []


# ----------------------------------------------------------------- lettura

def leggi(url):
    """Prima prova il feed .rss (pieno), poi il HTML old.reddit.com."""
    try:
        return leggi_rss(url)
    except RuntimeError as e:
        print("[rss non disponibile: %s -> provo HTML]" % str(e)[:70], file=sys.stderr)
    testo, effettivo = scarica(in_old(url))
    p = RedditParser()
    p.feed(testo)
    out = ["URL: %s" % effettivo]
    m = re.search(r"<title>(.*?)</title>", testo, re.S | re.I)
    if m:
        out.append("PAGINA: %s" % " ".join(htmllib.unescape(m.group(1)).split()))
    if p.titoli:
        out.append("TITOLO: %s" % p.titoli[0][1])
    if p.blocchi:
        out.append("")
        out.append("--- POST ---")
        out.append(p.blocchi[0][1][:MAX_CARATTERI])
        if len(p.blocchi) > 1:
            out.append("")
            out.append("--- COMMENTI (%d) ---" % (len(p.blocchi) - 1))
            for i, (a, t) in enumerate(p.blocchi[1:], 1):
                out.append("[%d] %s: %s" % (i, a or "?", t[:MAX_CARATTERI]))
    else:
        out.append("(nessun testo estratto)")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--q", help="domanda di ricerca")
    ap.add_argument("--url", help="link diretto a una discussione")
    ap.add_argument("--urls", help="lista di link separati da virgola")
    ap.add_argument("--urls-file", help="file con un link per riga")
    ap.add_argument("--file", help="legge un HTML locale invece di scaricare")
    ap.add_argument("--sub", help="subreddit da scansionare (comma separati)")
    ap.add_argument("--max", type=int, default=5, help="quante discussioni (default 5)")
    ap.add_argument("--commenti", action="store_true", help="leggi i commenti")
    ap.add_argument("--out", help="salva il testo su file")
    ap.add_argument("--no-tavily", action="store_true", help="salta Tavily")
    ap.add_argument("--max-righe", type=int, default=0, help="taglia l'output a N righe")
    ap.add_argument("--pausa", type=float, default=0,
                    help="secondi fra una richiesta e l'altra (default 6)")
    args = ap.parse_args()

    global PAUSA
    if args.pausa > 0:
        PAUSA = args.pausa

    testo_out = []
    link_da_leggere = []

    if args.file:
        t = open(args.file, encoding="utf-8", errors="replace").read()
        p = RedditParser()
        p.feed(t)
        for a, corpo in p.blocchi:
            testo_out.append("[%s] %s" % (a or "?", corpo[:MAX_CARATTERI]))
    else:
        if args.url:
            link_da_leggere.append(args.url)
        if args.urls:
            link_da_leggere += [u.strip() for u in args.urls.split(",") if u.strip()]
        if args.urls_file:
            link_da_leggere += [l.strip() for l in
                                open(os.path.expanduser(args.urls_file), encoding="utf-8")
                                if l.strip()]

        if args.q:
            subs = [s.strip() for s in args.sub.split(",")] if args.sub else None
            risultati = None
            if not args.no_tavily:
                risultati = cerca_tavily(args.q, args.max)
                if risultati:
                    testo_out.append("[ricerca: Tavily]")
            if not risultati:
                risultati = cerca_rss(args.q, args.max, subs[0] if subs else None)
                if risultati:
                    testo_out.append("[ricerca: feed .rss di Reddit]")
            if not risultati:
                risultati = cerca_subreddit_html(args.q, args.max, subs)
                if risultati:
                    testo_out.append("[ricerca: listing old.reddit.com]")
            if not risultati:
                risultati = cerca_old_html(args.q, args.max)
                if risultati:
                    testo_out.append("[ricerca: ricerca HTML old.reddit.com]")
            if not risultati:
                print("nessun risultato (WAF o nessuna corrispondenza)")
                return 1
            testo_out.append("RISULTATI per: %s" % args.q)
            for i, (u, t) in enumerate(risultati, 1):
                testo_out.append("%d. %s" % (i, t or "(senza titolo)"))
                testo_out.append("   %s" % u)
            if args.commenti:
                link_da_leggere += [u for u, _ in risultati]

        for u in link_da_leggere:
            testo_out.append("")
            try:
                testo_out.append(leggi(u))
            except RuntimeError as e:
                testo_out.append("(lettura fallita: %s)" % e)
            time.sleep(PAUSA)

    testo = "\n".join(testo_out)
    if args.max_righe and args.max_righe > 0:
        righe = testo.splitlines()
        if len(righe) > args.max_righe:
            testo = ("\n".join(righe[:args.max_righe])
                     + "\n[...tagliato a %d righe]" % args.max_righe)
    print(testo)
    if args.out:
        with open(os.path.expanduser(args.out), "w", encoding="utf-8") as f:
            f.write(testo)
        print("\n[salvato in %s]" % os.path.expanduser(args.out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
