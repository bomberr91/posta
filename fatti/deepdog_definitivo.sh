#!/bin/bash
# DEEP DOG — COLLAUDO DEFINITIVO (1/11 sera, ~21:30)
#
# Cosa manca perché il cane sia DEFINITIVO:
#  1) la patch (output_mode=file + save_report_to_file=True + outputs/) è sul PC?
#     → verifico, e se manca la riapplico (idempotente);
#  2) il report atterra davvero sul disco? → collaudo con una ricerca vera
#     sul server di PROVA (8766): il 8765 del capo non si tocca mai;
#  3) i report arrivano nel repo (dal_pc/deepdog_reports/) → così gli agenti
#     li rileggono anche se il PC muore;
#  4) il report SambaNova (quello che il capo ha fatto girare) → recuperato
#     dalla scheda e messo nel repo.
#
# Il .bat NON riscarica il wrapper (verificato) → la patch sopravvive ai
# riavvii: nessun launcher nuovo serve.
set -uo pipefail
REPO="$HOME/posta"
D="[CHIAVE-RIMOSSA]"
PY="$D/.venv/Scripts/python.exe"
cd "$REPO" || { echo "❌ non trovo $REPO"; exit 1; }
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }
[ -x "$PY" ] || PY="$(command -v python3)"

say "1. la patch è sul PC?"
if grep -q 'save_report_to_file=True' "$D/web_app.py" 2>/dev/null \
   && grep -q 'output_mode="file"' "$D/web_app.py" 2>/dev/null; then
  echo "   ✓ output_mode=file + save_report_to_file=True"
else
  echo "   ⚠️ non c'è: la riapplico"
  python3 /tmp/dd_outputs_patch.py 2>/dev/null || {
    cat > /tmp/dd_outputs_patch.py << 'PYEOF'
import os, re, shutil, time
D = "[CHIAVE-RIMOSSA]"
F = os.path.join(D, "web_app.py")
src = open(F, encoding="utf-8").read()
shutil.copy2(F, F + ".bak-" + time.strftime("%Y%m%d-%H%M%S"))
src = re.sub(r'output_mode="none"', 'output_mode="file"', src)
src = re.sub(r'save_report_to_file=False', 'save_report_to_file=True', src)
if "DEEPDOG_OUTPUTS" not in src:
    if "import os" not in src:
        src = src.replace("import json", "import json\nimport os", 1)
    src = src.replace('load_dotenv(ROOT / ".env")',
        'load_dotenv(ROOT / ".env")\nDEEPDOG_OUTPUTS = ROOT / "outputs"\n'
        'DEEPDOG_OUTPUTS.mkdir(parents=True, exist_ok=True)', 1)
    src = src.replace('def main() -> None:\n',
        'def main() -> None:\n    try:\n        os.chdir(DEEPDOG_OUTPUTS)\n'
        '    except OSError:\n        pass\n', 1)
open(F, "w", encoding="utf-8").write(src)
print("   riapplicata")
PYEOF
    python3 /tmp/dd_outputs_patch.py; }
fi
grep -n 'output_mode=' "$D/web_app.py" | head -2
grep -n 'save_report_to_file=' "$D/web_app.py" | head -2

say "2. il file compila?"
WIN_APP="$(wslpath -w "$D/web_app.py" 2>/dev/null || echo "$D/web_app.py")"
"$PY" -m py_compile "$WIN_APP" && echo "   ✓ compila" || { echo "   ❌ non compila"; exit 1; }

say "3. collaudo sul server di PROVA (8766) — il 8765 non si tocca"
mkdir -p "$D/outputs"
PRIMA="$(ls -1 "$D/outputs" 2>/dev/null | wc -l)"
cd "$D" || exit 1
nohup "$PY" -c "import web_app; web_app.PORT=8766; web_app.main()" > /tmp/dd_def.log 2>&1 &
SRV=$!
PRONTO=0
for i in $(seq 1 40); do
  curl -s -m 3 http://127.0.0.1:8766/api/status >/dev/null 2>&1 && { PRONTO=1; break; }
  sleep 1
