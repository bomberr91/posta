#!/bin/bash
cd ~/posta
nohup bash -c '
PY=~/deepopen_venv/bin/python
L=dal_pc/deepopen_round5.md
{
echo "# Round 5 — il paziente: $(date +%H:%M)"
echo "## fase 1: completo il download (resume, max 60 min)"
timeout 3600 $PY -u -c "
from huggingface_hub import snapshot_download
p = snapshot_download(\"convaiinnovations/laya\")
print(\"download COMPLETO in:\", p)
"
echo "## fase 2: il banco (max 20 min)"
timeout 1200 $PY -u << "PYEOF"
import time, json
import deepopen
q = deepopen.router_questions()
r = deepopen.Router(preload=False)
PROVE = [("write a python function that sorts a list","code","hard_o_moderate"),
 ("hi, how are you today?","chat",""),("analyze pros and cons of these 3 API providers","analysis",""),
 ("find the latest FastAPI documentation","search",""),("fix this error: TypeError at line 42","code",""),
 ("tell me a joke","fun",""),("compare LiteLLM and Portkey costs in a table","analysis",""),
 ("prove that sqrt(2) is irrational","math","")]
tempi = []
r.predict(PROVE[0][0], q, lang="en")
print("riscaldamento ok")
for testo, atteso, _ in PROVE:
    t0 = time.time()
    out = r.predict(testo, q, lang="en")
    ms = (time.time()-t0)*1000; tempi.append(ms)
    print("[%s] → %s (%.0fms)" % (testo[:38], json.dumps(out, default=str)[:140], ms))
tempi.sort()
print()
print("### NUMERI FINALI: mediana %.0fms · max %.0fms su CPU (soglia 1500ms)" % (tempi[len(tempi)//2], tempi[-1]))
PYEOF
echo "## fine: $(date +%H:%M)"
} > "$L" 2>&1
cd ~/posta && git pull -q --rebase 2>/dev/null; git add "$L"; git commit -q -m "deepopen round 5 - il paziente"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
' > /dev/null 2>&1 &
echo "round 5 avviato (pid $!): scarica con calma, collauda, si committa. Buonanotte."
