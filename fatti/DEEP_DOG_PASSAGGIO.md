# DEEP DOG — passaggio di consegne all'altro agente (4/11 sera)

Documento di handover scritto dall'orchestratore. Serve a far ripartire il
lavoro **senza rifare gli stessi errori** e a sapere esattamente **da che
punto siamo** e **cosa deve essere vero alla fine**.

> Stato in una riga: **il codice è a metà strada, il cane è GIÙ, e l'agente #39
> è appeso da ~30 minuti.** La destinazione è chiara e ripetibile in 6 comandi.

---

## 1. Che cos'è Deep Dog (il "cane")

Il **sistema di ricerca degli agenti**: gli agenti gli chiedono una ricerca e
lui risponde. Non è un agente del ponte, è uno strumento a cui gli agenti
chiedono.

| cosa | dove |
|---|---|
| Cartella (Windows) | `C:\Users\giopi\Documents\AgentWorkspace\deepdog` |
| Cartella (WSL) | `/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog` |
| Servizio web | porta **8765** → `http://127.0.0.1:8765` |
| Avvio | `Avvia Deep Dog Web.bat` (nella sua cartella) |
| Codice chiave | `web_app.py` (UI + API), `deep_research/config.py` (mappa dei modelli), `.env` |
| Wrapper per gli agenti | `lavori/deepdog_ricerca.sh` (nel repo `bomberr91/posta`) |
| Report | `dal_pc/deepdog_reports/` (il postino li pubblica nel repo) |
| Cervello locale | `http://127.0.0.1:20129/v1`, chiave fissa `sk-cervello`, `model=auto` |

Il wrapper fa tutto da solo: controlla che il cane sia vivo, **se non gira lo
riavvia lui**, manda la domanda (`POST /api/start`), aspetta il report (max 10
min), lo copia in `dal_pc/deepdog_reports/` e dice dove sta il file.

---

## 2. Perché siamo qui (punto di partenza, 4/11 sera)

- Nel libro mastro (`lavori/assegnazioni_provider.tsv`) la riga **Deep Dog**
  era: `Deep Dog | - | OpenRouter;Tavily;Exa;DeepSeek | diretto | - | ATTIVO`.
- **`OpenRouter` è anche nel roster del cervello (20129) e la usa
  l'orchestratore** ⇒ il verificatore segnalava il conflitto *"due strumenti
  sulla stessa chiave"*. È l'**unico conflitto rimasto** in tutto il libro
  mastro (gli altri sono chiusi).
- Ordine del capo (4/11 sera): **«ok per deepdog chiama chiavi dal cervello —
  fallo fare a un agente in locale la correzione»**.

---

## 3. Destinazione finale (cosa deve essere vero quando finisce)

1. **Deep Dog chiama il LLM del cervello locale**: `base_url http://127.0.0.1:20129/v1`,
   `api_key sk-cervello`, `model "auto"` (il cervello accetta `auto` e risponde `auto`).
2. **Le chiavi di ricerca (Tavily, Exa) restano**: sono strumenti di ricerca,
   non provider — si condividono per natura (il libro mastro le conta ma non
   le marca come conflitto).
3. **OpenRouter/DeepSeek non vengono più usate per le chiamate LLM** del cane.
   Le chiavi **non si cancellano** (restano nel portachiavi).
4. **Una ricerca vera** col wrapper finisce con `stato: done|completed` e
   produce un report in `dal_pc/deepdog_reports/`.
5. **Prova nei log**: `portiere_log.jsonl` (nel repo del PC) mostra la richiesta
   al cervello (`"rotta": "motore", "modello": "auto"`) e **non** errori OpenRouter.
