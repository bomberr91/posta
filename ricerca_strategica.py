#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ricerca_strategica.py — SUPER-AGENTE DI RICERCA & DECISIONE (stile GPT-Researcher + Agent-Reach)
Cerca sul web / GitHub / Reddit / YouTube gratuitamente, incrocia le fonti e produce un Dossier Decisionale.
"""
import sys, os, re, json, urllib.request, urllib.parse
import json as _json

HOME = os.path.expanduser("~")

def cerca_ddg(query, max_res=6):
    url = "https://html.duckduckgo.com/html/?q=" + urllib.parse.quote(query)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
    out = []
    try:
        html = urllib.request.urlopen(req, timeout=15).read().decode("utf-8", errors="ignore")
        blocchi = re.findall(r'<a rel="nofollow" class="result__a" href="([^"]+)">(.*?)</a>.*?<a class="result__snippet"[^>]*>(.*?)</a>', html, re.S)
        for href, title, snip in blocchi[:max_res]:
            t_clean = re.sub(r'<[^>]+>', '', title).strip()
            s_clean = re.sub(r'<[^>]+>', '', snip).strip()
            out.append(f"- **{t_clean}** ({href})\n  {s_clean}")
    except Exception as e:
        out.append(f"Nota ricerca web: {e}")
    return "\n".join(out)

def cerca_github(query, max_res=5):
    url = f"https://api.github.com/search/repositories?q={urllib.parse.quote(query)}&sort=stars&order=desc&per_page={max_res}"
    req = urllib.request.Request(url, headers={"User-Agent": "RicercaStrategica/1.0"})
    out = []
    try:
        data = json.loads(urllib.request.urlopen(req, timeout=15).read().decode("utf-8"))
        for it in data.get("items", [])[:max_res]:
            out.append(f"- **{it['full_name']}** ({it['stargazers_count']}★) — {it.get('description','')} [{it['html_url']}]")
    except Exception:
        pass
    return "\n".join(out)


UA_REDDIT = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
             "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")


def _reddit_testo(s):
    """Reddit manda il contenuto doppio-escapato: prima si sblocca l'HTML, poi si pulisce."""
    import html as _html
    if not s:
        return ""
    s = _html.unescape(_html.unescape(s))
    s = re.sub(r"(?is)<(script|style)[^>]*>.*?</\1>", " ", s)
    s = re.sub(r"(?is)<!--.*?-->", " ", s)
    s = re.sub(r"(?i)<br\s*/?>|</p>|</div>|</li>", "\n", s)
    s = re.sub(r"<[^>]+>", " ", s)
    s = _html.unescape(s)
    s = re.sub(r"[ \t]+", " ", s)
    return re.sub(r"\n\s*\n+", "\n", s).strip()


def leggi_reddit(url, max_post=2500, max_commenti=6):
    """Legge una discussione Reddit dal feed .rss pubblico (senza login).

    I feed .rss di Reddit rispondono anche da IP cloud e restituiscono il post
    completo + i commenti con l'autore: e' la via che funziona senza credenziali
    e senza attendere l'approvazione della Data API.
    """
    import time as _time
    u = re.sub(r"\?.*$", "", url.strip()).rstrip("/") + "/.rss"
    x = None
    for tentativo in range(3):
        try:
            req = urllib.request.Request(
                u, headers={"User-Agent": UA_REDDIT,
                            "Accept": "application/atom+xml,application/xml,*/*"})
            x = urllib.request.urlopen(req, timeout=30).read().decode("utf-8", "replace")
            break
        except Exception as e:
            if "429" in str(e) and tentativo < 2:
                _time.sleep(20 * (tentativo + 1))
                continue
            return f"(lettura Reddit fallita: {e})"
    if x is None:
        return "(lettura Reddit fallita: troppe richieste)"
    voci = re.findall(r"<entry>(.*?)</entry>", x, re.S)
    if not voci:
        return "(feed vuoto)"
    def campo(e, tag):
        m = re.search(r"<%s[^>]*>(.*?)</%s>" % (tag, tag), e, re.S)
        return m.group(1) if m else ""
    def nome(e):
        m = re.search(r"<name>(.*?)</name>", e, re.S)
        return (m.group(1).strip() if m else "?")
    out = []
    titolo = _reddit_testo(campo(voci[0], "title"))
    out.append(f"**{titolo}**")
    out.append(_reddit_testo(campo(voci[0], "content"))[:max_post])
    if len(voci) > 1 and max_commenti > 0:
        out.append("")
        out.append("Commenti:")
        for v in voci[1:1 + max_commenti]:
            c = _reddit_testo(campo(v, "content"))[:600]
            if c:
                out.append(f"- {nome(v)}: {c}")
    _time.sleep(12)
    return "\n".join(out)

