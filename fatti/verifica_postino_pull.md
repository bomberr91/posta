# VERIFICA POSTINO — pull in loop ⛔ (4/11 notte)

## Diagnosi (fatta direttamente dall'orchestratore, non delegata)

Al momento della diagnosi il pull **funzionava** ("Already up to date",
0 commit di ritardo, niente lock, niente non tracciati, identità presente):
il loop ⛔ era quindi **intermittente**, non permanente. La causa meccanica
è stata identificata leggendo `sync_down` in `postino.sh`:

1. **Contesa col poller**: poller e postino fanno git sullo STESSO repo.
   Quando uno tiene `.git/index.lock`, il pull dell'altro fallisce al volo
   (il rimedio non aspetta il lock: fallisce di nuovo → ⛔ → riprova identico).
2. **`git stash drop` nel rimedio**: con `--autostash` lo stash viene
   ripristinato da git; buttarlo perdeva le modifiche locali (i file
   "perdonati" dell'handover) e rialimentava il ciclo.
3. **Errori muti**: `-q` + `>/dev/null` = l'errore vero non esisteva nei log
   (il buco originale, ricreato in altra forma).
4. Niente contatore: il ⛔ poteva durare all'infinito senza allarme cumulativo.

## Patch applicata (postino.sh, sync_down)

- **Attesa del lock**: fino a 4×10s se un git è attivo; rimozione SOLO del
  lock orfano (nessun processo git) — stesso schema del poller.
- **NIENTE `stash drop`** (con commento che spiega perché).
- **Errore vero nel log**: `/tmp/postino_pull.log` (con rotazione a 400 righe).
- **Contatore falli di fila**: `/tmp/postino_falli` — il ⛔ ora dice quante
  volte di fila, e il contatore si azzera al primo pull riuscito.
- `GIT_TERMINAL_PROMPT=0`: già presente in testa allo script (invariato).
- `git config core.fileMode false`: impostato (la nota-trappola del handover).

## Validazione meccanica

- Scenario **lock orfano**: lock creato a mano → sync_down lo rimuove →
  pull ok, `falli=0` ✓
- Scenario **lock tenuto** (finto `git` che lo tiene 15s): sync_down attende
  e vince, `falli=0` ✓ (test: `/tmp/test_sync.sh orfano|tenuto`, costruito
  con il sync_down VERO estratto da postino.sh)
- Dopo la patch e il riavvio del postino (via scorta): **17 pull riusciti,
  0 errori, 0 simboli ⛔** nel nuovo log.

## Criteri di accettazione (handover §5)

1. ⛔ assente dal riavvio col nuovo codice (17 pull consecutivi ok) ✓
2. Nessun "rejected (fetch first)" dopo la cura del poller ✓
3. `git rev-list --count HEAD..origin/main` = 0 ✓
4. Il log del pull mostra gli errori veri quando capitano ✓
5. Questo referto ✓
