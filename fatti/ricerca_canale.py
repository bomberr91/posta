#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ricerca_canale.py — il canale di ricerca UNICO del sistema: Reddit + GitHub + web.

Come funziona (4/11, dopo il refuso della versione con i segnaposto):
- Reddit   : motore di ricerca (Tavily) filtrato su reddit.com + lettura del
             feed .rss pubblico del post. NESSUNA credenziale Reddit, nessun
             login, nessun scraping di reddit.com (l'API Data non e' stata
             approvata: ticket NNJ0GP-27J47).
- GitHub   : API di ricerca repositories, con la chiave GitHub letta a runtime
             dal portachiavi (chiave_di.py). Senza chiave funziona lo stesso,
             solo con limiti piu' stretti.
- Web      : DuckDuckGo html, senza chiave.

Le chiavi NON sono mai nel codice: si leggono a runtime.
  - Tavily : env TAVILY_API_KEY, altrimenti ~/.tavily/config.json
  - GitHub : chiave_di.py "GitHub (bomberr91)" (portachiavi)

Uso:
  python3 fatti/ricerca_canale.py "<query>" [--max N] [--fonte reddit|github|web|tutte]
                                                 [--leggi N]   # post .rss da leggere (0 = nessuno)
"""
import argparse
import json
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)

try:
    import ricerca_strategica as rs
except Exception as e:                                    # pragma: no cover
    print("Errore: ricerca_strategica.py non trovato in %s (%s)" % (ROOT, e), file=sys.stderr)
    sys.exit(2)


# ---------------------------------------------------------------- chiavi
def chiave_tavily():
    k = os.environ.get("TAVILY_API_KEY", "").strip()
    if k:
        return k
    try:
        p = os.path.expanduser("~/.tavily/config.json")
        return (json.load(open(p, encoding="utf-8")).get("api_key") or "").strip()
    except Exception:
        return ""


def chiave_github():
    """La chiave GitHub si legge dal portachiavi, mai hardcoded."""
    script = os.path.join(ROOT, "chiave_di.py")
    if not os.path.exists(script):
        return ""
    try:
        out = subprocess.run([sys.executable, script, "GitHub (bomberr91)"],
                             capture_output=True, text=True, timeout=25)
        k = (out.stdout or "").strip()
        if k and "nessuna chiave" not in k.lower() and "provider non trovato" not in k.lower():
            return k
    except Exception:
        pass
    return ""


# ---------------------------------------------------------------- fonti
def _tavily(query, max_res, domini=None):
    """Tavily: stessa rotta di ricerca_strategica.cerca_reddit, con o senza filtro domini."""
    chiave = chiave_tavily()
    if not chiave:
        return []
    payload = {"api_key": chiave, "query": query, "max_results": max_res,
               "search_depth": "advanced"}
    if domini:
        payload["include_domains"] = list(domini)
    corpo = json.dumps(payload).encode()
    req = urllib.request.Request("https://api.tavily.com/search", data=corpo, method="POST",
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": "RicercaCanale/1.0"})
    try:
        dati = json.loads(urllib.request.urlopen(req, timeout=30).read().decode("utf-8"))
    except Exception as e:
        print("  [avviso] Tavily non ha risposto: %s" % str(e)[:160], file=sys.stderr)
        return []
    out = []
    for r in dati.get("results", [])[:max_res]:
        titolo = re.sub(r"<[^>]+>", "", r.get("title", "") or "").strip()
        snip = " ".join(re.sub(r"<[^>]+>", "", r.get("content", "") or "").split())[:280]
        out.append({"titolo": titolo, "url": r.get("url", ""), "snippet": snip})
    return out


def _tavily_reddit(query, max_res):
    return _tavily(query, max_res, domini=["reddit.com"])


def _ddg_reddit(query, max_res):
    """Fallback senza chiave: DuckDuckGo html limitato a reddit.com."""
    url = "https://html.duckduckgo.com/html/?q=" + urllib.parse.quote(query + " site:reddit.com")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
    try:
        html = urllib.request.urlopen(req, timeout=20).read().decode("utf-8", errors="ignore")
    except Exception as e:
        print("  [avviso] DuckDuckGo non ha risposto: %s" % str(e)[:160], file=sys.stderr)
        return []
    out = []
    for href, titolo in re.findall(r'<a rel="nofollow" class="result__a" href="([^"]+)">(.*?)</a>', html, re.S)[:max_res]:
        out.append({"titolo": re.sub(r"<[^>]+>", "", titolo).strip(),
                    "url": href, "snippet": ""})
    return out


def cerca_reddit(query, max_res, leggi=1):
    voci = _tavily_reddit(query, max_res)
    fonte = "Tavily + feed .rss pubblico"
    if not voci:
        voci = _ddg_reddit(query, max_res)
        fonte = "DuckDuckGo (senza chiave)"
    for v in voci:
        if leggi and v.get("url"):
            try:
                testo = rs.leggi_reddit(v["url"])
            except Exception as e:
                testo = "[feed .rss non leggibile: %s]" % str(e)[:120]
            v["testo"] = (testo or "")[:1200]
    return voci, fonte


def cerca_github(query, max_res):
    url = ("https://api.github.com/search/repositories?q=" + urllib.parse.quote(query) +
           "&sort=stars&order=desc&per_page=%d" % max_res)
    headers = {"User-Agent": "RicercaCanale/1.0", "Accept": "application/vnd.github+json"}
    k = chiave_github()
    if k:
        headers["Authorization"] = "Bearer " + k
    req = urllib.request.Request(url, headers=headers)
    try:
        dati = json.loads(urllib.request.urlopen(req, timeout=25).read().decode("utf-8"))
    except Exception as e:
        print("  [avviso] GitHub non ha risposto: %s" % str(e)[:160], file=sys.stderr)
        return []
    return [{"titolo": it.get("full_name", ""), "url": it.get("html_url", ""),
             "snippet": "%s★ — %s" % (it.get("stargazers_count", 0), (it.get("description") or "").strip())}
            for it in dati.get("items", [])[:max_res]]


def cerca_web(query, max_res):
    """Web generico: Tavily senza filtro; in assenza di chiave, DuckDuckGo html."""
    voci = _tavily(query, max_res)
    if voci:
        return voci
    txt = rs.cerca_ddg(query, max_res)
    for m in re.finditer(r"-\s*\*\*(.+?)\*\*\s*\((.+?)\)\s*\n\s*(.*)", txt or ""):
        voci.append({"titolo": m.group(1).strip(), "url": m.group(2).strip(),
                     "snippet": " ".join(m.group(3).split())[:280]})
    return voci


# ---------------------------------------------------------------- stampa
def stampa_rete(titolo, voci, con_testo=False):
    print("\n=== %s (%d risultati)" % (titolo, len(voci)))
    if not voci:
        print("  nessun risultato")
        return
    for i, v in enumerate(voci, 1):
        print("%d. %s" % (i, v.get("titolo") or "(senza titolo)"))
        print("   %s" % (v.get("url") or ""))
        if v.get("snippet"):
            print("   %s" % v["snippet"][:280])
        if con_testo and v.get("testo"):
            for riga in str(v["testo"]).splitlines():
                if riga.strip():
                    print("   | %s" % riga.strip()[:280])


def main():
    ap = argparse.ArgumentParser(description="Canale unico di ricerca: Reddit + GitHub + web")
    ap.add_argument("query", nargs="*", help="domanda da cercare")
    ap.add_argument("--max", type=int, default=5, help="risultati per fonte (default 5)")
    ap.add_argument("--fonte", default="tutte", choices=["reddit", "github", "web", "tutte"])
    ap.add_argument("--leggi", type=int, default=1, help="post .rss da leggere (0 = nessuno)")
    args = ap.parse_args()

    query = " ".join(args.query).strip()
    if not query:
        ap.print_help()
        sys.exit(1)

    print("Ricerca su: %s" % query)
    if args.fonte in ("reddit", "tutte"):
        voci, fonte = cerca_reddit(query, args.max, args.leggi)
        stampa_rete("REDDIT — %s" % fonte, voci, con_testo=bool(args.leggi))
    if args.fonte in ("github", "tutte"):
        voci = cerca_github(query, args.max)
        stampa_rete("GITHUB", voci)
    if args.fonte in ("web", "tutte"):
        voci = cerca_web(query, args.max)
        stampa_rete("WEB", voci)
    return 0


if __name__ == "__main__":
    sys.exit(main())
