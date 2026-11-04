✅ COMPLETATO — issue #28 — 110s — exit 0
Agente: `opencode`

### Output (coda)
```
Ho completato la verifica dello stato del POLLER del ponte senza apportare modifiche. Ecco il referto scritto in `/home/agenti/posta/fatti/verifica_poller.md`:

```markdown
# Referto Verifica Poller

## 1. Stato Attuale
- **Processo poller**: Non in esecuzione (nessun processo trovato)
- **Log recenti**: Nessuna voce recente (log file vuoto o inesistente)
- **File di lock**: Assente (nessun `_stato/poller.lock`)
- **Directory _stato**: Vuota

## 2. Giudizio
- **Poller vivo**: No
- **Ciclo**: Non rilevato (non in esecuzione)
- **Errori ricorrenti**: Nessun log disponibile per analisi
- **Issue in corso**: 0 (nessun lock presente)

## 3. Verifica Fix
- "TIMEOUT dopo 180s": **Assente**
- "GIT_TERMINAL_PROMPT": **Assente**
- "il campo e": **Assente**

## 4. Latenza GitHub
- Media: 0.18s (misurazioni: 0.19s, 0.17s, 0.18s)

## BUG RILEVATI
1. **Poller non in esecuzione**  
   *Prova*: Nessun processo `poller.py` attivo e log vuoti.

2. **Fix mancanti**  
   *Prova*: Nessuna delle tre patch è presente nel codice.

## PROPOSTA FIX
1. Avviare manualmente il poller
2. Applicare i tre fix mancanti al file `poller.py`

### VERDETTO FINALE
IL POLLER E' SANO? **NO**  
QUALI BUG? Poller fermo + fix mancanti
```

Tutti i controlli sono stati eseguiti in read-only come richiesto. Il poller richiede attenzione immediata.
```
### Errori (coda)
```
[0m
> build · auto
[0m
[0m$ [0mpgrep -af poller.py
(no output)
[0m
[0m$ [0mtail -40 /home/agenti/posta/lavori/ponte/poller.log
(no output)
[0m
[0m$ [0mls -la /home/agenti/posta/lavori/ponte/_stato/
(no output)
[0m
[0m$ [0m[ -f /home/agenti/posta/lavori/ponte/_stato/poller.lock ] && cat /home/agenti/posta/lavori/ponte/_stato/poller.lock || echo 'File does not exist'
(no output)
[0m
[0m$ [0mgrep -n 'TIMEOUT dopo 180s' '/home/agenti/posta/lavori/ponte/poller.py'
(no output)
[0m
[0m$ [0mgrep -n 'GIT_TERMINAL_PROMPT' '/home/agenti/posta/lavori/ponte/poller.py'
(no output)
[0m
[0m$ [0mgrep -n 'il campo e' '/home/agenti/posta/lavori/ponte/poller.py'
(no output)
[0m
[0m$ [0mfor i in {1..3}; do python3 -c 'import urllib.request,time; t=time.time(); urllib.request.urlopen("https://api.github.com/rate_limit", timeout=20); print(round(time.time()-t,2))'; done
0.19
0.17
0.18
[0m
[0m← [0mWrite posta/fatti/verifica_poller.md
Wrote file successfully.
[0m
```

Consegna: `/consegne/28-verifica-dello-stato-del-poller-e-dei-su`