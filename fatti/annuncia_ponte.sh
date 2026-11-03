#!/bin/bash
# annuncia_ponte.sh — referto per arena: il ponte verso gli agenti locali è attivo.
# Il postino lo esegue e il suo stdout finisce in dal_pc/annuncia_ponte.md.

cat <<'EOF'
# 🌉 PONTE ARENA → AGENTI LOCALI — ATTIVO dal 3/11 sera

Puoi affidare compiti reali al PC del capo. Apri una **Issue** nel repo
(titolo: `PONTE: <cose da fare in breve>`) con questo corpo:

```
target: <agente>
compito:
<lavoro preciso: percorsi esatti, risultato atteso>

contesto:
<vincoli, cosa non toccare> (facoltativo)
```

Etichetta: `inbox` (va messa). Aggiungi `richiede-conferma` SOLO se l'azione
è irreversibile (cancellazioni, invii, pubblicazioni): il capo la approva a mano.

**Cosa succede**: entro ~40 secondi il poller sul PC prende la issue, la esegue
con l'agente locale scelto, consegna i risultati in `/consegne/<N>-.../` nel repo,
commenta la issue con l'esito e la chiude. Tu poi la rileggi ("stato della issue #N").
Aperta con `in-corso` = in esecuzione; chiusa = esito pronto.

**Agenti disponibili e a cosa servono:**
- `goose` — coding e automazioni su repo/file (WSL)
- `opencode` — coding e automazioni (WSL; già collaudato)
- `secondhand` — script Python, calcoli, estrazioni (Open Interpreter)
- `hermes` — compiti rapidi one-shot con strumenti
- `antigravity` — compiti leggeri (effort basso = economico)
- `openclaw` — cose legate a Gateway/chat/canali
- `test` — collaudo del canale (non usare per lavoro)

**REGOLE DI BUDGET (obbligatorie):**
1. Se il compito tocca il PC, DELEGA al ponte: non dare mai comandi CMD al capo.
2. Scegli l'agente più adatto: coding → goose/opencode; calcoli/script → secondhand;
   leggero → antigravity; veloce con strumenti → hermes.
3. La coda è ordinata (max 2 in parallelo, un task per agente): niente crash.
   Il contatore: quante issue aperte hanno `in-corso` = quanti agenti stanno lavorando.
4. Compito preciso = meno giri = meno crediti: dai percorsi e il risultato atteso.

Documentazione completa nel repo: `lavori/ponte/PROTOCOLLO.md`.
EOF
