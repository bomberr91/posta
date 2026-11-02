# 🔬 AUDIT v4 — 15:43

## Boccone 1


[ALTA] sicurezza: `indirizzo` invia la chiave anche a URL `http://` in chiaro -> rifiuta HTTP, salvo loopback.
[MEDIA] concorrenza: `ricarica` sostituisce sei mappe separatamente mentre le richieste le leggono -> pubblica un’unica configurazione immutabile sotto lock.
[MEDIA] affidabilità: il `except Exception` sugli import nasconde errori interni e disattiva profili e compressione -> intercetta solo `ImportError`.
[MEDIA] affidabilità: `vivo` usa la porta 80 anche per URL HTTPS -> usa 443 per HTTPS e gestisci IPv6 correttamente.

## Boccone 2


[ALTA] cache: la chiave ignora parametri come `top_p`, `stop` e `response_format`; richieste diverse possono ricevere la stessa risposta -> includere tutti i parametri rilevanti o disattivare la cache.
[ALTA] stato: scritture concorrenti sullo stesso JSON possono troncare il file o perdere aggiornamenti -> usare un lock e scrivere su file temporaneo con sostituzione atomica.
[ALTA] quote: `freno()` e `batte()` non sono atomici; richieste simultanee possono superare i limiti -> controllare e registrare ogni chiamata sotto lo stesso lock.
[MEDIA] memoria: `batte()` accumula istanti senza limite quando il provider non ha una quota configurata -> potare la lista in `batte()` o non registrare quei provider.
[MEDIA] stato: `stato_carica()` accetta strutture JSON valide ma con tipi errati; chiamate successive possono fallire su `.items()` o sugli incrementi -> validare schema e tipi prima di assegnare `STATO`.
[MEDIA] sentinella: `push_visto` con `sentinella_repos` vuoto causa `IndexError` e può interrompere la richiesta -> verificare che la lista contenga almeno un elemento.
[MEDIA] risposte locali: `banale()` risponde `OK` anche se la richiesta richiede tool o un formato specifico -> escludere richieste con vincoli, tool o formato di risposta.

## Boccone 3


[CRITICO] riserva/errori: gestisci solo `HTTPError`. `URLError`, timeout e `JSONDecodeError` escono e bloccano il failover. -> Aggiungi `except (urllib.error.URLError, TimeoutError, ValueError)` e passa al provider dopo.

[CRITICO] a_pagamento: il test `"mini" in m` trova "mini" dentro "gemini". I Gemini a pagamento passano con `solo_gratis`. -> Controlla `"gemini"` prima di `"mini"` o usa token esatti.

[ALTO] stato condiviso: `STATO`, `REGISTRO` e `PROFILI` cambiano da più thread senza lock. `ses.pop(min(ses,...))` può dare `RuntimeError`. -> Proteggi lettura e scrittura con un `Lock` o copia il dict.

[ALTO] risposta: `.read()` legge tutta la risposta. Un provider rotto o ostile esaurisce la memoria. -> Leggi al massimo N byte e rifiuta il resto.

[ALTO] max_tokens: prendi il valore dal client senza limite. Un client impone costo e latenza enormi. -> Limita con `min(valore, CONFIG["max_tokens"])`.

[MEDIO] ripara_tool_call: la regex `\{.*\}` è greedy e prende dal primo `{` all'ultimo `}`. -> Usa `json.JSONDecoder().raw_decode` o una regex non greedy.

[MEDIO] regola_di: vince il primo prefisso inserito. Una chiave vuota o corta applica la regola a tutte le sessioni. -> Scegli la chiave più lunga e scarta chiavi vuote.

[MEDIO] sessione: il valore va nell'header senza controllo. Un CR/LF genera `ValueError` e blocca la richiesta. -> Valida il valore o codificalo prima dell'header.

## Boccone 4


$ ls -la && rg -n "def castiga|def segna|def _rispondi|def appello_da_solo|def punito" -S . 2>/dev/null | head -50
(no output)

$ rg -n "appello_da_solo|class H|ThreadingHTTPServer|HTTPServer|text/event-stream|\[DONE\]|Access-Control-Allow-Origin" -S . 2>/dev/null | head -80
(no output)

