#!/usr/bin/env python3
"""Lettore di discussioni Reddit pubbliche, SENZA credenziali.

Perche' esiste: la Data API di Reddit richiede approvazione (ticket in attesa),
ma le pagine pubbliche si possono leggere normalmente dal PC (IP residenziale).
Il canale che funziona oggi e' questo; quando arriva l'approvazione si puo'
passare al client OAuth ufficiale (reddit_search.py nel repo pubblico).

Niente login, niente cookie, niente account: solo pagine pubbliche, con un
User-Agent descrittivo, a 1 richiesta al secondo con back-off sul 429.

Uso:
  python3 ~/posta/fatti/reddit_leggi.py --q "free llm api" --max 5
  python3 ~/posta/fatti/reddit_leggi.py --url "https://old.reddit.com/r/X/comments/..."
  python3 ~/posta/fatti/reddit_leggi.py --q "..." --max 3 --out ~/reddit_due.txt
  python3 ~/posta/fatti/reddit_leggi.py --file /tmp/pagina.html      (prova offline)
"""
import argparse
import gzip
import html as htmllib
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

PAUSA = 1.5          # secondi fra una richiesta e l'altra
TIMEOUT = 25
MAX_CARATTERI = 4000  # per commento


def spiega_403():
    return ("HTTP 403: Reddit ha bloccato questo IP (WAF). Da un IP residenziale "
            "come il PC normalmente va; se arrivi qui, prova dal PC e non dal sandbox.")


def scarica(url, tentativi=3):
    """Scarica una pagina e restituisce (html, url_effettivo)."""
    for i in range(tentativi):
        req = urllib.request.Request(url, headers={
            "User-Agent": UA,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
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
                attesa = 5 * (i + 1)
                print("[back-off] 429, riprovo fra %ds" % attesa, file=sys.stderr)
                time.sleep(attesa)
                continue
            if e.code == 403:
                raise RuntimeError(spiega_403())
            if e.code in (503, 502, 500) and i < tentativi - 1:
                time.sleep(3)
                continue
            raise RuntimeError("HTTP %s (%s)" % (e.code, e.reason))
        except Exception as e:  # noqa: BLE001
            if i < tentativi - 1:
                time.sleep(3)
                continue
            raise RuntimeError("%s: %s" % (type(e).__name__, str(e)[:120]))
    raise RuntimeError("nessuna risposta")


class RedditParser(HTMLParser):
    """Estrae: titoli/link, blocchi di testo (post + commenti) e autori."""

    SKIP = ("script", "style", "noscript", "svg", "head")

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.titoli = []        # (href, testo)
        self.blocchi = []       # (autore, testo) post prima, poi commenti
        self._autore = None
        self._cattura = None    # None | 'md' | 'author' | 'title'
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
            elif "search-link" in cls or "search-title" in cls:
                self._cattura = "title"
                self._buffer = []
                self._buf_link = d.get("href")
            elif "title" in cls and "may-blank" in cls:
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
            elif self._cattura == "title" and testo:
                if self._buf_link:
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
    return href


def cerca(query, max_risultati=5, sott=""):
    q = urllib.parse.quote_plus(query)
    if sott:
        url = "https://old.reddit.com/r/%s/search?q=%s&sort=relevance&t=all" % (
            urllib.parse.quote(sott), q)
    else:
        url = "https://old.reddit.com/search?q=%s&sort=relevance&t=all" % q
    testo, _ = scarica(url)
    p = RedditParser()
    p.feed(testo)
    risultati = []
    for href, titolo in p.titoli:
        u = normalizza(href)
        if "/comments/" not in u:
            continue
        if any(u == r[0] for r in risultati):
            continue
        risultati.append((u, titolo))
        if len(risultati) >= max_risultati:
            break
    if not risultati:
        # riprova con l'URL "r/all" (a volte /search non restituisce risultati)
        try:
            testo2, _ = scarica("https://old.reddit.com/r/all/search?q=%s&sort=relevance&t=all" % q)
            p2 = RedditParser()
            p2.feed(testo2)
            for href, titolo in p2.titoli:
                u = normalizza(href)
                if "/comments/" in u and not any(u == r[0] for r in risultati):
                    risultati.append((u, titolo))
                if len(risultati) >= max_risultati:
                    break
        except RuntimeError:
            pass
    if not risultati:
        # fallback: link grezzi che contengono /comments/
        for m in re.finditer(r'href="(https?://[^"]*?/comments/[^"]+)"', testo):
            u = htmllib.unescape(m.group(1))
            if not any(u == r[0] for r in risultati):
                risultati.append((u, ""))
            if len(risultati) >= max_risultati:
                break
    return risultati


def leggi(url):
    testo, effettivo = scarica(url)
    p = RedditParser()
    p.feed(testo)
    titolo_pagina = ""
    m = re.search(r"<title>(.*?)</title>", testo, re.S | re.I)
    if m:
        titolo_pagina = " ".join(htmllib.unescape(m.group(1)).split())
    out = []
    out.append("URL: %s" % effettivo)
    if titolo_pagina:
        out.append("PAGINA: %s" % titolo_pagina)
    if p.titoli:
        out.append("TITOLO: %s" % p.titoli[0][1])
    blocchi = p.blocchi
    if blocchi:
        autore, corpo = blocchi[0]
        out.append("")
        out.append("--- POST ---")
        out.append(corpo[:MAX_CARATTERI])
        if len(blocchi) > 1:
            out.append("")
            out.append("--- COMMENTI (%d) ---" % (len(blocchi) - 1))
            for i, (a, t) in enumerate(blocchi[1:], 1):
                t = t[:MAX_CARATTERI]
                out.append("[%d] %s: %s" % (i, a or "?", t))
    else:
        out.append("(nessun testo estratto: la pagina potrebbe essere la versione JS)")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--q", help="domanda di ricerca")
    ap.add_argument("--url", help="link diretto a una discussione")
    ap.add_argument("--file", help="legge un HTML locale invece di scaricare")
    ap.add_argument("--sub", help="cerca dentro un subreddit specifico")
    ap.add_argument("--max", type=int, default=5, help="quante discussioni (default 5)")
    ap.add_argument("--commenti", action="store_true",
                    help="leggi anche i commenti delle discussioni trovate")
    ap.add_argument("--out", help="salva il testo su file")
    args = ap.parse_args()

    testo_out = []

    if args.file:
        testo = open(args.file, encoding="utf-8", errors="replace").read()
        p = RedditParser()
        p.feed(testo)
        for a, t in p.blocchi:
            testo_out.append("[%s] %s" % (a or "?", t[:MAX_CARATTERI]))
    elif args.url:
        testo_out.append(leggi(args.url))
    elif args.q:
        risultati = cerca(args.q, args.max, args.sub)
        if not risultati:
            print("nessun risultato (o pagina bloccata)")
            return 1
        testo_out.append("RISULTATI per: %s" % args.q)
        for i, (u, t) in enumerate(risultati, 1):
            testo_out.append("%d. %s" % (i, t or "(senza titolo)"))
            testo_out.append("   %s" % u)
        if args.commenti:
            for u, t in risultati:
                testo_out.append("")
                try:
                    testo_out.append(leggi(u))
                except RuntimeError as e:
                    testo_out.append("(lettura fallita: %s)" % e)
                time.sleep(PAUSA)
    else:
        ap.print_help()
        return 2

    testo = "\n".join(testo_out)
    print(testo)
    if args.out:
        with open(os.path.expanduser(args.out), "w", encoding="utf-8") as f:
            f.write(testo)
        print("\n[salvato in %s]" % os.path.expanduser(args.out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
