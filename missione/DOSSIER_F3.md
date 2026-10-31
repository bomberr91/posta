# DOSSIER FASE 3 — moduli per il Portiere (cervello.py, porta 20129)
Regole per TUTTI i moduli: Python PURO (solo libreria standard) · commenti in
italiano · nessuna rete, nessun file letto/scritto se non indicato · ogni modulo
chiude con un blocco `if __name__ == "__main__":` pieno di assert di collaudo
che stampano anche la percentuale di risparmio dove sensato. RISPONDI SOLO col
codice del modulo dentro UN UNICO blocco ```python ... ```.

## MODULO 1 — compressione.py (idee 1-2 del quaderno, scuola Lynkr)
Scopo: risparmiare token prima di mandare le richieste ai provider gratuiti.
Funzioni richieste:
1. `alleggerisci_tools(tools)` → lista tools ridotta: per ogni tool tieni SOLO
   name, description tagliata a 110 caratteri, e dei parametri SOLO quelli in
   "required" (con type, senza descrizioni). Ritorna (tools_ridotti, caratteri
   risparmiati). Deve reggere tools malformati senza esplodere.
2. `json_a_toon(oggetto, indent=0)` → stringa compatta stile TOON: dizionari come
   righe "chiave: valore" indentate (2 spazi per livello), liste di dizionari
   OMOGENEI come tabella (prima riga intestazioni separate da |, poi una riga
   per elemento). Niente parentesi, niente virgolette superflue.
3. `comprimi_system(testo)` → se dentro al testo di sistema ci sono blocchi JSON
   (tra ``` o tra { }), li converte con json_a_toon; il resto resta intatto.
   Ritorna (testo_nuovo, caratteri_risparmiati).
4. `taglia_storia(messaggi, max_caratteri)` → tiene sempre: tutti i system, gli
   ultimi 4 messaggi interi; i messaggi vecchi in mezzo vengono riassunti in UNA
   riga ciascuno ("[tagliato: role, N caratteri]") finché il totale scende sotto
   max_caratteri. MAI toccare l'ultimo messaggio utente. Ritorna lista nuova.
Collaudi attesi: tools finti con 3 funzioni verbose → risparmio >40% · un JSON
tabellare da 20 righe → risparmio >50% con json_a_toon · storia da 30 messaggi
tagliata sotto 4000 caratteri senza perdere system e ultimi 4.

## MODULO 2 — per_agente.py (idee 13+16 del quaderno, versione mini decisa dal capo)
Scopo: profili per-agente letti da un JSON FACOLTATIVO.
Formato file portiere_profili.json:
  { "goose-": {"max_tokens": 900, "temperature": 0.2, "politica": "veloce",
                "comprimi": true},
    "opencode-": {"politica": "code"} }
Le chiavi sono PREFISSI dell'id sessione dell'agente.
Funzioni richieste:
1. `carica_profili(percorso)` → dict; se il file manca torna {}; se il JSON è
   rotto torna {} E ritorna anche un messaggio d'errore chiaro (tupla), mai
   eccezioni (il saggio: default robusti + log chiari).
2. `profilo_di(sessione, profili)` → il profilo del primo prefisso che combacia,
   altrimenti None.
3. `applica_profilo(payload, profilo)` → copia del payload con: max_tokens solo
   se l'agente non l'ha già messo PIÙ BASSO; temperature solo se assente; la
   chiave "model" sostituita con profilo["politica"] SOLO se il payload chiede
   "auto". Ritorna (payload_nuovo, note) dove note è la lista delle modifiche
   fatte (per il log glass-box).
Collaudi attesi: file mancante → {} senza errori · JSON rotto → {} + messaggio ·
profilo applicato senza calpestare le scelte esplicite dell'agente.
