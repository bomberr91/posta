# CONTROLLO FINALE DEL CERVELLO — come sta ADESSO

- **Quando:** 1/11/2026, ore 23:00–23:15
- **Cosa:** `~/posta/cervello.py` (2157 righe), lo stato vivo, i collaudi. Nessun file modificato tranne questo rapporto (in `dal_pc/`).
- **sha256 `cervello.py`:** `4eb366fb2f7ae875be10755f773322a1677efe2c2d5dfc694703327be275db7c`
- **Git:** HEAD `d795749` (48 commit dopo `ca69a3b`, la versione del primo audit ZCode). **Albero pulito: zero modifiche non committate.**
- **Processo vivo:** PID 270, `python3 cervello.py`, cwd `/home/agenti/posta`, avviato **22:48:29** — l'ultima modifica del file è 22:40:44 → **il server gira il codice del disco** (nessuna versione stantia). Guardiano `lavori/scorta_cervello.sh` vivo (pid 32660).

---

## STEP 2 — Stato vivo misurato

| Misura | Valore |
|---|---|
| `/salute` | `ok:true`, **62 provider**, 3 gruppi, 0 regole, motore (OmniRoute) vivo, riserva 6, `struttura: []` |
| `/portiere.json` | totali 62, capo **Pollinations (senza chiave)**, sostituti 3, rispondono 6, castighi attivi 0 |
| Appello (22:36, `--svelto`) | 62 voci: **6 risponde · 46 strano · 7 chiave-no · 3 no-chiave** |
| `portiere_stato.json` | 6 sezioni ✓; castighi 0; **uso `{}`** (i contatori di oggi sono spariti → vedi N1); agenti: 1 voce (mio collaudo); sessioni 0; sentinella: controllo **22:45:05**, baseline presenti, nessun avviso |
| `portiere_log.jsonl` | 107 righe; traffico engine 6-7s/richiesta; 3 burst di errori "indirizzo" alle 22:33/22:42/23:00 → **sono i TEST, non il server** (prova a N2) |
| Config su disco | `portiere_lista.txt` (62 chat + 7 da confermare), `portiere_gruppi.txt` (code, forte, rinforzi), `portiere_quote.txt` ✓; **`portiere_regole.txt` e `portiere_profili.json` assenti** → 0 regole / 0 profili, coerente con /salute |

**Cose che non tornano — verificate e spiegate:** (a) i contatori `uso/agenti` di oggi sono nulli nonostante 11 richieste motore nel log (17:07–17:10) → **wiping da parte dei test, difetto N1**; (b) la pagella `p-test` nel file di stato è spazzatura di test; (c) i burst "http in chiaro" nel log non sono il server: sono il test F2 che chiama `riserva()` senza redirigere il log (N2) — la prova è che la stessa `pollinationsfree` "rifiutata" alle 23:00:43 ha servito una richiesta vera alle 23:11:42 in 1044 ms.

---

## STEP 3 — Collaudi

- **`python3 -m unittest tests.test_cervello_offline` → 27/27 OK.** Nessun fallimento. Il nuovo `test_f1` (body malformato → 400, non disconnessione) passa.
- **`python3 cervello.py --autoprova` → ✅ AUTOPROVA SUPERATA** (struttura pulita, 62 provider · 3 gruppi · 0 regole, chat risponde, 0 token).
- **Policy "gratis" sul file REALE (collaudo indipendente importando il modulo):** 62 provider in BASE, classi `{free-ricorrente: 58, keyless: 4}`; **gratis ne prende 62 (58+4) ✓** — il buco corretto ieri sera (commit `bc0b473`) regge; **keyless ne prende 4, keyless-only ✓** (scelta rispettata). Nessun modello della lista flaggato a pagamento ✓. Test dedicato `test_su_62_provider_gratis_e_tutti` presente e verde.
- **Prova viva della riserva (model `keyless`):** HTTP 200 in **1,04 s** via `pollinationsfree` — rotta `riserva` nel glass-box identica (ms 1044, tentativi 1). Il percorso riserva funziona davvero end-to-end.