$ ls -la /home/agenti/posta; find /home/agenti/posta -maxdepth 2 -type f | head -50
total 1788
drwxr-xr-x 1 agenti agenti    4096 Nov  1 14:13 .
drwxr-x--- 1 agenti agenti    4096 Nov  1 12:05 ..
drwxr-xr-x 1 agenti agenti    4096 Nov  1 16:36 .git
-rw-r--r-- 1 agenti agenti      61 Oct 27 15:20 .gitignore
-rw-r--r-- 1 agenti agenti      10 Oct 27 15:20 .padrone
drwxr-xr-x 1 agenti agenti    4096 Oct 27 15:20 00_INSTALLA_AGENTI
-rw-r--r-- 1 agenti agenti    1116 Oct 27 15:20 6_BROWSER_AGENTI.bat
-rw-r--r-- 1 agenti agenti     133 Oct 27 15:20 7_SQUADRA_FUSION.bat
-rw-r--r-- 1 agenti agenti     286 Oct 29 09:40 8_CENTRALE_GUI.bat
-rw-r--r-- 1 agenti agenti    1897 Oct 27 15:20 APRI_OPENCLAW.bat
-rw-r--r-- 1 agenti agenti     892 Oct 27 15:20 CENTRALE_AGENTI.bat
-rw-r--r-- 1 agenti agenti    2376 Oct 27 15:20 CONFIGURA_OPENCLAW.bat
-rw-r--r-- 1 agenti agenti    8674 Oct 27 15:20 GUIDA_OPENCLAW.md
-rw-r--r-- 1 agenti agenti    2354 Oct 27 15:20 INDICE_CARTELLE.md
-rw-r--r-- 1 agenti agenti   11563 Oct 27 15:20 INSTALLA_OPENCLAW.bat
-rw-r--r-- 1 agenti agenti    3770 Oct 27 15:20 RAPPORTO_AGENTI.txt
-rw-r--r-- 1 agenti agenti      49 Oct 27 15:20 README.md
drwxr-xr-x 1 agenti agenti    4096 Oct 27 15:20 RISPOSTE_AGENTI
drwxr-xr-x 1 agenti agenti    4096 Oct 31 18:54 __pycache__
-rw-r--r-- 1 agenti agenti    6179 Oct 27 15:20 agenti_stato.sh
-rwxr-xr-x 1 agenti agenti   13517 Oct 27 15:20 aggiorna_tutto.sh
-rw-r--r-- 1 agenti agenti    9958 Oct 27 15:20 appello_chiavi.sh
-rwxr-xr-x 1 agenti agenti    3256 Oct 28 17:12 apri_free_llm_hub.sh
-rwxr-xr-x 1 agenti agenti    4071 Oct 27 15:20 apri_openclaw.sh
-rwxr-xr-x 1 agenti agenti   12053 Oct 29 09:40 centrale.sh
-rw-r--r-- 1 agenti agenti   77484 Nov  1 14:13 cervello.py
-rw-r--r-- 1 agenti agenti   22489 Oct 27 15:20 checkin_agentrouter.py
-rw-r--r-- 1 agenti agenti    1573 Oct 27 15:20 checkin_agentrouter.sh
-rw-r--r-- 1 agenti agenti    3067 Oct 27 15:20 chiave_di.py
-rw-r--r-- 1 agenti agenti    4531 Oct 27 15:20 chiavi_env.sh
-rw-r--r-- 1 agenti agenti    6493 Oct 31 18:53 compressione.py
drwxr-xr-x 1 agenti agenti    4096 Nov  1 16:34 da_me
drwxr-xr-x 1 agenti agenti    4096 Nov  1 16:34 dal_pc
drwxr-xr-x 1 agenti agenti    4096 Nov  1 16:34 fatti
drwxr-xr-x 1 agenti agenti    4096 Oct 28 17:12 free-llm-hub
-rw-r--r-- 1 agenti agenti   17736 Oct 27 15:20 fusion_engine.py
drwxr-xr-x 1 agenti agenti    4096 Oct 29 09:40 gui
-rw-r--r-- 1 agenti agenti   11389 Oct 27 15:20 installa_agenti.sh
drwxr-xr-x 1 agenti agenti    4096 Nov  1 15:43 lavori
-rw-r--r-- 1 agenti agenti    6154 Oct 27 15:20 leggi_discord.py
-rw-r--r-- 1 agenti agenti    6619 Oct 27 15:20 leggi_fb_cdp.mjs
-rw-r--r-- 1 agenti agenti    9080 Oct 27 15:20 leggi_fb_cdp.py
-rwxr-xr-x 1 agenti agenti    6871 Oct 27 15:20 leggi_video.py
-rw-r--r-- 1 agenti agenti    1002 Oct 27 15:20 mappa_innesto.txt
drwxr-xr-x 1 agenti agenti    4096 Nov  1 12:13 missione
-rw-r--r-- 1 agenti agenti    5098 Oct 27 15:20 omni_chiavi.sh
-rw-r--r-- 1 agenti agenti    4982 Oct 27 15:20 omni_free.sh
-rwxr-xr-x 1 agenti agenti    8549 Oct 27 15:20 openclaw_fix.sh
-rw-r--r-- 1 agenti agenti    2483 Oct 27 15:20 openclaw_stato.sh
-rw-r--r-- 1 agenti agenti    2739 Oct 31 18:53 per_agente.py
-rw-r--r-- 1 agenti agenti  167987 Oct 31 15:58 portiere_catalogo.json
-rw-r--r-- 1 agenti agenti     317 Oct 31 17:16 portiere_gruppi.txt
-rw-r--r-- 1 agenti agenti    9037 Oct 31 18:27 portiere_lista.txt
-rw-r--r-- 1 agenti agenti    9714 Nov  1 16:37 portiere_log.jsonl
-rw-r--r-- 1 agenti agenti     536 Oct 31 18:21 portiere_quote.txt
-rw-r--r-- 1 agenti agenti    1457 Nov  1 16:37 portiere_stato.json
-rw-r--r-- 1 agenti agenti     780 Oct 27 15:20 postino.log
-rwxr-xr-x 1 agenti agenti    3574 Oct 27 15:20 postino.sh
-rw-r--r-- 1 agenti agenti     540 Oct 27 15:20 prova.sh
-rw-r--r-- 1 agenti agenti    4962 Oct 27 15:20 prova_agenti.sh
-rw-r--r-- 1 agenti agenti    5223 Oct 27 15:20 prova_provider.sh
-rw-r--r-- 1 agenti agenti    2269 Oct 27 15:20 ricerca_strategica.py
-rw-r--r-- 1 agenti agenti    3296 Oct 27 15:20 serbatoio_hub_v2.json
-rw-r--r-- 1 agenti agenti 1202960 Oct 27 15:20 skills_pack.tar.gz
-rwxr-xr-x 1 agenti agenti     308 Oct 27 15:20 squadra.sh
-rw-r--r-- 1 agenti agenti     315 Oct 27 15:20 stato_fusion.json
drwxr-xr-x 1 agenti agenti    4096 Oct 30 16:49 strumenti
drwxr-xr-x 1 agenti agenti    4096 Oct 28 23:10 tests
-rwxr-xr-x 1 agenti agenti    7878 Oct 27 15:20 verifica.sh
/home/agenti/posta/.git/COMMIT_EDITMSG
/home/agenti/posta/.git/config
/home/agenti/posta/.git/description
/home/agenti/posta/.git/FETCH_HEAD
/home/agenti/posta/.git/HEAD
/home/agenti/posta/.git/index
/home/agenti/posta/.git/opencode
/home/agenti/posta/.git/ORIG_HEAD
/home/agenti/posta/.git/packed-refs
/home/agenti/posta/.gitignore
/home/agenti/posta/.padrone
/home/agenti/posta/00_INSTALLA_AGENTI/01_HERMES.bat
/home/agenti/posta/00_INSTALLA_AGENTI/02_DIAGNOSTICA_HERMES_WINDOWS.bat
/home/agenti/posta/00_INSTALLA_AGENTI/03_OPENCODE_WINDOWS.bat
/home/agenti/posta/00_INSTALLA_AGENTI/04_GOOSE_WINDOWS.bat
/home/agenti/posta/00_INSTALLA_AGENTI/05_SECONDHAND_WINDOWS.bat
/home/agenti/posta/00_INSTALLA_AGENTI/06_ANTIGRAVITY_WINDOWS.bat
/home/agenti/posta/00_INSTALLA_AGENTI/07_ICONE_AGENTI_WINDOWS.bat
/home/agenti/posta/00_INSTALLA_AGENTI/08_ICONA_OPENCLAW_WINDOWS.bat
/home/agenti/posta/6_BROWSER_AGENTI.bat
/home/agenti/posta/7_SQUADRA_FUSION.bat
/home/agenti/posta/8_CENTRALE_GUI.bat
/home/agenti/posta/agenti_stato.sh
/home/agenti/posta/aggiorna_tutto.sh
/home/agenti/posta/appello_chiavi.sh
/home/agenti/posta/apri_free_llm_hub.sh
/home/agenti/posta/APRI_OPENCLAW.bat
/home/agenti/posta/apri_openclaw.sh
/home/agenti/posta/centrale.sh
/home/agenti/posta/CENTRALE_AGENTI.bat
/home/agenti/posta/cervello.py
/home/agenti/posta/checkin_agentrouter.py
/home/agenti/posta/checkin_agentrouter.sh
/home/agenti/posta/chiave_di.py
/home/agenti/posta/chiavi_env.sh
/home/agenti/posta/compressione.py
/home/agenti/posta/CONFIGURA_OPENCLAW.bat
/home/agenti/posta/dal_pc/accendi_omniroute.md
/home/agenti/posta/dal_pc/accendi_omniroute_2.md
/home/agenti/posta/dal_pc/accendi_omniroute_e_rilancia.md
/home/agenti/posta/dal_pc/agentrouter_checkin.md
/home/agenti/posta/dal_pc/aggiorna_26_skill_e_browser.md
/home/agenti/posta/dal_pc/analisi_blocco_1.md
/home/agenti/posta/dal_pc/analisi_blocco_2.md
/home/agenti/posta/dal_pc/analisi_blocco_3.md
/home/agenti/posta/dal_pc/analisi_blocco_4.md
/home/agenti/posta/dal_pc/appello_chiavi.md
/home/agenti/posta/dal_pc/ar_canali_aperti.md
/home/agenti/posta/dal_pc/ar_processo3.md
/home/agenti/posta/dal_pc/ar_processo4.md

