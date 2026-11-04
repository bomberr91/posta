# AUDIT CERVELLO_ZCODE — `cervello.py` (il Portiere)

- **Data:** 1/11/2026, sera
- **Oggetto:** `~/posta/cervello.py` su WSL (repo GitHub `bomberr91/posta`) — **1991 righe** (non ~3000), md5 `93d66242dca8be847a118b694108094a`, git HEAD `ca69a3b`, albero pulito.
- **Modalità:** sola lettura. Nessun file in `~/posta` modificato (md5 riverificato a fine audit). I test sono stati eseguiti; il codice no.
- **Percorso richiesta verificato:** `do_GET`/`do_POST` → `riserva()` → `inoltra()`/`urllib`, più i gemelli `per_agente.py` e `compressione.py` e lo scrittore di `~/.posta_appello.json` (`appello_chiavi.sh`), perché `do_POST` li chiama **senza** try/except.

---

## Verdetto per categoria (richiesta 1–5)

| # | Categoria | Verdetto |
|---|-----------|----------|
| 1 | Bug che perdono richieste / uccidono il processo | **NON pulito** — F1, F2, F3, F6, F7 (+ basse F12b, F14, F15, F16) |
| 2 | Race su `portiere_stato.json` / `portiere_log.jsonl` | **NON pulito** — F3, F4, F8, F9, F10, F11. Nota: la **scrittura del file di stato è atomica e sotto lucchetto** (riga 473, `os.replace` + `LOCK`) ✓; il problema è chi muta `STATO` in memoria *senza* lucchetto |
| 3 | Scritture non atomiche | **Quasi pulita su portiere_stato.json** (tmp+`os.replace`, righe 470–473 ✓). Non pulite altrove: rotazione del log (F11), `portiere_catalogo.json` e `~/.posta_appello.json` (F13) |
| 4 | Eccezioni non gestite → "empty reply" | **NON pulito** — 9 punti scoperti (F1, F2, F3, F5, F9, F10 + latenza F6). In `http.server` un'eccezione in `do_*` chiude la connessione **senza risposta** = esattamente il sintomo del 1/11 |
| 5 | Timeout/retry che raddoppiano i costi | **NON pulito** — F12, F6, tagli di lettura che diventano "errore rete" |

## Collaudo (richiesta esplicita)

```
python3 -m unittest tests.test_cervello_offline -v   (pytest NON è installato in WSL)
Ran 19 tests in 1.392s — OK
```

**19/19 PASSANO, nessuno fallisce.** Dettaglio: ProvaStrutturale 3/3, ProvaViva 5/5, GuardiaSoloGratis 3/3, RegoleAgente 2/2, Stato 4/4, Vivo 1/1, MaxTokens 1/1.

**Ma attenzione:** la suite **non può dire NO sui bug trovati sotto** — non copre payload malformati, `Content-Length` sporco, stato con tipi sbagliati nei campi nuovi (`ms_ewma`…), profili non-dizionario, concorrenza. Sono tutti riproducibili offline: aggiungerli è questione di minuti (vedi §"Cosa aggiungere ai test").

---

# FINDING, per gravità

## 🔴 CRITICHE

### F1 · `do_POST` muore su input malformato → "empty reply" (cat. 1+4)
**File:** `cervello.py:1746`, `cervello.py:1762`, `cervello.py:1768`, `cervello.py:691`, `cervello.py:717`
**Perché:** il 400 per corpo rotto esiste (1763–1767) ma **non copre**:
- `n = int(self.headers.get("Content-Length") or 0)` (anche 1746, path immagini): header non numerico → `ValueError` → risposta mai inviata;
- corpo JSON **valido ma non-oggetto** (es. `[1,2]`): `json.loads` riesce, poi `payload.pop("stream", False)` a 1768 → `AttributeError`;
- `messages` presente ma con elementi non-dizionario: `m.get("role")` in `banale()` (691) o `cache_chiave()` (717) → `AttributeError`.
Tutti percorsi **senza try**: `http.server` chiude la connessione a vuoto. È la stessa firma del disastro del 1/11.
**Correzione esatta** — sostituire il blocco 1762–1767 con:
```python
        try:
            n = int(self.headers.get("Content-Length") or 0)
        except (TypeError, ValueError):
            n = 0
        if n > CONFIG.get("risposta_max", 8_000_000):
            self._json({"error": {"message": "corpo troppo grande"}}, 413)   # F7
            return
        try:
            payload = json.loads(self.rfile.read(n).decode() or "{}")
        except Exception:
            self._json({"error": {"message": "corpo non valido"}}, 400)
            return
        if not isinstance(payload, dict) or \
                not isinstance(payload.get("messages", []), list) or \
                any(not isinstance(m, dict) for m in payload.get("messages", [])):
            self._json({"error": {"message": "payload non valido"}}, 400)
            return
```
(stesso guard su `int(Content-Length)` a 1746, path immagini.)

