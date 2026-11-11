# SearXNG persistente — 2026-11-11T12:01:15+00:00 — repo=/home/user/posta_ponte
non attivo: avvio l'istanza
Docker assente: via nativa (collaudata l'11/11 nel sandbox)

[notice] A new release of pip is available: 26.2.1 -> 26.3
[notice] To update, run: /home/user/.local/share/searxng-venv/bin/python3 -m pip install --upgrade pip
avviato pid 3654
collaudo: OK 40
PERSISTENTE: JSON valido, 40 results; usata solo in freno di Tavily da lavori/cerca.sh
FINE rc=0

## ESECUZIONE DELLA FLOTTA (PC, issue #57 — 11/11 13:04 CET)

Delegato al poller con `target: secondhand` e compito
`PONTE_DETERMINISTICO:fatti/searxng_persistente.sh`: il wrapper ha eseguito lo script
**direttamente** (niente interpreter, niente output vuoto). Output reale della consegna:

```
[secondhand_run] deterministica: bash /home/agenti/posta/fatti/searxng_persistente.sh
# SearXNG persistente — 2026-11-11T13:04:43+01:00 — repo=/home/agenti/posta
non attivo: avvio l'istanza
Docker assente: via nativa (collaudata l'11/11 nel sandbox)
avviato pid 2994857
collaudo: OK 26
PERSISTENTE: JSON valido, 26 results; usata solo in freno di Tavily da lavori/cerca.sh
FINE rc=0
```

Issue #57 **chiusa** con `COMPLETATO 100s — exit 0` e consegna
`consegne/57-searxng-persistente-sulla-flotta/RISULTATO.md`. **0 issue aperte**.
L'istanza è attiva sul PC (`nohup`, pid 2994857): sopravvive alla sessione, non a un
riavvio della macchina (per quello servirebbe un task pianificato, non creato).

Nessuna chiave in questo file.
