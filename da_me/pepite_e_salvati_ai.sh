#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

echo "=== 1. Installo XERJ (xerj-org/xerj - 40x meno token di grep) ==="
if ! command -v xerj >/dev/null 2>&1; then
  curl -fsSL https://xerj.org/get | sh >/dev/null 2>&1 || true
fi
echo "XERJ: $(xerj --version 2>&1 | head -1 || echo non installato)"

echo "=== 2. Installo Headroom (headroomlabs-ai/headroom - compressione token -80%) ==="
if ! command -v headroom >/dev/null 2>&1; then
  python3 -m venv "$HOME/.local/share/headroom-venv" 2>/dev/null || true
  "$HOME/.local/share/headroom-venv/bin/pip" install -q --upgrade pip >/dev/null 2>&1 || true
  "$HOME/.local/share/headroom-venv/bin/pip" install -q --only-binary :all: "headroom-ai[proxy,mcp]" >/dev/null 2>&1 \
    || "$HOME/.local/share/headroom-venv/bin/pip" install -q headroom-ai >/dev/null 2>&1 || true
  if [ -x "$HOME/.local/share/headroom-venv/bin/headroom" ]; then
    ln -sf "$HOME/.local/share/headroom-venv/bin/headroom" "$HOME/.local/bin/headroom"
  fi
fi
echo "Headroom: $(headroom --version 2>&1 | head -1 || echo installato parziale)"

echo "=== 3. Estraggo tutta la raccolta 'TIPS AI' dai Salvati di Facebook (SOLA LETTURA) ==="
python3 - << 'PYEOF'
import json, time, urllib.request, os, sys
sys.path.insert(0, os.path.expanduser("~/posta"))
from leggi_fb_cdp import SimpleWS, get_tabs

tabs = get_tabs()
page_tab = next((t for t in tabs if t.get("type") == "page" and "facebook.com" in t.get("url", "")), None)
if not page_tab:
    page_tab = next((t for t in tabs if t.get("type") == "page"), None)

ws = SimpleWS(page_tab["webSocketDebuggerUrl"])
ws.send_json({"id": 1, "method": "Page.navigate", "params": {"url": "https://www.facebook.com/saved"}})
ws.recv_json_id(1)
time.sleep(5)

js_saved = r"""
(async () => {
  const wait = (ms) => new Promise(r => setTimeout(r, ms));
  // Clicca su "TIPS AI" se presente nella barra sinistra
  for (const el of document.querySelectorAll('a, div[role="button"], span')) {
    if ((el.innerText || '').trim() === 'TIPS AI') {
      try { el.click(); } catch(e) {}
      await wait(3500);
      break;
    }
  }
  // Scorri giù 15 volte per caricare tutti i salvati di TIPS AI
  for (let i = 0; i < 15; i++) {
    window.scrollBy(0, 2000);
    await wait(900);
  }
  const items = [];
  for (const a of document.querySelectorAll('a[href]')) {
    const h = a.href || '';
    const tx = (a.innerText || '').trim().replace(/\s+/g, ' ');
    if (tx.length > 5 && (h.includes('/reel/') || h.includes('/posts/') || h.includes('/videos/') || h.includes('/permalink/') || h.includes('/watch/') || h.includes('facebook.com/'))) {
      if (!h.includes('/saved') && !h.includes('/groups/feed') && !h.includes('/notifications')) {
        items.push(tx.slice(0, 180) + ' -> ' + h.split('?')[0]);
      }
    }
  }
  return {
    url: location.href,
    links: Array.from(new Set(items)),
    body: document.body.innerText
  };
})()
"""
ws.send_json({"id": 2, "method": "Runtime.evaluate", "params": {"expression": js_saved, "awaitPromise": True, "returnByValue": True}})
res = ws.recv_json_id(2)
ws.close()

val = res.get("result", {}).get("result", {}).get("value", {})
out_p = os.path.expanduser("~/posta/dal_pc/salvati_tips_ai.md")
with open(out_p, "w", encoding="utf-8") as f:
    f.write(f"# 📌 Salvati Facebook — Raccolta TIPS AI\n- **URL**: {val.get('url','')}\n- **Link trovati**: {len(val.get('links',[]))}\n\n## Link estratti\n")
    for l in val.get("links", []):
        f.write(f"- {l}\n")
    f.write("\n## Testo completo pagina\n\n" + val.get("body", ""))
print(f"Salvati TIPS AI estratti: {len(val.get('links',[]))} link, {len(val.get('body',''))} caratteri")
PYEOF
