#!/bin/bash
# OCCHI-FB — occhio Facebook del PC:
#   1) video/reel → scarica e fa GUARDARE a Gemini (parlato + testo a schermo)
#   2) --batch    → tanti URL in fila, UN rapporto riassuntivo (da file .txt o da argomenti)
#   3) --cataloga → pagina FB (non video): titolo/immagini/link/testo, SENZA aprire il browser
#
# SECONDO TENTATIVO: se un URL fallisce, si riprova UNA volta con strategia DIVERSA
# (mai lo stesso metodo): UA browser normale invece dello standard, download diretto,
# via inline forzata invece della File API. Se fallisce anche la riserva, si segnalano
# i due errori e si va avanti: niente terzo tentativo.
#
# Uso:
#   bash lavori/occhi_fb.sh "URL_VIDEO" [nome_rapporto]
#   bash lavori/occhi_fb.sh --batch lista.txt
#   bash lavori/occhi_fb.sh --batch "URL1" "URL2" ...
#   bash lavori/occhi_fb.sh --cataloga "URL_PAGINA"
#
# Chiavi: solo LETTURA, mai scritte. Ordine: variabili d'ambiente → ~/posta/.env (se c'è) →
#         ~/.posta_agenti.env (se c'è) → GEMINI_STUDIO in ~/CHIAVI_LOCALI.md (la via di sempre).

cd ~/posta || exit 1

