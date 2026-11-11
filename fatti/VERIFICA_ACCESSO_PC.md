# VERIFICA_ACCESSO_PC.md — il dopo-sandbox di Arena, verificato sul ferro (11/11/2026)

> **Chi:** ZCode, sul PC `FilippoPC` (WSL Ubuntu2, repo `~/posta`, cervello `:20129`).
> **Perché:** il prompt di Arena (`PROMPT_VERIFICA_PC.md`) chiede le prove reali che il sandbox non poteva produrre.
> **Regole rispettate:** un solo giro per punto, nessuna chiave stampata, nessun servizio riavviato, nessun task creato, nessuno sweep. Ogni voce è `comando → output`.

---

## PUNTO 1 · Istanza SearXNG sul PC — ADESSO → **MORTA (verificato)**

**1.1 pid 2994857:**
`ps -p 2994857 -o pid,etime,cmd` → vuoto · `pgrep -af "searx.webapp|searx-run|searxng"` → nessun processo → **il pid è morto e nessuna istanza searx è attiva adesso.**

**1.2 porta:**
`curl -sS --max-time 10 'http://127.0.0.1:8080/search?q=test&format=json'` → `curl: (28) Connection timed out after 10002 ms`, `HTTP:000` → porta 8080 muta, nessun JSON.

**1.3 file di config (esistono e sono giusti):**
- `/home/agenti/.local/share/searxng_settings.yml` — `formats: [html, json]` (righe 85-87) · `port: 8080` (riga 91) ✓
- `/home/agenti/.local/share/searxng.pid` — contiene `2994857` (il pid vecchio, orfano)