### F2 · `indirizzo()` lancia `ValueError` fuori try dentro `riserva()` → una riga sbagliata in lista ammazza TUTTA la richiesta (cat. 1+4)
**File:** `cervello.py:1132` (chiamata) → `cervello.py:340` (`raise ValueError`)
**Perché:** il guard anti-http-in-chiaro (336–340) è giusto come idea, ma `base, intestazioni = indirizzo(pid, k)` sta **fuori dal try** del loop: l'eccezione risale `do_POST` → "empty reply", invece di saltare quel provider e fare failover. Oggi la lista è pulita (0 righe `http://` su 71), ma basta un'aggiunta sbagliata per spegnere il Portiere. Stesso punto: `_, modello = BASE[pid]` (1119) → `KeyError` se l'hot-reload (idea 10) sostituisce `BASE` mentre la richiesta vola.
**Correzione esatta** — nel loop di `riserva()`:
```python
        try:
            _, modello = BASE[pid]
        except KeyError:
            continue
        modello = v.get("modello") or modello
        ...
        try:
            base, intestazioni = indirizzo(pid, k)
        except (KeyError, ValueError) as e:
            logga(tipo="errore-riserva", provider=pid, errore="indirizzo", nota=str(e)[:120])
            continue
```

### F3 · `stato_carica()` non valida i tipi annidati → UN campo sbagliato in `portiere_stato.json` mette in "empty reply" OGNI chat (cat. 1+2+4)
**File:** `cervello.py:449–455` (validazione incompleta) → crash a `cervello.py:532–533`, `1071`, `1108`, `798`
**Perché:** la funzione difende da "tipi sbagliati" ma valida solo `castighi` (numerico) e `pagella.ok/ko` (int). **Non valida:** `ms_ewma` e `ms_quando` (usati da `velocita()` → `velocita(...) // CONFIG["fascia_ms"]` a 1071 → `TypeError: str // int`), `fila_ko`/`ultimo_ko`, `uso[*].n/token` (`>=` su str), `sessioni[*].quando` (`time.time() - str`). Il sort a 1071 è sul percorso **default "auto"**: un solo campo corrotto = tutta la riserva morta con empty reply, finché non si ripara il file a mano. Il file è toccato anche da agenti esterni → trigger realistico.
**Correzione esatta** — estendere il blocco di validazione in `stato_carica()` (dopo le righe 449–455):
```python
    for pid, p in list(nuovo["pagella"].items()):
        if not isinstance(p, dict):
            nuovo["pagella"].pop(pid, None); continue
        for campo in ("ok", "ko", "fila_ko"):
            if not isinstance(p.get(campo), int) or isinstance(p.get(campo), bool):
                p[campo] = 0
        for campo in ("ultimo_ko", "ms_quando"):
            if not isinstance(p.get(campo), (int, float)) or isinstance(p.get(campo), bool):
                p.pop(campo, None)
        me = p.get("ms_ewma")
        if not isinstance(me, (int, float)) or isinstance(me, bool):
            p.pop("ms_ewma", None)
    for pid, u in list(nuovo.get("uso", {}).items()):
        if not isinstance(u, dict) or not isinstance(u.get("n"), int) \
                or not isinstance(u.get("token"), int):
            nuovo["uso"].pop(pid, None)
    for s, v in list(nuovo.get("sessioni", {}).items()):
        if not isinstance(v, dict) or not isinstance(v.get("pid"), str) \
                or not isinstance(v.get("quando"), (int, float)) or isinstance(v.get("quando"), bool):
            nuovo["sessioni"].pop(s, None)
```

