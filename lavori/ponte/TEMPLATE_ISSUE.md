# TEMPLATE_ISSUE — formato che usa l'agente di arena

L'agente di arena (o tu a mano) apre la issue con questo corpo esatto.
I campi si leggono per riga: `campo: valore`. `compito` e `contesto` possono
essere su più righe, finché non inizia il campo successivo.

```markdown
target: goose
consegna: /consegne/issue-<NUMERO>/

compito:
Riscrivi la funzione `esporta_csv` nel progetto X perché gestisca
le date in formato ISO. Verifica con un test prima di dichiarare fatto.

contesto:
Il progetto è in /home/agenti/progetti/x. Python 3.12. Non toccare
altri moduli. Report in italiano.
```

## Regole per chi scrive la issue
- `target`: DEVE essere una chiave di "agenti" in `ponte.json`
  (es. `openclaw`, `goose`, `hermes`, `opencode`, ...)
- `consegna`: facoltativo; default `/consegne/<numero>-<slug>/`
- `compito`: il lavoro. Più è preciso, meno crediti e meno giri brucia l'agente
  (percorsi esatti, nomi file, risultato atteso).
- `contesto`: facoltativo; vincoli, percorsi, cose da NON fare.
- **Titolo**: `PONTE: <riassunto in 5-8 parole>`
- Se l'azione è delicata (cancellazioni, invii, pubblicazioni): aggiungi
  l'etichetta `richiede-conferma`. Il poller non la tocca finché TU non la rimuovi.

## Lettura esito (lato arena)
- Issue **chiusa** → guarda l'ultimo commento: riepilogo + cartella di consegna.
- Issue **aperta** con `in-corso` → lavoro in esecuzione.
- Issue **aperta** con `inbox` → in attesa (o `richiede-conferma` da approvare).
- Issue con `bloccato` → 3 tentativi falliti, leggere i commenti per gli errori.
