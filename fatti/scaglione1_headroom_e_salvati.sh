#!/usr/bin/env bash
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
  git commit -qm "Scaglione 1: salvati FB + Headroom" >/dev/null 2>&1 || true
  if [ -n "$TOKEN" ]; then
    git pull -q --autostash --rebase "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" main >/dev/null 2>&1 || true
    git push -q "https://x-access-token:$TOKEN@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1 || true
  fi
}

echo "=== PASSO 1/2: Scansione completa di TUTTI i Salvati di Facebook (tutte le sezioni) ==="
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
msg_id = 1
ws.send_json({"id": msg_id, "method": "Page.navigate", "params": {"url": "https://www.facebook.com/saved"}})
ws.recv_json_id(msg_id)
msg_id += 1
time.sleep(5)

js_scan_all = r"""
(async () => {
  const wait = (ms) => new Promise(r => setTimeout(r, ms));

  const harvestPage = (sectionName) => {
    const found = [];
    // Prendi tutti i blocchi / card dei salvati o link significativi
    const anchors = Array.from(document.querySelectorAll('a[href]'));
    for (const a of anchors) {
      const href = a.href || '';
      if (!href || href.includes('/saved') || href.includes('/notifications') || href.includes('/messages') || href.includes('/friends')) continue;
      // Risali al contenitore della card per avere anche il testo/raccolta
      let card = a;
      for (let k = 0; k < 5; k++) {
        if (card.parentElement && (card.parentElement.innerText || '').length < 900) {
          card = card.parentElement;
        }
      }
      const text = (card.innerText || a.innerText || '').trim().replace(/\s+/g, ' ');
      if (text.length > 8) {
        found.push({
          section: sectionName,
          url: href.split('?__cft__')[0].split('&__cft__')[0],
          text: text.slice(0, 500)
        });
      }
    }
    return found;
  };

  const allItems = [];
  // 1. Prima siamo su "Tutte" (/saved generale): scorriamo a fondo 28 volte!
  for (let i = 0; i < 28; i++) {
    window.scrollBy(0, 2200);
    for (const d of document.querySelectorAll('div[role="main"]')) {
      try { d.scrollTop += 2200; } catch(e) {}
    }
    await wait(750);
  }
  allItems.push(...harvestPage("TUTTI_I_SALVATI"));
  const fullBodyGeneral = document.body.innerText;

  // 2. Trova i link delle singole raccolte (es. TIPS AI, POST, ecc.)
  const collLinks = Array.from(document.querySelectorAll('a[href*="/saved/?list_id="], a[href*="collection_token"]'))
    .map(a => ({ name: (a.innerText || '').trim().replace(/\s+/g, ' '), href: a.href }))
    .filter(x => x.name && !/cucina|psicolog/i.test(x.name));

  return {
    collections: collLinks,
    items: allItems,
    rawBody: fullBodyGeneral
  };
})()
"""
ws.send_json({"id": msg_id, "method": "Runtime.evaluate", "params": {"expression": js_scan_all, "awaitPromise": True, "returnByValue": True}})
res = ws.recv_json_id(msg_id)
msg_id += 1
val = res.get("result", {}).get("result", {}).get("value", {})

all_items = val.get("items", [])
raw_bodies = [("=== PAGINA GENERALE /SAVED ===\n" + val.get("rawBody", ""))]

