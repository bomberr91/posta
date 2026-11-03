# PROTOCOLLO — Ponte arena → agenti locali (via GitHub Issues)

> Staging: `AgentWorkspace/ponte-arena/`. Installazione prevista in `~/posta/lavori/ponte/` SOLO su richiesta esplicita.
> Costo: 0 € — usa solo il repo privato + `gh` (già autenticato per il postino).

## Principio
L'agente di arena (cloud) apre una **Issue** nel repo. Un poller locale (`poller.py`)
la prende in carico, smista il compito all'agente locale giusto, raccoglie il risultato
in `/consegne/`, commenta la issue e la chiude. L'agente di arena rilegge la issue per
sapere com'è andata. Nessuna porta aperta: il poller fa solo richieste in uscita.

## Etichette (stati del task)

| Etichetta | Significato | Chi la mette / toglie |
|---|---|---|
| `inbox` | task pronto da prendere | agente arena (all'apertura) |
| `in-corso` | preso in carico dal poller (lock anti-doppioni) | poller |
| `richiede-conferma` | azione delicata: il poller NON la tocca | agente arena |
| — (rimossa) | approvazione umana: togliendo `richiede-conferma` il task diventa eseguibile | **tu** |
| `bloccato` | 3 tentativi falliti: intervento umano | poller |

## Flusso

```
ARENA: apre issue [inbox] (+[richiede-conferma] se delicata)
POLLER (ogni ~40s): issue con [inbox] e SENZA [richiede-conferma]
  → claim: [inbox]→[in-corso]  (se fallisce: qualcun altro l'ha presa, skip)
  → dispatch all'agente locale (ponte.json → "agenti")
  → OK:     scrive /consegne/<N>-slug/ (RISULTATO.md + file raccolti),
            commit+push, commenta con il riepilogo, CHIUDE la issue
  → FALLITO: commenta l'errore, aumenta il contatore (_stato/<N>.json),
             riporta [in-corso]→[inbox]; dopo 3 fallimenti → [bloccato]
ARENA: "leggi la issue #N" → stato + riepilogo + file nel repo
```

## Convenzioni
- **Titolo issue**: `PONTE: <cose da fare in breve>`
- **Corpo**: campi `target`, `consegna`, `compito`, `contesto` (vedi TEMPLATE_ISSUE.md)
- **Consegne**: `/consegne/<numero>-<slug>/RISULTATO.md` + eventuali file raccolti
- **Fallback**: se il poller muore a metà esecuzione, la issue resta `in-corso`:
  al riavvio il poller la vede senza esito → la riporta `inbox` con un commento
  "riprendo dopo riavvio" (contatore tentativi non incrementa per riavvii puliti).

## Sicurezza (red lines rispettate)
- Il poller esegue **solo** i comandi dichiarati in `ponte.json` → whitelist esplicita.
- Nessun dato privato esce dal PC se non dentro il repo privato che già usi.
- Task delicati: SOLO con `richiede-conferma` rimossa da te a mano.
- Timeout per agente: un task bloccato non immobilizza la coda (viene ucciso e contanto come fallito).
- Lock a istanza singola (`_stato/poller.lock`): mai due poller in gara.

## Ordine preventivo e contatore (dal 3/11)
- `max_paralleli` (default 2): al massimo 2 agenti insieme; gli altri aspettano il turno.
- **Un task per agente**: due issue per lo stesso `target` girano in fila (niente due goose in gara).
- I commit/push delle consegne sono serializzati (mai index.lock per colpa del ponte).
- **Contatore**: `_stato/ponte_stato.json` dice chi sta lavorando ora; per l'umano:
  `bash stato_ponte.sh`. Arena può contare le issue aperte con etichetta `in-corso`.
- La scorta (`scorta_ponte.sh`, avviata da `PONTE_ARENA.vbs` alla Startup) riavvia
  il poller se muore — stesso schema delle altre scorte del sistema.

## Corsia veloce (futuro, opzionale)
Tailscale Funnel (gratis, URL stabile) esporrà `cervello` per task immediati;
la coda GitHub resta il fondamento: consegne, storico, conferme, fallback quando
il PC è spento o il tunnel cade. Le due corsie condividono le stesse convenzioni
di `/consegne/`.
