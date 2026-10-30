#!/usr/bin/env bash
# leggi_salvati_nuovi.sh — 30/10/2026
# Legge i Salvati di Facebook DALL'ALTO (i piu' recenti) e si FERMA
# al salvato-segnalibro: "ti regalo 10 milioni di visualizzazioni"
# (incluso). Tutto quello sopra il segnalibro = roba nuova dei
# 10 giorni, da analizzare. Risultato in dal_pc/salvati_nuovi_30_10.*
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

POSTA_DIR="$HOME/posta"
TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
[ -z "$TOKEN" ] && [ -f "$HOME/CHIAVI_LOCALI.md" ] && TOKEN="$(grep -oE 'ghp_[A-Za-z0-9]{30,}' "$HOME/CHIAVI_LOCALI.md" | head -1)"

push_git(){
  cd "$POSTA_DIR" || return
  git config user.name "bomberr91"
  git config user.email "bomberr91@users.noreply.github.com"
  git add dal_pc/ >/dev/null 2>&1
  git commit -qm "Salvati nuovi (fino al segnalibro 10 milioni)" >/dev/null 2>&1 || true
  if [ -n "$TOKEN" ]; then
    git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1 || true
    git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1 || true
  fi
}

echo "=== Lettura salvati NUOVI (stop al segnalibro) ==="
python3 - << 'PYEOF'
import os, sys, json, time, re
sys.path.insert(0, os.path.expanduser("~/posta"))
from leggi_fb_cdp import SimpleWS, get_tabs, ensure_browser

ensure_browser()
tabs = get_tabs()
fb_tab = next((t for t in tabs if t.get("type") == "page" and "facebook.com" in t.get("url", "")), None)
if not fb_tab:
    fb_tab = next((t for t in tabs if t.get("type") == "page"), None)

ws = SimpleWS(fb_tab["webSocketDebuggerUrl"])
mid = 1
ws.send_json({"id": mid, "method": "Page.navigate", "params": {"url": "https://www.facebook.com/saved"}})
ws.recv_json_id(mid); mid += 1
time.sleep(6)

# Scorre poco alla volta e si ferma appena il segnalibro compare nel testo.
js = r"""
(async () => {
  const wait = (ms) => new Promise(r => setTimeout(r, ms));
  const MARKER = /ti\s*regalo\s*10\s*milioni/i;

  const harvest = () => {
    const found = [];
    const anchors = Array.from(document.querySelectorAll('a[href]'));
    for (const a of anchors) {
      const href = a.href || '';
      if (!href || href.includes('/saved') || href.includes('/notifications') ||
          href.includes('/messages') || href.includes('/friends')) continue;
      let card = a;
      for (let k = 0; k < 5; k++) {
        if (card.parentElement && (card.parentElement.innerText || '').length < 900) {
          card = card.parentElement;
        }
      }
      const text = (card.innerText || a.innerText || '').trim().replace(/\s+/g, ' ');
      if (text.length > 8) {
        found.push({ url: href.split('?__cft__')[0].split('&__cft__')[0],
                     text: text.slice(0, 600) });
      }
    }
    return found;
  };

  let trovato = MARKER.test(document.body.innerText);
  let giri = 0;
  const MAX_GIRI = 50;
  while (!trovato && giri < MAX_GIRI) {
    window.scrollBy(0, 1800);
    for (const d of document.querySelectorAll('div[role="main"]')) {
      try { d.scrollTop += 1800; } catch(e) {}
    }
    await wait(900);
    giri++;
    trovato = MARKER.test(document.body.innerText);
  }
  // un giro in piu' per caricare bene la card del segnalibro
  window.scrollBy(0, 900);
  await wait(900);

  return { items: harvest(), segnalibro_trovato: trovato, giri: giri,
           body: document.body.innerText.slice(0, 120000) };
})()
"""
ws.send_json({"id": mid, "method": "Runtime.evaluate",
              "params": {"expression": js, "awaitPromise": True, "returnByValue": True}})
res = ws.recv_json_id(mid); mid += 1
ws.close()
val = res.get("result", {}).get("result", {}).get("value", {})

items = val.get("items", [])
marker = re.compile(r"ti\s*regalo\s*10\s*milioni", re.I)

# tieni l'ordine della pagina (alto = piu' recente) e TAGLIA al segnalibro (incluso)
dedup, ordinati = set(), []
for it in items:
    u = it.get("url", "")
    if not u or u in dedup:
        continue
    dedup.add(u)
    ordinati.append(it)
    if marker.search(it.get("text", "")):
        it["SEGNALIBRO"] = True
        break

out_dir = os.path.expanduser("~/posta/dal_pc")
os.makedirs(out_dir, exist_ok=True)
with open(os.path.join(out_dir, "salvati_nuovi_30_10.json"), "w", encoding="utf-8") as f:
    json.dump({"generato": time.strftime("%d/%m/%Y %H:%M"),
               "segnalibro_trovato": bool(val.get("segnalibro_trovato")),
               "giri_di_scroll": val.get("giri"),
               "voci": ordinati}, f, ensure_ascii=False, indent=1)
with open(os.path.join(out_dir, "salvati_nuovi_30_10_raw.txt"), "w", encoding="utf-8") as f:
    f.write(val.get("body", ""))
with open(os.path.join(out_dir, "salvati_nuovi_30_10.md"), "w", encoding="utf-8") as f:
    f.write("# Salvati NUOVI (dall'alto fino al segnalibro) — %s\n\n" % time.strftime("%d/%m %H:%M"))
    f.write("Segnalibro trovato: %s — voci raccolte: %d\n\n" %
            ("SI'" if val.get("segnalibro_trovato") else "NO (presi comunque i primi)", len(ordinati)))
    for i, it in enumerate(ordinati, 1):
        tag = "  ← SEGNALIBRO (qui ci si ferma)" if it.get("SEGNALIBRO") else ""
        f.write("%d. %s%s\n   %s\n\n" % (i, it["text"][:300], tag, it["url"]))
print("Voci nuove raccolte:", len(ordinati),
      "| segnalibro:", "trovato" if val.get("segnalibro_trovato") else "NON trovato")
PYEOF

push_git
echo "=== FINITO: risultato in dal_pc/salvati_nuovi_30_10.md (+ json + raw) ==="