$ rg -n "def castiga|def segna|def punito|def appello|def motore_vivo|def uso_oggi|def ricarica|def chiave|def indirizzo|def sonda|def scopri|class H|ThreadingHTTPServer|HTTPServer|Retry-After|def _rispondi|text/event-stream|\[DONE\]|SOSTITUTI_MAX|def classifica|def da_confermare" /home/agenti/posta/cervello.py
/bin/bash: line 1: rg: command not found

✗ Grep "def castiga|def segna|def punito|def appello|def motore_vivo|def uso_oggi|def ricarica|def chiave|def indirizzo|def sonda|def scopri|class H|ThreadingHTTPServer|HTTPServer|Retry-After|def _rispondi|text/event-stream|\[DONE\]|SOSTITUTI_MAX|def classifica|def da_confermare" failed in cervello.py
Error: Ripgrep JSON record exceeded 65536 bytes

$ grep -nE "def castiga|def segna|def punito|def appello|def motore_vivo|def uso_oggi|def ricarica|def chiave|def indirizzo|class H|ThreadingHTTPServer|HTTPServer|Retry-After|def _rispondi|text/event-stream|SOSTITUTI_MAX|def classifica|def da_confermare" /home/agenti/posta/cervello.py
39:  51  429 intelligenti: se il provider manda Retry-After, obbediamo (max 5 min)
91:from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
128:    "retry_after_max": 300,      # idea 51: rispetta Retry-After, ma mai oltre 5 min
233:def ricarica_gruppi():
266:def ricarica():
285:def indirizzo(pid, k):
317:def motore_vivo():
323:def appello():
334:def chiave(pid):
385:def castiga(pid, modello, secondi, globale=False):
398:def punito(pid, modello):
407:def segna(pid, ok, ms=None):
468:def uso_oggi(pid):
493:def classifica_errore(codice, testo):
652:def ricarica_quote():
705:def ricarica_regole():
863:def ricarica_profili():
1047:                        ra = int(float(e.headers.get("Retry-After") or 0))
1085:def da_confermare():
1104:SOSTITUTI_MAX = 12
1114:def appello_da_solo():
1122:def classifica():
1136:    return buoni[0], buoni[1:SOSTITUTI_MAX + 1]
1310:class H(BaseHTTPRequestHandler):
1323:    def _rispondi(self, d, stream):
1345:        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
1666:    ThreadingHTTPServer(("127.0.0.1", PORTA), H).serve_forever()

→ Read cervello.py [offset=380, limit=120]
→ Read cervello.py [offset=1000, limit=160]
→ Read cervello.py [limit=120, offset=920]
→ Read cervello.py [limit=200, offset=1300]
→ Read cervello.py [limit=170, offset=1499]
→ Read cervello.py [limit=130, offset=110]
✱ Grep "def riserva\(" in cervello.py · 1 match
→ Read cervello.py [limit=150, offset=1160]
[CRITICA] `_rispondi`: Content-Length blocca lo streaming SSE dinamico e rifiuta chunk successivi -> rimuovere Content-Length e usare chunked transfer encoding o flush diretto.
[ALTA] `riserva`: `headers.get("Retry-After")` ignora le date HTTP IMF-fixdate e azzera il cooldown su 429 -> eseguire parsing RFC 7231 con `email.utils.parsedate_to_datetime`.
[ALTA] `STATO`: modifiche concorrenti e `json.dump` su file non sincronizzato causano race condition -> proteggere letture e scritture con `threading.Lock`.
[MEDIA] `da_confermare` / `scopri`: file aperti senza context manager causano resource leak di file descriptor -> usare `with open(...) as f:`.
[MEDIA] `_rispondi`: payload con `choices` vuoto solleva `IndexError` non gestito su crash del provider -> sostituire `d.get("choices")[0]` con slicing sicuro `(d.get("choices") or [{}])[0]`.
[MEDIA] `immagini`: timeout assente su `urllib` o URL esterno blocca il worker HTTP -> aggiungere timeout esplicito e gestire eccezioni di rete.
[BASSA] `appello_da_solo`: `subprocess.Popen` crea processi concorrenti multipli se invocato in parallelo -> aggiungere flag atomico o lock per singola esecuzione.
[BASSA] `da_confermare`: `r.split("|")` senza sanitizzazione causa campi errati su separatori non protetti -> normalizzare le righe ignorando spazi vuoti e sezioni invalide.

