#!/bin/bash
# collaudo_f2b4.sh — COLLAUDO FINALE FASE 2·B4 + IDEA 64
# CURA-AUDIT v5: chat lette con fatti/chat_leggi.sh (corpo vuoto = FAILURE),
# la chiave del gateway NON è più scritta qui (si legge dall'ambiente) e
# l'uscita dice NO se qualcosa non torna. Prima non poteva dire NO.
set -uo pipefail
cd ~/posta || exit 1
B=http://127.0.0.1:20129
FALLITI=0
# la chiave del gateway si legge dal portachiavi (regola #3: mai nel repo)
. ./chiavi_env.sh 2>/dev/null || true
export OMNIROUTE_API_KEY="${OMNIROUTE_API_KEY:-${OM_KEY:-}}"
echo "## COLLAUDO FINALE FASE 2·B4 + IDEA 64 — $(date '+%H:%M')"
echo
echo "### 1. Versione"
if curl -s -m 5 $B/portiere | grep -o "FASE 2·B4" | head -1; then :; else echo "   ✗ NON TROVATA!"; FALLITI=$((FALLITI+1)); fi
echo
echo "### 2. CACHE dal vivo (stessa domanda 2 volte)"
Q='{"model":"auto","max_tokens":30,"messages":[{"role":"user","content":"Quante zampe ha un ragno? Solo il numero."}]}'
if bash fatti/chat_leggi.sh 180 "$Q" "'1ª: '+d.get('model','?')"; then :; else FALLITI=$((FALLITI+1)); fi
sleep 2
if bash fatti/chat_leggi.sh 180 "$Q" "'2ª: '+d.get('model','?')+' ← deve dire (cache)'"; then :; else FALLITI=$((FALLITI+1)); fi
echo
echo "### 3. IDEA 64 — LA COMPRESSIONE RTK DEL MOTORE LAVORA?"
python3 << 'PYEOF'
import json, os, urllib.request
# prompt gonfio e ripetitivo: ~8000 caratteri = ~2000 token se NON compresso
zavorra = ("Il gatto dorme sul tappeto rosso del salotto grande. " * 150)
corpo = json.dumps({"model": "auto", "max_tokens": 20, "messages": [
    {"role": "user", "content": zavorra + " DOMANDA: di che colore e il tappeto? Una parola."}]}).encode()
req = urllib.request.Request("http://127.0.0.1:20128/v1/chat/completions", data=corpo,
    headers={"Content-Type": "application/json",
             "Authorization": "Bearer " + os.environ.get("OMNIROUTE_API_KEY", "")})
try:
    d = json.loads(urllib.request.urlopen(req, timeout=120).read().decode())
    u = d.get("usage") or {}
    stima = len(zavorra) // 4
    visti = u.get("prompt_tokens")
    print("caratteri zavorra:", len(zavorra), "→ stima SENZA compressione: ~%d token" % stima)
    print("prompt_tokens VISTI dal provider:", visti, "· modello:", d.get("model", "?"))
    if visti and visti < stima * 0.6:
        print("VERDETTO IDEA 64: ✅ COMPRESSIONE ATTIVA (risparmio ~%d%%)" % round(100 - 100 * visti / stima))
    elif visti:
        print("VERDETTO IDEA 64: ❌ compressione NON rilevata (token pieni)")
    else:
        print("VERDETTO IDEA 64: ⚠ usage non riportato dal provider — prova non conclusiva")
except Exception as e:
    print("prova fallita:", str(e)[:200])
    raise SystemExit(1)
PYEOF
[ $? -eq 0 ] || FALLITI=$((FALLITI+1))
echo
echo "### 4. Statistiche del Portiere"
python3 cervello.py --statistiche 2>&1 | head -20
echo
if [ "$FALLITI" -gt 0 ]; then
  echo "❌ COLLAUDO F2·B4 FALLITO: $FALLITI problema/i"
  exit 1
fi
echo "✅ COLLAUDO F2·B4 OK"
exit 0
