#!/usr/bin/env python3
import os, sys, re, html, json, time, shutil, urllib.request, subprocess
from datetime import datetime

HOME = os.path.expanduser("~")
CHIAVI = os.path.join(HOME, "CHIAVI_LOCALI.md")
OUT_DIR = os.path.join(HOME, "posta", "dal_pc")
os.makedirs(OUT_DIR, exist_ok=True)

def get_groq_key():
    if os.path.exists(CHIAVI):
        txt = open(CHIAVI, encoding="utf-8", errors="ignore").read()
        m = re.search(r'gsk_[A-Za-z0-9_-]{20,}', txt)
        if m: return m.group(0)
    return os.environ.get("GROQ_API_KEY", "")

def fetch_fb_media(url, work):
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7",
        "Sec-Fetch-Mode": "navigate",
    })
    page = urllib.request.urlopen(req, timeout=20).read().decode("utf-8", errors="ignore")
    urls = re.findall(r'"(?:base_url|playable_url(?:_quality_hd)?|browser_native_(?:hd|sd)_url)":"(https:[^"]+)"', page)
    clean = []
    for u in urls:
        cu = u.replace("\\/", "/").encode("utf-8").decode("unicode_escape", errors="ignore")
        if cu not in clean: clean.append(cu)
    audio_u = next((u for u in clean if "mp4a" in u or "audio" in u.lower()), None)
    video_u = next((u for u in clean if u != audio_u), clean[0] if clean else None)
    if not audio_u and len(clean) > 1: audio_u = clean[-1]
    target = os.path.join(work, "audio.m4a")
    if audio_u:
        urllib.request.urlretrieve(audio_u, target)
        return target
    if video_u:
        vpath = os.path.join(work, "video.mp4")
        urllib.request.urlretrieve(video_u, vpath)
        return vpath
    return None

def download_media(url, work):
    if "facebook.com" in url or "fb.watch" in url:
        try:
            m = fetch_fb_media(url, work)
            if m and os.path.exists(m) and os.path.getsize(m) > 1000:
                return m
        except Exception as e:
            print(f"  · Fallback a yt-dlp ({e})...")
    # Fallback universale: yt-dlp (YouTube, Instagram, TikTok, X, ecc.)
    out_tmpl = os.path.join(work, "media.%(ext)s")
    subprocess.run(["yt-dlp", "--no-playlist", "-f", "ba/b", "-o", out_tmpl, url], check=False)
    for f in os.listdir(work):
        if f.startswith("media."):
            return os.path.join(work, f)
    return None

def transcribe_groq(media_path, gkey):
    out = subprocess.check_output([
        "curl", "-s", "https://api.groq.com/openai/v1/audio/transcriptions",
        "-H", f"Authorization: Bearer {gkey}",
        "-F", f"file=@{media_path}",
        "-F", "model=whisper-large-v3-turbo",
        "-F", "response_format=verbose_json"
    ]).decode("utf-8", errors="ignore")
    return json.loads(out)

def process_url(url):
    gkey = get_groq_key()
    if not gkey:
        print("✗ Chiave Groq non trovata in ~/CHIAVI_LOCALI.md")
        return
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    work = f"/tmp/video_{stamp}"
    os.makedirs(work, exist_ok=True)
    print(f"\n[1/3] Scarico l'audio da: {url} ...")
    media = download_media(url, work)
    if not media or not os.path.exists(media):
        print("✗ Impossibile scaricare l'audio direttamente (se il post è privato apri il BROWSER DEGLI AGENTI).")
        shutil.rmtree(work, ignore_errors=True)
        return
    print(f"  ✓ Media scaricato ({os.path.getsize(media)//1024} KB). Invio a Groq Whisper-large-v3-turbo...")
    print("[2/3] Trascrizione ultra-rapida in corso...")
    d = transcribe_groq(media, gkey)
    text = d.get("text", "").strip()
    lang = d.get("language", "?")
    dur = round(float(d.get("duration", 0) or 0), 1)
    shutil.rmtree(work, ignore_errors=True)
    if not text:
        print("✗ Nessun parlato rilevato nel video.")
        return
    print(f"  ✓ Trascritto ({dur}s, lingua: {lang})!")
    print("[3/3] Catalogazione e sintesi in italiano con l'agente...")
    out_file = os.path.join(OUT_DIR, f"video_{stamp}.md")
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(f"# 🎬 Scheda Video Trascritto e Catalogato\n")
        f.write(f"- **Link**: {url}\n")
        f.write(f"- **Data**: {datetime.now().strftime('%d/%m/%Y %H:%M')} · **Durata**: {dur}s · **Lingua**: {lang}\n\n")
        f.write(f"## 📝 Trascrizione Originale Completa\n> {text}\n\n")
        f.write(f"## 🧠 Analisi, Strumenti Citati e Utilità per Noi\n")

    prompt = (
        f"Analizza questa trascrizione di un video ({url}). "
        f"Scrivi in italiano: 1) Riassunto in 3 righe; 2) Tabella di tutti i tool/siti/repo/metodi citati; "
        f"3) Cosa ci serve davvero a costo zero per le nostre missioni.\n\nTRASCRIZIONE:\n{text}"
    )
    subprocess.run(
        f'opencode run -m opencode/big-pickle {json.dumps(prompt)} >> {json.dumps(out_file)} 2>/dev/null || opencode run {json.dumps(prompt)} >> {json.dumps(out_file)} 2>/dev/null',
        shell=True
    )
    print("\n==========================================================")
    print(f" ✓ SCHEDA SALVATA IN: {out_file}")
    print("==========================================================\n")
    print(open(out_file, encoding="utf-8").read())

def process_saved_fb():
    print("\nControllo il BROWSER DEGLI AGENTI sulla porta 9222...")
    try:
        tabs = json.loads(urllib.request.urlopen("http://127.0.0.1:9222/json", timeout=3).read().decode())
    except Exception:
        print("✗ Il Browser degli Agenti non è aperto! Scegli prima l'opzione [5] nel menu, fai login su Facebook e apri https://www.facebook.com/saved")
        return
    print(f"  ✓ Browser Agenti connesso ({len(tabs)} schede aperte).")
    print("Uso agent-browser su https://www.facebook.com/saved per estrarre i link dei video salvati...")
    out = subprocess.getoutput("agent-browser --cdp 9222 snapshot 2>/dev/null || true")
    links = re.findall(r'https://www\.facebook\.com/(?:reel/[0-9]+|watch/\?v=[0-9]+|[^/\s]+/videos/[0-9]+)', out + " " + json.dumps(tabs))
    uniq = list(dict.fromkeys(links))
    if not uniq:
        print("  · Nessun link reel/video trovato nella scheda corrente.")
        u = input("Incolla qui il link del video salvato (o premi INVIO per uscire): ").strip()
        if u: process_url(u)
        return
    print(f"  ✓ Trovati {len(uniq)} video salvati! Avvio trascrizione automatica...")
    for u in uniq[:10]:
        process_url(u)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--saved":
        process_saved_fb()
    elif len(sys.argv) > 1:
        process_url(sys.argv[1])
    else:
        u = input("Incolla il link del Video/Reel (Facebook, YouTube, Instagram, TikTok): ").strip()
        if u: process_url(u)
