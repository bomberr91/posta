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
if ! yt-dlp -q -f "best[height<=480][ext=mp4]/best[ext=mp4]/best" --max-filesize 40M -o "$V" "$URL" 2>&1 | tail -2; then true; fi
if [ ! -s "$V" ]; then
  echo "   pubblico no → provo coi cookie del BROWSER_AGENTI (Chromium :9222)"
  PROF=$(ls -d /mnt/c/Users/giopi/*Browser*Profile* /mnt/c/Users/giopi/AppData/Local/agenti/*rofile* 2>/dev/null | head -1)
  [ -n "$PROF" ] && yt-dlp -q --cookies-from-browser "chromium:$PROF" -f "best[height<=480][ext=mp4]/best" --max-filesize 40M -o "$V" "$URL" 2>&1 | tail -2
fi
if [ ! -s "$V" ]; then echo "❌ SCARICAMENTO FALLITO (serve forse la via-screenshot)"; exit 0; fi
echo "   ✓ scaricato: $(du -h "$V" | cut -f1)"
echo
echo "## 2. Gemini guarda il video"
K=$(python3 chiave_di.py gemini 2>/dev/null)
python3 - "$V" "$K" << 'PYEOF'
import base64, json, sys, urllib.request
video, chiave = sys.argv[1], sys.argv[2]
dati = open(video, "rb").read()
if len(dati) > 14_000_000:
    print("video troppo grosso per la via inline (%.1f MB): serve il formato piu' leggero" % (len(dati)/1e6))
    sys.exit(0)
corpo = json.dumps({"contents": [{"parts": [
    {"inline_data": {"mime_type": "video/mp4", "data": base64.b64encode(dati).decode()}},
    {"text": "Analizza questo video in ITALIANO: 1) trascrivi il parlato 2) riporta TUTTO il testo che appare a schermo (titoli, scritte, sottotitoli) 3) elenca nomi di strumenti/repo/siti/link citati 4) riassunto in 3 righe del contenuto utile."}]}]}).encode()
req = urllib.request.Request(
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" + chiave,
    data=corpo, headers={"Content-Type": "application/json"})
try:
    d = json.loads(urllib.request.urlopen(req, timeout=600).read().decode())
    print(d["candidates"][0]["content"]["parts"][0]["text"])
except urllib.error.HTTPError as e:
    print("Gemini dice", e.code, ":", e.read(300).decode(errors="replace"))
PYEOF
} > "$R" 2>&1
git pull -q --rebase 2>/dev/null; git add "$R"; git commit -q -m "occhi-fb: $NOME"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