## STEP 4 — Chat vera

```
POST /v1/chat/completions (model "auto")  →  HTTP 200 in 27,62 s
rotta: MOTORE (OmniRoute) → "gemini-3.8-flash", usage 15 token, finish stop
glass-box: {"tipo":"richiesta","rotta":"motore","modello":"auto","ms":27561}  ← coincide col client
```

Il glass-box racconta esattamente ciò che il client ha visto. Nota: 27,5 s per una richiesta banale è la latenza del motore, non del Portiere — resta sotto il nuovo `timeout_motore` 90 s.

---

# I TRE VERDETTI

## 1) Le correzioni dell'audit sono applicate bene? → **SÌ, 17 su 19, e le ho verificato una per una sul codice + dal vivo**

| Rilievo del primo audit | Stato | Prova |
|---|---|---|
| F1 body malformato → empty reply | ✅ applicato | guard 1902–1918 (+ immagini 1879–1888) + test nuovo verde |
| F2 `indirizzo()` fuori try | ✅ applicato | riserva 1205–1208 e 1221–1227: salto+log, la richiesta sopravvive |
| F3 stato con tipi sbagliati | ✅ applicato | validazione annidata in `stato_carica` + test dedicato |
| F4 STATO senza lucchetto | ⚠️ **a metà** | `stato_salva` ✓, `conta_uso` ✓; ma `segna` copre 2 righe e `conta_agente`/`sentinella` niente → N3, N4, N5 |
| F5 profilo non-dizionario | ✅ applicato | `isinstance(prof, dict)` 1934 + test |
| F6 sentinella in linea | ✅ applicato | thread daemon 1873–1876 |
| F7 costi (180s/retry/reasoning) | ✅ applicato | `timeout_motore` 90; retry solo su 429 (1301); `TimeoutError` 1334 e `JSONDecodeError` 1343 senza ritento; esenzione reasoning sul motore 2044–2050 |
| F8 corpo richiesta illimitato | ✅ applicato | 413 oltre `risposta_max` (1906–1908) |
| F9 TOCTOU freno/batte | ✅ applicato (con 2 ritocchi da fare) | battito dentro il lucchetto 861–876; effetti collaterali minori → N7, N8 |
| F10 iterazioni castighi senza lock | ⚠️ **a metà** | `pagina()` e `stato()` ✓; **`/portiere.json` no** (1810–1812) → N6 |
| F11 cache race | ✅ applicato | `_CACHE_LOCK` 795–817 |
| F12 rotazione log | ✅ applicato | `_LOG_LOCK` + `os.replace` 712–731 |
| F13 scritture non atomiche | ⚠️ **a metà** | catalogo ✓ (1504–1507); **`appello_chiavi.sh:207` ancora `open(out,"w")` diretto** |
| F14 socket `vivo()` | ✅ applicato | try/finally 366–376 |
| F15 `except ImportError` stretto | ✅ applicato | `(ImportError, SyntaxError, AttributeError)` + urla su stderr 129–137 |
| F16 `chiave()` 20s | ✅ applicato | `timeout=5` |
| F17 policy "gratis" solo-keyless | ✅ applicato | 1025–1029 + prova reale 62/62 |
| F18 `profilo_di` primo match | ✅ applicato | `per_agente.py:31` ora prefisso più lungo |
| F19 `open()` senza `with` | ⬜ non applicato | solo cosmetico (ResourceWarning nei test) |

## 2) Difetti nuovi introdotti? → **SÌ, uno importante e gli altri piccoli. Tutti descritti sotto.**

