#!/usr/bin/env python3
import os, sys, re, json, time, subprocess, urllib.request
sys.path.insert(0, os.path.expanduser("~/posta"))
from leggi_fb_cdp import SimpleWS, get_tabs, ensure_browser

DISCORD_URL = "https://discord.com/channels/1119998900271587471/1120000721262227507"
OUT_DISCORD = os.path.expanduser("~/posta/dal_pc/discord_ecom_elite.md")
OUT_SALVATI = os.path.expanduser("~/posta/dal_pc/salvati_tips_ai.md")

def push_now():
    posta_dir = os.path.expanduser("~/posta")
    tok = ""
    tf = os.path.expanduser("~/.posta_token")
    cf = os.path.expanduser("~/CHIAVI_LOCALI.md")
    if os.path.exists(tf):
        tok = open(tf, encoding="utf-8", errors="ignore").read().strip()
    if not tok and os.path.exists(cf):
        m = re.search(r'ghp_[A-Za-z0-9]{30,}', open(cf, encoding="utf-8", errors="ignore").read())
        if m: tok = m.group(0)
    subprocess.run('git config user.name "bomberr91" && git config user.email "bomberr91@users.noreply.github.com"', shell=True, cwd=posta_dir)
    subprocess.run('git fetch -q origin main && git add dal_pc/ && git commit -qm "Discord Ecom Elite + Salvati estratti da FilippoPC" || true', shell=True, cwd=posta_dir)
    if tok:
        subprocess.run(f'git pull -q --rebase "https://x-access-token:{tok}@github.com/bomberr91/posta.git" main || true', shell=True, cwd=posta_dir)
        subprocess.run(f'git push -q "https://x-access-token:{tok}@github.com/bomberr91/posta.git" HEAD:main || true', shell=True, cwd=posta_dir)
        print("🚀 Inviato automaticamente sul ponte GitHub (bomberr91/posta)!")

def main():
    # Sblocca eventuale pip install headroom bloccato
    subprocess.run("pkill -f headroom-venv 2>/dev/null || true", shell=True)

    if not ensure_browser():
        print("✗ Browser degli Agenti (porta 9222) non raggiungibile.")
        sys.exit(1)

    tabs = get_tabs()
    print(f"Schede aperte nel Browser degli Agenti: {len(tabs)}")
    for t in tabs:
        if t.get("type") == "page":
            print("  •", t.get("title", "")[:50], "->", t.get("url", "")[:80])

    # 1. Cerca la scheda Discord
    d_tab = next((t for t in tabs if t.get("type") == "page" and "discord.com" in t.get("url", "")), None)
    if not d_tab:
        d_tab = next((t for t in tabs if t.get("type") == "page"), None)

    ws = SimpleWS(d_tab["webSocketDebuggerUrl"])
    msg_id = 1
    if "1119998900271587471" not in d_tab.get("url", ""):
        print("➡️ Apro il canale Discord Ecom Elite:", DISCORD_URL)
        ws.send_json({"id": msg_id, "method": "Page.navigate", "params": {"url": DISCORD_URL}})
        ws.recv_json_id(msg_id)
        msg_id += 1
        time.sleep(6)
    else:
        time.sleep(2)

    print("⏳ Leggo il server Discord Ecom Elite (canali + messaggi + link in SOLA LETTURA)...")
    js_discord = r"""
    (async () => {
      const wait = (ms) => new Promise(r => setTimeout(r, ms));
      const report = [];
      report.push("### Canale iniziale: " + location.href + " (" + document.title + ")");

      // Raccogli tutti i canali della sidebar del server
      const chanEls = Array.from(document.querySelectorAll('a[href*="/channels/1119998900271587471/"], [data-list-item-id^="channels___"]'));
      const channels = [];
      const seenHrefs = new Set();
      for (const el of chanEls) {
        const href = el.getAttribute('href') || '';
        const name = (el.innerText || el.getAttribute('aria-label') || '').trim().replace(/\s+/g, ' ');
        if (name && !seenHrefs.has(href || name)) {
          seenHrefs.add(href || name);
          channels.push({ name, href });
        }
      }

      // Funzione per estrarre messaggi e link visibili nel canale corrente
      const dumpCurrentChannel = () => {
        const links = Array.from(document.querySelectorAll('main a[href], [class*="chatContent"] a[href]'))
          .map(a => (a.innerText || '').trim() + ' -> ' + a.href)
          .filter(x => !x.includes('discord.com/channels/'));
        const text = document.body.innerText;
        return {
          url: location.href,
          title: document.title,
          links: Array.from(new Set(links)),
          text: text.slice(0, 18000)
        };
      };

      const dumps = [];
      dumps.push(dumpCurrentChannel());

      // Visita in sola lettura fino a 7 altri canali chiave del server
      const clickable = Array.from(document.querySelectorAll('a[href^="/channels/1119998900271587471/"]'));
      const visited = new Set([location.pathname]);
      for (const a of clickable) {
        const h = a.getAttribute('href');
        if (h && !visited.has(h) && visited.size < 8) {
          visited.add(h);
          try {
            a.click();
            await wait(2500);
            dumps.push(dumpCurrentChannel());
          } catch(e) {}
        }
      }

      return { channels, dumps };
    })()
    """
    ws.send_json({"id": msg_id, "method": "Runtime.evaluate", "params": {"expression": js_discord, "awaitPromise": True, "returnByValue": True}})
    res = ws.recv_json_id(msg_id)
    ws.close()

    val = res.get("result", {}).get("result", {}).get("value", {})
    os.makedirs(os.path.dirname(OUT_DISCORD), exist_ok=True)
    with open(OUT_DISCORD, "w", encoding="utf-8") as f:
        f.write("# 💎 Server Discord `Ecom Elite` — Esplorazione Sola Lettura\n\n")
        f.write("## 📋 Lista Canali Trovati nel Server\n")
        for c in val.get("channels", []):
            f.write(f"- **{c.get('name','')}** (`{c.get('href','')}`)\n")
        f.write("\n---\n\n")
        for i, d in enumerate(val.get("dumps", []), 1):
            f.write(f"## 📖 Canale {i}: {d.get('title','')} (`{d.get('url','')}`)\n")
            if d.get("links"):
                f.write("### 🔗 Link esterni nel canale:\n")
                for lk in d.get("links", []):
                    f.write(f"- {lk}\n")
            f.write("\n### 📝 Contenuto:\n```text\n")
            f.write(d.get("text", "")[:12000])
            f.write("\n```\n\n---\n\n")

    print(f"✓ Salvato report Discord in {OUT_DISCORD} ({os.path.getsize(OUT_DISCORD)} byte)!")
    push_now()

if __name__ == "__main__":
    main()
