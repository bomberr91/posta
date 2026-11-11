# Attivazione SearXNG — referto reale (11/11, orchestratore)

## Applicato (codice)
Riserva **scritta in `lavori/cerca.sh`**: funzione `riserva(q, n)` che chiama
`http://127.0.0.1:8080/search?q=...&format=json`, usata **SOLO** quando Exa+Tavily
sono muti o non producono risultati (freno/esaurimento). Dominio di guasto `ip-diverso`,
nessuna chiave, nessuna quota, titolare Tavily **non toccato**. `bash -n lavori/cerca.sh`
→ **OK**.

## NON applicato (servizio)
`command -v docker` → **ASSENTE nel sandbox**; nessun processo SearXNG su `:8080`
(`curl` darebbe connection refused). L'istanza Docker va sul PC.

## Perché prima non c'era questo file
`poller.py:336` (`ok = exit_code == 0`) + `secondhand_run.sh:28` (`exec interpreter exec`):
uscita 0 con output vuoto ⇒ «COMPLETATO» senza referto. La delega in linguaggio naturale
è stata **sostituita dalla modifica reale al codice** qui sopra; gli script pronti restano
in `fatti/` (non piu' in `da_me/`, quindi **nessuna coda pendente**).

Titolare intatto: `cerca.sh` modificato solo per AGGIUNGERE la riserva.
Nessuna chiave, token o credenziale in questo file.
