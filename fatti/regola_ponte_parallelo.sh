#!/bin/bash
# regola_ponte_parallelo.sh — istruzione operativa per arena: auto-regolazione paralleli.
cat <<'EOF'
# 🌉 PONTE — regola di auto-regolazione (paralleli)

Prima di aprire una issue `PONTE:` fai questo conto:
1. Conta le issue APERTE con etichetta `in-corso` (sono gli agenti al lavoro).
2. Se sono già **2** (il massimo parallelo): NON aprirne una terza adesso —
   aspetta che una si chiuda, oppure apri la issue ma sappi che resterà
   in coda (il poller non la esegue finché non si libera uno slot).
3. Mai più di 2 task in volo: apertura della terza solo a coda libera.
4. Un task per agente: se `goose` è già in-corso, il prossimo task per goose
   aspetta il suo turno (usa un altro agente se il compito è urgente).

Il sistema comunque protegge (la coda tiene l'ordine e non c'è mai crash),
ma questa regola ti fa PIANIFICARE invece di accumulare: meno attese,
meno crediti bruciati a controllare issue ferme.
EOF
