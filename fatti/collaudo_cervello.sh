#!/bin/bash
# collaudo_cervello.sh — IL COLLAUDO VERO (CURA-AUDIT, 1/11 sera).
#
# PERCHÉ È STATO RISCRITTO. Prima i deploy facevano:
#     curl -s -m 10 .../v1/chat/completions | python3 -c "import json,sys; print(json.load(sys.stdin)...)"
# Il timeout del curl (5-20s) era più corto del budget del motore
# (timeout_motore 180s + 5 tentativi × timeout_riserva 60s ≈ 480s) e nessuno
# guardava il codice di uscita: un Portiere morto dava "corpo vuoto" →
# JSONDecodeError → lo script proseguiva → il postino scriveva il .done →
# "deploy riuscito".
# Il 1/11 il Portiere era MORTO dalle 16:24 (le richieste chat morivano con
# "empty reply from server") e il collaudo diceva "tutto bene".
#
# ADESSO: i timeout sono coerenti col budget del motore, ogni passo verifica
# davvero, e l'uscita dice NO quando qualcosa non torna. I deploy lo chiamano
# con `collaudo || exit 1`.
set -uo pipefail

CERVELLO_URL="${CERVELLO_URL:-http://127.0.0.1:20129}"
CERVELLO_PORTA="${CERVELLO_PORTA:-20129}"
# Il motore può aspettare 180s e la riserva 5×60s: il collaudo deve poter
# aspettare il suo stesso budget, altrimenti non distingue "lento" da "rotto".
T_CHAT="${T_CHAT:-240}"

attendi(){
  for i in $(seq 1 30); do
    sleep 2
    (exec 3<>/dev/tcp/127.0.0.1/"$CERVELLO_PORTA") 2>/dev/null && { echo "   porta aperta dopo ~$((i*2))s"; return 0; }
  done
  echo "   ✗ la porta $CERVELLO_PORTA non si è aperta"
  return 1
}

targa(){
  local t
  t=$(curl -fsS -m 10 "$CERVELLO_URL/portiere" 2>/dev/null | grep -o "FASE [0-9]" | head -1)
  if [ -n "$t" ]; then echo "   ✓ targa: $t"; return 0; fi
  echo "   ✗ targa: nessuna risposta"
  return 1
}

salute(){
  local out
  out=$(curl -fsS -m 15 "$CERVELLO_URL/salute" 2>/dev/null) || { echo "   ✗ /salute non risponde"; return 1; }
  echo "$out" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d.get('ok'), 'ok assente'
assert not d.get('struttura'), d.get('struttura')
print('   ✓ salute: f3=%s provider=%d motore=%s' % (d.get('f3'), d.get('provider', 0), d.get('motore')))
" || { echo "   ✗ /salute: dati non buoni"; return 1; }
}

chat(){
  local out
  out=$(curl -fsS -m "$T_CHAT" -H 'Content-Type: application/json' \
        -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' \
        "$CERVELLO_URL/v1/chat/completions" 2>/dev/null) || {
        echo "   ✗ la chat non risponde (timeout ${T_CHAT}s o connessione chiusa dal server)"
        return 1; }
  echo "$out" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d.get('choices'), 'risposta senza scelte: %s' % str(d)[:120]
print('   ✓ chat: %s' % str(d.get('model', '?'))[:70])
" || { echo "   ✗ la chat risponde ma male"; return 1; }
}

collaudo(){
  echo "── COLLAUDO DEL PORTIERE ──"
  attendi || return 1
  targa  || return 1
  salute || return 1
  chat   || return 1
  echo "── COLLAUDO OK ──"
  return 0
}
