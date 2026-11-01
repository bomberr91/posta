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
