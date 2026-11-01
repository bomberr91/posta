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
-rw-r--r-- 1 agenti agenti     540 Oct 27 15: