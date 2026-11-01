# 👁 OCCHI-FB BATCH — 01/11/2026 22:42
URL in coda: 1 — sorgente: https://www.facebook.com/reel/000000000000001

---

## ▶ URL 1/1 — https://www.facebook.com/reel/000000000000001
### 1. Scarico (prima senza cookie: molti reel sono pubblici)
ERROR: [facebook] 000000000000001: Unable to download webpage: HTTP Error 404: Not Found (caused by <HTTPError 404: Not Found>)
   pubblico no → provo coi cookie del BROWSER_AGENTI (Chromium :9222)
❌ SCARICAMENTO FALLITO col metodo standard (yt-dlp + cookie)

### ⛅ SECONDO TENTATIVO — riserva (strategia diversa, non lo stesso metodo)
### 1. Scarico con la via di riserva
   riserva a) yt-dlp ma con lo UA normale del browser
ERROR: [facebook] 000000000000001: Unable to download webpage: HTTP Error 404: Not Found (caused by <HTTPError 404: Not Found>)
   riserva b) via diretta: yt-dlp -g risolve l'URL del CDN, curl scarica col browser
❌ RISERVA: scarico fallito anche con UA browser e via diretta

## 📊 Riepilogo
| # | URL | esito | tempo | tentativi (metodo: esito) |
|---|-----|-------|-------|---------------------------|
| 1 | https://www.facebook.com/reel/000000000000001 | ❌ | 8s | T1 scarico yt-dlp standard (+cookie): ko → T2 scarico yt-dlp UA browser: ko → T2 scarico diretto (curl su URL CDN): ko |

**Bilancio: ✓ 0 su 1 riusciti** (salvati dalla riserva: 0 — ❌ falliti: 1, dopo 2 tentativi, niente terzo)
