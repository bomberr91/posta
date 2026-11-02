#!/bin/bash
# DEEP DOG: I REPORT DEVONO ATTERRARE SUL DISCO (1/11 sera)
#
# Il wrapper (web_app.py) aveva:
#     output_mode="none"            → il motore non scrive NULLA
#     save_report_to_file=False     → e comunque non salverebbe
# Nel motore la scrittura avviene solo se: save_report_to_file AND
# files_enabled() (che richiede output_mode "file" o "both") → quindi la riga
# da cambiare era UNA, ma servivano DUE.
# Il file finiva nella cartella CORRENTE del processo → la mettiamo in
# outputs/ (così il postino la pubblica e gli agenti la ritrovano).
#
# Il server vero (porta 8765) NON si tocca: il collaudo gira su 8766.
set -uo pipefail
D="/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog"
PY="/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog/.venv/Scripts/python.exe"
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }

say "1. dove sono i file"
[ -f "$D/web_app.py" ] || { echo "❌ non trovo $D/web_app.py"; exit 1; }
[ -x "$PY" ] || PY="$(command -v python3)"
echo "   web_app.py: $(wc -c < "$D/web_app.py") byte"

say "2. applico il cerotto (idempotente, con backup)"
cat > /tmp/dd_outputs_patch.py << 'PYEOF'
import os, re, shutil, time
D = "/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog"
F = os.path.join(D, "web_app.py")
src = open(F, encoding="utf-8").read()
shutil.copy2(F, F + ".bak-" + time.strftime("%Y%m%d-%H%M%S"))
done = []
new, n = re.subn(r'output_mode="none"', 'output_mode="file"', src)
if n: done.append("output_mode: none->file"); src = new
new, n = re.subn(r'save_report_to_file=False', 'save_report_to_file=True', src)
if n: done.append("save_report_to_file: False->True"); src = new
if "DEEPDOG_OUTPUTS" not in src:
    if "import os" not in src:
        src = src.replace("import json", "import json\nimport os", 1)
        done.append("import os")
    src = src.replace(
        'load_dotenv(ROOT / ".env")',
        'load_dotenv(ROOT / ".env")\n'
        '# DEEPDOG_OUTPUTS (CURA 1/11 sera): i report atterrano sul disco.\n'
        'DEEPDOG_OUTPUTS = ROOT / "outputs"\n'
        'DEEPDOG_OUTPUTS.mkdir(parents=True, exist_ok=True)', 1)
    src = src.replace(
        'def main() -> None:\n',
        'def main() -> None:\n'
        '    # DEEPDOG_OUTPUTS: il motore scrive i report nella cartella corrente\n'
        '    # -> li mettiamo in outputs/, dove li trova anche il postino.\n'
        '    try:\n'
        '        os.chdir(DEEPDOG_OUTPUTS)\n'
        '    except OSError:\n'
        '        pass\n', 1)
    done.append("outputs + chdir")
open(F, "w", encoding="utf-8").write(src)
print("   modifiche:", done if done else "nessuna (gia' applicato)")
PYEOF
python3 /tmp/dd_outputs_patch.py

say "3. il file compila?"
WIN_APP="$(wslpath -w "$D/web_app.py" 2>/dev/null || echo "$D/web_app.py")"
if "$PY" -m py_compile "$WIN_APP"; then
  echo "   ✓ web_app.py compila"
else
  echo "   ❌ NON compila: ripristino il backup"
  ls -t "$D"/web_app.py.bak-* 2>/dev/null | head -1 | xargs -r -I{} cp {} "$D/web_app.py"
  exit 1
fi

say "4. le righe che contano"
grep -n 'output_mode=' "$D/web_app.py" | head -3
grep -n 'save_report_to_file=' "$D/web_app.py" | head -3
grep -n 'DEEPDOG_OUTPUTS' "$D/web_app.py" | head -4

say "5. collaudo sul server di prova (8766) — il tuo 8765 NON si tocca"
mkdir -p "$D/outputs"
SRV=""
cd "$D" || exit 1
nohup "$PY" -c "import web_app; web_app.PORT=8766; web_app.main()" > /tmp/dd_out.log 2>&1 &
SRV=$!
echo "   server di prova avviato (pid $SRV)"
PRONTO=0
for i in $(seq 1 40); do
  if curl -s -m 3 http://127.0.0.1:8766/api/status >/dev/null 2>&1; then PRONTO=1; break; fi
  sleep 1
done
if [ "$PRONTO" -ne 1 ]; then
  say "   ❌ la porta 8766 non si è aperta"
  tail -20 /tmp/dd_out.log
  [ -n "$SRV" ] && kill "$SRV" 2>/dev/null
  exit 1
fi
echo "   ✓ porta 8766 aperta"

say "6. una ricerca vera (deve scrivere un file)"
PRIMA="$(ls -1 "$D/outputs" 2>/dev/null | wc -l)"
curl -s -m 30 -X POST http://127.0.0.1:8766/api/start \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"Scrivi in una riga: il capoluogo d Italia."}' >/dev/null 2>&1
FINITO=0
for i in $(seq 1 60); do
  ST="$(curl -s -m 8 http://127.0.0.1:8766/api/status 2>/dev/null)"
  case "$ST" in
    *'"status": "completed"'*|*'"status":"completed"'*) FINITO=1; break ;;
    *'"status": "failed"'*|*'"status":"failed"'*) echo "   la ricerca è fallita"; break ;;
  esac
  sleep 5
done
DOPO="$(ls -1 "$D/outputs" 2>/dev/null | wc -l)"
echo "   file in outputs/: prima=$PRIMA dopo=$DOPO"
ls -lt "$D/outputs" 2>/dev/null | head -5
NEWFILE="$(ls -t "$D"/outputs/*.md 2>/dev/null | head -1)"
if [ -n "$NEWFILE" ] && [ "$DOPO" -gt "$PRIMA" ]; then
  say "7. IL REPORT È ATTERRATO ✅"
  echo "   file: $(basename "$NEWFILE") — $(wc -c < "$NEWFILE") byte"
  head -8 "$NEWFILE"
else
  say "7. ⚠️ nessun file nuovo in outputs/ (la ricerca è finita? $FINITO)"
  tail -15 /tmp/dd_out.log
fi

say "8. chiudo il server di prova (il tuo 8765 resta acceso)"
[ -n "$SRV" ] && kill "$SRV" 2>/dev/null && echo "   chiuso"
say "9. il tuo cane (8765) è ancora vivo?"
if curl -s -m 5 http://127.0.0.1:8765/api/status >/dev/null 2>&1; then
  echo "   ✓ 8765 risponde (il server vero non è stato toccato)"
else
  echo "   ⚠️ 8765 non risponde: riavvialo col .bat (ora i report si salveranno)"
fi
say "10. fine"
exit 0