## 🟠 ALTE

### F4 · Mutazioni di `STATO` senza `LOCK` contro `json.dump` → salvataggi saltati in silenzio, contatori e castighi persi (cat. 2)
**File:** `cervello.py:506–523` (`segna`), `553–559` (`conta_uso`), `569–575` (`conta_agente`), `617–656` (`sentinella`) vs `stato_salva` 467–473
**Perché:** `stato_salva` serializza `STATO` sotto `LOCK`, ma `segna`/`conta_uso`/`conta_agente`/`sentinella` inseriscono chiavi **senza lucchetto**: se mutano mentre `json.dump` itera → `RuntimeError: dictionary changed size during iteration` → catturato dal `except: pass` → **salvataggio saltato senza alcun avviso**. Al riavvio spariscono castighi, pagelle e contatori quota (→ spese non tracciate). In più due thread in `conta_uso` si perdono incrementi (`u["n"] += 1` non atomico). Il pattern corretto esiste già: `castiga` (487–488) e le sessioni (1166–1175) stanno sotto `LOCK`.
**Correzione esatta:** (a) snapshot serializzato dentro il lucchetto:
```python
def stato_salva(forza=False):
    try:
        with LOCK:
            if not forza and time.time() - _ultimo_salvataggio[0] < 2:
                return
            _ultimo_salvataggio[0] = time.time()
            ora = time.time()
            STATO["castighi"] = {k: v for k, v in STATO["castighi"].items() if v > ora}
            testo = json.dumps(STATO)          # snapshot coerente
        tmp = STATO_FILE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            f.write(testo)
        os.replace(tmp, STATO_FILE)
    except Exception:
        pass
```
(b) avvolgere in `with LOCK:` il corpo mutante di `segna`, `conta_uso`, `conta_agente` (lasciando `stato_salva()` fuori dal lucchetto). (c) in `sentinella()` lavorare su una copia (`st = dict(STATO.get("sentinella") or {})`) e committare con `with LOCK: STATO["sentinella"] = st` prima di `stato_salva(forza=True)` — **mai** tenere il lucchetto durante gli `urlopen`. Nota: così sparisce anche il difetto minore per cui il timestamp (465) viene segnato **prima** del salvataggio, silenziando i retry per 2s anche se il salvataggio è fallito.

