# IL CERVELLO DI CASA — cosa è e dove duole (il quadro per i cloni)

Componenti vivi:
- **cervello.py** (:20129) — il portiere: un'API OpenAI-compatible; instrada a OmniRoute
  (:20128) e alla riserva (54 provider, chiavi vere); castighi per (chiave, modello),
  pagelle, cache ESATTA (assorbe il 94% del traffico), log glass-box, uso per agente
  (14 giorni), tetto per agente con approvazione (nuovo 13/11), guardia solo-gratis.
- **OmniRoute** (:20128) — il motore: 359 provider catalogati, 90+ gratis.
- **GUI Hub** (:20200) + **pannello AGENTI LIVE** (:20201, nuovo 13/11) + Centrale (menu).
- I buchi/aperti: **compressione contesto NON implementata** (idea TOON nel quaderno),
  **cache semantica valutata e NON montata** (la cache esatta copre il 94%: la semantica
  servirebbe all'1-2% — serve un embedding leggero per valutarla bene),
  **osservabilità live delle sessioni agente** (il pannello ora ha i battiti, manca
  lo stream di cosa fanno dentro), XERJ-like per la ricerca a basso token.

Vincoli di casa: costo 0 · Python stdlib (dipendenze solo se giustificate) · niente Docker
per il cervello · solo localhost · Windows+WSL2 · non rompere le 36/36 test.
Il costo vero da ottimizzare: le ~114 richieste VERE al giorno portano contesti grandi
(primi 10 turni di chat + documenti): chi comprime l'INPUT risparmia di più di chi ottimizza la rotta.
