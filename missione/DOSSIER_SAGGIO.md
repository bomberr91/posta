CONTESTO: abbiamo un router locale "cervello.py" (Portiere, porta 20129, Python puro senza
DB/Docker, su Windows+WSL1, utente principiante). Smista 7 agenti AI su modelli gratuiti,
custodisce le chiavi (gli agenti non ne hanno), ha fallback su riserva. DECISIONE GIA' PRESA
(non ridiscuterla): il cervello RESTA nostro, dai progetti esterni si copiano solo le idee.
Abbiamo raccolto 64 idee da 31 progetti analizzati; un analista le ha giudicate, un revisore
le ha ricontrollate: 45 SICURE, 6 parcheggi, 5 cacce, e 8 SONO SUL TAVOLO DEL CAPO.
REGOLE FERREE: costo zero (no carta/abbonamenti) · risparmio token = legge · chiavi solo nel
portachiavi del cervello · fallback solo sul modello "auto" · niente sonda LLM per richiesta ·
niente endpoint senza auth · Python puro semplice (SQLite ok, no Postgres/Redis).

LE 8 QUESTIONI APERTE (con parere di analista A, revisore R, regista REG):
1) IDEA 5 — Pagella provider (punteggio salute per provider + castigo/cooldown 30-120s a chi
   fallisce). A: decide-il-capo. R: parcheggio (teme tuning e costi nascosti). REG: SI' in F2,
   e' il cuore della fase affidabilita'; essendo tutto gratis la pagella sara' solo salute+velocita'.
2) IDEA 8 — Chiavi virtuali con budget per agente (tetto richieste). A: decide (sforzo L,
   rischio alto). REG: parcheggio, benefici gia' coperti in parte da 13+16.
3) IDEA 13 — Politiche per-agente in JSON ("OpenClaw: retry 3, fallback X; Hermes: cache on").
   A: decide (parser+logica complessa). REG: SI' ma F3 versione MINI (json semplice all'avvio).
4) IDEA 16 — Scope per chiave-agente (modelli permessi + quota/min per agente). A: decide.
   REG: fonderla con la 13 in un unico cantiere F3 "per-agente semplice".
5) IDEA 19 — Corsa tra provider (classifica per latenze misurate che scadono dopo 10 min;
   opzione "gare" con richieste doppie in parallelo). A: decide (instabilita'). REG: SI' a meta'
   in F2: classifica si', gare doppie NO perche' sprecano token.
6) IDEA 24 — on_status_codes (fallback solo su errori scelti: 429 si', 400 no) + retry
   esponenziale max 5. A: decide (refactor). REG: SI' in F2 solo questa meta', niente strategie
   annidate complete.
7) IDEA 36 — Auto-scoperta modelli da /v1/models all'avvio + igiene risposte (mai far
   trapelare errori grezzi del provider o pezzi di chiave; SSE senza doppio [DONE]).
   A: decide. REG: SI' in F2, l'igiene e' sacrosanta (il nostro SSE e' fatto a mano).
8) IDEA 41 — Installare freellmpool (pip) come SECONDA riserva accanto a OmniRoute.
   A: decide (ridondanza vs doppia manutenzione). REG: parcheggio; prima spremere OmniRoute.

IL TUO COMPITO (sei il TERZO PARERE, il consigliere saggio):
Per ognuna delle 8: di' se concordi col regista o no, con UN ragionamento asciutto ma profondo
(considera: semplicita' del codice, rischio di rompere cio' che funziona, resa reale per un
sistema casalingo con 7 agenti e traffico modesto, regole ferree). Segnala se tutti e tre
stiamo trascurando qualcosa. Chiudi con tabella: | questione | tua decisione | fase |.
Rispondi in italiano.
