#!/usr/bin/env python3
# vision_cf_frames.py — i frame a Cloudflare vision (llama-3.2-11b), uno per chiamata
# uso: python3 vision_cf_frames.py <dir_frames> <account_id:token>
import base64, glob, json, os, sys
import urllib.request

dirf, cfl = sys.argv[1], sys.argv[2]
account_id, token = cfl.split(":", 1)
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/157.0.0.0"
frames = sorted(glob.glob(os.path.join(dirf, "f*.jpg")))
for f in frames:
    b64 = base64.b64encode(open(f, "rb").read()).decode()
    body = json.dumps({"messages": [{"role": "user", "content": [
        {"type": "text", "text": "Leggi TUTTE le scritte a schermo in questa immagine (frame di un reel). Riporta solo le scritte esatte, una per riga, niente commenti. Se non ci sono scritte leggibili rispondi: -"},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + b64}}]}]}).encode()
    req = urllib.request.Request(
        "https://api.cloudflare.com/client/v4/accounts/" + account_id + "/ai/run/@cf/meta/llama-3.2-11b-vision-instruct",
        data=body, headers={"Content-Type": "application/json", "Authorization": "Bearer " + token, "User-Agent": UA})
    nome = os.path.basename(f)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            d = json.loads(r.read().decode())
        testo = (d.get("result") or {}).get("response", "").strip().replace("\n", " · ")[:280]
        print("- [" + nome + "] " + (testo if testo and testo != "-" else "(niente scritte)"), flush=True)
    except Exception as e:
        print("- [" + nome + "] (errore: " + str(e)[:60] + ")", flush=True)