### N1 · MEDIA-ALTA — I test nuovi scrivono nel VERO `portiere_stato.json` e lo svuotano
**Dove:** `tests/test_cervello_offline.py:443–465` (`ConcorrenzaTests` → `cerv.segna("p-test", …)`), `:363–390` (`test_f2` → `cerv.riserva(...)`); meccanismo: `stato_salva` (cervello.py:500–519) scrive `STATO_FILE`, che nel processo di test **non viene rediretto** (a differenza di `ProvaVivaTests`, che redirige solo `LOG_FILE`, righe 97–100).
**Cosa succede (provato stanotte):** ogni collaudo del server (pull→restart→collaudo gira più volte a sera) sovrascrive `portiere_stato.json` con lo STATO del processo di test — che non ha mai chiamato `stato_carica()`, quindi **persone/agenti/sessioni/sentinella/castighi spariscono dal file**, e in `pagella` resta il provider finto `p-test` (oggi: `{'p-test': (1,0), 'pollinationsfree': (1,0)}`). Conseguenze concrete: i contatori di consumo di oggi (11 richieste nel log) sono perduti; le baseline della sentinella sono state perse e ricostruite alle 22:45:05 (ri- controllo di rete + rischio falso allarme "promo pubblicata", la piaga che il CURA-AUDIT v5 aveva spento); **se c'erano castighi attivi, un riavvio subito dopo un collaudo li perde** (provider in castigo tornano subito → 429).
**Correzione esatta:** redirigere i due file UNA volta per tutta la suite, dopo `cerv = carica_cervello()` (riga 42):
```python
import tempfile
_fd, _tmp_log = tempfile.mkstemp(suffix=".jsonl", prefix="portiere-log-test-")
os.close(_fd)
cerv.LOG_FILE = _tmp_log                      # niente errori finti nel glass-box vero
_fd, _tmp_stato = tempfile.mkstemp(suffix=".json", prefix="portiere-stato-test-")
os.close(_fd)
cerv.STATO_FILE = _tmp_stato                  # niente write sullo stato vero
```
I blocchi save/restore già presenti nelle classi (97–114, StatoTests) continuano a funzionare: salvano e rimettono il valore corrente.

### N2 · MEDIA — I test nuovi scrivono errori FINTI nel VERO glass-box `portiere_log.jsonl`
**Dove:** stesso meccanismo di N1 ma sul log: `test_f2` chiama `cerv.riserva()` con `indirizzo` monkeypatchato per lanciare *"chiave su http in chiaro rifiutata"* → `logga(...)` finisce nel log di produzione.
**Prova:** le coppie di righe finte alle **22:33:45, 22:42:18, 23:00:43** (collaudo automatico) e alle **23:12:55** (il mio run del solo test F2: 2 righe aggiunte, verificate prima/dopo). Stessa identica firma dell'errore che un problema VERO avrebbe: chi legge il glass-box stanotte ha perso tempo a cercare un guasto inesistente (me compreso).
**Correzione:** coperta dalla redirezione di N1 (`cerv.LOG_FILE`).

### N3 · MEDIA-BASSA — `segna()`: il lucchetto copre solo 2 righe
**Dove:** `cervello.py:549–551` (`with LOCK:` attorno a setdefault+incremento); il resto — EWMA `p["ms_ewma"]` (560–562), `fila_ko`/`ultimo_ko` (564–565), dimezzamento (569–571) — muta STATO **senza lucchetto**, e `stato_salva` serializza sotto lucchetto: la corsa "mutazione durante il dump → RuntimeError → salvataggio saltato" che F4 voleva chiudere esiste ancora, solo più stretta; due `segna` concorrenti sullo stesso pid possono perdere aggiornamenti.
**Correzione esatta:** portare TUTTO il corpo dentro `with LOCK:` e rimandare `castiga()` fuori (il Lock non è rientrante, e `castiga` lo prende):
```python
def segna(pid, ok, ms=None):
    castigo_fila = False
    with LOCK:
        p = STATO["pagella"].setdefault(pid, {"ok": 0, "ko": 0, "ultimo_ko": 0, "fila_ko": 0})
        p["ok" if ok else "ko"] += 1
        if ok:
            p["fila_ko"] = 0
            if ms is not None:
                vecchio = p.get("ms_ewma")
                p["ms_ewma"] = int(ms) if vecchio is None else round(0.7 * vecchio + 0.3 * ms)
                p["ms_quando"] = time.time()
        else:
            p["ultimo_ko"] = time.time()
            p["fila_ko"] = p.get("fila_ko", 0) + 1
            if p["fila_ko"] >= CONFIG["fila_ko_max"]:
                p["fila_ko"] = 0
                castigo_fila = True
        if p["ok"] + p["ko"] > 50:
            p["ok"] //= 2
            p["ko"] //= 2
    if castigo_fila:
        castiga(pid, None, CONFIG["cooldown_fila"] + random.randint(0, 10))
    stato_salva(forza=not ok)
```

