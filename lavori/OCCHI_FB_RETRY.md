# OCCHI_FB_RETRY — il secondo tentativo (riserva con strategia diversa)

**Dove:** `~/posta/lavori/occhi_fb.sh` su WSL (backup v2 in `/tmp/occhi_fb_backup_v2_0111.sh`).
**Quando:** 1/11/2026 notte. **Chiavi: nessuna toccata** (stessa lettura di prima: `.env` se c'è → `~/.posta_agenti.env` → `GEMINI_STUDIO` in `~/CHIAVI_LOCALI.md`).

## La regola implementata

Ogni URL ha **DUE tentativi con strategie VOLUTAMENTE diverse** — mai lo stesso metodo due volte:

**T1 — tentativo standard** (come da sempre)
- scarico: yt-dlp con UA standard, poi cookie del Chromium se servono
- Gemini: File API resumable, con fallback inline interno (comportamento storico)

**T2 — riserva** (solo se il T1 fallisce; approccio cambiato, non rilanciato)
- se il video del T1 c'è già (il T1 era fallito su Gemini) → **niente nuovo scarico**
- altrimenti scarico con vie nuove: **a)** yt-dlp ma con **UA browser normale**, poi **b)** **download diretto** (`yt-dlp -g` risolve l'URL del CDN, `curl` scarica col browser, minimo 100KB per scartare pagine d'errore)
- Gemini: **via inline FORZATA** (la File API non viene mai ripetuta) + **dieta forte** (240p @ 1fps) se il file supera i 14MB dell'inline

**Se fallisce anche il T2** → i due errori compaiono nel riepilogo e si va avanti: **niente terzo tentativo**.

**--cataloga** ha la sua scala: T1 = UA `facebookcatalog/1.0`, T2 = **UA browser normale** (mbasic, poi www). Gli errori di entrambi finiscono nella riga "Tentativi" del rapporto.

## Il riepilogo mostra i due tentativi

La tabella finale del batch ha la colonna **"tentativi (metodo: esito)"** con ogni evento in fila:
`T1 scarico yt-dlp standard: ko → T2 scarico diretto (curl su URL CDN): ok (640K) → G2 gemini inline: ko: 503`.
La colonna esito distingue `✓ ok` (T1), `✓ riserva` (salvato dal T2), `❌` (entrambi). Il bilancio dice quante volte la riserva ha salvato: "**salvati dalla riserva: N**".

## Come è fatto (per chi rilegge)

- `scarico_std` / `scarico_riserva` — le due strategie di scarico, volutamente diverse
- `metti_a_dieta [std|riserva]` — 360p @1.5fps al T1; in più 240p @1fps alla riserva se >14MB
- `gemini_guarda [std|riserva]` — il python prende una via (`auto` = File API→inline, `inline` = solo inline) e scrive in un **file STATO** le righe `T1/T2|metodo|esito` che finiscono nel riepilogo; esce 1 solo se TUTTE le sue vie falliscono (prima usciva sempre 0)
- `occhi_uno URL [std|riserva] STATO` — una corsa della pipeline; `fa_batch` chiama std e, se ko, riserva una volta sola
- exit code onesti: un URL è ❌ solo se hanno fallito entrambe le strategie

## Collaudi veri (1/11/2026, 22:39–22:50)

| # | Prova | Esito |
|---|---|---|
| 1 | `--batch lista.txt`, 2 reel reali | **✓ 2 su 2** via T1 (80s+87s), File API ok per entrambi → nessuna regressione. Riepilogo: `dal_pc/occhi_batch_0111_2239.md` |
| 2 | `--batch` con URL inesistente | ❌ con **entrambi i tentativi** nel riepilogo: `T1 ko → T2 UA browser: ko (404) → T2 diretto: ko` — 8s, niente terzo tentativo |
| 3 | Prova unitaria della scala T2 sul reel reale (Beast Camp, 10s) | **tutte e tre le vie ok**: UA browser 622KB ✓, diretta CDN+curl 622KB ✓, inline forzata ✓ con trascrizione e riga `G2\|gemini inline\|ok` |
| 4 | Iniezione guasto (shim temporaneo che fa fallire le chiamate yt-dlp del T1) ×3 giri | **la riserva ha davvero lavorato**: in tutti i giri `T2 scarico diretto (curl su URL CDN): ok (640K)` — il video è stato salvato dalla via diretta; poi l'**inline di Gemini dava un 503 REALE** (transitorio, il servizio lo fa stasera: alle 22:39 rispondeva) → ❌ con i due errori esatti nel riepilogo e stop senza terzo tentativo |
| 5 | `--cataloga` pagina NASA (regressione) | ✓ T1 `UA facebookcatalog: ok`, riga Tentativi nel rapporto |
| 6 | `--cataloga` pagina inesistente | ✓ entrambi i tentativi falliti riportati: `T1 ko: risposta senza og-tag → T2 ko: HTTP 400` ×2 vie, "NESSUNA (entrambi i tentativi senza dati)" |

Nota onesta sul punto 4: il caso "✓ riserva" (T1 ko → T2 tutto ok) non si è verificato in un batch
completo solo perché stasera l'endpoint inline di Gemini dava 503 in quei minuti (la via diretta
ha salvato il download tutte le volte); ogni pezzo della scala T2 è comunque validato singolarmente
sul reel vero (punto 3) e il caso "❌ dopo due tentativi con errori veri" è documentato al punto 4.

## Insidie del collaudo (per chi rilegge dopo)

- `prepara_arsenale` **prepede** `~/.local/bin` al PATH: uno shim per iniettare guasti va messo LÌ dentro
  (rinominando un attimo `yt-dlp` in `yt-dlp.reale`, e ripristinando sempre), non in una cartella esterna — non verrebbe mai chiamato.
- Da cmd.exe → WSL: `\$` arriva a bash come escape letterale (PATH rotti, `$( )` guasti); usare sempre `$` nudo dentro le doppie virgolette.
- Il repo `~/posta` continua a vivere col postino e in detached HEAD: `pubblica` spinge `HEAD:main` e non tocca mai i rebase altrui.