done
[ "$PRONTO" -eq 1 ] && echo "   ✓ porta 8766 aperta" || { echo "   ❌ non si apre"; tail -15 /tmp/dd_def.log; kill $SRV 2>/dev/null; exit 1; }
curl -s -m 30 -X POST http://127.0.0.1:8766/api/start -H 'Content-Type: application/json' \
  -d '{"prompt":"Una riga sola: il capoluogo d Italia."}' >/dev/null 2>&1
FIN=0
for i in $(seq 1 60); do
  ST="$(curl -s -m 8 http://127.0.0.1:8766/api/status 2>/dev/null)"
  case "$ST" in *completed*) FIN=1; break ;; *failed*) break ;; esac
  sleep 5
done
DOPO="$(ls -1 "$D/outputs" 2>/dev/null | wc -l)"
NEWF="$(ls -t "$D"/outputs/*.md 2>/dev/null | head -1)"
echo "   file in outputs/: prima=$PRIMA dopo=$DOPO (ricerca finita: $FIN)"
if [ -n "$NEWF" ] && [ "$DOPO" -gt "$PRIMA" ]; then
  echo "   ✅ IL REPORT ATTERRA: $(basename "$NEWF") — $(wc -c < "$NEWF") byte"
  head -5 "$NEWF"
else
  echo "   ⚠️ nessun file nuovo"
  tail -12 /tmp/dd_def.log
fi
kill $SRV 2>/dev/null; echo "   server di prova chiuso"

say "4. il tuo cane (8765) è vivo?"
curl -s -m 5 http://127.0.0.1:8765/api/status >/dev/null 2>&1 \
  && echo "   ✓ 8765 risponde" \
  || echo "   ⚠️ 8765 non risponde: riavvialo col .bat (i report si salveranno da ora)"

say "5. recupero il report SambaNova dalla scheda (se c'è ancora)"
if curl -s -m 60 http://127.0.0.1:8765/api/download -o /tmp/dd_sam.md 2>/dev/null \
   && [ "$(wc -c < /tmp/dd_sam.md)" -gt 300 ]; then
  cp -p /tmp/dd_sam.md dal_pc/deepdog_report_sambanova.md
  echo "   ✅ messo in dal_pc/deepdog_report_sambanova.md ($(wc -c < /tmp/dd_sam.md) byte)"
  grep -n -i -A3 "sambanova" dal_pc/deepdog_report_sambanova.md | head -20
else
  echo "   (la scheda non è più in memoria: niente da recuperare)"
fi

say "6. porto i report in dal_pc/deepdog_reports/ (li pubblica il postino)"
mkdir -p dal_pc/deepdog_reports
N=0
for f in "$D"/outputs/*.md; do
  [ -f "$f" ] || continue
  b="$(basename "$f")"
  [ -f "dal_pc/deepdog_reports/$b" ] || { cp -p "$f" "dal_pc/deepdog_reports/$b" 2>/dev/null && N=$((N+1)); }
done
echo "   report copiati: $N"

say "7. commit e push dei report"
git add dal_pc/deepdog_reports dal_pc/deepdog_report_sambanova.md 2>/dev/null || true
if git diff --cached --quiet; then
  echo "   (niente di nuovo da pubblicare)"
else
  git commit -qm "🐕 Deep Dog: i report su disco e il report SambaNova (1/11 sera)" >/dev/null 2>&1
  git push origin HEAD:main 2>&1 | tail -2
fi

say "8. VERDETTO"
echo "   · patch sul PC:            $(grep -q 'save_report_to_file=True' "$D/web_app.py" && echo OK || echo MANCANTE)"
echo "   · report su disco:         $([ -n "$NEWF" ] && echo OK || echo 'DA VERIFICARE')"
echo "   · report nel repo:         $(ls dal_pc/deepdog_reports/ 2>/dev/null | wc -l) file"
echo "   · SambaNova nel repo:      $([ -f dal_pc/deepdog_report_sambanova.md ] && echo OK || echo NO)"
echo "   · il .bat NON riscarica:   OK (la patch sopravvive ai riavvii)"
say "9. fine"
exit 0
