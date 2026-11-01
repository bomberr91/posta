# 👁 OCCHI-FB BATCH — 01/11/2026 22:46
URL in coda: 1 — sorgente: /tmp/shim_test/lista1.txt

---

## ▶ URL 1/1 — https://www.facebook.com/reel/1195289147628387
### 1. Scarico (prima senza cookie: molti reel sono pubblici)
shim-test: chiamata yt-dlp n.2 fatta FALLIRE di proposito
   pubblico no → provo coi cookie del BROWSER_AGENTI (Chromium :9222)
❌ SCARICAMENTO FALLITO col metodo standard (yt-dlp + cookie)

### ⛅ SECONDO TENTATIVO — riserva (strategia diversa, non lo stesso metodo)
### 1. Scarico con la via di riserva
   riserva a) yt-dlp ma con lo UA normale del browser
shim-test: chiamata yt-dlp n.3 fatta FALLIRE di proposito
   riserva b) via diretta: yt-dlp -g risolve l'URL del CDN, curl scarica col browser
   ✓ scaricato: 640K
### 2. Gemini guarda il video
inline ko: HTTP Error 503: Service Unavailable

## 📊 Riepilogo
| # | URL | esito | tempo | tentativi (metodo: esito) |
|---|-----|-------|-------|---------------------------|
| 1 | https://www.facebook.com/reel/1195289147628387 | ❌ | 16s | T1 scarico yt-dlp standard (+cookie): ko → T2 scarico yt-dlp UA browser: ko → T2 scarico diretto (curl su URL CDN): ok (640K) → G2 gemini inline: ko: HTTP Error 503: Service Unavailable |

**Bilancio: ✓ 0 su 1 riusciti** (salvati dalla riserva: 0 — ❌ falliti: 1, dopo 2 tentativi, niente terzo)
