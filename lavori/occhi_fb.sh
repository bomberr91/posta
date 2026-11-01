#!/bin/bash
# OCCHI-FB: scarica un video FB/reel e lo fa GUARDARE a Gemini (parlato+testo a schermo)
# Uso: bash lavori/occhi_fb.sh "URL" [nome_rapporto]
cd ~/posta
URL="$1"
NOME="${2:-occhi_fb}"
R="dal_pc/${NOME}.md"
{
echo "# 👁 OCCHI-FB — $(date '+%d/%m %H:%M')"
echo "URL: $URL"
export PATH="$HOME/.local/bin:$PATH"
command -v yt-dlp > /dev/null || pip install --user -q yt-dlp 2>&1 | tail -1
yt-dlp -U 2>/dev/null | tail -1
V=/tmp/occhi_video.mp4
rm -f "$V"
echo "## 1. Scarico (prima senza cookie: molti reel sono pubblici)"
if ! yt-dlp -q -f "w[ext=mp4][acodec!=none]/b[height<=360][ext=mp4]/w" --max-filesize 40M -o "$V" "$URL" 2>&1 | tail -2; then true; fi
if [ ! -s "$V" ]; then
  echo "   pubblico no → provo coi cookie del BROWSER_AGENTI (Chromium :9222)"
  PROF=$(ls -d /mnt/c/Users/giopi/*Browser*Profile* /mnt/c/Users/giopi/AppData/Local/agenti/*rofile* 2>/dev/null | head -1)
  [ -n "$PROF" ] && yt-dlp -q --cookies-from-browser "chromium:$PROF" -f "best[height<=480][ext=mp4]/best" --max-filesize 40M -o "$V" "$URL" 2>&1 | tail -2
fi
if [ ! -s "$V" ]; then echo "❌ SCARICAMENTO FALLITO (serve forse la via-screenshot)"; exit 0; fi
echo "   ✓ scaricato: $(du -h "$V" | cut -f1)"
# ffmpeg: se manca, scarico il binario statico una volta per tutte (niente sudo)
FF=$(command -v ffmpeg || echo "$HOME/.local/bin/ffmpeg")
if [ ! -x "$FF" ]; then
  echo "   installo ffmpeg statico (una tantum)..."
  mkdir -p ~/.local/bin /tmp/ffst && cd /tmp/ffst
  curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz -o ff.tar.xz \
    && tar xf ff.tar.xz && cp ffmpeg-*-static/ffmpeg ~/.local/bin/ && chmod +x ~/.local/bin/ffmpeg \
    && echo "   ✓ ffmpeg pronto" || echo "   ffmpeg statico non scaricabile (si tira dritto)"
  cd ~/posta
fi
DIM=$(stat -c%s "$V")
if [ "$DIM" -gt 4000000 ] && [ -x "$FF" ]; then
  echo "   dieta Gemini: 360p a 1.5fps (lui campiona a 1fps, non perde nulla)"
  "$FF" -y -loglevel error -i "$V" -vf scale=-2:360 -r 1.5 -b:v 120k -ac 1 -b:a 40k /tmp/occhi_s.mp4 \
    && mv /tmp/occhi_s.mp4 "$V" && echo "   → ora: $(du -h "$V" | cut -f1)"
fi
echo
echo "## 2. Gemini guarda il video"
K=$(grep "^GEMINI_STUDIO=" ~/CHIAVI_LOCALI.md | cut -d= -f2)
python3 - "$V" "$K" << 'PYEOF'
import base64, json, sys, time, urllib.request
video, chiave = sys.argv[1], sys.argv[2]
dati = open(video, "rb").read()
PROMPT = "Analizza questo video in ITALIANO: 1) trascrivi il parlato 2) riporta TUTTO il testo che appare a schermo (titoli, scritte, sottotitoli) 3) elenca nomi di strumenti/repo/siti/link citati 4) riassunto in 3 righe del contenuto utile."
BASE = "https://generativelanguage.googleapis.com"

def genera(parte_video):
    corpo = json.dumps({"contents": [{"parts": [parte_video, {"text": PROMPT}]}]}).encode()
    req = urllib.request.Request(BASE + "/v1beta/models/gemini-3.8-flash:generateContent?key=" + chiave,
                                 data=corpo, headers={"Content-Type": "application/json"})
    d = json.loads(urllib.request.urlopen(req, timeout=600).read().decode())
    return d["candidates"][0]["content"]["parts"][0]["text"]

# VIA 1: File API col protocollo resumable VERO (2 passi)
try:
    avvio = urllib.request.Request(BASE + "/upload/v1beta/files?key=" + chiave,
        data=json.dumps({"file": {"display_name": "reel"}}).encode(), method="POST",
        headers={"X-Goog-Upload-Protocol": "resumable", "X-Goog-Upload-Command": "start",
                 "X-Goog-Upload-Header-Content-Length": str(len(dati)),
                 "X-Goog-Upload-Header-Content-Type": "video/mp4",
                 "Content-Type": "application/json"})
    r = urllib.request.urlopen(avvio, timeout=60)
    url_su = r.headers.get("X-Goog-Upload-URL")
    carica = urllib.request.Request(url_su, data=dati, method="POST",
        headers={"X-Goog-Upload-Command": "upload, finalize", "X-Goog-Upload-Offset": "0"})
    f = json.loads(urllib.request.urlopen(carica, timeout=600).read().decode())["file"]
    for _ in range(40):
        st = json.loads(urllib.request.urlopen(BASE + "/v1beta/" + f["name"] + "?key=" + chiave, timeout=30).read().decode())
        if st.get("state") == "ACTIVE": break
        time.sleep(4)
    print(genera({"file_data": {"mime_type": "video/mp4", "file_uri": f["uri"]}}))
    sys.exit(0)
except Exception as e:
    print("(File API ko: %s — provo la via inline)" % str(e)[:100])

# VIA 2: inline (se il video e' abbastanza piccolo)
if len(dati) > 14_000_000:
    print("e il video resta troppo grosso per la via inline (%.1f MB). Mi fermo." % (len(dati)/1e6))
    sys.exit(0)
print(genera({"inline_data": {"mime_type": "video/mp4", "data": base64.b64encode(dati).decode()}}))
PYEOF
} > "$R" 2>&1
git pull -q --rebase 2>/dev/null; git add "$R"; git commit -q -m "occhi-fb: $NOME"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
