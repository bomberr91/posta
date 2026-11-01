#!/bin/bash
# DEEP DOG: DIAGNOSI — il cane non risponde sulla 8765 (1/11 sera)
#
# Il capo ha riavviato il cane col .bat ma la porta 8765 non risponde.
# Non indovino: guardo (1) se il processo c'è, (2) se la porta è in ascolto,
# (3) cosa dice l'avvio, (4) e provo ad avviarlo come fa il .bat per vedere
# l'errore esatto. Il suo cane NON viene toccato: non ammazzo nessun
# processo Windows (regola: mai uccidere il server da WSL).
set -uo pipefail
D="/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog"
PY="$D/.venv/Scripts/python.exe"
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }
PS="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"

say "1. il processo python del cane c'è?"
"$PS" -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" | Select-Object ProcessId,CreationDate,CommandLine | Format-List" 2>/dev/null | head -30

say "2. la porta 8765 è in ascolto?"
netstat.exe -ano 2>/dev/null | grep -E ":8765|:8766" || echo "   (nessuna connessione su 8765/8766)"

say "3. il file è integro e la patch è dentro?"
ls -la "$D/web_app.py" 2>/dev/null
grep -n 'save_report_to_file=\|output_mode="file"\|DEEPDOG_OUTPUTS' "$D/web_app.py" 2>/dev/null | head -6

say "4. l'avvio: cosa dice? (lo provo per 25 secondi, su 8767 per non toccare nulla)"
mkdir -p "$D/outputs"
cd "$D" || exit 1
timeout 25 "$PY" -c "import web_app; web_app.PORT=8767; web_app.main()" > /tmp/dd_diag.log 2>&1
echo "   (uscita con codice $?)"
echo "   --- il log ---"
cat /tmp/dd_diag.log | head -30

say "5. i log del cane (se il .bat lascia tracce)"
ls -lt "$D"/*.log "$D"/logs/*.log 2>/dev/null | head -6
for f in "$D"/*.log; do [ -f "$f" ] && { echo "   --- $f (ultime righe)"; tail -12 "$f"; }; done

say "6. il Setup e l'API rispondono su 8767 mentre era vivo? (ora è spento, controllo i file)"
ls -la "$D/setup_state.json" "$D/.env" 2>/dev/null | head -4
echo "   setup_state.json:"; head -c 400 "$D/setup_state.json" 2>/dev/null; echo

say "7. i report già prodotti"
ls -lt "$D/outputs" 2>/dev/null | head -6

say "8. VERDETTO"
say "   (le righe sopra dicono se è: processo morto / porta occupata / errore di avvio / altro)"
exit 0
