#!/usr/bin/env bash
# team_nararouter.sh — 3 agenti in parallelo per sbloccare e usare il modello
# GRATIS di NaraRouter (7.000.000 di token che il capo non riesce a usare).
# La chiave non viene MAI stampata: si legge dal portachiavi e si usa dentro le richieste.
set -u
cd "$HOME/posta" || exit 1
W=/tmp/nararouter
mkdir -p "$W"

if [ -s "$HOME/CHIAVI_LOCALI.md" ]; then
  OC_KEY=$(grep -oE 'oc_sk_[A-Za-z0-9_-]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
  [ -n "$OC_KEY" ] && export OPENCODE_API_KEY="$OC_KEY"
fi
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

echo "=== MISURA ADESSO (dal PC) ==="
KEY=$(python3 chiave_di.py "NaraRouter" 2>/dev/null | head -1)
if [ -z "$KEY" ]; then
  echo "chiave NaraRouter non trovata nel portachiavi"
else
  NARAKEY="$KEY" python3 - << 'PY'
import os, json, urllib.request, urllib.error
key = os.environ.get("NARAKEY", "")
def call(method, path, body=None):
    h = {"User-Agent": "Mozilla/5.0", "Accept": "application/json", "Authorization": "Bearer " + key}
    d = json.dumps(body).encode() if body is not None else None
    if d: h["Content-Type"] = "application/json"
    req = urllib.request.Request("https://router.bynara.id" + path, data=d, headers=h, method=method)
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return 0, "ERR %s" % e
s, b = call("GET", "/v1/me")
print("GET /v1/me ->", s, b[:220].replace("\n", " "))
s, b = call("GET", "/v1/models")
print("GET /v1/models ->", s, b[:220].replace("\n", " "))
s, b = call("POST", "/v1/chat/completions",
            {"model": "laguna-s-2.1", "messages": [{"role": "user", "content": "Say OK"}], "max_tokens": 128})
print("POST chat laguna-s-2.1 ->", s, b[:220].replace("\n", " "))
PY
fi
echo

cat > "$W/p1.txt" << 'EOF'
OBIETTIVO: capire come funziona il requisito Telegram di NaraRouter (https://router.bynara.id) che oggi blocca l'account del nostro utente, cosi' da poter usare i 7.000.000 di token gratuiti. Il titolare della chiave non vuole credere che il blocco sia del suo account e sospetta sia un problema di formato delle richieste: gli hai dimostrato il contrario, ora lui vuole capire il meccanismo.

FATTI GIA' MISURATI (verificali, non rifarli da capo):
- la chiave si prende dal portachiavi con: python3 ~/posta/chiave_di.py "NaraRouter" -- NON stamparla mai nei referti, usala solo dentro variabili.
- con quella chiave, ADESSO, ogni richiesta a /v1/* risponde 403 {"error":{"type":"forbidden","message":"telegram_required: Join the required Telegram group/channel and relink at /settings to continue."}}
- con una chiave sbagliata risponde 401 "A valid API key is required." => la chiave e' valida, il blocco e' sull'account.
- il sito https://router.bynara.id/settings contiene le stringhe: "Join all required Telegram channels/groups below to unlock free account access.", "Regenerate link", "Unlink", "Refresh status", "Joined", "Not joined", "Ask admin for an invite link"
- il canale Telegram ufficiale e' https://t.me/bynara_ai
- stamattina 3/11 alle 14:35 la stessa chiave rispondeva 200 su /v1/me (free, 7.000.000/7.000.000 token, reset 04/11 00:00 UTC) e 200 su /v1/models (44 modelli); la chat su laguna-s-2.1 dava 400 e sugli altri 429 "Insufficient credits". Ieri gli id gratis dicevano "not available".

IL TUO COMPITO (agente ricerca):
1. Scarica il sito: home, /docs, /pricing, /settings e i bundle JS in _next/static (grep di "telegram", "requirements", "relink", "link", "refresh", "bot", "t.me/"). Riporta i PATH ESATTI degli endpoint che trovi (relink, stato dei canali richiesti, refresh).
2. Ricava quali canali Telegram bisogna unire (se piu' di uno) e come si fa il relink: serve account Telegram, un bot, un codice, un deep-link telegram://? Il relink si puo' fare via API o solo dal browser?
3. Capisci se il requisito scade nel tempo (ogni giorno? ogni N ore?) e se il testo del sito lo dice: e' il punto chiave, perche' il blocco era aperto stamattina e chiuso stasera.
4. Cerca sul web (webfetch/websearch, oppure python3 urllib) esperienze d'uso di NaraRouter / bynara.ai: modelli gratuiti, limiti, problemi noti col blocco telegram_required.

Scrivi il referto in /tmp/nararouter/agente1.md in italiano: link del canale da unire, procedura esatta passo-passo (anche via API), endpoint trovati, durata del vincolo, id gratuiti esatti se li trovi, citazioni. Massimo 800 parole. Non stampare chiavi.
EOF

cat > "$W/p2.txt" << 'EOF'
OBIETTIVO: preparare il banco di prova automatico che, quando l'account NaraRouter verra' sbloccato (ora risponde 403 telegram_required a TUTTO, anche a /v1/me e /v1/models), troverà subito il formato di richiesta giusto per il modello gratis "laguna-s-2.1" e lo dimostrerà con un HTTP 200 vero e con il contenuto della risposta.

FATTI: base https://router.bynara.id/v1 ; modello "laguna-s-2.1" ; chiave nel portachiavi con python3 ~/posta/chiave_di.py "NaraRouter" (non stamparla mai). Ieri la chat dava 400 su laguna-s-2.1, gli altri modelli 429 "Insufficient credits", ieri gli id gratis dicevano "not available", stasera 403 telegram_required ovunque.

IL TUO COMPITO:
1. Ricostruisci la cronologia leggendo: ~/posta/fatti/prova_nararouter.sh , ~/posta/dal_pc/prova_nararouter.md (se c'e'), la riga NaraRouter di ~/CHIAVI_LOCALI.md , e ~/LEGENDA_SISTEMA.md se esiste. Tabella degli errori con che cosa significa ciascuno (400 = id/parametri sbagliati? 402/429 = crediti insufficienti? 403 = blocco account? "not available" = id non attivo?).
2. Scrivi uno script NUOVO: ~/posta/fatti/prova_nararouter2.sh
   - non stampa mai la chiave;
   - prova in sequenza una matrice: endpoint (/v1/chat/completions, /v1/messages, /v1/responses, /v1/completions), header (Authorization Bearer, x-api-key, entrambi), payload (messages, input, prompt; con e senza max_tokens; stream true e false), nome modello (laguna-s-2.1, nara/laguna-s-2.1, Laguna-S-2.1, e gli id gratuiti letti al volo da /v1/models quando sara' sbloccato);
   - per ogni prova stampa una riga breve "HTTP xxx | endpoint | modello | payload | esito";
   - alla fine stampa un VERDETTO: la combinazione che ha risposto 200 col contenuto; se nessuna, l'errore piu' informativo e cosa fare;
   - deve finire pulito, senza file a meta', e non hangare (timeout su ogni richiesta).
3. Validalo: "bash -n ~/posta/fatti/prova_nararouter2.sh" e una esecuzione reale: oggi deve concludere "account bloccato (403 telegram_required)" senza errori e senza crash.
4. Scrivi il referto in /tmp/nararouter/agente2.md: la tabella degli errori e le istruzioni per lanciare lo script quando l'account e' sbloccato.

Non modificare il vault, non modificare il roster dei provider, non stampare chiavi.
EOF

cat > "$W/p3.txt" << 'EOF'
OBIETTIVO: trovare la strada piu' corta per usare i 7.000.000 di token gratuiti di NaraRouter, e capire se il blocco si puo' togliere senza passare dal browser.

FATTI: provider NaraRouter, base https://router.bynara.id/v1, chiave nel portachiavi (python3 ~/posta/chiave_di.py "NaraRouter", non stamparla). Ogni /v1/* risponde 403 {"error":{"type":"forbidden","message":"telegram_required: Join the required Telegram group/channel and relink at /settings to continue."}}; con chiave sbagliata arriva 401, quindi la chiave e' valida. Gruppo ufficiale https://t.me/bynara_ai ; pannello https://router.bynara.id/settings ; il sito dice "Join all required Telegram channels/groups below to unlock free account access." con pulsanti "Regenerate link", "Unlink", "Refresh status".

IL TUO COMPITO:
1. Nei bundle JS del sito cerca il flusso esatto del legame Telegram: quali endpoint chiama il pannello (percorso e metodo), se c'e' un deep-link telegram:// o un bot, che dati servono (user_id Telegram? telegram initData? codice?).
2. Verifica quali endpoint rispondono SENZA il blocco (pagine pubbliche, /v1/models senza chiave, prezzi) e che cosa dicono dei modelli gratuiti: id esatti, prezzi, limiti.
3. Cerca sul web come funziona NaraRouter (bynara.ai, bynara_ai): quanto dura il blocco, se altri utenti hanno risolto, se il requisito e' per account o per IP.
4. Proponi due strade: (A) sbloccare l'account con la procedura minima per il titolare (join + relink, link esatti, ordine dei passi), (B) se esiste un modo per spendere quei 7 milioni di token senza passare da NaraRouter (altri endpoint della stessa piattaforma o cosi' via).

Scrivi il referto in /tmp/nararouter/agente3.md in italiano, con i link cliccabili e le azioni numerate, distinguendo cio' che hai verificato da cio' che e' ipotesi. Massimo 700 parole. Non stampare chiavi.
EOF

echo "=== AGENTI IN PARALLELO (max 20 minuti) ==="
P1=$(cat "$W/p1.txt"); P2=$(cat "$W/p2.txt"); P3=$(cat "$W/p3.txt")

( timeout 1200 opencode run "$P1" > "$W/agente1.txt" 2>&1 \
  || timeout 1200 opencode run -m opencode/big-pickle "$P1" > "$W/agente1.txt" 2>&1 \
  || echo "(agente 1 non riuscito)" >> "$W/agente1.txt" ) &
A1=$!
( timeout 1200 opencode run "$P2" > "$W/agente2.txt" 2>&1 \
  || timeout 1200 opencode run -m opencode/big-pickle "$P2" > "$W/agente2.txt" 2>&1 \
  || echo "(agente 2 non riuscito)" >> "$W/agente2.txt" ) &
A2=$!
( timeout 1200 opencode run "$P3" > "$W/agente3.txt" 2>&1 \
  || timeout 1200 opencode run -m opencode/big-pickle "$P3" > "$W/agente3.txt" 2>&1 \
  || echo "(agente 3 non riuscito)" >> "$W/agente3.txt" ) &
A3=$!
wait $A1 $A2 $A3

for n in 1 2 3; do
  echo
  echo "=== AGENTE $n (output) ==="
  tail -c 9000 "$W/agente$n.txt" 2>/dev/null || echo "(nessun output)"
  echo
  echo "--- file del referto: /tmp/nararouter/agente$n.md ---"
  if [ -f "$W/agente$n.md" ]; then
    sed -n '1,220p' "$W/agente$n.md"
  else
    echo "(l'agente $n non ha scritto il file .md)"
  fi
  echo
done
echo "=== FINE TEAM ==="
