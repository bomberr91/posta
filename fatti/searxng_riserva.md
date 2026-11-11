# Riserva di ricerca SearXNG — stato e ricetta (11/11)

Le issue #54 (due giri) si sono chiuse con «exit 0» senza produrre questo file.
L'orchestratore lo scrive qui; l'**istanza Docker gira sul PC**, non nel sandbox.

## Ricetta (già verificata in `LEGENDA_SISTEMA.md`)

1. `docker run -d --name searxng -p 8080:8080 searxng/searxng:latest`.
2. Abilitare `formats: [html, json]` nel `settings.yml` dell'istanza (il progetto Vane
   lo prevede in `searxng/settings.yml:8-10`).
3. Collaudo: `http://127.0.0.1:8080/search?q=test&format=json` ⇒ JSON con risultati.
4. Aggancio come **riserva** in `lavori/cerca.sh` / Deep Dog :8765, dominio di guasto
   `ip-diverso`, switch **solo in freno/esaurimento di Tavily** (oggi unico titolare vivo:
   `SOSPESI.md:26-27`, Exa = 0 risultati). **Non toccare il titolare**.
5. ⚠️ **AGPL-3.0** (letta nel FILE `LICENSE` di `searxng/searxng`): uso interno ok;
   se offerto come servizio in rete va rilasciato il sorgente.

## Perché non è ancora attivo

Il sandbox non raggiunge il PC (`curl 127.0.0.1:20129` → HTTP 000 / exit 7). Il compito
in linguaggio naturale affidato a `secondhand` non ha prodotto output. È stato quindi
trasformato nello **script deterministico** `da_me/attiva_searxng.sh`: lo esegue il
postino con `bash`, e scrive sempre un referto con esito o errore esatto (niente falsi verdi).

Nessuna chiave in questo file.