uso() {
cat << 'USO'
OCCHI-FB — occhio Facebook del PC
  bash lavori/occhi_fb.sh "URL_VIDEO" [nome]      trascrive UN video/reel con Gemini (come prima)
  bash lavori/occhi_fb.sh --batch lista.txt       tanti URL (uno per riga, # = commento) → UN rapporto
  bash lavori/occhi_fb.sh --batch "URL1" "URL2"   idem, con gli URL direttamente da riga di comando
  bash lavori/occhi_fb.sh --cataloga "URL_PAGINA" cosa c'è in una pagina (titolo/immagini/link/testo)

Ogni URL ha DUE tentativi con strategie diverse (mai lo stesso metodo due volte):
il primo standard, il secondo di riserva (UA browser → download diretto → inline forzato).
Il riepilogo mostra entrambi: metodo + errore del 1°, metodo + esito del 2°.

Rapporti in: ~/posta/dal_pc/ (committati e spinti su git come sempre)
USO
}

# ---------- chiavi: SOLO LETTURA (il .env c'è già, non si tocca) ----------
[ -f "$HOME/posta/.env" ] && { set -a; . "$HOME/posta/.env" 2>/dev/null; set +a; }
[ -f "$HOME/.posta_agenti.env" ] && { set -a; . "$HOME/.posta_agenti.env" 2>/dev/null; set +a; }
# ---------- TERZA VIA (cucitura 14/11): whisper + vision quando Gemini tace ----------
via_casa() {  # $1 STATO
  local STATO="$1" FF GSK CFL t0 PARLATO
  echo
  echo "### 🏠 TERZA VIA — casa (Groq whisper + Cloudflare vision, niente Gemini)"
  t0=$SECONDS
  FF="$HOME/.hermes/tools/ffmpeg-9.0.1-linux-x64/bin/ffmpeg"
  [ -x "$FF" ] || FF=ffmpeg
  GSK=$(grep -oE 'gsk_[A-Za-z0-9_-]{20,}' ~/CHIAVI_LOCALI.md 2>/dev/null | head -1)
  CFL=$(grep -oE '[a-f0-9]{32}:[A-Za-z0-9_-]{20,}' ~/CHIAVI_LOCALI.md 2>/dev/null | head -1)
  if [ -z "$GSK" ]; then
    echo "G3|whisper|ko: chiave gsk_ mancante" >> "$STATO"
    echo "**PARLATO:** (chiave Groq mancante)"
  else
    "$FF" -y -loglevel error -i /tmp/occhi_video.mp4 -vn -ac 1 -ar 16000 -b:a 48k /tmp/occhi_audio.mp3 2>/dev/null
    PARLATO=$(curl -s --max-time 60 -X POST "https://api.groq.com/openai/v1/audio/transcriptions" \
      -H "Authorization: Bearer $GSK" \
      -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/157.0.0.0" \
      -F model=whisper-large-v3 -F language=it -F "file=@/tmp/occhi_audio.mp3" | \
      python3 -c "import json,sys; print(json.load(sys.stdin).get('text','')[:1200])" 2>/dev/null)
    echo "G3|whisper|ok" >> "$STATO"
    echo "**PARLATO (Groq whisper):** $PARLATO"
  fi
  if [ -z "$CFL" ]; then
    echo "G3|vision|ko: chiave Cloudflare mancante" >> "$STATO"
    return 0
  fi
  mkdir -p /tmp/occhi_frames
  "$FF" -y -loglevel error -i /tmp/occhi_video.mp4 -vf 'fps=1,scale=720:-2' /tmp/occhi_frames/f%02d.jpg 2>/dev/null
  echo "**SCRITE A SCHERMO (Cloudflare vision, frame per frame):**"
  python3 "$HOME/posta/lavori/vision_cf_frames.py" /tmp/occhi_frames "$CFL"
  echo "G3|vision|ok" >> "$STATO"
  echo "   (terza via in $((SECONDS - t0))s)"
  return 0
}

chiave_gemini() {
  local K="${GEMINI_API_KEY:-${GEMINI_STUDIO:-}}"
  [ -n "$K" ] || K=$(grep "^GEMINI_STUDIO=" ~/CHIAVI_LOCALI.md 2>/dev/null | head -1 | cut -d= -f2)
  [ -n "$K" ] || K=$(grep -i "Gemini Studio" ~/CHIAVI_LOCALI.md 2>/dev/null | grep -oE 'AQ\.[A-Za-z0-9_-]+' | head -1)   # 13/11: il vault riordinato tiene la chiave nel formato lista
  printf '%s' "$K"
}

# ---------- arsenale: yt-dlp + ffmpeg pronti (una volta per esecuzione) ----------
prepara_arsenale() {
  export PATH="$HOME/.local/bin:$PATH"
  command -v yt-dlp > /dev/null || pip install --user -q yt-dlp 2>&1 | tail -1
  yt-dlp -U 2>/dev/null | tail -1
  FF=$(command -v ffmpeg || echo "$HOME/.local/bin/ffmpeg")
  if [ ! -x "$FF" ]; then
    echo "   installo ffmpeg statico (una tantum)..."
    mkdir -p ~/.local/bin /tmp/ffst && cd /tmp/ffst
    curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz -o ff.tar.xz \
      && tar xf ff.tar.xz && cp ffmpeg-*-static/ffmpeg ~/.local/bin/ && chmod +x ~/.local/bin/ffmpeg \
      && echo "   ✓ ffmpeg pronto" || echo "   ffmpeg statico non scaricabile (si tira dritto)"
    cd ~/posta
    FF=$(command -v ffmpeg || echo "$HOME/.local/bin/ffmpeg")
  fi
}

pubblica() {
  local R="$1" MSG="$2"
  git add "$R"
  git commit -q -m "$MSG" 2>/dev/null
  # il repo a volte sta in detached HEAD (e il postino committa in parallelo):
  # si spinge HEAD:main (non main), e se il remoto è avanti si riaggancia SENZA
  # lasciare rebase a metà (mai operazioni che possano bloccare il repo)
  git push -q origin HEAD:main 2>/dev/null && return 0
  git fetch -q origin 2>/dev/null
  if ! git rebase -q origin/main 2>/dev/null; then
    git rebase --abort 2>/dev/null
  fi
  git push -q origin HEAD:main 2>/dev/null || echo "   (push rimandato: il commit resta locale, il postino lo raccoglierà)"
}

UA_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

# ---------- SCARICO video: due strategie VOLUTAMENTE diverse ----------
# T1: yt-dlp come da sempre (UA standard + cookie se servono)
scarico_std() {
  local URL="$1"
  rm -f "$V"
  if ! yt-dlp -q -f "w[ext=mp4][acodec!=none]/b[height<=360][ext=mp4]/w" --max-filesize 40M -o "$V" "$URL" 2>&1 | tail -2; then true; fi
  if [ ! -s "$V" ]; then
    echo "   pubblico no → provo coi cookie del BROWSER_AGENTI (Chromium :9222)"
    PROF=$(ls -d /mnt/c/Users/giopi/*Browser*Profile* /mnt/c/Users/giopi/AppData/Local/agenti/*rofile* 2>/dev/null | head -1)
    [ -n "$PROF" ] && yt-dlp -q --cookies-from-browser "chromium:$PROF" -f "best[height<=480][ext=mp4]/best" --max-filesize 40M -o "$V" "$URL" 2>&1 | tail -2
  fi
  [ -s "$V" ]
}

# T2 (riserva): a) yt-dlp con UA browser normale; b) download DIRETTO (yt-dlp -g + curl sul CDN)
scarico_riserva() {
  local URL="$1" STATO="$2" DURL
  rm -f "$V"
  echo "   riserva a) yt-dlp ma con lo UA normale del browser"
  if ! yt-dlp -q --user-agent "$UA_BROWSER" -f "b[ext=mp4]/b" --max-filesize 40M -o "$V" "$URL" 2>&1 | tail -2; then true; fi
  if [ -s "$V" ] && [ "$(stat -c%s "$V" 2>/dev/null || echo 0)" -gt 100000 ]; then
    echo "T2|scarico yt-dlp UA browser|ok ($(du -h "$V" | cut -f1))" >> "$STATO"
    return 0
  fi
  echo "T2|scarico yt-dlp UA browser|ko" >> "$STATO"
  echo "   riserva b) via diretta: yt-dlp -g risolve l'URL del CDN, curl scarica col browser"
  DURL=$(yt-dlp -g --user-agent "$UA_BROWSER" -f "b[acodec!=none][ext=mp4]/b[acodec!=none]/b" "$URL" 2>/dev/null | tail -1)
  if [ -n "$DURL" ] && curl -sL --max-time 180 -A "$UA_BROWSER" "$DURL" -o "$V" 2>/dev/null \
     && [ "$(stat -c%s "$V" 2>/dev/null || echo 0)" -gt 100000 ]; then
    echo "T2|scarico diretto (curl su URL CDN)|ok ($(du -h "$V" | cut -f1))" >> "$STATO"
    return 0
  fi
  echo "T2|scarico diretto (curl su URL CDN)|ko" >> "$STATO"
  return 1
}

# ---------- dieta per Gemini (T1 leggera; T2 con la FORTE se serve l'inline) ----------
metti_a_dieta() {
  local MOD="$1" DIM FF
  FF=$(command -v ffmpeg || echo "$HOME/.local/bin/ffmpeg")
  DIM=$(stat -c%s "$V" 2>/dev/null || echo 0)
  if [ "$DIM" -gt 4000000 ] && [ -x "$FF" ]; then
    echo "   dieta Gemini: 360p a 1.5fps (lui campiona a 1fps, non perde nulla)"
    "$FF" -y -loglevel error -i "$V" -vf scale=-2:360 -r 1.5 -b:v 120k -ac 1 -b:a 40k /tmp/occhi_s.mp4 \
      && mv /tmp/occhi_s.mp4 "$V" && echo "   → ora: $(du -h "$V" | cut -f1)"
  fi
  if [ "$MOD" = riserva ]; then
    DIM=$(stat -c%s "$V" 2>/dev/null || echo 0)
    if [ "$DIM" -gt 14000000 ] && [ -x "$FF" ]; then
      echo "   dieta FORTE da riserva: 240p a 1fps (la via inline vuole <14MB)"
      "$FF" -y -loglevel error -i "$V" -vf scale=-2:240 -r 1 -b:v 80k -ac 1 -b:a 24k /tmp/occhi_s.mp4 \
        && mv /tmp/occhi_s.mp4 "$V" && echo "   → ora: $(du -h "$V" | cut -f1)"
    fi
  fi
}

gemini_guarda() {  # $1 MOD (std|riserva)  $2 STATO
  local MOD="$1" STATO="$2" K VIA
  echo "### 2. Gemini guarda il video"
  K=$(chiave_gemini)
  if [ -z "$K" ]; then
    echo "❌ nessuna chiave Gemini trovata (vedi .env / CHIAVI_LOCALI.md)"
    { [ "$MOD" = std ] && echo "G1|gemini|ko: chiave mancante" || echo "G2|gemini|ko: chiave mancante"; } >> "$STATO"
    return 1
  fi
  VIA=auto
  [ "$MOD" = riserva ] && VIA=inline
python3 - "$V" "$K" "$VIA" "$STATO" << 'PYEOF' || via_casa "$STATO"
import base64, json, sys, time, urllib.request
video, chiave, via, stato = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
dati = open(video, "rb").read()
PROMPT = "Analizza questo video in ITALIANO: 1) trascrivi il parlato 2) riporta TUTTO il testo che appare a schermo (titoli, scritte, sottotitoli) 3) elenca nomi di strumenti/repo/siti/link citati 4) riassunto in 3 righe del contenuto utile."
BASE = "https://generativelanguage.googleapis.com"
TAG = "G1" if via == "auto" else "G2"   # G1 = primo tentativo, G2 = riserva

def nota(metodo, esito):
    try:
        with open(stato, "a") as f:
            f.write("%s|%s|%s\n" % (TAG, metodo, str(esito).replace("|", "/")[:90]))
    except Exception:
        pass

def genera(parte_video):
    corpo = json.dumps({"contents": [{"parts": [parte_video, {"text": PROMPT}]}]}).encode()
    req = urllib.request.Request(BASE + "/v1beta/models/gemini-3.8-flash:generateContent?key=" + chiave,
                                 data=corpo, headers={"Content-Type": "application/json"})
    d = json.loads(urllib.request.urlopen(req, timeout=int(os.environ.get("OCCHI_GEMINI_TIMEOUT", "600"))).read().decode())
    return d["candidates"][0]["content"]["parts"][0]["text"]

# VIA 1 (solo al primo tentativo): File API col protocollo resumable VERO
if via == "auto":
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
        nota("gemini FileAPI", "ok")
        sys.exit(0)
    except Exception as e:
        nota("gemini FileAPI", "ko: %s" % str(e)[:80])
        print("(File API ko: %s — provo la via inline)" % str(e)[:100])

# VIA 2: inline (fallback interno al T1; via FORZATA alla riserva)
if len(dati) > 14_000_000:
    nota("gemini inline", "ko: video %.1fMB oltre i 14MB della via inline" % (len(dati)/1e6))
    print("e il video resta troppo grosso per la via inline (%.1f MB). Mi fermo." % (len(dati)/1e6))
    sys.exit(1)
try:
    print(genera({"inline_data": {"mime_type": "video/mp4", "data": base64.b64encode(dati).decode()}}))
    nota("gemini inline", "ok")
except Exception as e:
    nota("gemini inline", "ko: %s" % str(e)[:80])
    print("inline ko: %s" % str(e)[:150])
    sys.exit(1)
sys.exit(0)
PYEOF
}

# ---------- GUARDA un video: T1 standard oppure T2 riserva ----------
# $1 URL   $2 MOD (std|riserva)   $3 STATO (file con le righe T/G|metodo|esito)
occhi_uno() {
  local URL="$1" MOD="${2:-std}" STATO="${3:-/dev/null}"
  export PATH="$HOME/.local/bin:$PATH"
  V=/tmp/occhi_video.mp4
  if [ "$MOD" = riserva ]; then
    echo
    echo "### ⛅ SECONDO TENTATIVO — riserva (strategia diversa, non lo stesso metodo)"
  fi
  if [ "$MOD" = std ]; then
    echo "### 1. Scarico (prima senza cookie: molti reel sono pubblici)"
    if scarico_std "$URL"; then
      echo "   ✓ scaricato: $(du -h "$V" | cut -f1)"
      echo "T1|scarico yt-dlp standard (+cookie se servono)|ok ($(du -h "$V" | cut -f1))" >> "$STATO"
    else
      echo "❌ SCARICAMENTO FALLITO col metodo standard (yt-dlp + cookie)"
      echo "T1|scarico yt-dlp standard (+cookie)|ko" >> "$STATO"
      return 1
    fi
  else
    if [ -s "$V" ]; then
      echo "   il video del 1° tentativo c'è già (era fallito su Gemini) → niente nuovo scarico"
      echo "T2|scarico|salto: file già presente dal 1° tentativo" >> "$STATO"
    else
      echo "### 1. Scarico con la via di riserva"
      if scarico_riserva "$URL" "$STATO"; then
        echo "   ✓ scaricato: $(du -h "$V" | cut -f1)"
      else
        echo "❌ RISERVA: scarico fallito anche con UA browser e via diretta"
        return 1
      fi
    fi
  fi
  metti_a_dieta "$MOD"
  gemini_guarda "$MOD" "$STATO"
}

# ---------- BATCH: tanti URL, UN rapporto, DUE tentativi ciascuno ----------
fa_batch() {
  local PRIMO="$1"; shift
  local -a URLS=()
  if [ -f "$PRIMO" ]; then
    mapfile -t URLS < <(grep -vE '^[[:space:]]*(#|$)' "$PRIMO" | tr -d '\r')
  else
    URLS=("$PRIMO" "$@")
  fi
  local N=${#URLS[@]}
  if [ "$N" -eq 0 ]; then echo "❌ nessun URL trovato (file vuoto o solo commenti?)" >&2; return 1; fi
  local R="dal_pc/occhi_batch_$(date '+%d%m_%H%M').md"
  echo "▶ BATCH: $N URL in coda → $R" >&2
  rm -f /tmp/occhi_tab.tmp
  {
    echo "# 👁 OCCHI-FB BATCH — $(date '+%d/%m/%Y %H:%M')"
    echo "URL in coda: $N — sorgente: $PRIMO"
  } > "$R"
  local OK=0 KO=0 RIS=0 i=0 t0 d esito U STATO riga
  STATO=/tmp/occhi_stato_$$.txt
  for U in "${URLS[@]}"; do
    i=$((i+1))
    echo "▶ [$i/$N] $U" >&2
    {
      echo
      echo "---"
      echo
      echo "## ▶ URL $i/$N — $U"
    } >> "$R"
    rm -f "$STATO"
    t0=$SECONDS
    if occhi_uno "$U" std "$STATO" >> "$R" 2>&1; then
      esito="✓ ok"; OK=$((OK+1))
    else
      # SECONDO TENTATIVO: strategia DIVERSA (mai lo stesso metodo) — e poi basta, niente terzo
      if occhi_uno "$U" riserva "$STATO" >> "$R" 2>&1; then
        esito="✓ riserva"; OK=$((OK+1)); RIS=$((RIS+1))
      else
        esito="❌"; KO=$((KO+1))
      fi
    fi
    d=$((SECONDS - t0))
    riga=""
    if [ -s "$STATO" ]; then
      while IFS='|' read -r t m e; do
        [ -n "$riga" ] && riga="$riga → "
        riga="$riga$t $m: $e"
      done < "$STATO"
    fi
    [ -n "$riga" ] || riga="(nessun dettaglio)"
    riga="${riga:0:280}"
    echo "| $i | $U | $esito | ${d}s | $riga |" >> /tmp/occhi_tab.tmp
    echo "   → $esito (${d}s)" >&2
  done
  {
    echo
    echo "## 📊 Riepilogo"
    echo "| # | URL | esito | tempo | tentativi (metodo: esito) |"
    echo "|---|-----|-------|-------|---------------------------|"
    cat /tmp/occhi_tab.tmp
    rm -f /tmp/occhi_tab.tmp
    echo
    echo "**Bilancio: ✓ $OK su $N riusciti** (salvati dalla riserva: $RIS — ❌ falliti: $KO, dopo 2 tentativi, niente terzo)"
  } >> "$R"
  pubblica "$R" "occhi-fb batch: $N url (ok $OK, ko $KO, riserva $RIS)"
  echo "✅ rapporto: ~/posta/$R (✓ $OK, ❌ $KO, riserva $RIS)" >&2
}

# ---------- CATALOGA: pagina FB senza browser, con riserva UA browser ----------
fa_cataloga() {
  local URL="$1"
  case "$URL" in http://*|https://*) ;; *) URL="https://$URL" ;; esac
  case "$URL" in
    */reel/*|*"/watch"*|*"/videos/"*) echo "⚠ sembra un VIDEO: per la trascrizione usa occhi_fb.sh senza --cataloga" >&2 ;;
  esac
  local SLUG
  SLUG=$(printf '%s' "$URL" | sed -E 's#https?://(www\.|mbasic\.|m\.)?facebook\.com/##; s#[/?&=]+#_#g; s#[^a-zA-Z0-9._-]#_#g; s#_+#_#g; s#^_##; s#_$##' | cut -c1-40)
  [ -n "$SLUG" ] || SLUG=pagina
  local R="dal_pc/catalogo_${SLUG}.md"
  echo "▶ CATALOGA $URL → $R" >&2
python3 - "$URL" "$R" << 'PYEOF'
import html, re, sys, urllib.parse, urllib.request
from datetime import datetime

url, out = sys.argv[1], sys.argv[2]
UA_CAT = "facebookcatalog/1.0"   # T1: il crawler-catalogo di FB (risponde coi meta og senza login)
UA_BRW = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"  # T2: UA normale del browser

def prendi(u, ua, t=25):
    req = urllib.request.Request(u, headers={"User-Agent": ua, "Accept-Language": "it_IT,it;q=0.9,en;q=0.8"})
    return urllib.request.urlopen(req, timeout=t).read().decode("utf-8", "ignore")

def parsi_og(h):
    og = {}
    for m in re.findall(r'<meta[^>]+property="(og:[^"]+)"[^>]*content="([^"]*)"', h):
        og.setdefault(m[0], html.unescape(m[1]))
    for m in re.findall(r'<meta[^>]+content="([^"]*)"[^>]*property="(og:[^"]+)"', h):
        og.setdefault(m[1], html.unescape(m[0]))
    return og

og, pagina, via = {}, "", ""
note = []   # (tentativo, metodo, esito)

# T1: UA facebookcatalog
try:
    pagina = prendi(url, UA_CAT)
    og = parsi_og(pagina)
    if "og:title" in og:
        note.append(("T1", "UA facebookcatalog", "ok"))
        via = "%s (UA facebookcatalog)" % url
    else:
        note.append(("T1", "UA facebookcatalog", "ko: risposta senza og-tag"))
        pagina = ""
except Exception as e:
    note.append(("T1", "UA facebookcatalog", "ko: %s" % str(e)[:70]))

# T2 (solo se T1 non ha dato nulla): UA normale del browser, vie diverse (mbasic, poi www)
if "og:title" not in og:
    for u in [url.replace("www.facebook.com", "mbasic.facebook.com"), url]:
        try:
            pagina = prendi(u, UA_BRW)
            og = parsi_og(pagina)
            if "og:title" in og:
                note.append(("T2", "UA browser normale", "ok (%s)" % urllib.parse.urlparse(u).netloc))
                via = "%s (UA browser normale)" % u
                break
            note.append(("T2", "UA browser normale", "ko: risposta senza og-tag (%s)" % urllib.parse.urlparse(u).netloc))
            pagina = ""
        except Exception as e:
            note.append(("T2", "UA browser normale", "ko: %s" % str(e)[:70]))

plug_testo, plug_img = "", ""
try:
    u_plug = "https://www.facebook.com/plugins/page.php?href=" + urllib.parse.quote(url, safe="")
    h2 = prendi(u_plug, UA_BRW)
    t = re.sub(r"<script.*?</script>", " ", h2, flags=re.S)
    t = re.sub(r"<style.*?</style>", " ", t, flags=re.S)
    t = re.sub(r"<[^>]+>", " ", t)
    plug_testo = html.unescape(re.sub(r"\s+", " ", t)).strip()
    m = re.search(r'<img[^>]+src="([^"]+)"', h2)
    if m:
        plug_img = m.group(1)
except Exception:
    pass

# --- immagini: og:image + foto profilo del plugin + qualunque scontent nel HTML ---
imgs = []
for x in [og.get("og:image"), plug_img]:
    x = html.unescape(x) if x else x
    if x and x not in imgs:
        imgs.append(x)
for u in re.findall(r'https:\\?/\\?/scontent[^"\'\\ <>]+', pagina):
    u = html.unescape(u.replace("\\/", "/"))
    # scarta i domini nudi (stringhe troncate nel JS) e i duplicati
    if len(u) > 60 and not u.rstrip("/").endswith("fbcdn.net") and u not in imgs:
        imgs.append(u)
imgs = imgs[:10]

# --- link: canonico/og + esterni veri (non facebook/fbcdn/static/w3/schema) ---
links = []
if og.get("og:url"):
    links.append(("canonico", og["og:url"]))
for u in re.findall(r'https?://(?![^"\' <>]*?(?:facebook\.com|fbcdn\.net|fb\.com|static\.xx|w3\.org|schema\.org))[^"\'\\ <>]{10,200}', pagina):
    u = html.unescape(u.replace("&amp;", "&"))
    if not any(u == l for _, l in links):
        links.append(("esterno", u))
links = links[:15]
if og.get("og:video"):
    links.insert(0, ("video", og["og:video"]))

titolo = og.get("og:title") or "(non trovato)"
desc = og.get("og:description") or ""
L = []
L.append("# 📇 CATALOGO FB — %s" % titolo[:80])
L.append("")
L.append("- **URL:** %s" % url)
L.append("- **Quando:** %s" % datetime.now().strftime("%d/%m/%Y %H:%M"))
L.append("- **Tentativi:** %s" % " → ".join("%s %s: %s" % n for n in note))
L.append("- **Via:** %s" % (via or "NESSUNA (entrambi i tentativi senza dati)"))
if og.get("og:type"):
    L.append("- **Tipo:** %s" % og["og:type"])
if og.get("og:locale"):
    L.append("- **Lingua:** %s" % og["og:locale"])
L.append("")
L.append("## 🏷 Titolo")
L.append(titolo)
L.append("")
L.append("## 📝 Testo trovato")
if desc:
    L.append("**Descrizione (og):** %s" % desc)
if plug_testo:
    L.append("")
    L.append("**Dal plugin pagina:** %s" % plug_testo[:800])
if not desc and not plug_testo:
    L.append("(il testo visibile non è accessibile senza login)")
L.append("")
L.append("## 🖼 Immagini (%d)" % len(imgs))
for i, u in enumerate(imgs, 1):
    L.append("%d. %s" % (i, u))
if not imgs:
    L.append("(nessuna)")
L.append("")
L.append("## 🔗 Link (%d)" % len(links))
for t_, u in links:
    L.append("- **%s:** %s" % (t_, u))
if not links:
    L.append("(nessuno)")
L.append("")
L.append("---")
L.append("*Senza login Facebook mostra solo la scheda pubblica (meta og + plugin pagina): i singoli post richiedono l'accesso.*")
L.append("*Due tentativi con vie diverse (T1 facebookcatalog, T2 UA browser); se entrambi falliscono, qui sopra ci sono i due errori — niente terzo tentativo.*")
open(out, "w", encoding="utf-8").write("\n".join(L) + "\n")
print("ok: %s" % out)
PYEOF
  local ST=$?
  if [ $ST -eq 0 ] && [ -s "$R" ]; then
    pubblica "$R" "occhi-fb catalogo: $SLUG"
    echo
    cat "$R"
  else
    echo "❌ catalogo non riuscito per $URL" >&2
  fi
  return $ST
}

# ---------- SMISTAMENTO ----------
case "${1:-}" in
  --batch|-b)
    shift
    [ $# -ge 1 ] || { uso; exit 1; }
    prepara_arsenale >&2
    fa_batch "$@"
    ;;
  --cataloga|-c)
    shift
    [ $# -ge 1 ] || { uso; exit 1; }
    fa_cataloga "$1"
    ;;
  --aiuto|-h|help)
    uso
    ;;
  "")
    uso
    ;;
  *)
    # come prima: UN video (con la scala di riserva)
    URL="$1"
    NOME="${2:-occhi_fb}"
    R="dal_pc/${NOME}.md"
    STATO=/tmp/occhi_stato_$$.txt
    {
      echo "# 👁 OCCHI-FB — $(date '+%d/%m %H:%M')"
      echo "URL: $URL"
      echo
      prepara_arsenale
      echo
      if ! occhi_uno "$URL" std "$STATO"; then
        occhi_uno "$URL" riserva "$STATO" || true
      fi
      rm -f "$STATO"
    } > "$R" 2>&1
    pubblica "$R" "occhi-fb: $NOME"
    ;;
esac
