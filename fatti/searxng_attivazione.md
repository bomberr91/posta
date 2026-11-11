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

## SEGUITO (stesso turno): istanza avviata DAVVERO, senza Docker

Ho aggirato l'assenza di Docker avviando SearXNG **nativo** nel sandbox
(`searxng/searxng` clonato, venv con `requirements.txt`, settings con
`formats: [html, json]` + `port: 8080` + engine `demo_offline`).

- `GET /search?q=test&format=json` → **HTTP 200**, JSON valido (**4 results**).
- **Collaudo end-to-end di `cerca.sh`** con portachiavi finto (titolari muti) → la
  riserva è scattata e ha stampato **3 risultati reali**:

```
RISERVA SearXNG (titolari senza risultati):
  - Test della riserva ovarica: scopo, risultati, range normale e altro
    https://www.apollohospitals.com/it/diagnostics-investigations/ovarian-reserve-testing
  - Valutazione Riserva Ovarica - Vis Procreandi Fertility Center
    https://visprocreandi.it/diagnostica/valutazione-riserva-ovarica/
  - RISERVA COGNITIVA: cos'è e come si misura?
    https://www.neuropsicologiaweb.it/index.php/neuropsicologia/test/65-riserva-cognitiva-cos-e-e-come-si-misura?showall=1
```

`bash -n` OK, `rc=0`. ⇒ La riserva non è più solo codice: è stata **eseguita e verificata**.
Il servizio nel sandbox è temporaneo (processo avviato per il collaudo, poi fermato);
sul PC resta da renderlo persistente con Docker o con la stessa via nativa.
