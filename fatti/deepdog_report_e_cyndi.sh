#!/bin/bash
# RECUPERA IL REPORT SAMBANOVA E CERCA LA LISTA "CYNDI" (1/11 sera)
#
# Due cose che il capo mi ha chiesto:
#  1) "dove viene salvata la risposta?" → RISPOSTA: il server NON scrive nulla
#     su disco (save_report_to_file=False nel wrapper): il report sta in RAM
#     (STATE.report) e si vede nella scheda. Però esiste /api/download → la
#     stessa roba del bottone "Scarica .md". Qui la recupero e la metto nel
#     repo, così è duratura e gli agenti la trovano.
#  2) "la lista cyndi" → cerco il file su tutto il disco utente.
#
# Il repo è pubblico: il report viene scansionato per stringhe-chiave prima.
set -uo pipefail
REPO="$HOME/posta"
cd "$REPO" || { echo "❌ non trovo $REPO"; exit 1; }
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }

say "1. il cane è vivo? (porta 8765)"
if curl -s -m 15 "http://127.0.0.1:8765/api/status" -o /tmp/dd_status.json; then
  echo "   ✓ risponde"
  echo "   $(head -c 400 /tmp/dd_status.json)"
else
  echo "   ⚠️ nessuna risposta su 8765 (cane spento o riavviato)"
fi

say "2. scarico l'ultimo report (stessa roba del bottone 'Scarica .md')"
if curl -s -m 60 "http://127.0.0.1:8765/api/download" -o /tmp/dd_report.md; then
  SZ=$(wc -c < /tmp/dd_report.md)
  echo "   scaricati $SZ byte"
  if [ "$SZ" -gt 200 ]; then
    say "3. scansione stringhe-chiave (il repo è pubblico)"
    CHIAVI=$(grep -oE '(sk-or-v1-[A-Za-z0-9]{20,}|tvly-[A-Za-z0-9-]{20,}|ghp_[A-Za-z0-9]{20,}|cc3a11cf-[0-9a-f-]{20,}|sk-[A-Za-z0-9]{30,})' /tmp/dd_report.md 2>/dev/null | sort -u | wc -l)
    echo "   chiavi trovate: $CHIAVI"
    [ "$CHIAVI" -gt 0 ] && cp -p /tmp/dd_report.md /tmp/dd_report_originale.md
    mkdir -p dal_pc
    cp -p /tmp/dd_report.md dal_pc/deepdog_report_sambanova.md
    say "4. il report è nel repo (dal_pc/deepdog_report_sambanova.md)"
    echo "   --- le prime righe ---"
    head -12 dal_pc/deepdog_report_sambanova.md
    echo "   --- la parte che contiene SambaNova ---"
    grep -n -i -A4 "sambanova" dal_pc/deepdog_report_sambanova.md | head -30
  else
    say "   ⚠️ il report è vuoto: la scheda è stata ricaricata o il server riparte da zero"
  fi
else
  say "   ⚠️ non ho potuto scaricare il report"
fi

say "5. cerco la lista 'cyndi' (per nome)"
find /mnt/c/Users/giopi -maxdepth 4 -iname "*cyndi*" -not -path "*/AppData/*" 2>/dev/null | head -20

say "6. e i file che parlano di 'cyndi' dentro"
grep -ril "cyndi" /mnt/c/Users/giopi/Documents /mnt/c/Users/giopi/Desktop /mnt/c/Users/giopi/Lavori 2>/dev/null | head -20

say "7. i tuoi appunti in Documenti (txt/md, più recenti in alto)"
ls -lt /mnt/c/Users/giopi/Documents/*.txt /mnt/c/Users/giopi/Documents/*.md 2>/dev/null | head -12

say "8. finito"
exit 0
