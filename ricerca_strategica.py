#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ricerca_strategica.py — SUPER-AGENTE DI RICERCA & DECISIONE (stile GPT-Researcher + Agent-Reach)
Cerca sul web / GitHub / Reddit / YouTube gratuitamente, incrocia le fonti e produce un Dossier Decisionale.
"""
import sys, os, re, json, urllib.request, urllib.parse

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

def main():
    tema = " ".join(sys.argv[1:]).strip() if len(sys.argv) > 1 else input("Tema della ricerca strategica: ").strip()
    if not tema:
        return
    print(f"🔎 Raccolta fonti live su: {tema}...")
    web_res = cerca_ddg(tema)
    gh_res = cerca_github(tema)
    print("\n### 🌐 Fonti Web & Social trovate\n" + (web_res or "Nessun risultato diretto."))
    if gh_res:
        print("\n### 💻 Repository GitHub correlate\n" + gh_res)

if __name__ == "__main__":
    main()