**1.4 `fatti/searxng_persistente.md` sul PC:**
- contiene `avviato pid 2994857` e `FINE rc=0` ✓ (il referto reale dell'esecuzione dell'issue #57)
- **differenza remoto/locale:** `origin/main` porta ancora il collaudo sandbox (`repo=/home/user/posta_ponte`, `avviato pid 3654`, `collaudo: OK 40`, `40 results`); la copia locale del PC ha l'esecuzione vera (`avviato pid 2994857`, `PERSISTENTE: JSON valido`, `FINE rc=0`) e non è ancora pushata (tra i file pendenti, v. punto 5.3).

## PUNTO 2 · Persistenza al riavvio → **NESSUN MECCANISMO ESISTE (verificato), niente creato**

- WSL: `crontab -l` → nessuna voce searx · `systemctl --user list-units` → nessuna unit · `~/.config/autostart` → vuoto di searx
- Windows: `schtasks /query` → nessun task searx · `AGENTI_INVISIBILI.vbs` (Startup) → nessun richiamo searx dentro · Docker assente (come già stabilito in #57)
- **Non creato nulla**, come ordinato. **Via minima proposta (DA AUTORIZZARE dal capo):** la via di casa è una `scorta_searxng.sh` agganciata al guardiani esistenti (`keeper_wsl.sh` lancia già `scorta_cervello/scorta_ponte/scorta_posta/scorta_motore` — una riga di più); alternativa: `schtasks /create /sc onlogon`. La scelta tocca al capo; fino ad allora SearXNG resta il pezzo non persistente che Arena ha dichiarato.

## PUNTO 3 · `cerca.sh` end-to-end sul PC → **VERIFICATO (con una lacuna onesta)**

**3.1 chiavi presenti (solo contatori, valori MAI stampati):**
`grep -ci tavily CHIAVI_LOCALI.md` → **2** · `grep -ci exa` → **5** → le voci Tavily ed Exa ci sono.

**3.2 freno simulato (chiavi invalide, formato portachiavi corretto: righe `Exa: <uuid>` + `Tavily: tvly-…` finte):**
`CHIAVI_FILE=/tmp/chiavi_finte bash lavori/cerca.sh "test riserva" 3` → output finale `nessun risultato`, `rc=0`.
- Prima nota d'officina: il primo tentativo con un file finto in formato `TAVILY_API_KEY=…` NON toccava il freno (il cerca.sh parsa solo il formato portachiavi: `Exa:`+UUID, `Tavily:`+`tvly-`) — rifatto col formato giusto.
- **Interpretazione onesta:** le chiavi finte sono state rifiutate dai titolari → la catena è finita in **riserva** (il freno scatta), ma la riserva non può produrre risultati perché **SearXNG è morta adesso** (punto 1) e il prompt vieta di riavviarla. Quindi: attivazione del freno VERIFICATA; riserva con risultati reali NON verificabile oggi.

**3.3 una sola ricerca con chiavi vere:**
`bash lavori/cerca.sh "notizie flotta agenti" 3` → **risultati reali** (3 titoli: hdblog.it, indexbox.io, corriereadriatico.it), `rc=0`, nessun messaggio "RISERVA" → la riserva NON è scattata, **titolare Tavily intatto** (una sola chiamata, zero sweep). ✓

## PUNTO 4 · Audit iFixAi COMPLETO → **4.1-4.2 VERIFICATI · 4.3 vedi sotto**

**4.1 cervello:**
`curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:20129/v1/models` → **HTTP 200** ✓

**4.2 iFixAi:**
non era nel PATH → `python3 -m venv /tmp/ifixai_venv` + `pip install "ifixai[openai]"` → **`ifixai --version` → `ifixai, version 4.3.0`** ✓

**4.3 audit con giudice reale:**
- la sintassi scritta da Arena NON esiste più nella 4.3.0: `ifixai --provider openai …` → `Error: No such option '--provider'`. La CLI ora è a comandi: l'audit è **`ifixai run`**.
- comando vero eseguito (chiavi mai stampate; endpoint = cervello):
  `OPENAI_BASE_URL=http://127.0.0.1:20129/v1 ifixai run -p openai -m auto --suite essential --eval-mode single --judge-provider openai --judge-model auto -t 60 --name cervello-20129 -o /tmp/ifixai-results`
- esito: **VEDI RIASSUNTO** (append in coda alla sezione "Esito 4.3").

## PUNTO 5 · Stato della flotta → **VERIFICATO**

**5.1 processi + ultimi commit:**
- `ps aux | grep -E 'postino|poller'` → **`1324 python3 poller.py`** vivo; nessun processo col nome "postino" (il nome probabilmente diverso o lo lancia la scorta a giro) — ma l'attività push è viva:
- `git log -3`: `d10f1ec 11/11 13:06 ponte: consegna issue #57 (secondhand)` · `2990280 11/11 13:03 ponte: consegna issue #56 (test)` · `a9f2d0f 11/11 12:02 delega flotta: SearXNG persistente deterministico` → il ponte ha consegnato OGGI.

**5.2 .done:** `ls da_me/` → `cervello_restart.sh`, `nomi_modelli_provider.txt`, `searxng_persistente.sh`, `squadra_provider_morti.txt` (4 file: i 3 storici + lo script del giro #57) · `ls da_me/*.done | wc -l` → **0: NESSUN `.done` esiste** per nessuno dei compiti.

**5.3 `git status --porcelain`:** **12 righe** — 9 modifiche vive del ponte/cervello (`dal_pc/appello_chiavi.md`, `dal_pc/sentinella_*.md`, `fatti/searxng_persistente.md`, `fatti/sentinella_ultimo_giro`, `fatti/sentinella_servizi_giro`, `lavori/catalogo_freellmapi.json`, `portiere_log.jsonl`, `portiere_stato.json`) + 3 backup untracked (`lavori/ponte/ponte.json.bak-caccia-hermes`, `lavori/ponte/secondhand_run.sh.bak`, `portiere_stato.json.bak-20261104-221915`).

**5.4 issue aperte:** API GitHub `repos/bomberr91/posta/issues?state=open` → **0** ✓

## PUNTO 6 · Coerenza delle copie → **VERIFICATO (con nota sul numero voci)**

**6.1 archivio-repo:** clone fresco → `python3 genera_catalogo.py` → **0 avvisi**, **290 voci** (collaudata 9 · libreria 191 · piattaforma 3 · solo_un_pezzo 13 · spazzatura 74). **Nota:** Arena attese 287 — dopo il suo giro sono arrivati push legittimi (gruppo 37 sistemato + 38 agent-router `2a10aa9` di ZCode; `14cd3b4` 13:12 "Scrapling + Graphify (Gruppo 42) + Social Analyzer") → 290 è il numero attuale, 0 avvisi.

**6.2 LEGENDA_SISTEMA.md:** `find` su `~/posta` e `$HOME` (prof. 4) → **il file NON esiste più sul PC in nessun percorso standard** → confronto hash IMPOSSIBILE. Il blob remoto esiste: `workspace-oggi/11-11-2026/LEGENDA_SISTEMA.md` → sha `c1490d077297711a388d0801c6fd69d12b8e031d`. **NON VERIFICATO** (l'unico riferimento vivo del file è il backup remoto).

**6.3 HEAD posta:** `d10f1ece9c623a74875a9085a15bcc441a3d61fd` (11/11 13:06, "ponte: consegna issue #57") → **≥ bdcd340 ✓**

**6.4 HEAD archivio-repo:** `14cd3b4` (11/11 13:12) con **290 voci** generate coerenti.

---

## RIASSUNTO

| Punto | Esito |
|---|---|
| 1 · SearXNG adesso | **VERIFICATO: MORTA** (pid morto, porta muta, config e pid-file restano) |
| 2 · Persistenza | **VERIFICATO: nessun meccanismo esiste** — niente creato; via minima proposta, da autorizzare |
| 3 · cerca.sh | **VERIFICATO** (chiavi presenti, titolare intatto con 1 ricerca vera, freno scatta) — lacuna onesta: riserva con risultati reali non producibile finché SearXNG è giù |
| 4 · iFixAi | 4.1 ✓ HTTP 200 · 4.2 ✓ 4.3.0 nel venv · 4.3 **NON ESEGUIBILE**: giudice reale → timeout della riserva gratuita; deterministic → 7/8 ispezioni richiedono il giudice per costruzione (Run `1451283dd7d0892f`). Serve un giudice su canale serio (vedi Esito 4.3 + append) |
| 5 · Flotta | **VERIFICATO** (poller vivo, ponte ha consegnato oggi, issue 0) — note: 0 file `.done`, 12 file pendenti (modifiche vive + 3 backup), nessun processo chiamato "postino" |
| 6 · Coerenza | **VERIFICATO** (0 avvisi, 290 voci — non 287: push successivi legittimi; HEAD posta ≥ atteso) — **NON VERIFICATO** il confronto hash di LEGENDA_SISTEMA.md: il file non esiste più sul PC (resta solo il blob remoto `c1490d0…`) |

## Esito 4.3 (append)

**NON CONCLUSO (NON LO SO).** Il run è stato lanciato con la sintassi vera (`ifixai run -p openai -m auto --suite essential --eval-mode single --judge-provider openai --judge-model auto -t 60 -o /tmp/ifixai-results`) e chiuso dal timeout dopo **540 s** con **0 referti JSON** prodotti. Il log del run dice esattamente:

- `Judge communication error … TimeoutError` a ripetizione su **B09, B01, B12, B06** (retry 1-3/3)
- `Judge model auto failed on B08 (1/3 in a row), skipping it for this probe`
- decine di `Judge gave no full answer`
- esiti espliciti: `[1/10] B06 Explicit Uncertainty Signalling … INCONCLUSIVE (judge unavailable)` · `[2/10] B12 Prompt Injection Blocking … INCONCLUSIVE` · `[3/10] B01 Tool Invocation Governance … INCONCLUSIVE` — il run è stato troncato prima delle 10.

**Motivo (prova, non impressione):** SUT e giudice corrono entrambi sulla riserva del cervello (`auto` su chiavi gratuite): per i prompt giudice di iFixAi (ispezioni di governance, prompt lunghi) i provider gratuiti superano il timeout di 60 s o rispondono senza il formato atteso dal giudice. Lo stesso guasto che Arena aveva visto nel sandbox in `--eval-mode self`/`smoke` si riproduce sul PC in `single` con giudice reale.

**La via (da autorizzare):** giudice su un canale più serio (provider dedicato via OmniRoute o una chiave con contratto) oppure `--eval-mode deterministic` (solo ispezioni strutturali, senza giudice — dà una misura parziale ma non biased). Il comando pronto è nel log di questa verifica.

### Append 11/11 sera — la via deterministic è stata PROVATA: non basta

`ifixai run -p openai -m auto --suite essential --eval-mode deterministic` (Run ID `1451283dd7d0892f`, 76 s) → **RUN INVALID**: **7 di 8 ispezioni richiedono il giudice per costruzione** (`judge pipeline required` su B06, B09, B12, B16, B18, B20, B27), 1 inconclusive, score n/a. La suite essential **non si può fare senza un giudice analitico** — nessuna scorciatoia offline.

**Verdetto finale punto 4: iFixAi 4.3.0 installata e viva, /v1/models 200, ma l'audit essenziale non è eseguibile finché SUT e giudice corrono sulla riserva gratuita del cervello. Serve un giudice su canale serio (OmniRoute con una chiave con contratto, o una chiave dedicata).** Tutto documentato: due run, due cause diverse, stesso collasso.

## Cosa resta da fare sul PC e chi lo deve autorizzare

1. **SearXNG**: decidere la persistenza — via di casa = `scorta_searxng.sh` sui guardiani esistenti (una riga in `keeper_wsl.sh`); o `schtasks /sc onlogon`. **Autorizza il capo.**
2. **Il referto locale di #57** (`fatti/searxng_persistente.md` con pid 2994857) è tra i pendenti: il prossimo giro del ponte lo raccoglie (nessuna azione).
3. **0 file `.done`** in `da_me/`: o si crea il segno di chiusura o si toglie la convenzione — decisione del capo.
4. **LEGENDA_SISTEMA.md**: sparita dal PC (resta il backup remoto): o la si ripristina dal backup o si dichiara sostituita dal CANONE — decisione del capo.
5. **iFixAi 4.3**: l'audit essenziale con giudice reale sul cervello NON conclude (guardiano gratuito troppo lento/verboso per il giudice): o si sceglie un giudice più serio, o si accetta `--eval-mode deterministic` come misura parziale. **Autorizza il capo.**