## Distillato EN


[ALTA] Security: `indirizzo` sends the key over plain HTTP; reject HTTP except for loopback.
[MEDIA] Concurrency: `ricarica` replaces six maps separately while requests read them; publish one immutable config under a lock.
[MEDIA] Reliability: Catching `Exception` during imports hides internal errors and disables profiles and compression; catch only `ImportError`.
[MEDIA] Reliability: `vivo` uses port 80 for HTTPS URLs; use port 443 for HTTPS and handle IPv6 correctly.
[ALTA] Cache: The key omits parameters such as `top_p`, `stop`, and `response_format`, so different requests may get the same response; include all relevant parameters or disable caching.
[ALTA] State: Concurrent writes to the same JSON file can truncate it or lose updates; use a lock and write to a temporary file before atomic replacement.
[ALTA] Quotas: `freno()` and `batte()` are not atomic, so concurrent requests can exceed limits; check and record each call under the same lock.
[MEDIA] Memory: `batte()` accumulates timestamps indefinitely when a provider has no quota configured; prune the list or skip recording those providers.
[MEDIA] State: `stato_carica()` accepts valid JSON with invalid types, causing later `.items()` or increment operations to fail; validate the schema and types before assigning `STATO`.
[MEDIA] Sentinel: `push_visto` raises `IndexError` when `sentinella_repos` is empty and may interrupt the request; ensure the list has at least one item.
[MEDIA] Local responses: `banale()` returns `OK` even when the request requires tools or a specific format; exclude requests with constraints, tools, or response-format requirements.
[CRITICO] Failover/errors: Only `HTTPError` is handled. `URLError`, timeouts, and `JSONDecodeError` escape and stop failover; catch `(urllib.error.URLError, TimeoutError, ValueError)` and try the next provider.
[CRITICO] Paid models: `"mini" in m` also matches `"gemini"`, allowing paid Gemini models through `solo_gratis`; check `"gemini"` first or use exact tokens.
[ALTO] Shared state: `STATO`, `REGISTRO`, and `PROFILI` are accessed by multiple threads without locks. `ses.pop(min(ses,...))` can raise `RuntimeError`; lock access or copy the dictionary.
[ALTO] Responses: `.read()` loads the entire response, letting a broken or hostile provider exhaust memory; limit reads to N bytes and reject larger responses.
[ALTO] `max_tokens`: The client-supplied value is unrestricted, allowing excessive cost and latency; cap it with `min(value, CONFIG["max_tokens"])`.
[MEDIO] `ripara_tool_call`: The greedy `\{.*\}` regex matches from the first `{` to the last `}`; use `json.JSONDecoder().raw_decode` or a non-greedy regex.
[MEDIO] `regola_di`: The first inserted prefix wins, so an empty or short key can affect every session; choose the longest key and discard empty keys.
[MEDIO] Session: The value is inserted into a header without validation; CR/LF can raise `ValueError` and stop the request; validate or encode it first.
[CRITICA] `_rispondi`: `Content-Length` prevents dynamic SSE streaming and rejects subsequent chunks; remove it and use chunked transfer encoding or flush directly.
[ALTA] `riserva`: `headers.get("Retry-After")` ignores HTTP IMF-fixdate values, resetting the cooldown on 429; parse RFC 7231 dates with `email.utils.parsedate_to_datetime`.
[ALTA] `STATO`: Concurrent mutations and unsynchronized `json.dump` cause race conditions; protect reads and writes with `threading.Lock`.
[MEDIA] `da_confermare` / `scopri`: Files opened without context managers can leak file descriptors; use `with open(...) as f:`.
[MEDIA] `_rispondi`: An empty `choices` payload raises an unhandled `IndexError` when a provider fails; use safe slicing: `(d.get("choices") or [{}])[0]`.
[MEDIA] Images: Missing timeouts on `urllib` or external URLs can block an HTTP worker; set an explicit timeout and handle network exceptions.
[BASSA] `appello_da_solo`: Parallel calls to `subprocess.Popen` can spawn duplicate processes; use an atomic flag or a per-run lock.
[BASSA] `da_confermare`: Unsanitized `r.split("|")` can produce malformed fields; normalize lines and ignore blank or invalid sections.

