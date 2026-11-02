#!/bin/bash
# chat_leggi.sh — LEGGE una risposta chat e DICE LA VERITÀ.
#
# CURA-AUDIT v5 (1/11 sera): i collaudi storici facevano
#     curl -s -m N .../v1/chat/completions | python3 -c "json.load(sys.stdin)"
# Se il cervello era MORTO arrivava un corpo VUOTO: la python tirava fuori una
# JSONDecodeError, nessuno guardava il codice di uscita, e il collaudo
# proseguiva stampando una traccia di errore come se fosse un risultato.
# (È la stessa bugia del 1/11: un collaudo che non può dire NO.)
#
# QUI: corpo vuoto = FAILURE esplicito, con il perché. E l'uscita dice NO.
#
# uso:
#   bash fatti/chat_leggi.sh <timeout> <body-json> [espressione-python]
# L'espressione riceve `d` (la risposta JSON) e viene stampata.
# Senza espressione stampa "modello → risposta".
set -uo pipefail

CERVELLO_URL="${CERVELLO_URL:-http://127.0.0.1:20129}"
T="${1:-120}"
BODY="${2:-}"
if [ -z "$BODY" ]; then
  BODY='{"model":"auto","messages":[{"role":"user","content":"ping"}]}'
fi
ESPR="${3:-}"

out=$(curl -fsS -m "$T" -H 'Content-Type: application/json' -d "$BODY" \
      "$[CHIAVE-RIMOSSA]" 2>/dev/null) || {
  echo "   ✗ la chat non ha risposto (timeout ${T}s o connessione chiusa)" >&2
  exit 1
}

if [ -z "$out" ]; then
  echo "   ✗ RISPOSTA VUOTA (corpo vuoto: il cervello non ha risposto)" >&2
  exit 1
fi

printf '%s' "$out" | python3 -c "
import json, sys
s = sys.stdin.read().strip()
try:
    d = json.loads(s)
except Exception as e:
    print('   ✗ RISPOSTA NON JSON: %s' % str(e)[:90], file=sys.stderr)
    sys.exit(1)
if not isinstance(d, dict):
    print('   ✗ RISPOSTA NON UN OGGETTO JSON', file=sys.stderr)
    sys.exit(1)
if not d.get('choices'):
    print('   ✗ RISPOSTA SENZA SCELTE: %s' % str(d)[:140], file=sys.stderr)
    sys.exit(1)
espr = '''$ESPR'''
if not espr:
    espr = \"d.get('model','?') + ' → ' + str(((d.get('choices') or [{}])[0].get('message',{}).get('content','')) or d.get('error',{}).get('message',''))[:80]\"
print(eval(espr, {'d': d, 'str': str, 'len': len}))
" || exit 1
exit 0
