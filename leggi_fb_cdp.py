#!/usr/bin/env python3
import os, sys, json, time, socket, struct, base64, hashlib, urllib.request, urllib.parse, subprocess

TARGET_URL = sys.argv[1] if len(sys.argv) > 1 else "https://www.facebook.com/groups/vibecodinglife/permalink/2167430827178776"
OUT_FILE = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser("~/posta/dal_pc/fb_post_commenti.md")

def get_tabs():
    with urllib.request.urlopen("http://127.0.0.1:9222/json", timeout=3) as r:
        return json.loads(r.read().decode("utf-8", errors="ignore"))

def ensure_browser():
    try:
        get_tabs()
        return True
    except Exception:
        print("🌐 Avvio automaticamente il Browser degli Agenti (porta 9222)...")
        try:
            bat_w = subprocess.check_output(["wslpath", "-w", os.path.expanduser("~/posta/6_BROWSER_AGENTI.bat")]).decode().strip()
            subprocess.Popen(["cmd.exe", "/c", "start", "", bat_w], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            print("Nota avvio browser:", e)
        for _ in range(15):
            time.sleep(1)
            try:
                get_tabs()
                return True
            except Exception:
                pass
        return False

class SimpleWS:
    def __init__(self, ws_url):
        u = urllib.parse.urlparse(ws_url)
        host = u.hostname or "127.0.0.1"
        port = u.port or 9222
        path = u.path + ("?" + u.query if u.query else "")
        self.sock = socket.create_connection((host, port), timeout=90)
        key = base64.b64encode(os.urandom(16)).decode()
        req = (
            f"GET {path} HTTP/1.1\r\n"
            f"Host: {host}:{port}\r\n"
            f"Upgrade: websocket\r\n"
            f"Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            f"Sec-WebSocket-Version: 13\r\n\r\n"
        )
        self.sock.sendall(req.encode())
        buff = b""
        while b"\r\n\r\n" not in buff:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise RuntimeError("Handshake WebSocket chiuso")
            buff += chunk
        self.extra = buff.split(b"\r\n\r\n", 1)[1]

    def _recv_exact(self, n):
        data = b""
        if self.extra:
            take = min(n, len(self.extra))
            data += self.extra[:take]
            self.extra = self.extra[take:]
        while len(data) < n:
            chunk = self.sock.recv(min(65536, n - len(data)))
            if not chunk:
                raise RuntimeError("Connessione WebSocket interrotta")
            data += chunk
        return data

    def send_json(self, obj):
        payload = json.dumps(obj).encode("utf-8")
        mask_key = os.urandom(4)
        header = bytearray([0x81])
        n = len(payload)
        if n < 126:
            header.append(0x80 | n)
        elif n < 65536:
            header.append(0x80 | 126)
            header.extend(struct.pack("!H", n))
        else:
            header.append(0x80 | 127)
            header.extend(struct.pack("!Q", n))
        header.extend(mask_key)
        masked = bytearray(n)
        for i in range(n):
            masked[i] = payload[i] ^ mask_key[i & 3]
        self.sock.sendall(header + masked)

    def recv_json_id(self, target_id):
        while True:
            msg_bytes = bytearray()
            while True:
                b1, b2 = self._recv_exact(2)
                fin = (b1 & 0x80) != 0
                opcode = b1 & 0x0F
                masked = (b2 & 0x80) != 0
                length = b2 & 0x7F
                if length == 126:
                    length = struct.unpack("!H", self._recv_exact(2))[0]
                elif length == 127:
                    length = struct.unpack("!Q", self._recv_exact(8))[0]
                mask_k = self._recv_exact(4) if masked else None
                data = bytearray(self._recv_exact(length))
                if masked and mask_k:
                    for i in range(length):
                        data[i] ^= mask_k[i & 3]
                if opcode == 0x8:
                    raise RuntimeError("WebSocket chiuso dal browser")
                if opcode == 0x9: # Ping -> Pong
                    self.sock.sendall(bytes([0x8A, 0x80, 0, 0, 0, 0]))
                    continue
                if opcode in (0x1, 0x2, 0x0):
                    msg_bytes.extend(data)
                    if fin:
                        break
            try:
                obj = json.loads(msg_bytes.decode("utf-8", errors="ignore"))
                if obj.get("id") == target_id:
                    return obj
            except Exception:
                pass

    def close(self):
        try: self.sock.close()
        except Exception: pass

def main():
    if not ensure_browser():
        print("✗ Browser degli Agenti (porta 9222) non raggiungibile.")
        sys.exit(1)

    tabs = get_tabs()
    print(f"Schede aperte nel Browser degli Agenti: {len(tabs)}")
    for t in tabs:
        if t.get("type") == "page":
            print("  •", t.get("title", "")[:60], "->", t.get("url", "")[:80])

    slug = TARGET_URL.rstrip("/").split("/")[-1]
    page_tab = next((t for t in tabs if t.get("type") == "page" and slug in t.get("url", "")), None)
    if not page_tab:
        page_tab = next((t for t in tabs if t.get("type") == "page" and "facebook.com" in t.get("url", "")), None)
    if not page_tab:
        page_tab = next((t for t in tabs if t.get("type") == "page"), None)

    if not page_tab:
        req = urllib.request.Request("http://127.0.0.1:9222/json/new?" + urllib.parse.quote(TARGET_URL, safe=":/?&="), method="PUT")
        page_tab = json.loads(urllib.request.urlopen(req, timeout=5).read().decode())

    ws = SimpleWS(page_tab["webSocketDebuggerUrl"])
    msg_id = 1

    if slug not in page_tab.get("url", ""):
        print(f"➡️ Apro nel Browser degli Agenti: {TARGET_URL}")
        ws.send_json({"id": msg_id, "method": "Page.navigate", "params": {"url": TARGET_URL}})
        ws.recv_json_id(msg_id)
        msg_id += 1
        time.sleep(6)
    else:
        time.sleep(2)

    print("⏳ Espando TUTTI i commenti e le sottorisposte (circa 20 secondi)...")
    js_code = r"""
    (async () => {
      const wait = (ms) => new Promise(r => setTimeout(r, ms));
      const scroller = document.scrollingElement || document.documentElement || document.body;

      // 1. Cambia filtro da "Più pertinenti" / "Most relevant" a "Tutti i commenti" / "All comments"
      for (const el of document.querySelectorAll('div[role="button"], span')) {
        const tx = (el.innerText || '').trim();
        if (/^(Più pertinenti|Most relevant|Commenti più pertinenti)$/i.test(tx)) {
          try { el.click(); } catch(e) {}
          await wait(1200);
          for (const opt of document.querySelectorAll('div[role="menuitem"], div[role="menuitemradio"], div[role="option"], span')) {
            const otx = (opt.innerText || '').trim();
            if (/^(Tutti i commenti|All comments)/i.test(otx)) {
              try { opt.click(); } catch(e) {}
              await wait(2200);
              break;
            }
          }
          break;
        }
      }

      // 2. Clicca su tutti i pulsanti di espansione commenti/risposte e scorre sia la finestra sia eventuali dialog/container
      for (let i = 0; i < 24; i++) {
        let clicked = 0;
        for (const el of document.querySelectorAll('div[role="button"], span')) {
          const tx = (el.innerText || '').trim();
          if (
            tx.length > 2 && tx.length < 60 &&
            /altri commenti|altre risposte|visualizza altr|mostra altr|altro\.\.\.|more comments|more replies|view more|see more|\b\d+\s+(rispost|repl|comment)/i.test(tx)
          ) {
            try { el.click(); clicked++; } catch(e) {}
          }
        }
        window.scrollBy(0, 1800);
        for (const d of document.querySelectorAll('div[role="dialog"], div[role="main"]')) {
          try { d.scrollTop += 1800; } catch(e) {}
        }
        await wait(850);
        if (clicked === 0 && i > 7) break;
      }

      return {
        url: location.href,
        title: document.title,
        text: document.body.innerText
      };
    })()
    """

    ws.send_json({
        "id": msg_id,
        "method": "Runtime.evaluate",
        "params": {
            "expression": js_code,
            "awaitPromise": True,
            "returnByValue": True
        }
    })
    res = ws.recv_json_id(msg_id)
    ws.close()

    val = res.get("result", {}).get("result", {}).get("value", {})
    body = val.get("text", "")
    os.makedirs(os.path.dirname(OUT_FILE), exist_ok=True)
    with open(OUT_FILE, "w", encoding="utf-8") as f:
        f.write(f"# 📌 Post e Commenti Facebook Estratti\n")
        f.write(f"- **URL**: {val.get('url', TARGET_URL)}\n")
        f.write(f"- **Titolo**: {val.get('title', '')}\n")
        f.write(f"- **Caratteri estratti**: {len(body)}\n\n---\n\n")
        f.write(body)

    print(f"✓ Estratti {len(body)} caratteri in {OUT_FILE}!")

if __name__ == "__main__":
    main()