### N4 · MEDIA-BASSA — `conta_agente()` è rimasta senza lucchetto
**Dove:** `cervello.py:617–625` — il gemello `conta_uso` (602–608) è stato corretto, questa no. È il mutatore più frequente (ogni risposta riuscita del motore e della riserva).
**Correzione esatta:** avvolgere il corpo (fino a prima di `stato_salva()`) in `with LOCK:`, identico a `conta_uso`.

### N5 · BASSA — `sentinella()` muta STATO senza lucchetto, ora da thread
**Dove:** `cervello.py:667–704`. Con F6 gira in un thread → concorrente vera con `stato_salva`. Frequenza: 1 volta/giorno.
**Correzione esatta:** lavorare su una copia (`st = dict(STATO.get("sentinella") or {})`), fare le fetch, poi `with LOCK: STATO["sentinella"] = st` prima di `stato_salva(forza=True)`.

### N6 · BASSA — `/portiere.json` itera pagella/castighi/uso senza snapshot
**Dove:** `cervello.py:1807–1815` — le tre comprehension leggono dict vivi mentre `castiga`/`segna`/`conta_*` inseriscono → `RuntimeError: dictionary changed size during iteration` → dashboard "empty reply" (la metà di F10 non applicata; `pagina()` e `stato()` invece sono stati corretti).
**Correzione esatta:** prima del `_json`, snapshot sotto lucchetto:
```python
            with LOCK:
                _pag = dict(STATO.get("pagella") or {})
                _cast = dict(STATO.get("castighi") or {})
                _uso = dict(STATO.get("uso") or {})
```
e usare `_pag/_cast/_uso` nelle comprehension (1810–1815).

### N7 · BASSA — `freno()` consuma il battito per provider che poi vengono saltati
**Dove:** il battito si paga in `freno` (861–876) ma i salti successivi (`chiave` vuota 1218–1220, `indirizzo` 1221–1227) arrivano DOPO; inoltre il rifiuto per quota giornaliera avviene **dopo** l'append (877–878): il battito resta registrato anche se la chiamata non parte. Effetto: battiti fantasma che possono far scattare `al_min`/`distanza` al giro successivo sui provider con freni in `portiere_quote.txt`.
**Correzione minima:** spostare il check `al_giorno` dentro il lucchetto, prima dell'append; per i salti successivi accettare il fantasma (rari e stabili) e documentarlo.

### N8 · BASSA — Il ritento non registra più il battito
**Dove:** `cervello.py:1250–1256` (il `batte(pid)` era nel loop dei tentativi, rimosso col fix F9) — ora il ritento sullo stesso provider (429 a 1301–1306, rete a 1349–1355) **non conta** nella finestra 60s: `al_min` può essere superato dai ritenti, esattamente ciò che il freno previene.
**Correzione esatta:** rimettere un `batte(pid)` all'inizio del `while` (dopo `tentativi += 1`): è thread-safe di suo (`batte` ha il suo lucchetto) e non riapre la corsa del check, che resta in `freno`.

### N9 · TRIVIA — Commento vs comportamento in `stato_salva`
**Dove:** `cervello.py:511` — il commento dice "il timestamp si segna DOPO che il salvataggio è riuscito", ma `_ultimo_salvataggio[0] = time.time()` sta dentro il lucchetto, prima della scrittura del file: se la scrittura fallisce, i salvataggi restano silenziati 2s. Correzione: spostare l'assegnazione dopo `os.replace`.

