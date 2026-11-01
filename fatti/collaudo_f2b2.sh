#!/bin/bash
# collaudo_f2b2.sh — COLLAUDO FASE 2·B2
# CURA-AUDIT v5: chat lette con fatti/chat_leggi.sh (corpo vuoto = FAILURE)
# e uscita 1 se qualcosa non torna. Prima non poteva dire NO.
set -uo pipefail
cd ~/posta || exit 1
B=http://127.0.0.1:20129
FALLITI=0
echo "## COLLAUDO FASE 2·B2 SUL PC — $(date '+%H:%M')"
echo
echo "### 1. Versione (deve dire FASE 2·B2)"
# la versione è un AVVISO, non un errore: questo collaudo nacque per la
# fase 2·B2, ma il motore è andato avanti (FASE 3). Quello che deve
# stare in piedi è la TARGA, cioè che il cervello risponde.
targa=$(curl -fsS -m 5 $B/portiere 2>/dev/null | grep -o "FASE [0-9][0-9]*" | head -1)
if [ -n "$targa" ]; then
  if [ "$targa" = "FASE 2·B2" ]; then echo "   ✓ $targa";
  else echo "   ℹ trovata $targa (questo collaudo era della 2·B2: avanti va bene)"; fi
else
  echo "   ✗ la targa non risponde"; FALLITI=$((FALLITI+1))
fi
echo
echo "### 2. Casella 'riserva oggi'"
if curl -s -m 5 $B/portiere | grep -o "riserva oggi" | head -1; then :; else echo "   ✗ MANCA!"; FALLITI=$((FALLITI+1)); fi
echo
echo "### 3. Politica GRATIS dal vivo (dritta in riserva, nutre la pagella)"
if bash fatti/chat_leggi.sh 180 '{"model":"gratis","max_tokens":40,"messages":[{"role":"user","content":"Di che colore e il cielo? Rispondi in 3 parole."}]}' "d.get('model','?')+' → '+str(((d.get('choices') or [{}])[0].get('message',{}).get('content','')) or d.get('error',{}).get('message',''))[:80]"; then :; else FALLITI=$((FALLITI+1)); fi
sleep 3
if bash fatti/chat_leggi.sh 180 '{"model":"gratis","max_tokens":40,"messages":[{"role":"user","content":"Conta da 1 a 3."}]}' "d.get('model','?')+' → '+str(((d.get('choices') or [{}])[0].get('message',{}).get('content','')) or d.get('error',{}).get('message',''))[:80]"; then :; else FALLITI=$((FALLITI+1)); fi
sleep 4
echo
echo "### 4. Pagella, velocità e consumi NUTRITI"
python3 -c "
import json
try:
    d = json.load(open('portiere_stato.json'))
    for pid, p in d.get('pagella',{}).items():
        print('  pagella %s: %dok/%dko' % (pid, p.get('ok',0), p.get('ko',0)) + (' · ~%dms' % p['ms_ewma'] if p.get('ms_ewma') is not None else ''))
    for pid, u in d.get('uso',{}).items():
        print('  uso %s: %d richieste · %d token (%s)' % (pid, u.get('n',0), u.get('token',0), u.get('giorno','')))
    print('  agenti censiti:', len(d.get('agenti',{})))
    print('  castighi attivi:', len(d.get('castighi',{})))
except FileNotFoundError:
    print('  stato ancora vuoto')" 2>&1
echo
echo "### 5. Glass-box: ultime 6"
tail -6 portiere_log.jsonl 2>/dev/null
echo
if [ "$FALLITI" -gt 0 ]; then
  echo "❌ COLLAUDO F2·B2 FALLITO: $FALLITI problema/i"
  exit 1
fi
echo "✅ COLLAUDO F2·B2 OK"
exit 0