6. **Libro mastro**: la riga Deep Dog passa a `via=cervello` ⇒ **0 conflitti**.
7. **Il cane resta avviato**, in **una sola** finestra CMD (il capo ha chiuso
   le sue e non ne vuole altre: niente Chrome all'avvio).

---

## 4. Cronologia dei tentativi (tutti, con l'esito)

| # | Chi | Cosa ha fatto | Esito |
|---|---|---|---|
| #31 | goose | ha commentato `OPENROUTER_API_KEY` nel `.env`, ha cambiato `base_url/api_key/model` in `web_app.py`, `route_via_openrouter=False` in `config.py` | **metà**: ha **ucciso** il servizio e non l'ha riavviato (la `.bat` è Windows) |
| #32 | goose | riavvio con path **WSL** dentro `cmd.exe` | **fallito**: timeout, porta 8765 chiusa; file ripristinati dal backup |
| #33 | goose | riavvio col path Windows; aggiunto provider `cervello` alla mappa `model_providers` | servizio **SU**, ma 2° edit fallito («No match found») e nessun collaudo |
| #34 | opencode | stato + «quale finestra chiudere» | **falso negativo**: `ps` dalla WSL non vede i processi Windows ⇒ disse «servizio NO» mentre la porta era **APERTA** |
| #35 | goose | opzione «cervello» nella `<select>` + default `model_provider = "cervello" if os.environ.get("CERVELLO_API_KEY") else …` | servizio su (5 test di fila **APERTA**), ma collaudo fallito (wrapper non eseguibile) |
| #36 | goose | riavvio + collaudo | **falso verde**: chiusa in 32 s con un `tasklist` e nient'altro |
| #37 | goose | riavvio | chiusa in 21 s, output incompleto |
| #38 | goose | collaudo | **inutile**: ha risposto con i comandi da incollare a mano («non devi fare altro che copiarli») ⇒ **mai chiedere al capo di fare CMD** |
| #39 | goose | fix del codice (campo chiave cervello + «missing» dipendente dal provider) + riavvio + collaudo | **appeso da ~30 minuti**, ancora `in-corso`; **ha però riscritto `web_app.py`** (vedi §5) |
| script `deepdog_cervello_collaudo.sh` | orch. | collaudo meccanico | **scoperta chiave**: il cane chiama **OpenRouter** ⇒ errore **402 «requires more credits»** (quota OpenRouter a zero) |
| script `deepdog_riattiva_collaudo.sh` | orch. | `POST /api/setup` | **400 «Opzione di setup non valida»** ⇒ imparate le opzioni valide (§6) |
| script `deepdog_riattiva_collaudo2.sh` | orch. | `POST /api/setup` minimale | **200 OK**, `model_provider: "cervello"` ✔ ma `ready:false, missing:["DEEPSEEK_API_KEY","DEEPSEEK_KEY"]` ⇒ blocco del check «pronto»; ha poi **ucciso il solo PID sulla 8765** e riavviato ✔ |
| script `deepdog_fix_cervello_v4.sh` | orch. | patch UI + riavvio | patch non agganciata (il file è stato riscritto dall'agente #39 ⇒ pattern diversi) e **il cane non è più ripartito** ⇒ **oggi il cane è GIÙ** |

**Incidente collaterale (risolto)**: l'agente #31 stampò una chiave vera nella
consegna ⇒ GitHub respinse la push del repo **pubblico** («GH013 – Push cannot
contain secrets») ⇒ **ogni push dal PC era bloccato, il ponte era fermo**.
Rimedi: script di sanifica sul PC (reset soft + maschera + push), **patch al
poller** (maschera le chiavi prima di committare), riavvio del poller. Da quel
momento nei referti si scrive sempre `«chiave mascherata»`.

---

## 5. Lo stato ESATTO adesso (4/11, ~18:10)

**Fatto ✔**
- `deep_research/config.py`: la mappa `model_providers` contiene
  `"cervello": {"base_url": "http://127.0.0.1:20129/v1", "api_key": "sk-cervello", "model": "auto"}`
  (aggiunto dall'agente #33).
- `web_app.py`: l'opzione `<option value="cervello">Cervello</option>` c'è nella
  `<select>` della card «Setup» (#35) e **l'agente #39 ha riscritto il file**:
  `keyFields` è ora un dizionario su più righe con
  `CERVELLO_API_KEY: ["cervelloKey", "cervelloState"]` ✔.
- `web_app.py`: la validazione del setup **accetta** `cervello`
  (`model_provider not in ("cervello", "deepseek", "openrouter")` ⇒ ok).
- `.env`: `CERVELLO_API_KEY=sk-cervello` **aggiunto** (chiave fissa del
  portone, non è una chiave provider); `OPENROUTER_API_KEY` c'è ancora ma
  non viene usata se il provider è «cervello».
- `lavori/deepdog_ricerca.sh` (nel repo): **corretto** — non usa più `curl`
  (assente nella WSL del PC) ma `python3/urllib` ✔, ed è `chmod +x` ✔.
- Il wrapper **riavvia il cane da solo** se non gira ✔.

**Non fatto / rotto ✘**
- **IL CANE È GIÙ**: l'ultimo script ha ucciso il processo sulla 8765 e il
  riavvio non è riuscito ⇒ `/api/status` dà *Connection refused*, porta 8765
  chiusa. **Prima cosa da fare: rimetterlo su.**
- **L'agente #39 è appeso** (etichetta `in-corso` da ~30 minuti): potrebbe
  essere lui a tenere il cane giù o a litigare con il riavvio. **Va chiuso o
  lasciato terminare prima di cominciare.**
- **Il check «pronto» (`missing`)**: quando era su "cervello" si fermava con
  «Apri Setup e configura: DEEPSEEK_API_KEY, DEEPSEEK_KEY» ⇒ il calcolo delle
  chiavi mancanti chiede **sempre** la chiave DeepSeek, anche col provider
  «cervello» (che non usa chiavi nostre). **Da correggere in `web_app.py`
  (righe ~85-95)**: se `model_provider == "cervello"` ⇒ `missing = []`.
- Il campo di input della chiave del cervello nella UI (`id="cervelloKey"`)
  **non è stato verificato**: il `keyFields` c'è, ma nel HTML il campo forse
  manca ⇒ controllare (riga ~265).

---

## 6. I 6 comandi per finire (in quest'ordine)

```bash
# 1) chiudere l'agente appeso #39 (o attendere che finisca)
#    (dal lato GitHub: togliere l'etichetta "in-corso" alla issue #39)

# 2) rimettere su il cane — path WINDOWS dentro cmd.exe (mai /mnt/c!)
cd /mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog
cmd.exe /c start "" "C:\Users\giopi\Documents\AgentWorkspace\deepdog\Avvia Deep Dog Web.bat"

# 3) verificare la porta (attendere 15-30 s, ripetere 5 volte con 10 s di attesa)
python3 -c "import socket;s=socket.socket();s.settimeout(5);print('APERTA' if s.connect_ex(('127.0.0.1',8765))==0 else 'CHIUSA')"

# 4) impostare il provider a runtime (opzionale se il .env è già a posto:
#    il default diventa "cervello" SOLO se il servizio è partito DOPO l'aggiunta)
python3 - << 'EOF'
import json, urllib.request
req = urllib.request.Request("http://127.0.0.1:8765/api/setup",
    data=json.dumps({"keys": {"CERVELLO_API_KEY": "sk-cervello"},
                     "model_provider": "cervello"}).encode(),
    headers={"Content-Type": "application/json"}, method="POST")
print(urllib.request.urlopen(req, timeout=90).read().decode()[:300])
EOF

# 5) COLLAUDO vero
bash /home/agenti/posta/lavori/deepdog_ricerca.sh "che modelli offre il cervello locale?"
#    -> deve dire "stato: done" (o completed) e produrre il report

# 6) PROVA
tail -5 /home/agenti/posta/portiere_log.jsonl      # deve comparire la richiesta al cervello
python3 -c "import json,urllib.request;print(json.load(urllib.request.urlopen('http://127.0.0.1:8765/api/status',timeout=10))['model_provider'])"
```

**Se al punto 5 l'errore è ancora «Apri Setup e configura: DEEPSEEK_API_KEY»** ⇒
manca il fix del check «pronto» (§5) ⇒ in `web_app.py`, dove si costruisce la
lista `missing`, aggiungi: se il provider scelto è `cervello`, la lista delle
chiavi mancanti è vuota (il cervello non usa chiavi nostre).

**Opzioni valide del setup** (l'API le valida, righe ~377-383 di `web_app.py`):
`model_provider ∈ {cervello, deepseek, openrouter}` ·
`search_provider ∈ {exa, tavily, both}` · `speed_profile ∈ {fast, deep}`
(⚠ `standard`/`balanced` **non** esistono ⇒ 400 «Opzione di setup non valida»).

---

## 7. Trappole (NON ripeterle)

1. **`cmd.exe` va dato con il path WINDOWS** (`C:\...`), mai `/mnt/c/...`: con il
   path WSL va in timeout e non apre niente.
2. **MAI `taskkill /IM python.exe`**: il cervello gira in WSL ma la regola
   vale comunque — per chiudere il cane: `cmd.exe /c netstat -ano | findstr
   8765` → prendi il PID finale → `taskkill /F /PID <pid>`.
3. **`curl` non esiste nella WSL del PC** ⇒ `python3`/`urllib` (già fixed nel
   wrapper).
4. Il file del wrapper non era eseguibile ⇒ lanciarlo con `bash` davanti (ora
   è `chmod +x`).
5. **Una chiave vera in un file del repo ⇒ GitHub blocca la push (GH013) e il
   ponte si blocca.** Nei referti: `«chiave mascherata»`.
6. **goose è inaffidabile sul multi-step**: chiude con `exit 0` senza aver
   fatto (vedi #36, #37, #38) e una volta ha risposto con i comandi da incollare
   a mano ⇒ **mai chiedere al capo di fare CMD**.
   **opencode scrive solo dentro il repo** ⇒ non può toccare la cartella del
   cane ⇒ per il codice serve goose **o uno script deterministico in `da_me/`**
   (è la strada che funziona).
8. **Dal WSL `ps` non vede i processi Windows** ⇒ per sapere chi tiene il cane
   usare `cmd.exe /c tasklist` o `netstat -ano`.
9. Nel `da_me/` **i file `.py` vengono archiviati come compiti** dal postino ⇒
   il python va **dentro** lo `.sh` (heredoc), non in un file a parte.
10. Il postino esegue `da_me/*.sh` sul PC e scrive il referto in
    `dal_pc/<nome>.md`; i file degli agenti vanno in `fatti/`.
11. Il repo `posta` è **pubblico**: chiavi mai dentro.

---

## 8. Dove trovi TUTTI i documenti dei tentativi

Repo `bomberr91/posta` (questo stesso repo):

| cosa | percorso |
|---|---|
| consegna #31 (primo giro, metà lavoro) | `consegne/31-deep-dog-passa-dal-cervello-locale-nient/RISULTATO.md` |
| consegna #32 (riavvio fallito, path WSL) | `consegne/32-riavvia-deep-dog-su-windows-e-collauda-c/RISULTATO.md` |
| consegna #33 | `consegne/33-rimetti-in-piedi-deep-dog-path-windows-e/RISULTATO.md` |
| consegna #34 (falso negativo opencode) | `consegne/34-stato-reale-di-deep-dog-e-quale-finestra/RISULTATO.md` |
| consegna #35 | `consegne/35-finisci-il-collegamento-di-deep-dog-al-c/RISULTATO.md` |
| consegna #36 (falso verde) | `consegne/36-deep-dog-in-una-sola-finestra-collaudo-v/RISULTATO.md` |
| consegna #37 | `consegne/37-riattiva-deep-dog-una-sola-finestra/RISULTATO.md` |
| consegna #38 | `consegne/38-collaudo-deep-dog-sul-cervello-env-ricer/RISULTATO.md` |
| **collaudo 1** (scoperta OpenRouter 402) | `dal_pc/deepdog_cervello_collaudo.md` |
| **collaudo 2** (400 + opzioni valide) | `dal_pc/deepdog_riattiva_collaudo.md` |
| **collaudo 3** (setup OK, `missing` DEEPSEEK) | `dal_pc/deepdog_riattiva_collaudo2.md` |
| **collaudo 4** (patch UI, cane giù) | `dal_pc/deepdog_fix_cervello_v4.md` |
| stato letto da opencode | `fatti/stato_deepdog.md` |
| script usati | `da_me/deepdog_cervello_collaudo.sh`, `da_me/deepdog_riattiva_collaudo.sh`, `da_me/deepdog_riattiva_collaudo2.sh`, `da_me/deepdog_fix_cervello_v4.sh` |
| wrapper degli agenti | `lavori/deepdog_ricerca.sh` |
| libro mastro (riga Deep Dog) | `lavori/assegnazioni_provider.tsv` |
| issue di ponte | GitHub `bomberr91/posta`, issue #31→#39 |
| storico di cominciamento | `dal_pc/deepdog_diagnosi.md`, `dal_pc/deepdog_fix.md`, `dal_pc/deepdog_mistero.md`, `dal_pc/deepdog_report_sambanova.md` (giorni precedenti) |

---

## 9. Protocollo per lavorare sul PC (come fanno gli agenti qui)

**Due strade, entrambe nel repo `bomberr91/posta`:**

1. **Issue di ponte** — apri una issue GitHub con titolo `PONTE: <cosa>` e corpo:
   ```
   target: goose|opencode|hermes|antigravity
   compito:
   <istruzioni>
   ```
   Il poller la prende (etichetta `in-corso`), esegue l'agente, scrive
   `consegne/<N>-<slug>/RISULTATO.md`, commenta e chiude. **Max 2 `in-corso`.**
2. **Script deterministico** — scrivi `da_me/<nome>.sh` (il postino lo esegue
   sul PC e scrive `dal_pc/<nome>.md` con l'output). È la strada vincente per
   i passi meccanici.

**Regole**: niente chiavi nel repo · un task per agente · i file prodotti in
`fatti/` · spiegare il compito a parole prima di delegare · nessuna azione
irreversibile senza l'OK del capo · **mai far eseguire CMD al capo**.

---

## 10. Le mie lezioni (se leggi solo una parte, leggi questa)

- «Se il dato viene da un test che può solo dire sì, non è un dato.» (il
  falso verde di opencode: `ps` non vede i processi Windows ⇒ «servizio NO»
  mentre la porta era aperta).
- «Un HTTP 200 non è una prova.» (il 200 di `/api/setup` con `ready:false`).
- «Il vero verde lo dà il test meccanico, non l'exit 0 del ponte.»
- «Dopo 2 falsi verdi di agenti, l'orchestratore riscrive e collauda da sé.»
- «Un canale che può fallire in silenzio è un canale morto.» (il wrapper con
  `curl` assente: la ricerca degli agenti non è mai arrivata al cane).
- «Niente si butta senza la conferma del capo» (le chiavi OpenRouter/DeepSeek
  restano nel portachiavi: si smettono di usare, non si cancellano).
