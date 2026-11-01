#!/bin/bash
# collaudo_f2b3.sh — COLLAUDO FASE 2·B3
# CURA-AUDIT v5: chat lette con fatti/chat_leggi.sh (corpo vuoto = FAILURE)
# e uscita 1 se qualcosa non torna. Prima non poteva dire NO.
set -uo pipefail
cd ~/posta || exit 1
B=http://127.0.0.1:20129
FALLITI=0
echo "## COLLAUDO FASE 2·B3 SUL PC — $(date '+%H:%M')"
echo
echo "### 1. Versione"
# la versione è un AVVISO, non un errore: questo collaudo nacque per la
# fase 2·B3, ma il motore è andato avanti (FASE 3). Quello che deve
# stare in piedi è la TARGA, cioè che il cervello risponde.
targa=$(curl -fsS -m 5 $B/portiere 2>/dev/null | grep -o "FASE [0-9][0-9]*" | head -1)
if [ -n "$targa" ]; then
  if [ "$targa" = "FASE 2·B3" ]; then echo "   ✓ $targa";
  else echo "   ℹ trovata $targa (questo collaudo era della 2·B3: avanti va bene)"; fi
else
  echo "   ✗ la targa non risponde"; FALLITI=$((FALLITI+1))
fi
echo
echo "### 2. 'migliore' col motore vivo → deve viaggiare su auto/best-reasoning"
if bash fatti/chat_leggi.sh 240 '{"model":"migliore","max_tokens":40,"messages":[{"role":"user","content":"Due parole: come stai?"}]}' "d.get('model','?')+' → '+str(((d.get('choices') or [{}])[0].get('message',{}).get('content','')) or d.get('error',{}).get('message',''))[:60]"; then :; else FALLITI=$((FALLITI+1)); fi
grep '"rotta": "motore-mappato"' portiere_log.jsonl | tail -1
echo
echo "### 3. PRIMA SCOPERTA VERA DEL PORTACHIAVI (--scopri, zero token)"
timeout 600 python3 cervello.py --scopri 2>&1 | tail -25
echo
echo "### 4. Peso del catalogo"
ls -la portiere_catalogo.json 2>/dev/null
python3 -c "
import json
c = json.load(open('portiere_catalogo.json'))
print('provider nel catalogo:', len(c), '· modelli totali:', sum(len(v.get('modelli',[])) for v in c.values()))" 2>&1
echo
if [ "$FALLITI" -gt 0 ]; then
  echo "❌ COLLAUDO F2·B3 FALLITO: $FALLITI problema/i"
  exit 1
fi
echo "✅ COLLAUDO F2·B3 OK"
exit 0
