# 🦾 OpenClaw — guida semplice (una volta sola, 3 minuti)

> **In una frase**: OpenClaw lo installiamo **su Windows**, non dentro Ubuntu. Dentro Ubuntu (WSL1) non può funzionare, e non è colpa tua né della configurazione: è un limite tecnico preciso (te lo spiego in fondo, in 5 righe).

---

## 1 · Cosa devi fare tu

### Passo 1 — apri la cartella giusta
Dalla Centrale: scegli **`[6]`** (apre la cartella `posta` in Esplora Risorse).
Oppure scrivi nella barra degli indirizzi di Esplora Risorse:

```
\\wsl.localhost\Ubuntu\home\agenti\posta
```

### Passo 2 — doppio clic su `INSTALLA_OPENCLAW.bat`
Si apre una finestra blu con un menu. Scegli:

```
[1]  TUTTO AUTOMATICO
```

e premi INVIO. **Non chiudere quella finestra**: lavora da sola per 2-5 minuti (scarica e installa). Ti scrive a ogni passaggio cosa sta facendo.

> Se Windows chiede «Windows ha protetto il PC» → **Ulteriori informazioni → Esegui comunque**. È un file di testo nostro, non un programma scaricato da chissà dove. (E non serve essere amministratore.)

### Passo 3 — leggi cosa ti dice alla fine
- **«FATTO: OpenClaw è installato su Windows»** → è a posto, vai al punto 2 qui sotto.
- **«FATTO: l'app grafica è stata scaricata»** → si è aperta la finestra di installazione dell'app: premi **Avanti** fino alla fine, poi apri **OpenClaw Companion** dal menu Start e scegli **Set up locally**.
- **«Non ci sono riuscito da solo»** → mandami il file del log che ti indica (`C:\Users\<il tuo nome>\openclaw_install.log`). Lo sistemo io. Non è tempo perso: nel log c'è scritto esattamente dove si è fermato.

### Passo 4 — torna nella Centrale
```
[v]   → il controllo salute deve dire OpenClaw ✓ (installato su Windows)
[1] → [e]   → apre OpenClaw
```

---

## 1-bis · «Ho già Node 22 per il Free LLM Hub» — va benissimo, anzi

Il tuo Node 22 è quello **di Windows** (lo usa `AVVIA_HUB.bat` → `node dev.js`). Con OpenClaw **non c'è nessun conflitto**, perché sono due mondi separati:

| | Chi lo usa | Lo tocchiamo? |
|---|---|---|
| **Node 22 su Windows** | Free LLM Hub (`node dev.js`) | ❌ **No. Resta com'è.** |
| **Node 22 dentro Ubuntu (WSL)** | agenti, OmniRoute, `[1]`…`[9]` | ❌ **No.** |
| **Node di OpenClaw** | solo OpenClaw | ✅ se lo gestisce lui, per conto suo |

OpenClaw ha un meccanismo apposta: se il Node che trova non va bene, **si installa un Node suo privato** dentro `~/.openclaw/tools/cli-node` e **lascia intatto il Node di sistema**. È per questo che nel `.bat`, al primo avvio, può comparire:

```
Update NodeJS: Y/N [N]:
```

→ **rispondi `Y`**. Fine. Il tuo Node 22 del Hub non viene spostato, aggiornato né disinstallato.

**Cose da NON fare** (per non rompere il Hub):
- non disinstallare Node 22;
- non cambiare la variabile PATH a mano;
- non installare nvm-windows per «fare ordine».

**Se anche l'installer aggiornasse il Node di Windows** (succede solo se lo ritiene troppo vecchio): il Free LLM Hub **continua a funzionare lo stesso**, perché è JavaScript puro senza dipendenze — `node dev.js` gira su Node 22, 24 e 26. Nel caso peggiore reinstalli il 22 da nodejs.org in 2 minuti, e i due Node possono convivere.

Come lo verifichi in un colpo: dalla Centrale `[v]`. Ora mostra **due righe separate**:

```
✓ Node v22 (Hub/Omni)     v22.22.3 · è quello che fa girare hub e agenti
✓ Node Windows (Hub)      v22.20.0 · serve al Free LLM Hub, si lascia stare
✓ OpenClaw (Windows)      installato · si apre con [1]→[e]
```

---

## 2 · Come lo usi, da qui in avanti

| Da dove | Come |
|---|---|
| **Centrale** | `[1]` poi `[e]` — apre OpenClaw (anche se è su Windows) |
| **Ubuntu** | `./apri_openclaw.sh` |
| **Windows** | doppio clic su `APRI_OPENCLAW.bat`, oppure menu Start → cerca «OpenClaw» |
| **App grafica** | menu Start → «OpenClaw Companion» (icona nel tray, chat, diagnostica) |

Il primo avvio ti fa qualche domanda (lingua, provider, canali): rispondi con calma, si fa una volta sola. Se preferisci, dal Prompt dei comandi di Windows:

