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
    try:
        dati = _json.loads(urllib.request.urlopen(req, timeout=25).read().decode("utf-8"))
        for r in dati.get("results", [])[:max_res]:
            t = re.sub(r"<[^>]+>", "", r.get("title", "")).strip()
            s = re.sub(r"<[^>]+>", "", r.get("content", "")).strip()
            s = " ".join(s.split())[:300]
            out.append(f"- **{t}** ({r.get('url','')})\n  {s}")
    except Exception as e:
        out.append(f"Nota Reddit: {e}")
    return "\n".join(out) if out else "Nessun risultato Reddit."

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