# Visita anche le raccolte non-personali trovate
for col in val.get("collections", [])[:6]:
    cname = col.get("name", "")
    chref = col.get("href", "")
    if not chref or re.search(r'cucina|psicolog', cname, re.I):
        continue
    ws.send_json({"id": msg_id, "method": "Page.navigate", "params": {"url": chref}})
    ws.recv_json_id(msg_id)
    msg_id += 1
    time.sleep(4)
    js_col = r"""
    (async () => {
      const wait = (ms) => new Promise(r => setTimeout(r, ms));
      for (let i = 0; i < 15; i++) {
        window.scrollBy(0, 2000);
        await wait(700);
      }
      const items = [];
      for (const a of document.querySelectorAll('a[href]')) {
        const href = a.href || '';
        if (!href || href.includes('/saved') || href.includes('/notifications')) continue;
        let card = a;
        for (let k = 0; k < 4; k++) {
          if (card.parentElement && (card.parentElement.innerText || '').length < 800) card = card.parentElement;
        }
        const tx = (card.innerText || a.innerText || '').trim().replace(/\s+/g, ' ');
        if (tx.length > 8) items.push({ url: href.split('?__cft__')[0].split('&__cft__')[0], text: tx.slice(0, 500) });
      }
      return { items, body: document.body.innerText };
    })()
    """
    ws.send_json({"id": msg_id, "method": "Runtime.evaluate", "params": {"expression": js_col, "awaitPromise": True, "returnByValue": True}})
    r2 = ws.recv_json_id(msg_id)
    msg_id += 1
    v2 = r2.get("result", {}).get("result", {}).get("value", {})
    for it in v2.get("items", []):
        it["section"] = cname
        all_items.append(it)
    raw_bodies.append(f"=== RACCOLTA: {cname} ===\n" + v2.get("body", ""))

ws.close()

# Deduplica per URL
dedup = {}
for it in all_items:
    u = it.get("url", "")
    if u and u not in dedup:
        dedup[u] = it
    elif u and len(it.get("text", "")) > len(dedup[u].get("text", "")):
        dedup[u] = it

out_json = os.path.expanduser("~/posta/dal_pc/tutti_i_salvati_fb.json")
with open(out_json, "w", encoding="utf-8") as f:
    json.dump({"collections": val.get("collections", []), "items": list(dedup.values())}, f, ensure_ascii=False, indent=2)

out_txt = os.path.expanduser("~/posta/dal_pc/tutti_i_salvati_fb_raw.txt")
with open(out_txt, "w", encoding="utf-8") as f:
    f.write("\n\n".join(raw_bodies))

print(f"✓ Salvati estratti: {len(dedup)} elementi unici in {out_json}!")
PYEOF

push_git

echo "=== PASSO 2/2: Installazione pulita di XERJ e HEADROOM su FilippoPC ==="
if ! command -v xerj >/dev/null 2>&1; then
  curl -fsSL https://xerj.org/get | sh >/dev/null 2>&1 || true
fi

if [ ! -x "$HOME/.local/bin/headroom" ]; then
  python3 -m venv "$HOME/.local/share/headroom-venv" 2>/dev/null || true
  "$HOME/.local/share/headroom-venv/bin/pip" install -q --upgrade pip >/dev/null 2>&1 || true
  # Installiamo headroom-ai evitando la compilazione Rust da zero (--only-binary=:all: o pacchetto base + proxy + mcp)
  "$HOME/.local/share/headroom-venv/bin/pip" install -q --prefer-binary "headroom-ai[proxy,mcp]" >/dev/null 2>&1 \
    || "$HOME/.local/share/headroom-venv/bin/pip" install -q --prefer-binary headroom-ai >/dev/null 2>&1 || true
  if [ -x "$HOME/.local/share/headroom-venv/bin/headroom" ]; then
    ln -sf "$HOME/.local/share/headroom-venv/bin/headroom" "$HOME/.local/bin/headroom"
  fi
fi

{
  echo "# ✅ Stato Installazione Headroom & XERJ su FilippoPC"
  echo "- **Data**: $(date '+%d/%m/%Y %H:%M')"
  echo "- **XERJ**: $(~/.local/bin/xerj --version 2>&1 | head -1 || echo non trovato)"
  echo "- **Headroom**: $(~/.local/bin/headroom --version 2>&1 | head -1 || echo non trovato)"
} > "$POSTA_DIR/dal_pc/headroom_status.md"

cat "$POSTA_DIR/dal_pc/headroom_status.md"
push_git