### Osservazione (non difetto) — coalescing dei salvataggi
Dopo la mia chat keyless delle 23:11, `uso` e `sessioni` nel file erano ancora vuoti mentre `pagella` sì: `segna` salva, poi `conta_uso`/sessioni cadono nel freno di 2s e restano solo in memoria fino al prossimo salvataggio. È il design voluto ("freno 2s"); se il processo muore in quella finestra si perdono gli ultimi contatori. Accettabile — lo scrivo solo perché stanotte l'ho visto accadere e ha confuso l'analisi.

## 3) Cose che l'audit non aveva visto (dal vivo)

- **Il guardiano funziona ma è muto.** `lavori/scorta_cervello.sh` ha riportato su il cervello alle 22:48 in ~3s ✓. MA avvia `nohup python3 cervello.py >> /tmp/cervello.log` **senza `PYTHONUNBUFFERED`**: il banner e gli eventuali traceback di `handle_error` restano nel buffer da 8KB → `/tmp/cervello.log` è vuoto proprio quando servirebbe (il `tail -5 $CERV` del guardiano mostrerebbe nulla). Correzione: `nohup env PYTHONUNBUFFERED=1 python3 cervello.py >> "$CERV" 2>&1 &`. Nota anche: alle 22:47 il guardiano è partito due volte (pid 32602 e 32660; ora ne vive uno) — innocuo grazie al `flock`, ma vale un eye.
- **Portata reale della riserva oggi: 6 provider, non 62.** La policy "gratis" ora prende tutti i 62 ✓, ma `classifica()` arriva solo ai provider che l'appello ha marcato `risponde`: l'appello `--svelto` di oggi ne segna 6 (46 "strano" = endpoint `/models` che non rispondono 200, 7 chiave-no, 3 no-chiave). Non è un bug del codice: è la differenza tra policy e appello. Per usare davvero i 58 free-ricorrente serve un appello completo (prova "chat").
- **Latenza motore.** 27,6 s per "Va bene." su gemini-3.8-flash: dentro il budget (90s) ma se il motore resta il collo di bottiglia abituale, il tetto a 90s va tenuto d'occhio con i client lenti.
- **Provider "openai-fast" (Pollinations) ignora `max_tokens=30`** (completion 63) e riporta prompt 314 token per una richiesta da ~15: comportamento del provider, non del Portiere (il tetto 8000 vale in ingresso). Da sapere quando si leggono i costi.
- **Il test F2 ha un'asserzione debole:** `assertIsNotNone(risultato)` passa anche se `riserva` ritorna `(None, None)` — la rete regge ma non dimostra che qualcuno abbia risposto. Meglio: `self.assertIsNotNone(risultato[0])` oppure verificare 503/502 via HTTP come fa ProvaVivaTests.

---

## Trasparenza: tracce lasciate dai collaudi di stanotte (miei)

Eseguito quanto richiesto: 2 run completi della suite + 1 run del solo test F2 + autoprova + 2 richieste vere (1 auto → motore, 1 keyless → riserva). Conseguenze: ~6 righe finte "errore indirizzo" nel log (N2), la pagella `p-test` nello stato (N1), una pagella/contatore per `pollinationsfree` e una voce in `agenti` dal mio collaudo, 392 token di riserva e 15 di motore spesi. Nessun file toccato; nessuna chiave letta al di fuori del normale funzionamento; il rapporto (questo file) è l'unico scritto nuovo nel repo.

## Conclusione

Il cervello è **vivo e fa il suo mestiere**: struttura pulita, 27/27 test verdi, autoprova verde, policy "gratis" 62/62 come da correzione, riserva che risponde davvero in ~1s, glass-box coerente. I fix dell'audit sono applicati correttamente dove ci sono (17/19; 3 a metà per sotto-punti sfuggiti). I difetti nuovi sono tutti nella **collaudo di stanotte** (test che scrivono nel log e nello stato veri — N1/N2) più cinque ritocchi di rifinitura su lock e battiti. Nessuno dei nuovi difetti manda in "empty reply" una richiesta del percorso principale; il peggiore (N1) corrompe però il libro mastro e lo stato — ed è il primo da aggiustare, con 4 righe nel file dei test.

*Fine controllo — `cervello.py` intoccato (sha256 verificato prima e dopo).*
