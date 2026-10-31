#!/bin/bash
# Prova DeepOpen su CPU (lavoro n.6) — gira in sottofondo, si committa da solo
cd ~/posta
L=dal_pc/deepopen_lavoro.log
V=dal_pc/deepopen_verdetto.md
{
echo "# Prova DeepOpen su CPU — avvio $(date '+%d/%m %H:%M')"
PYV=$(python3 -c "import sys; print('%d.%d' % sys.version_info[:2])")
echo "python: $PYV"
python3 -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)" || { echo "PYTHON TROPPO VECCHIO (<3.10): STOP"; exit 0; }
echo "## 1. ambiente"
python3 -m venv ~/deepopen_venv 2>&1 | tail -1 || true
P=~/deepopen_venv/bin/pip; PY=~/deepopen_venv/bin/python
[ -x "$PY" ] || { echo "venv fallito, uso --user"; P="python3 -m pip"; PY=python3; }
echo "## 2. torch CPU (puo' metterci 10-20 min)"
timeout 1800 $P install -q torch --index-url https://download.pytorch.org/whl/cpu 2>&1 | tail -2
echo "## 3. deepopen da git"
timeout 1200 $P install -q "git+https://github.com/deepopen-com/deepopen.git" 2>&1 | tail -2
echo "## 4. banco di prova"
timeout 1800 $PY << 'PYEOF'
import time, json, inspect
import deepopen
print("versione:", getattr(deepopen, "__version__", "?"))
print("contenuto modulo:", [x for x in dir(deepopen) if not x.startswith("_")])
# introspezione delle firme utili
for nome in ("load", "Router", "router", "evaluate", "ask", "decide"):
    f = getattr(deepopen, nome, None)
    if f:
        try: print("firma", nome, ":", inspect.signature(f))
        except Exception: print("firma", nome, ": (classe)")
# prove: domanda tipizzata stile router del cervello
PROVE = [
    ("scrivi una funzione python che ordina una lista", "code"),
    ("ciao come stai oggi?", "chat"),
    ("analizza i pro e contro di questi 3 provider API", "analisi"),
    ("cerca informazioni aggiornate sul meteo di domani a Mantova", "ricerca"),
    ("correggi questo errore: TypeError at line 42", "code"),
    ("raccontami una barzelletta", "chat"),
    ("confronta i costi di LiteLLM e Portkey in una tabella", "analisi"),
    ("trova la documentazione ufficiale di FastAPI", "ricerca"),
]
OPZIONI = ["code", "chat", "analisi", "ricerca"]
ok = tot = 0
tempi = []
caricato = None
for tentativo in ("router", "load"):
    try:
        if tentativo == "router" and hasattr(deepopen, "Router"):
            caricato = deepopen.Router()
        elif hasattr(deepopen, "load"):
            caricato = deepopen.load()
        if caricato is not None:
            print("caricato via:", tentativo)
            break
    except Exception as e:
        print("caricamento", tentativo, "fallito:", str(e)[:150])
if caricato is None:
    print("NESSUN CARICATORE RIUSCITO: servono le firme qui sopra per il round 2")
else:
    metodi = [m for m in dir(caricato) if not m.startswith("_")]
    print("metodi oggetto:", metodi[:15])
    for metodo in ("ask", "evaluate", "decide", "classify", "__call__"):
        f = getattr(caricato, metodo, None)
        if not f: continue
        try:
            t0 = time.time()
            r = f("quale categoria? " + PROVE[0][0], OPZIONI) if metodo != "__call__" else f(PROVE[0][0])
            ms = (time.time() - t0) * 1000
            print("metodo funzionante:", metodo, "->", str(r)[:120], "in %.0f ms" % ms)
            for testo, atteso in PROVE:
                t0 = time.time()
                r = f("quale categoria descrive meglio questa richiesta? " + testo, OPZIONI) if metodo != "__call__" else f(testo)
                tempi.append((time.time() - t0) * 1000)
                tot += 1
                if atteso in str(r).lower(): ok += 1
                print("  [%s] atteso=%s → %s (%.0fms)" % (testo[:40], atteso, str(r)[:80], tempi[-1]))
            break
        except Exception as e:
            print("metodo", metodo, "fallito:", str(e)[:150])
    if tempi:
        tempi.sort()
        print("RISULTATO: %d/%d giuste · latenza mediana %.0f ms · max %.0f ms (CPU)" % (ok, tot, tempi[len(tempi)//2], tempi[-1]))
PYEOF
echo "## 5. fine lavoro $(date '+%H:%M')"
} > "$L" 2>&1
# riassunto scritto da un operaio locale
export PATH="$HOME/.opencode/bin:$PATH"
timeout 600 opencode run -m cervello/auto "Sei il revisore. Qui sotto il log di una prova di DeepOpen (classificatore senza LLM) su CPU per decidere se usarlo come giudice-lampo del routing del nostro Portiere (oggi l'alternativa e' un conteggio caratteri). Scrivi in italiano un VERDETTO di 10 righe: funziona su questa macchina? latenze accettabili (soglia: <1500ms a richiesta)? precisione? INNESTO CONSIGLIATO SI/NO/RIPROVARE CON ALTRE FIRME. Log:

$(cat $L)" > "$V" 2>&1
# consegna
git pull -q --rebase 2>/dev/null
git add "$L" "$V" 2>/dev/null
git commit -q -m "deepopen: prova CPU + verdetto operaio" 2>/dev/null
git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
