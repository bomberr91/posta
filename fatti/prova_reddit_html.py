#!/usr/bin/env python3
"""Prova se le pagine Reddit in chiaro si aprono da questo IP (senza credenziali).

Non usa login ne cookie: solo User-Agent descrittivo, come farebbe un lettore
pubblico. Serve a capire se gli agenti possono leggere le discussioni per
intero senza attendere l'approvazione della Data API.
"""
import gzip
import sys
import urllib.error
import urllib.request

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

URL = "https://www.reddit.com/r/LocalLLaMA/comments/1f0xk0q/awesome_free_llm_apis/"

PROBE = [
    ("thread www", URL),
    ("subreddit www", "https://www.reddit.com/r/LLM/"),
    ("subreddit old", "https://old.reddit.com/r/LLM/"),
]


def probe(etichetta, url):
    req = urllib.request.Request(url, headers={
        "User-Agent": UA,
        "Accept": "text/html,application/xhtml+xml",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip",
    })
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            raw = r.read()
            if r.headers.get("Content-Encoding") == "gzip":
                raw = gzip.decompress(raw)
            corpo = raw.decode("utf-8", "replace")
            titolo = ""
            if "<title>" in corpo:
                titolo = corpo.split("<title>", 1)[1].split("</title>", 1)[0].strip()[:90]
            print("%-16s HTTP %s  bytes=%d  titolo=%s"
                  % (etichetta, r.status, len(corpo), titolo or "n/d"))
            print("%-16s segnale 'comment' nel testo: %s"
                  % ("", "SI" if "comment" in corpo.lower() else "NO"))
            return True
    except urllib.error.HTTPError as e:
        print("%-16s HTTP %s  (%s)" % (etichetta, e.code, e.reason))
    except Exception as e:  # noqa: BLE001
        print("%-16s ERRORE %s: %s" % (etichetta, type(e).__name__, str(e)[:100]))
    return False


if __name__ == "__main__":
    if len(sys.argv) > 1:
        PROBE = [("url passata", sys.argv[1])]
    print("--- prova lettura pagine Reddit senza credenziali ---")
    for nome, u in PROBE:
        probe(nome, u)
    print("--- fine ---")
