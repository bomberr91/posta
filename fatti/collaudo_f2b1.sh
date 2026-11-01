#!/bin/bash
# collaudo_f2b1.sh — COLLAUDO FASE 2·B1
# CURA-AUDIT v5: le chat si leggono con fatti/chat_leggi.sh (corpo vuoto =
# FAILURE, non una traccia di errore) e lo script esce 1 se qualcosa non
# torna. Prima non poteva dire NO.
set -uo pipefail
cd ~/posta || exit 1
B=http://127.0.0.1:20129
FALLITI=0
echo "## COLLAUDO FASE 2·B1 SUL PC — $(date '+%H:%M')"
echo
echo "### 1. Versione (deve dire FASE 2·B1)"
# la versione è un AVVISO, non un errore: questo collaudo nacque per la
# fase 2·B1, ma il motore è andato avanti (FASE 3). Quello che deve
# stare in piedi è la TARGA, cioè che il cervello risponde.
targa=$(curl -fsS -m 5 $B/portiere 2>/dev/null | grep -o "FASE [0-9][0-9]*" | head -1)
if [ -n "$targa" ]; then
  if [ "$targa" = "FASE 2·B1" ]; then echo "   ✓ $targa";
  else echo "   ℹ trovata $targa (questo collaudo era della 2·B1: avanti va bene)"; fi
else
  echo "   ✗ la targa non risponde"; FALLITI=$((FALLITI+1))
fi
echo
echo "### 2. Ping in casa (0 token)"
if bash fatti/chat_leggi.sh 30 '{"model":"auto","messages":[{"role":"user","content":"ping"}]}' "d.get('model','?')"; then :; else FALLITI=$((FALLITI+1)); fi
echo
echo "### 3. Una richiesta vera piccola (nutre la pagella)"
if bash fatti/chat_leggi.sh 180 '{"model":"auto","max_tokens":30,"messages":[{"role":"user","content":"Rispondi con una parola sola: pronto"}]}' "d.get('model','?')+' → '+str(((d.get('choices') or [{}])[0].get('message',{}).get('content','')) or d.get('error',{}).get('message',''))[:60]"; then :; else FALLITI=$((FALLITI+1)); fi
echo
echo "### 4. Pagella e velocità osservate"
python3 -c "
import json
try:
    d = json.load(open('portiere_stato.json'))
    print('castighi attivi:', len(d.get('castighi',{})))
    for pid, p in list(d.get('pagella',{}).items())[:8]:
        print('  %s: %dok/%dko' % (pid, p.get('ok',0), p.get('ko',0)) + (' · ~%dms' % p['ms_ewma'] if p.get('ms_ewma') is not None else ''))
except FileNotFoundError:
    print('stato non ancora creato (normale: nessuna richiesta di riserva ancora)')" 2>&1
echo
echo "### 5. Glass-box: ultime 5 righe"
tail -5 portiere_log.jsonl 2>/dev/null || echo "(vuoto)"
echo
if [ "$FALLITI" -gt 0 ]; then
  echo "❌ COLLAUDO F2·B1 FALLITO: $FALLITI problema/i"
  exit 1
fi
echo "✅ COLLAUDO F2·B1 OK"
exit 0
