#!/bin/bash
cd ~/posta
nohup bash -c '
PY=~/deepopen_venv/bin/python
L=dal_pc/deepopen_round3.md
timeout 2400 $PY << "PYEOF" > "$L" 2>&1
import time, json
import deepopen
print("# Round 3 — preset e schema giusti:", time.strftime("%H:%M"))
print("## router_questions (lo schema nativo):")
print(json.dumps(deepopen.router_questions, default=str)[:800] if hasattr(deepopen, "router_questions") else "assente")
r = deepopen.Router(preload=True)
DOMANDE = {"category": {"type": "choice", "options": ["coding", "chat", "analysis", "search"]}}
PROVE = [
    ("write a python function that sorts a list", "coding"),
    ("hi, how are you today?", "chat"),
    ("analyze pros and cons of these 3 API providers", "analysis"),
    ("find the latest documentation for FastAPI", "search"),
    ("fix this error: TypeError at line 42", "coding"),
    ("tell me a joke", "chat"),
    ("compare LiteLLM and Portkey costs in a table", "analysis"),
    ("look up tomorrow weather forecast", "search"),
]
ok = tot = 0; tempi = []
try:
    t0 = time.time(); r.predict(PROVE[0][0], DOMANDE); print("riscaldamento: %.0f ms" % ((time.time()-t0)*1000))
    for testo, atteso in PROVE:
        t0 = time.time()
        out = r.predict(testo, DOMANDE)
        ms = (time.time()-t0)*1000; tempi.append(ms); tot += 1
        risp = json.dumps(out, default=str)
        giusta = atteso in risp.lower()
        ok += giusta
        print("%s [%s] atteso=%s → %s (%.0fms)" % ("✓" if giusta else "✗", testo[:35], atteso, risp[:90], ms))
except Exception as e:
    print("ERRORE predict con schema scelto:", str(e)[:250])
    try:
        preset = deepopen.router_questions
        t0 = time.time(); out = r.predict(PROVE[0][0], preset)
        print("col PRESET nativo funziona (%.0f ms):" % ((time.time()-t0)*1000), json.dumps(out, default=str)[:300])
    except Exception as e2:
        print("anche il preset fallisce:", str(e2)[:250])
if tempi:
    tempi.sort()
    print()
    print("VERDETTO NUMERI: %d/%d corrette · mediana %.0fms · max %.0fms su CPU (soglia 1500ms)" % (ok, tot, tempi[len(tempi)//2], tempi[-1]))
PYEOF
cd ~/posta && git pull -q --rebase 2>/dev/null; git add "$L"; git commit -q -m "deepopen round 3"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
' > /dev/null 2>&1 &
echo "round 3 in sottofondo (pid $!)"