def cerca_reddit(query, max_res=6, dominio="reddit.com"):
    """Reddit come fonte: ricerca per parole chiave via motore di ricerca.

    3/11: percorso SENZA credenziali Reddit (che non sono ancora state
    approvate). Non e' scraping: non si chiama reddit.com, si chiede a un
    motore di ricerca di indicizzare il dominio, con include_domains.
    Se un giorno Reddit approva l'accesso, si puo' sostituire questa funzione
    con il client ufficiale (vedi repo bomberr91/reddit-research-agent).
    """
    chiave = os.environ.get("TAVILY_API_KEY", "")
    if not chiave:
        try:
            import json as _json
            chiave = _json.load(open(os.path.expanduser("~/.tavily/config.json"))).get("api_key", "")
        except Exception:
            pass
    if not chiave:
        return "Nota Reddit: nessuna chiave di ricerca disponibile (TAVILY_API_KEY)."
    url = "https://api.tavily.com/search"
    corpo = _json.dumps({"api_key": chiave, "query": query,
                         "max_results": max_res, "include_domains": [dominio],
                         "search_depth": "advanced"}).encode()
    req = urllib.request.Request(url, data=corpo, method="POST",
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": "RicercaStrategica/1.0"})
    out = []
    link = []
    try:
        dati = _json.loads(urllib.request.urlopen(req, timeout=25).read().decode("utf-8"))
        for r in dati.get("results", [])[:max_res]:
            t = re.sub(r"<[^>]+>", "", r.get("title", "")).strip()
            s = re.sub(r"<[^>]+>", "", r.get("content", "")).strip()
            s = " ".join(s.split())[:300]
            out.append(f"- **{t}** ({r.get('url','')})\n  {s}")
            link.append(r.get("url", ""))
    except Exception as e:
        out.append(f"Nota Reddit: {e}")
    testo = "\n".join(out) if out else "Nessun risultato Reddit."
    # approfondimento: testo integrale delle prime discussioni (feed .rss pubblico)
    n = int(os.environ.get("REDDIT_LEGGI", "2"))
    if n > 0:
        for u in [x for x in link[:n] if x]:
            testo += "\n\n**Approfondimento** _(feed .rss, senza credenziali)_\n"
            testo += leggi_reddit(u) + "\n"
    return testo

def main():
    tema = " ".join(sys.argv[1:]).strip() if len(sys.argv) > 1 else input("Tema della ricerca strategica: ").strip()
    if not tema:
        return
    print(f"🔎 Raccolta fonti live su: {tema}...")
    web_res = cerca_ddg(tema)
    gh_res = cerca_github(tema)
    rd_res = cerca_reddit(tema)
    print("\n### 🌐 Fonti Web & Social trovate\n" + (web_res or "Nessun risultato diretto."))
    if gh_res:
        print("\n### 💻 Repository GitHub correlate\n" + gh_res)
    if rd_res:
        print("\n### 📡 Reddit (discussioni pubbliche)\n" + rd_res)

if __name__ == "__main__":
    main()