## Verdetto giudice di lusso
GIUDICE=gpt-5.6-sol
1. **CRITICAL — Paid-model policy bypass:** `"mini" in m` matches `"gemini"`, allowing paid Gemini models under `solo_gratis`; use exact model classification.
2. **CRITICAL — Broken failover:** `URLError`, timeouts, and JSON parsing failures escape, preventing fallback to another provider; catch expected transport and decoding errors.
3. **CRITICAL — Invalid SSE handling:** `_rispondi` sets `Content-Length`, blocking dynamic streaming and later chunks; use chunked transfer or direct flushing.
4. **HIGH — Credential exposure:** `indirizzo` can transmit API keys over plain HTTP; reject non-loopback HTTP endpoints.
5. **HIGH — Unsafe shared state:** Concurrent access and non-atomic persistence of `STATO`, `REGISTRO`, and `PROFILI` can crash, corrupt files, or lose updates; lock access and use atomic file replacement.
**VERDICT: FRAGILE**
[claude-opus-5 → HTTP Error 503: Service Unavailable {"error":{"message":"当前分组 default 下对于模型 claude-opus-5 无可用渠道 (request id: 202611012345018763934055rwkng1OXmDwc)","type":"]
[claude-opus-4-8 → HTTP Error 503: Service Unavailable {"error":{"message":"当前分组 default 下对于模型 claude-opus-4-8 无可用渠道 (request id: 202611012345112820561796p9sdjwT7XNeD)","type"]
[claude-sonnet-4-5-20250929 → HTTP Error 503: Service Unavailable {"error":{"message":"当前分组 default 下对于模型 claude-sonnet-4-5-20250929 无可用渠道 (request id: 20261101234522732473309lh28g5FBou0]
FINE 16:45