### F5 · Profilo per-agente non-dizionario → `AttributeError` → "empty reply" per quell'agente (cat. 4)
**File:** `cervello.py:1780` + `cervello.py:1787` (radice: `per_agente.py:12–19`, che accetta qualunque JSON valido)
**Perché:** `prof = profilo_di(sess, PROFILI)`; se in `portiere_profili.json` il profilo è una stringa/numero, `if prof:` passa e a 1787 `prof.get("comprimi")` → `AttributeError` **fuori dal try** (l'`applica_profilo` a 1781 è protetto, il `.get` dopo no). Hot-reload rende il trigger facile: basta un profilo scritto male.
**Correzione esatta** (riga 1780):
```python
            if isinstance(prof, dict) and prof:
```

### F6 · `sentinella()` gira IN LINEA nella prima POST del giorno: fino a ~32s di rete prima di smistare → client timeout → richiesta persa e ripetuta (cat. 1+4+5)
**File:** `cervello.py:1743` (chiamata) + `609–656` (corpo)
**Perché:** 2 pagine × timeout 10s (630–631) + 2 repo GitHub × 6s (642–644) = **~32s bloccati prima di qualunque routing**, una volta ogni 24h. Un client con timeout più corto (o un curl di collaudo, che è esattamente come è nato il falso-OK del 1/11) vede hang/empty reply e **rimanda**: la richiesta originale poi viene comunque processata → doppio lavoro/doppio costo. Le eccezioni sono tutte catturate (`continue`) quindi non crasha — ma blocca.
**Correzione esatta** (riga 1743, al posto di `sentinella()`):
```python
        if time.time() - (STATO.get("sentinella") or {}).get("controllo", 0) \
                >= CONFIG["sentinella_ore"] * 3600:
            threading.Thread(target=sentinella, daemon=True).start()
```
(sentinella imposta `st["controllo"]` all'inizio → nessun thread-storm.)

### F7 · Costi: motore 180s + riserva 5×60s + ritenti ambigui = fino a ~9 minuti di lavoro fatturato per UNA richiesta client (cat. 5)
**File:** `cervello.py:152` (`timeout_motore: 180`), `1880–1897`, `159` (`max_tentativi: 5`), `1200–1205` (retry su 5xx), `1233–1239` (retry su rete/timeout), `1156` + tagli di lettura
**Perché — quattro moltiplicatori:**
1. **Motore → riserva:** `inoltra` attende 180s (966); su timeout il motore può comunque completare e fatturare, e la STESSA richiesta riparte sulla riserva (fino a 5 tentativi). Worst case: 180 + 5×(60+backoff≈9) ≈ **8,7 min**. Il client ha molltato molto prima → ogni tentativo è spesa fantasma (è la lezione "curl con timeout più corto del budget del motore" del 1/11, rimasta valida in produzione).
2. **Retry su `passeggero` (5xx)** (1200–1205): un 502/504 ha esito ignoto — il primo tentativo può essere stato processato e fatturato; il ritento sullo stesso provider raddoppia. (Il retry su `breve`/429 è sicuro: la richiesta è stata rifiutata.)
3. **Timeout di lettura** cade nel generico `except Exception` (1233) e viene ritentato **sullo stesso provider**: esito ignoto → possibile doppia fattura.
4. **Tetti di lettura:** riserva legge max 3.000.000 byte (1156), motore 8.000.000 (967): una risposta più grande → `json.JSONDecodeError` → trattata come "errore rete" → **ritento = doppia spesa** per una risposta che il provider aveva già prodotto. Sul motore, inoltre, il fallback tocca la riserva → doppia generazione.
5. (minore) Il path motore non ha l'esenzione "ragionatore senza budget" della riserva: un 200 con `reasoning` pieno e `content` vuoto (1884) viene butta via e **rinviata alla riserva** → doppia generazione. A 1185–1188 la riserva invece la rispetta.
**Correzioni esatte:**
- (1) `timeout_motore` ≤ timeout tipici dei client (es. 90) e commento col worst case;
- (2) a 1200, ritentare sullo stesso provider **solo** per `breve`:
```python
                if tipo == "breve" and \
                        per_questo <= CONFIG["retry_stesso"] and \
                        tentativi < CONFIG["max_tentativi"]:
```
- (3) prima del generico `except Exception` (1233), aggiungere (+ `import socket` in testa):
```python
            except (TimeoutError, socket.timeout):      # esito ignoto: niente ritento
                castiga(pid, modello, CONFIG["cooldown_passeggero"])
                segna(pid, False)
                logga(tipo="errore-riserva", provider=pid, modello=modello,
                      errore="timeout", tentativo=tentativi)
                break
            except json.JSONDecodeError:                # risposta tronca dal tetto: già pagata
                logga(tipo="igiene", provider=pid, modello=modello,
                      nota="risposta oltre il tetto di lettura, niente ritento")
                segna(pid, False)
                break
```
- (5) specchiare l'esenzione a 1884:
```python
            if d and not msg0.get("content") and not msg0.get("tool_calls"):
                if not (msg0.get("reasoning") or msg0.get("reasoning_content")):
                    d = None
                    logga(tipo="igiene", agente=sess, rotta="motore",
                          nota="risposta vuota dal motore, passo alla riserva")
```

## 🟡 MEDIE

### F8 · Corpo richiesta illimitato → OOM può uccidere il processo (cat. 1)
**File:** `cervello.py:1748`, `1764`
**Perché:** `self.rfile.read(n)` legge qualunque `Content-Length` (le risposte hanno il tetto `risposta_max` a 198, le richieste no). Un agente impazzito che manda centinaia di MB riempie la RAM → OOM-killer → processo morto. Mitigato dal bind su 127.0.0.1, ma il codice si difende già dalle risposte "ostili": stessa cortesia alle richieste. Fix incluso nel blocco di F1 (413 oltre il tetto).

### F9 · TOCTOU `freno()` → `batte()`: il freno preventivo non frena (cat. 2)
**File:** `cervello.py:1127` (controllo) vs `1151` (registrazione), commento 784–786
**Perché:** il commento promette "controllo e registrazione sotto lo stesso lucchetto", ma `batte(pid)` avviene **dopo** `chiave(pid)` (402, fino a 20s) e `indirizzo()`: due richieste simultanee passano entrambe `freno` → superano `al_min`/`distanza` → 429 → castighi immersi su provider sani.
**Correzione esatta** — far riservare il battito a `freno` dentro il lucchetto e cancellare `batte(pid)` a 1151 (la funzione `batte` resta, i test la usano):
```python
def freno(pid):
    lim = QUOTE.get(pid)
    if not lim:
        return False
    al_min, al_giorno, distanza = lim
    ora = time.time()
    with LOCK:
        batt = [t for t in _battiti.get(pid, []) if ora - t < 60]
        if (al_min and len(batt) >= al_min) or \
                (distanza and batt and ora - batt[-1] < distanza) or \
                (al_giorno and uso_oggi(pid) >= al_giorno):
            _battiti[pid] = batt
            return True
        batt.append(ora)                       # il posto si paga all'ingresso
        if len(batt) > CONFIG.get("battiti_max", 120):
            batt = batt[-CONFIG.get("battiti_max", 120):]
        _battiti[pid] = batt
    return False
```

### F10 · Iterazioni su `STATO["castighi"]` senza lucchetto → `RuntimeError` → dashboard "empty reply" (cat. 2+4)
**File:** `cervello.py:1398`, `1413–1416` (`pagina()`), `1684–1686` (`/portiere.json`)
**Perché:** `castiga()` (488) inserisce nel dict mentre queste comprehension/max lo iterano da un altro thread → `dictionary changed size during iteration` → la pagina del Portiere e `/portiere.json` muoiono a intermittenza.
**Correzione esatta:** snapshot prima di iterare:
```python
    with LOCK:
        cast = dict(STATO["castighi"])
    castigati = sum(1 for v in cast.values() if v > ora)     # e in pagina(): usa cast
```
(`resta = max(...)` a 1413 itera `cast.items()`; a 1684 costruisci `cast` identico prima del `_json`.)

### F11 · `_CACHE`: `min()` iterante contro `pop` concorrente → `RuntimeError` → "empty reply" dopo una risposta BUONA (cat. 2+4)
**File:** `cervello.py:746–747` vs `738`
**Perché:** `cache_scrivi` fa `min(_CACHE, ...)` per sfoltire; `cache_leggi` fa `_CACHE.pop(k)` senza lucchetto: pop durante l'iterazione di `min` → eccezione che risale al `do_POST` di una richiesta **già riuscita**.
**Correzione esatta:**
```python
_CACHE_LOCK = threading.Lock()

def cache_leggi(k):
    if not k:
        return None
    with _CACHE_LOCK:
        v = _CACHE.get(k)
        if v and time.time() - v[0] < CONFIG["cache_ttl"]:
            d = json.loads(v[1])
            d["model"] = str(d.get("model", "")) + " (cache)"
            return d
        _CACHE.pop(k, None)
    return None

def cache_scrivi(k, d):
    if not k:
        return
    with _CACHE_LOCK:
        _CACHE[k] = (time.time(), json.dumps(d, ensure_ascii=False))
        while len(_CACHE) > CONFIG["cache_max"]:
            _CACHE.pop(min(_CACHE, key=lambda x: _CACHE[x][0]))
```

### F12 · `logga()`: append e rotazione senza lucchetto, rotazione non atomica e DENTRO la richiesta (cat. 2+3)
**File:** `cervello.py:663–668`
**Perché:** `logga` scrive una riga per ogni richiesta riuscita; quando il file supera 3MB, il thread **di una richiesta in corso** legge tutto, tiene le ultime 2000 e riscrive con `open(...,"w")` (non atomicamente). Contemporaneamente: append di un altro thread perso, doppia rotazione = log mescolato/troncato, e la richiesta che ruota si fermenta qualche secondo. Il file `portiere_log.jsonl` è la memoria glass-box: è qui che si perdono le righe.
**Correzione esatta:**
```python
_LOG_LOCK = threading.Lock()

def logga(**voce):
    voce["quando"] = time.strftime("%Y-%m-%d %H:%M:%S")
    riga = json.dumps(voce, ensure_ascii=False) + "\n"
    try:
        with _LOG_LOCK:
            if os.path.exists(LOG_FILE) and os.path.getsize(LOG_FILE) > 3_000_000:
                righe = open(LOG_FILE, encoding="utf-8").read().splitlines()[-2000:]
                tmp = LOG_FILE + ".tmp"
                with open(tmp, "w", encoding="utf-8") as f:
                    f.write("\n".join(righe) + "\n" + riga)
                os.replace(tmp, LOG_FILE)      # rotazione atomica, nessuna riga persa
            else:
                with open(LOG_FILE, "a", encoding="utf-8") as f:
                    f.write(riga)
    except Exception:
        pass
```

### F13 · Scritture non atomiche residue: catalogo e appello (cat. 3)
**File:** `cervello.py:1385`; `appello_chiavi.sh:207`
**Perché:** `json.dump(cat, open(CATALOGO_FILE, "w", ...))` e (nello script d'appello, che il Portiere lancia da solo a ogni avvio, riga 1281–1282) `json.dump(dati, open(out, "w"), ...)`: un crash/interruzione a metà → JSON tronco. Effetti: `catalogo_leggi()` → `{}` → `chi_ha_modello` sordo (routing degradato in silenzio); `appello()` (381–386) legge JSON a metà → `[]` → raffica di 503 "nessuna chiave" finché l'appello non finisce.
**Correzione esatta (cervello.py:1384–1385):**
```python
    tmp = CATALOGO_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(cat, f)
    os.replace(tmp, CATALOGO_FILE)
```
**Correzione esatta (appello_chiavi.sh:207):** `json.dump(dati, open(out + ".tmp", "w"), ensure_ascii=False, indent=1)` e subito dopo `os.replace(out + ".tmp", out)`.

## 🟢 BASSE

### F14 · `vivo()`: socket chiuso solo se la connect riesce (cat. 1)
**File:** `cervello.py:357–365`
**Perché:** in caso di errore manca `s.close()`; CPython lo chiude al GC quindi **non è una perdita reale oggi**, ma è un fd temporaneamente orfano per ogni controllo "motore morto" (che avviene a ogni POST quando OmniRoute è giù — proprio il momento in cui serve la riserva).
**Correzione esatta:**
```python
    try:
        fam = socket.AF_INET6 if ":" in host else socket.AF_INET
        s = socket.socket(fam, socket.SOCK_STREAM)
        try:
            s.settimeout(secondi)
            s.connect((host, int(porta)))
            return True
        finally:
            s.close()
    except Exception:
        return False
```

### F15 · `except ImportError` non prende `SyntaxError` → un gemello corrotto impedisce l'AVVIO (cat. 1)
**File:** `cervello.py:127–135`
**Perché:** un `compressione.py`/`per_agente.py` con errore di sintassi lancia `SyntaxError`, non `ImportError` → il Portiere non parte proprio (non "va come prima" come dice il commento). `gate_pubblicazione.py` mitiga, ma il file eseguito può differire dal repository. L'intenzione dell'audit v5 (fallire rumorosamente, non in silenzio) si rispetta ugualmente.
**Correzione esatta:**
```python
except (ImportError, SyntaxError, AttributeError) as _e:
    import sys as _sys
    print("cervello: F3 spento (%s): %s" % (type(_e).__name__, _e), file=_sys.stderr)
    F3_OK = False
```

### F16 · `chiave()`: subprocess con `timeout=20` nel percorso richiesta (cat. 4-adiacente)
**File:** `cervello.py:403`
**Perché:** a cache scaduta (ogni 10 min per provider), fino a 20s di attesa dentro `riserva()`, per un portachiavi locale. `timeout=5` è già generoso.

### F17 · Politica "gratis" = SOLO classe keyless (da verificare se intenzionale) (cat. 1)
**File:** `cervello.py:941–943`
**Perché:** `ordina_per_politica` con "gratis" scarta le voci `free-ricorrente` (chiavi free vere): se i keyless sono giù, "gratis" → 503 anche con dieci chiavi free sane in lista. Se voleva essere "tutto ciò che non costa": `CLASSI.get(v["id"]) in ("keyless", "free-ricorrente")`.

### F18 · `profilo_di`: vince il PRIMO prefisso, non il più lungo (incoerenza con `regola_di`) (cat. 2-adiacente)
**File:** `per_agente.py:21–28` vs `cervello.py:853–866`
**Perché:** la stessa classe di bug corretta in `regola_di` ("vince il prefisso PIÙ LUNGO") è viva nei profili: l'ordine decide, cioè l'ordine del JSON.
**Correzione esatta:**
```python
def profilo_di(sessione, profili):
    migliore, lunghezza = None, -1
    for prefisso, profilo in profili.items():
        if sessione.startswith(prefisso) and len(prefisso) > lunghezza:
            migliore, lunghezza = profilo, len(prefisso)
    return migliore
```

### F19 · Igiene: `open()` senza `with` — le stesse segnalate come ResourceWarning dal collaudo
**File:** `cervello.py:383, 434, 1491` (+257, 769, 1252)
**Perché:** solo cosmetico su CPython (il GC chiude), ma i warning intasano l'uscita dei test e nascondono segnali veri.

---

## Cosa aggiungere ai test (così il collaudo sa dire NO)

Tutti offline, in `tests/test_cervello_offline.py` (ProvaVivaTests, server di prova già pronto):
1. **F1:** POST con corpo `"[1,2]"`, con `Content-Length: abc`, con `messages: ["ciao"]` → attendere **400**, non disconnessione;
2. **F3:** file stato con `ms_ewma: "abc"` → `stato_carica()` + una chat "auto" → 200;
3. **F5:** `PROFILI = {"x-": "stringa"}` + chat da sessione `x-1` → 200;
4. **F9/F10/F11:** 20 thread su `batte`/`cache_scrivi`/`segna` + `stato_salva` in parallelo → nessuna eccezione;
5. **F12(5):** payload con risposta `{"message":{"reasoning":"...","content":""}}` sul motore finto → non deve ripartire sulla riserva.

## Difese verificate e SOLIDE (per onestà d'audit)

- `stato_salva`: tmp + `os.replace` sotto `LOCK` (**470–473**) — la scrittura di `portiere_stato.json` è atomica ✓
- tetto risposta 8MB motore / 3MB riserva (967, 1156), tetto `max_tokens` (197, 1770–1774), tetto battiti (810–811) ✓
- retry mai su 400/401/404 (classificazione 587–602), budget tentativi globale (1116, 1147), `Retry-After` rispettato con tetto 5 min (1207–1215) ✓
- 400 su corpo rotto (1763–1767), 403 guardia solo-gratis (1815–1820), tetti per agente (1801–1812) ✓
- `H._sessione` è di nuovo metodo di classe (1657) e `NOME` c'è (346) — le due reti del CURA-AUDIT v5 funzionano: l'autoprova strutturale (`controlla_struttura`) e la prova viva coprono esattamente il buco del 1/11 ✓
- sessioni e castighi già scritti sotto `LOCK` (1166–1175, 487–488) ✓

*Fine audit — `cervello.py` e gli altri file di `~/posta` non modificati (md5 riverificati a fine lavoro).*
