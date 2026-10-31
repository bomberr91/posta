#!/bin/bash
cd ~/posta
nohup bash -c '
PY=~/deepopen_venv/bin/python
L=dal_pc/deepopen_round2.md
timeout 1800 $PY << "PYEOF" > "$L" 2>&1
import time, inspect
import deepopen
print("# DeepOpen round 2 — firme vere:", time.strftime("%H:%M"))
r = deepopen.Router()
for m in ("predict", "route", "system_one"):
    try: print("firma", m, ":", inspect.signature(getattr(r, m)))
    except Exception as e: print(m, "?", e)
PROVE = [
    ("scrivi una funzione python che ordina una lista", "code"),
    ("ciao come stai oggi?", "chat"),
    ("analizza pro e contro di questi 3 provider API", "analisi"),
    ("cerca informazioni aggiornate sul meteo a Mantova", "ricerca"),
    ("correggi questo errore: TypeError at line 42", "code"),
    ("raccontami una barzelletta", "chat"),
    ("confronta i costi di LiteLLM e Portkey in tabella", "analisi"),
    ("trova la documentazione ufficiale di FastAPI", "ricerca"),
]
OPZ = ["code", "chat", "analisi", "ricerca"]
ok = tot = 0; tempi = []
for metodo in ("predict", "route", "system_one"):
    f = getattr(r, metodo, None)
    if not f: continue
    riuscito = False
    for stile in ("domanda_opzioni", "solo_testo", "kw"):
        try:
            t0 = time.time()
            if stile == "domanda_opzioni":
                out = f("quale categoria descrive meglio questa richiesta?", options=OPZ, state=PROVE[0][0])
            elif stile == "solo_testo":
                out = f(PROVE[0][0], OPZ)
            else:
                out = f(question="quale categoria?", options=OPZ, state=PROVE[0][0])
            print("FUNZIONA:", metodo, "stile", stile, "→", str(out)[:150], "(%.0f ms)" % ((time.time()-t0)*1000))
            riuscito = True
        except Exception as e:
            print(" ", metodo, stile, "→", str(e)[:120])
        if riuscito:
            for testo, atteso in PROVE:
                t0 = time.time()
                try:
                    if stile == "domanda_opzioni":
                        out = f("quale categoria descrive meglio questa richiesta?", options=OPZ, state=testo)
                    elif stile == "solo_testo":
                        out = f(testo, OPZ)
                    else:
                        out = f(question="quale categoria?", options=OPZ, state=testo)
                    ms = (time.time()-t0)*1000; tempi.append(ms); tot += 1
                    giusta = atteso in str(out).lower()
                    ok += giusta
                    print("  %s [%s] atteso=%s → %s (%.0fms)" % ("✓" if giusta else "✗", testo[:38], atteso, str(out)[:70], ms))
                except Exception as e:
                    print("  errore su prova:", str(e)[:100]); break
            break
    if riuscito: break
if tempi:
    tempi.sort()
    print()
    print("VERDETTO GREZZO: %d/%d corrette · mediana %.0f ms · max %.0f ms su CPU" % (ok, tot, tempi[len(tempi)//2], tempi[-1]))
else:
    print("NESSUNO STILE HA FUNZIONATO — allego help:")
    try: help(r.predict)
    except Exception: pass
PYEOF
cd ~/posta && git pull -q --rebase 2>/dev/null; git add "$L"; git commit -q -m "deepopen round 2"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
' > /dev/null 2>&1 &
echo "round 2 avviato in sottofondo (ambiente già caldo: pochi minuti)"
