#!/bin/bash
# DEEP DOG: "È OK DEFINITIVAMENTE?" — verifica sul server vero (1/11 sera)
#
# Tre prove, in ordine di forza:
#  1) il cane risponde;
#  2) il processo è partito DOPO la patch (21:24) → ha il codice nuovo in
#     memoria (il .bat non riscarica il wrapper, quindi il file su disco è
#     quello giusto);
#  3) la prova vera: una ricerca sul 8765 di lui → il report deve atterrare
#     in outputs/ (è questo il punto che stanotte non funzionava).
#  + il Setup deve essere rimasto (openrouter, missing []) dopo il riavvio.
set -uo pipefail
D="[CHIAVE-RIMOSSA]"
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }

say "1. il cane (8765) risponde?"
if curl -s -m 8 http://127.0.0.1:8765/api/status -o /tmp/dd_ok_status.json; then
  echo "   ✓ vivo: $(head -c 220 /tmp/dd_ok_status.json)"
else
  echo "   ❌ 8765 non risponde"
  exit 1
fi

say "2. quando è partito il processo rispetto alla patch?"
PATCHED="$(stat -c '%y' "$D/web_app.py" 2>/dev/null | cut -d. -f1)"
echo "   web_app.py è stato patchato: $PATCHED"
PSOUT="$([CHIAVE-RIMOSSA].0/powershell.exe -NoProfile -Command \
  "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" | Select-Object ProcessId,CreationDate,CommandLine | Format-List" 2>/dev/null)"
echo "$PSOUT" | grep -A2 -i "web_app\|CreationDate\|ProcessId" | head -24
CREATED="$(echo "$PSOUT" | grep -i "CreationDate" | head -3 | sed 's/.*CreationDate[^:]*: *//' | head -1)"
echo "   processo partito: ${CREATED:-?}"
if [ -n "$CREATED" ] && [ -n "$PATCHED" ]; then
  if [[ "$(date -d "$CREATED" +%s 2>/dev/null)" -ge "$(date -d "$PATCHED" +%s 2>/dev/null)" ]]; then
    echo "   ✅ il processo è PARTITO DOPO la patch → ha il codice nuovo"
  else
    echo "   ⚠️ il processo è più vecchio della patch → riavvialo ancora col .bat"
  fi
fi

say "3. il Setup è rimasto dopo il riavvio?"
curl -s -m 10 http://127.0.0.1:8765/api/setup -o /tmp/dd_ok_setup.json 2>/dev/null
cat /tmp/dd_ok_setup.json 2>/dev/null | head -c 400; echo

say "4. LA PROVA VERA: una ricerca sul suo cane → il report deve atterrare"
PRIMA="$(ls -1 "$D/outputs" 2>/dev/null | wc -l)"
echo "   file in outputs/ prima: $PRIMA"
curl -s -m 30 -X POST http://127.0.0.1:8765/api/start -H 'Content-Type: application/json' \
  -d '{"prompt":"Una riga sola: la capitale della Francia."}' >/dev/null 2>&1
FIN=0
for i in $(seq 1 72); do
  ST="$(curl -s -m 8 http://127.0.0.1:8765/api/status 2>/dev/null)"
  case "$ST" in *completed*) FIN=1; break ;; *failed*) break ;; esac
  sleep 5
done
DOPO="$(ls -1 "$D/outputs" 2>/dev/null | wc -l)"
NEWF="$(ls -t "$D"/outputs/*.md 2>/dev/null | head -1)"
echo "   ricerca conclusa: $FIN · file in outputs/: prima=$PRIMA dopo=$DOPO"
if [ -n "$NEWF" ] && [ "$DOPO" -gt "$PRIMA" ]; then
  say "5. ✅ IL REPORT È ATTERRATO SUL DISCO"
  echo "   file: $(basename "$NEWF") — $(wc -c < "$NEWF") byte"
  echo "   --- le prime righe ---"
  head -8 "$NEWF"
  # e lo metto nel repo, così è durabile per gli agenti
  mkdir -p "$[CHIAVE-RIMOSSA]"
  cp -p "$NEWF" "$[CHIAVE-RIMOSSA]" 2>/dev/null && echo "   copiato in dal_pc/deepdog_reports/ ✅"
else
  say "5. ⚠️ nessun file nuovo (la ricerca è finita? $FIN)"
  tail -20 /tmp/dd_ok_status.json 2>/dev/null | head -5
fi

say "6. VERDETTO"
if [ -n "$NEWF" ] && [ "$DOPO" -gt "$PRIMA" ]; then
  say "   ✅ DEEP DOG È OK DEFINITIVAMENTE: ricerca reale → file su disco → durabile"
  exit 0
fi
say "   ⛔ NON è ancora a posto (vedi sopra)"
exit 1
