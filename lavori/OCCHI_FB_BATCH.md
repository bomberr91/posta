# OCCHI_FB_BATCH — cosa ho fatto

**Dove:** `~/posta/lavori/occhi_fb.sh` su WSL (backup del vecchio in `/tmp/occhi_fb_backup_0111.sh` e nella cronistica git).
**Quando:** 1/11/2026 sera. **Chiavi: nessuna toccata** — solo lettura.

## Cosa c'era prima

`occhi_fb.sh` accettava UN solo URL video: scaricava con yt-dlp (prima pubblico, poi coi
cookie del Chromium BROWSER_AGENTI), lo metteva a dieta con ffmpeg (360p @ 1.5fps) e lo
faceva guardare a Gemini (File API resumable, fallback inline), salvando in `dal_pc/*.md`
con commit+push su `bomberr91/posta`.

Tutta questa pipeline resta **identica** per il video singolo: `bash lavori/occhi_fb.sh "URL" [nome]` funziona ancora come prima.

## Cosa ho aggiunto

### 1. `--batch` — tanti URL, un solo rapporto

```bash
bash lavori/occhi_fb.sh --batch lista.txt        # file .txt: un URL per riga, # = commento
bash lavori/occhi_fb.sh --batch "URL1" "URL2"    # oppure gli URL direttamente
```

- Lavora gli URL **in sequenza**: per ognuno ripete la pipeline storica (scarico → dieta → Gemini).
- Scrive **un solo rapporto**: `dal_pc/occhi_batch_<ggmm_HHMM>.md`, con una sezione per URL
  (scarico + trascrizione) e in fondo la **tabella di riepilogo** (✓/✗ + tempo) e il bilancio.
- Un URL fallito **non ferma la coda**: viene segnato ❌ nel riepilogo e si va avanti.
- I file .txt creati da Windows (CRLF) sono gestiti; righe vuote e commenti ignorati.
- Commit+push **uno solo** alla fine, messaggio tipo `occhi-fb batch: 2 url (ok 2, ko 0)`.

### 2. `--cataloga` — pagina FB senza aprire il browser

```bash
bash lavori/occhi_fb.sh --cataloga https://www.facebook.com/NASA
```

- Solo `python3` stdlib + HTTP: niente yt-dlp, niente Chromium, niente chiavi.
- Due vie senza login, unite nel rapporto `dal_pc/catalogo_<slug>.md` (stampato anche a video):
  - **meta og-tag** con UA `facebookcatalog/1.0` (il crawler-catalogo di FB risponde 200 col
    titolo, la descrizione con follower e intro, l'immagine, l'URL canonico; fallback su mbasic);
  - **plugin pagina** (`/plugins/page.php`) → nome pagina, follower, foto profilo, link canonico.
- Estrae: titolo, testo trovato (og:description + testo del plugin), immagini (og:image + foto
  profilo + scontent nel HTML, scartando domini troncati), link (canonico + esterni veri,
  scartando namespace tipo w3.org).
- Se l'URL sembra un video (reel/watch/videos) avvisa: per quello c'è la modalità normale.
- **Limite onesto** (scritto anche nel rapporto): senza login FB mostra solo la scheda pubblica;
  i singoli post richiedono l'accesso.

### 3. Robustezza git

Sul repo gira in parallelo il "postino" (commit periodici) e il repo a volte sta in **detached HEAD**:
il vecchio `git pull --rebase` + `git push origin main` falliva. Ora `pubblica` spinge
`HEAD:main`, e se il remoto è avanti si riaggancia senza mai lasciare un rebase a metà
(se il push non passa, il commit resta locale e il postino lo raccoglie comunque — verificato).

## Chiavi (sola lettura)

Ordine di lettura, nessuna scritta o modificata:
1. variabili d'ambiente (`GEMINI_API_KEY` / `GEMINI_STUDIO`);
2. `~/posta/.env` se esiste;
3. `~/.posta_agenti.env` se esiste (quello che c'è già);
4. `GEMINI_STUDIO=` in `~/CHIAVI_LOCALI.md` — la via di sempre, che è quella usata nei collaudi.

## Collaudi veri (1/11/2026 sera)

| Test | Comando | Esito |
|---|---|---|
| Batch da file, 2 reel pubblici | `--batch lista.txt` | **✓ 2 su 2** (99s + 120s), rapporto `dal_pc/occhi_batch_0111_2203.md`, push ok (commit `2be4644`) |
| Catalogo pagina | `--cataloga https://www.facebook.com/NASA` | ✓ titolo, intro+follower (28,7M), 2 immagini, link canonico → `dal_pc/catalogo_NASA.md` |
| Batch da argomenti + via degli errori | `--batch <URL inesistente>` | ✓ ❌ segnalato in 3s, riepilogo 0/1, rapporto regolare |

Reel usati nella lista di prova (`~/posta/lista.txt`):
- `https://www.facebook.com/reel/1350782990582563` — Humans of New York (100s): trascrizione integrale + sottotitoli a schermo + riassunto;
- `https://www.facebook.com/reel/1195289147628387` — Beast Camp Training (10s).

Nota dal collaudo: un reel fallì una volta per un errore transitorio (e la File API di Gemini
ha dato 503 una volta: il fallback inline della pipeline storica lo ha assorbito da solo).

## Insidie incontrate (per chi rilegge dopo)

- Il "postino" committa l'intero albero ogni ~1-2 minuti: può fotografare un rapporto a metà
  scrittura e il file può comparire/sparire per un attimo durante i suoi rebase. I rapporti
  finiti sono sempre integri (eventualmente li spinge lui).
- Il repo è stato trovato in **detached HEAD** e a metà di un rebase interattivo lasciato da
  un altro agente: non ho toccato quel rebase; script e lista sono comunque arrivati su
  origin/main tramite le sue istantanee (verificato identici).
- Da cmd.exe, lanciare WSL con `wsl -e bash -lc "..."`: apici singoli e `%`/`$` sfuggiti
  rompono PATH e pipe. Per script lunghi: scrivere il file e copiarlo via `/mnt/c/`.
