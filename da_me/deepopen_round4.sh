#!/bin/bash
cd ~/posta
nohup bash -c '
PY=~/deepopen_venv/bin/python
L=dal_pc/deepopen_round4.md
timeout 1200 $PY -u << "PYEOF" > "$L" 2>&1
import time, json, inspect
import deepopen
print("# Round 4 — il chirurgico:", time.strftime("%H:%M"))
# 1. lo schema nativo, CHIAMANDO la funzione
try:
    q = deepopen.router_questions()
    print("## schema nativo router_questions():")
    print(json.dumps(q, default=str)[:600])
except Exception as e:
    print("router_questions() err:", str(e)[:150]); q = None
# 2. router sobrio: SOLO inglese, niente preload
r = deepopen.Router(preload=False)
# 3. prova col nativo
if q:
    try:
        t0 = time.time()
        out = r.predict("write a python function that sorts a list", q, lang="en")
        print("## predict col nativo (%.0f ms):" % ((time.time()-t0)*1000), json.dumps(out, default=str)[:250])
    except Exception as e:
        print("predict nativo err:", str(e)[:200])
# 4. schema nostro ricalcato sul nativo
MIO = None
if isinstance(q, dict) and q:
    import copy
    k0 = list(q.keys())[0]
    base = copy.deepcopy(q[k0])
    if isinstance(base, dict) and "options" in base:
        base["options"] = ["coding", "chat", "analysis", "search"]
        MIO = {"category": base}
        print("## schema nostro:", json.dumps(MIO, default=str)[:200])
if MIO is None:
    MIO = {"category": {"type": "choice", "options": ["coding", "chat", "analysis", "search"]}}
PROVE = [("write a python function that sorts a list","coding"),("hi, how are you today?","chat"),
 ("analyze pros and cons of these 3 API providers","analysis"),("find the latest FastAPI documentation","search"),
 ("fix this error: TypeError at line 42","coding"),("tell me a joke","chat"),
 ("compare LiteLLM and Portkey costs in a table","analysis"),("look up tomorrow weather forecast","search")]
ok = tot = 0; tempi = []
try:
    r.predict(PROVE[0][0], MIO, lang="en")   # riscaldamento
    for testo, atteso in PROVE:
        t0 = time.time()
        out = r.predict(testo, MIO, lang="en")
        ms = (time.time()-t0)*1000; tempi.append(ms); tot += 1
        risp = json.dumps(out, default=str)
        giusta = atteso in risp.lower(); ok += giusta
        print("%s [%s] atteso=%s → %s (%.0fms)" % ("OK" if giusta else "NO", testo[:35], atteso, risp[:100], ms))
except Exception as e:
    print("banco fallito:", str(e)[:250])
if tempi:
    tempi.sort()
    print()
    print("### VERDETTO NUMERI: %d/%d corrette · mediana %.0fms · max %.0fms su CPU (soglia 1500)" % (ok, tot, tempi[len(tempi)//2], tempi[-1]))
PYEOF
cd ~/posta && git pull -q --rebase 2>/dev/null; git add "$L"; git commit -q -m "deepopen round 4 - il chirurgico"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
' > /dev/null 2>&1 &
echo "round 4 lanciato (pid $!)"
