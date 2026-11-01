#!/bin/bash
# OCCHI-FB — occhio Facebook del PC:
#   1) video/reel → scarica e fa GUARDARE a Gemini (parlato + testo a schermo)
#   2) --batch    → tanti URL in fila, UN rapporto riassuntivo (da file .txt o da argomenti)
#   3) --cataloga → pagina FB (non video): titolo/immagini/link/testo, SENZA aprire il browser
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

Rapporti in: ~/posta/dal_pc/ (committati e spinti su git come sempre)
USO
}

# ---------- chiavi: SOLO LETTURA (il .env c'è già, non si tocca) ----------
[ -f "$HOME/posta/.env" ] && { set -a; . "$HOME/posta/.env" 2>/dev/null; set +a; }
[ -f "$HOME/.posta_agenti.env" ] && { set -a; . "$HOME/.posta_agenti.env" 2>/dev/null; set +a; }
chiave_gemini() {
  local K="${GEMINI_API_KEY:-${GEMINI_STUDIO:-}}"
  [ -n "$K" ] || K=$(grep "^GEMINI_STUDIO=" ~/CHIAVI_LOCALI.md 2>/dev/null | head -1 | cut -d= -f2)
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

# ---------- GUARDA un video: pipeline storica (stampa il suo pezzo di rapporto) ----------
occhi_uno() {
  local URL="$1"
  export PATH="$HOME/.local/bin:$PATH"
  V=/tmp/occhi_video.mp4
  rm -f "$V"
  echo "### 1. Scarico (prima senza cookie: molti reel sono pubblici)"
  if ! yt-dlp -q -f "w[ext=mp4][acodec!=none]/b[height<=360][ext=mp4]/w" --max-filesize 40M -o "$V" "$URL" 2>&1 | tail -2; then true; fi
  if [ ! -s "$V" ]; then
    echo "   pubblico no → provo coi cookie del BROWSER_AGENTI (Chromium :9222)"
    PROF=$(ls -d /mnt/c/Users/giopi/*Browser*Profile* /mnt/c/Users/giopi/AppData/Local/agenti/*rofile* 2>/dev/null | head -1)
    [ -n "$PROF" ] && yt-dlp -q --cookies-from-browser "chromium:$PROF" -f "best[height<=480][ext=mp4]/best" --max-filesize 40M -o "$V" "$URL" 2>&1 | tail -2
  fi
  if [ ! -s "$V" ]; then echo "❌ SCARICAMENTO FALLITO (serve forse la via-screenshot)"; return 1; fi
  echo "   ✓ scaricato: $(du -h "$V" | cut -f1)"
  local FF=$(command -v ffmpeg || echo "$HOME/.local/bin/ffmpeg")
  DIM=$(stat -c%s "$V")
  if [ "$DIM" -gt 4000000 ] && [ -x "$FF" ]; then
    echo "   dieta Gemini: 360p a 1.5fps (lui campiona a 1fps, non perde nulla)"
    "$FF" -y -loglevel error -i "$V" -vf scale=-2:360 -r 1.5 -b:v 120k -ac 1 -b:a 40k /tmp/occhi_s.mp4 \
      && mv /tmp/occhi_s.mp4 "$V" && echo "   → ora: $(du -h "$V" | cut -f1)"
  fi
  echo
  echo "### 2. Gemini guarda il video"
  local K
  K=$(chiave_gemini)
  if [ -z "$K" ]; then echo "❌ nessuna chiave Gemini trovata (vedi .env / CHIAVI_LOCALI.md)"; return 1; fi
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
}

# ---------- BATCH: tanti URL, UN rapporto ----------
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
  local OK=0 KO=0 i=0 t0 d esito U
  for U in "${URLS[@]}"; do
    i=$((i+1))
    echo "▶ [$i/$N] $U" >&2
    {
      echo
      echo "---"
      echo
      echo "## ▶ URL $i/$N — $U"
    } >> "$R"
    t0=$SECONDS
    if occhi_uno "$U" >> "$R" 2>&1; then OK=$((OK+1)); esito="✓ ok"; else KO=$((KO+1)); esito="❌ ko"; fi
    d=$((SECONDS - t0))
    echo "| $i | $U | $esito | ${d}s |" >> /tmp/occhi_tab.tmp
    echo "   → $esito (${d}s)" >&2
  done
  {
    echo
    echo "## 📊 Riepilogo"
    echo "| # | URL | esito | tempo |"
    echo "|---|-----|-------|-------|"
    cat /tmp/occhi_tab.tmp
    rm -f /tmp/occhi_tab.tmp
    echo
    echo "**Bilancio: ✓ $OK su $N riusciti** (❌ $KO falliti)"
  } >> "$R"
  pubblica "$R" "occhi-fb batch: $N url (ok $OK, ko $KO)"
  echo "✅ rapporto: ~/posta/$R (✓ $OK, ❌ $KO)" >&2
}

# ---------- CATALOGA: pagina FB senza browser ----------
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
UA_CAT = "facebookcatalog/1.0"   # il crawler-catalogo di FB: risponde coi meta og SENZA login
UA_BRW = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

def prendi(u, ua, t=25):
    req = urllib.request.Request(u, headers={"User-Agent": ua, "Accept-Language": "it_IT,it;q=0.9,en;q=0.8"})
    return urllib.request.urlopen(req, timeout=t).read().decode("utf-8", "ignore")

og, pagina, via = {}, "", ""
for u, ua in [(url, UA_CAT), (url.replace("www.facebook.com", "mbasic.facebook.com"), UA_BRW)]:
    try:
        pagina = prendi(u, ua)
    except Exception:
        continue
    via = "%s (UA %s)" % (u, ua)
    for m in re.findall(r'<meta[^>]+property="(og:[^"]+)"[^>]*content="([^"]*)"', pagina):
        og.setdefault(m[0], html.unescape(m[1]))
    for m in re.findall(r'<meta[^>]+content="([^"]*)"[^>]*property="(og:[^"]+)"', pagina):
        og.setdefault(m[1], html.unescape(m[0]))
    if "og:title" in og:
        break

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
L.append("- **Via:** %s" % (via or "nessuna risposta utile"))
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
    # come prima: UN video
    URL="$1"
    NOME="${2:-occhi_fb}"
    R="dal_pc/${NOME}.md"
    {
      echo "# 👁 OCCHI-FB — $(date '+%d/%m %H:%M')"
      echo "URL: $URL"
      echo
      prepara_arsenale
      echo
      occhi_uno "$URL"
    } > "$R" 2>&1
    pubblica "$R" "occhi-fb: $NOME"
    ;;
esac