```
openclaw onboard
```

Per controllare che stia bene, in qualsiasi momento:

```
openclaw --version
openclaw doctor
openclaw gateway status
```

---

## 2-bis · Come lo usi (senza mai aprirlo a mano)

Il punto è che OpenClaw **non è un'app da aprire**: è un servizio che gira sotto. Una volta acceso il **Gateway**, resta lì e risponde. Da quel momento:

| Dove | Cosa fai |
|---|---|
| **Centrale → GUI (`[g]`)** | scheda **🦾 OpenClaw**: `▶ Accendi` / `🩺 Diagnostica` / `🔄 Riavvia` / `🖥 Interfaccia` |
| **Hub + Agenti** (in arrivo) | OpenClaw entra come **motore disponibile**, perché parla la stessa lingua di OpenAI: `http://127.0.0.1:18789/v1` |
| **Terminale** | `./openclaw_stato.sh` → dice tutto in 5 righe (installato? acceso? configurato?) |

### I due pulsanti che contano

1. **⚙️ Configura ora** — una volta sola. Apre una finestra su Windows con le domande di OpenClaw (lingua, provider, canali): rispondi lì, poi torna nella GUI e premi *Controlla*.
2. **▶ Accendi** — installa il Gateway come **servizio**: da quel momento **parte da solo all'accensione del PC**, e la Centrale lo trova sempre acceso. Non dovrai più aprirlo tu.

Quando è acceso, il semaforo in GUI diventa 🟢 e compare l'indirizzo:
`http://localhost:18789` (interfaccia) · `http://127.0.0.1:18789/v1` (API per il Hub).

---

## 3 · Se qualcosa non va

| Cosa vedi | Cosa fare |
|---|---|
| Il `.bat` si apre e si chiude subito | Aprilo da **Esplora Risorse** con doppio clic, non da dentro un altro programma. Se persiste: tasto destro → **Esegui come amministratore**. |
| «iwr non è riconosciuto» | Manca PowerShell: aggiorna Windows, oppure scegli `[3]` (app grafica, non usa PowerShell). |
| Download bloccato / lento | Rifai `[1]`: riparte da dove serve. Se continua, scegli `[3]`. |
| Installato ma `openclaw` non si trova | Chiudi e riapri la finestra (il PATH si aggiorna al nuovo avvio). Se ancora no: riavvia il PC una volta. |
| Compare `Update NodeJS: Y/N [N]:` | Rispondi **Y**: OpenClaw si mette un Node privato, il tuo resta dov'è. |
| La salute resta ✗ | Mandami l'output di `./apri_openclaw.sh --trova` e il log. |
| Vuoi disinstallarlo | Impostazioni → App → «OpenClaw» (o «OpenClaw Companion») → Disinstalla. |

**Regola**: se non funziona, non insistere a ripetere gli stessi passi — mandami `~/openclaw_install.log` (o `C:\Users\<nome>\openclaw_install.log`) e ci penso io.

---

## 4 · Perché non «installo Node 24 e via» (la verità in 5 righe)

1. OpenClaw, **dalla versione v2026.9.3**, richiede **Node ≥ 24.16** (prima bastava il 22). Non è una cosa di ieri: è una soglia alzata da loro.
2. Su **WSL1** (il tuo Ubuntu dentro Windows) i Node **23 e 24 non partono affatto**: `cannot execute binary file: Exec format error`. Motivo: quei binari hanno un segmento di memoria allineato a 2 MB che WSL1 rifiuta (bug noto `nodejs/node#63735`). Il Node 22 funziona proprio perché usa il formato vecchio.
3. Quindi non esiste un «Node 24 dentro WSL1 che funziona»: non è questione di saperlo installare.
4. **Su Windows invece Node 24 e 26 girano benissimo** — e l'installer ufficiale di OpenClaw se lo porta dietro da solo. Zero Node da gestire a mano.
5. L'alternativa (se un giorno vuoi tutto dentro Ubuntu) è **Bun**, che non ha bisogno di Node: `./openclaw_fix.sh` ci prova da solo. Ma la strada consigliata, anche da OpenClaw, è quella Windows.

---

## 5 · Cosa ho già fatto io (così sai cosa aspettarti)

- `INSTALLA_OPENCLAW.bat` — installa su Windows in automatico, con log e senza privilegi di amministratore.
- `APRI_OPENCLAW.bat` — lo apre con un doppio clic.
- `apri_openclaw.sh` — trova OpenClaw ovunque sia (Ubuntu, Bun, Windows) e lo lancia: è quello che usa la Centrale con `[1]→[e]`.
- `openclaw_fix.sh` — prova Windows nativo, poi Bun, e se non riesce ti dice cosa fare. Non tenta più Node 24 su WSL1 (era tempo perso).
- `verifica.sh --[v]` — ora vede anche la versione installata su Windows.

---

*Ultimo aggiornamento: 20/10/2026 · se qualcosa non torna, dimmelo e correggo la guida.*
