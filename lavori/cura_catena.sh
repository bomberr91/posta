#!/bin/bash
cd ~/posta
export PATH="$HOME/.opencode/bin:$PATH"
A=dal_pc/cura_funzioni.md
estrai() { awk "/^def $1\(/{f=1} f{print} f&&/^$/{c++; if(c==2) exit}" cervello.py | head -60; }
echo "# 🚑 CURA: funzioni riscritte dagli operai — $(date +%H:%M)" > "$A"
SPEC=$(cat missione/DOSSIER_CURA.md)
# LOTTO 1
L1="FIX 1 — a_pagamento: BUG 'mini' dentro 'gemini' fa passare i Gemini a pagamento. Correggi: controlla PRIMA i pattern a pagamento; le eccezioni-gratis valgono solo per token espliciti (':free', '-free', 'oss' come parola). FIX 2 — cache_chiave: la chiave deve includere anche temperature, top_p, stop, presence_penalty, frequency_penalty, seed, response_format. FIX 3 — banale: ritorna None anche quando il payload contiene 'tools' o 'response_format'. FIX 4 — ripara_tool_call: la regex golosa prende dal primo { all'ultimo }; usa json.JSONDecoder().raw_decode scorrendo dal primo { utile. FIX 5 — batte: pota SEMPRE la lista agli ultimi 60 secondi anche per provider senza quota (oggi cresce senza limite)."
CTX1="=== a_pagamento ===
$(estrai a_pagamento)
=== cache_chiave ===
$(estrai cache_chiave)
=== banale ===
$(estrai banale)
=== ripara_tool_call ===
$(estrai ripara_tool_call)
=== batte ===
$(estrai batte)"
while pgrep -f "opencode ru[n]" > /dev/null; do sleep 30; done
echo "" >> "$A"; echo "## LOTTO 1" >> "$A"
timeout 700 opencode run -m cervello/auto "$SPEC

DIAGNOSI DEL LOTTO:
$L1

CODICE ATTUALE:
$CTX1" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -v "^> build" >> "$A"
# LOTTO 2
L2="FIX 6 — sentinella: se CONFIG['sentinella_repos'] è vuota, la migrazione di push_visto va saltata senza IndexError; e un fallimento di UNA pagina/repo non deve fermare le altre (già ok, conserva). FIX 7 — _sessione (metodo della classe H): sanifica il valore: togli \r \n e spazi, tronca a 64 caratteri, se dopo pulizia è vuoto usa il ricavato dallo user-agent. FIX 8 — indirizzo: se l'url inizia con http:// e l'host NON è 127.0.0.1/localhost, solleva ValueError('chiave su http in chiaro rifiutata') — mai mandare chiavi in chiaro fuori dal loopback."
CTX2="=== sentinella ===
$(estrai sentinella)
=== _sessione (dentro classe H, indentata) ===
$(grep -A8 'def _sessione' cervello.py)
=== indirizzo ===
$(estrai indirizzo)"
while pgrep -f "opencode ru[n]" > /dev/null; do sleep 30; done
echo "" >> "$A"; echo "## LOTTO 2" >> "$A"
timeout 700 opencode run -m cervello/auto "$SPEC

DIAGNOSI DEL LOTTO:
$L2

CODICE ATTUALE:
$CTX2" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -v "^> build" >> "$A"
# REVISORE
while pgrep -f "opencode ru[n]" > /dev/null; do sleep 30; done
echo "" >> "$A"; echo "## REVISIONE" >> "$A"
timeout 700 opencode run -m cervello/auto "Sei il revisore severo. Dossier, diagnosi e funzioni riscritte qui sotto. Per ogni FIX: la correzione risolve la diagnosi? introduce regressioni? firma cambiata? Elenca SOLO problemi veri + correzione puntuale, poi PROMOSSO/BOCCIATO per fix. ASD-STE100.

$(cat "$A")" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -v "^> build" >> "$A"
echo "FINE $(date +%H:%M)" >> "$A"
git pull -q --rebase 2>/dev/null; git add "$A"; git commit -q -m "cura-audit: funzioni riscritte + revisione"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
