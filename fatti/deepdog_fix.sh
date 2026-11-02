#!/bin/bash
# deepdog_fix.sh — IL CEROTTO DI DEEP DOG + IL COLLAUDO
#
# LA DIAGNOSI (provata, non ipotizzata — vedi dal_pc/deepdog_mistero.md):
# il wrapper Windows scriveva TRE catene di modelli con il nome "deepseek-flash".
# Ma Deep Dog conosce solo "deepseek-v4-flash": "deepseek-flash" non è nella
<<<<<<< HEAD
# mappa _OPENROUTER_MODEL_MAP_BY_NAME, quindi get_model() saltava il ramo
=======
# mappa _OPENROUTE..., quindi get_model() saltava il ramo
>>>>>>> 0610ed5 (postino: risposte sanitizzate)
# OpenRouter e finiva sulla PIATTAFORMA DEEPSEEK (a pagamento) → 402
# "Insufficient Balance". Ecco perché il Setup chiedeva DEEPSEEK_API_KEY
# anche con OpenRouter selezionato: diceva la verità su un codice sbagliato.
#
# Il secondo difetto: la scelta del Setup NON veniva salvata. Al riavvio
# model_provider tornava "deepseek" (nativo) → stesso 402, di nuovo.
#
# QUI: due correzioni minime + un collaudo che parla. Il collaudo esce 1 se
# qualcosa non torna: se non dice NO, non dice niente.
set -uo pipefail
D="[CHIAVE-RIMOSSA]"
PY="$D/.venv/Scripts/python.exe"
echo "## 🐕 IL CEROTTO DI DEEP DOG — $(date '+%d/%m %H:%M')"

if [ ! -f "$D/web_app.py" ] || [ ! -x "$PY" ]; then
  echo "❌ non trovo l'installazione di Deep Dog in $D"
  exit 1
fi

# ── 1. LA PROVA (sul posto, non a memoria) ───────────────────────────────
echo "### 1. Lo stato PRIMA (le prove sul posto)"
echo "— le tre catene che il wrapper scrive:"
grep -n "model_fallback_chain=" "$D/web_app.py" | head -5
echo "— la mappa OpenRouter di Deep Dog (i nomi che CONOSCE):"
<<<<<<< HEAD
grep -n -A 6 "_OPENROUTER_MODEL_MAP_BY_NAME = {" "$D/deep_research/config.py" | head -8
=======
grep -n -A 6 "_OPENROUTE... = {" "$D/deep_research/config.py" | head -8
>>>>>>> 0610ed5 (postino: risposte sanitizzate)
echo "— il default del provider nel Setup:"
grep -n 'model_provider: str = ' "$D/web_app.py" | head -3
echo "— ROUTE_VIA_OPENROUTER nel .env:"
grep -E "^ROUTE_VIA_OPENROUTER|^WEB_SEARCH_ENGINE|^OPENROUTER_API_KEY|^EXA_API_KEY|^TAVILY_API_KEY" "$D/.env" 2>/dev/null \
  | sed -E 's/=(.{12,}).*/=\1…(mascherata)/'
echo

# ── 2. IL CEROTTO ─────────────────────────────────────────────────────────
echo "### 2. Applico il cerotto (idempotente, con backup)"
cat > /tmp/dd_patch.py << 'PATCHEOF'
import io, os, re, shutil, sys, time

D = "[CHIAVE-RIMOSSA]"
F = os.path.join(D, "web_app.py")
src = io.open(F, encoding="utf-8").read()
MARCA = "CURA-AUDIT (1/11):"

if MARCA in src:
    print("   il cerotto c'è già: non lo tocco (idempotente)")
    sys.exit(0)

backup = F + ".bak-" + time.strftime("%Y%m%d-%H%M%S")
shutil.copy2(F, backup)
print("   backup:", os.path.basename(backup))

modifiche = []

# (a) le tre catene: il nome che Deep Dog CONOSCE, e che segue l'ambiente
<<<<<<< HEAD
vecchio = '''        [CHIAVE-RIMOSSA]["deepseek-flash"],
        subagent_model_fallback_chain=["deepseek-flash"],
        [CHIAVE-RIMOSSA]["deepseek-flash"],'''
=======
vecchio = '''        supervisor...=["deepseek-flash"],
        subagent_m...=["deepseek-flash"],
        draft_repo...=["deepseek-flash"],'''
>>>>>>> 0610ed5 (postino: risposte sanitizzate)
nuovo = '''        # CURA-AUDIT (1/11): il wrapper scriveva "deepseek-flash", nome che
        # Deep Dog NON conosce: non è nella mappa OpenRouter, quindi get_model()
        # saltava il ramo OpenRouter e la chiamata finiva sulla piattaforma
        # DeepSeek (a pagamento) -> 402 Insufficient Balance. Qui il nome vero,
        # e lo si cambia dal .env (SUPERVISOR_MODEL ecc.).
<<<<<<< HEAD
        [CHIAVE-RIMOSSA][os.environ.get("SUPERVISOR_MODEL", "deepseek-v4-flash")],
        subagent_model_fallback_chain=[os.environ.get("SUBAGENT_MODEL", "deepseek-v4-flash")],
        [CHIAVE-RIMOSSA][os.environ.get("DRAFT_REPORT_MODEL", "deepseek-v4-flash")],'''
=======
        supervisor...=[os.environ.get("SUPERVISOR_MODEL", "deepseek-v4-flash")],
        subagent_m...=[os.environ.get("SUBAGENT_MODEL", "deepseek-v4-flash")],
        draft_repo...=[os.environ.get("DRAFT_REPORT_MODEL", "deepseek-v4-flash")],'''
>>>>>>> 0610ed5 (postino: risposte sanitizzate)
if vecchio in src:
    src = src.replace(vecchio, nuovo, 1); modifiche.append("catene di modelli")
else:
    print("   ✗ non trovo le tre catene: NIENTO cambiato"); sys.exit(1)

# (b) import os (serve per leggere l'ambiente)
if "\nimport os\n" not in src:
    src = src.replace("\nimport json\n", "\nimport json\nimport os\n", 1)
    modifiche.append("import os")
else:
    modifiche.append("import os (già presente)")

# (c) il default del provider: OpenRouter se la chiave c'è
vecchio_def = '    model_provider: str = "deepseek"'
nuovo_def = ('    # CURA-AUDIT (1/11): la scelta non veniva salvata e il default era\n'
             '    # "deepseek" (piattaforma a pagamento). Con la chiave OpenRouter\n'
             '    # presente il default è OpenRouter.\n'
             '    model_provider: str = "openrouter" if os.environ.get("OPENROUTER_API_KEY") else "deepseek"')
if vecchio_def in src:
    src = src.replace(vecchio_def, nuovo_def, 1); modifiche.append("default del provider")
else:
    print("   ✗ non trovo il default del provider: NIENTO cambiato"); sys.exit(1)

# (d) la scelta viene salvata su disco (al riavvio non torna indietro)
vecchio_set = 'STATE = JobState()\nSETUP = SetupState()'
nuovo_set = '''STATE = JobState()
SETUP = SetupState()
# CURA-AUDIT (1/11): la scelta del Setup viveva solo in memoria: al riavvio
# il cane tornava sulla piattaforma a pagamento e moriva con 402. Ora la
# salviamo su disco e la ricarichiamo all'avvio.
_SETUP_FILE = ROOT / "setup_state.json"
try:
    if _SETUP_FILE.exists():
        _salvato = json.loads(_SETUP_FILE.read_text(encoding="utf-8"))
        if isinstance(_salvato, dict):
            for _campo, _def in (("model_provider", SETUP.model_provider),
                                 ("search_provider", SETUP.search_provider),
                                 ("speed_profile", SETUP.speed_profile)):
                _v = _salvato.get(_campo)
                if isinstance(_v, str) and _v:
                    setattr(SETUP, _campo, _v)
except Exception:
    pass'''
if vecchio_set in src:
    src = src.replace(vecchio_set, nuovo_set, 1); modifiche.append("caricamento del setup")
else:
    print("   ✗ non trovo SETUP = SetupState(): NIENTO cambiato"); sys.exit(1)

vecchio_post = '''                SETUP.model_provider = model_provider
                SETUP.search_provider = search_provider
                SETUP.speed_profile = speed_profile'''
nuovo_post = '''                SETUP.model_provider = model_provider
                SETUP.search_provider = search_provider
                SETUP.speed_profile = speed_profile
                try:                       # CURA-AUDIT (1/11): salvataggio su disco
                    _SETUP_FILE.write_text(json.dumps({
                        "model_provider": SETUP.model_provider,
                        "search_provider": SETUP.search_provider,
                        "speed_profile": SETUP.speed_profile,
                    }, ensure_ascii=False), encoding="utf-8")
                except Exception:
                    pass'''
if vecchio_post in src:
    src = src.replace(vecchio_post, nuovo_post, 1); modifiche.append("salvataggio del setup")
else:
    print("   ✗ non trovo il blocco POST /api/setup: NIENTO cambiato"); sys.exit(1)

io.open(F, "w", encoding="utf-8").write(src)
print("   applicati:", ", ".join(modifiche))
PATCHEOF

python3 /tmp/dd_patch.py          # python di WSL: /mnt/c lo capisce
RC=$?
if [ $RC -ne 0 ]; then
  echo "❌ il cerotto non è stato applicato (exit $RC): il cane resta com'era"
  exit 1
fi

echo "— il file adesso:"
grep -n "model_fallback_chain=" "$D/web_app.py" | head -5
grep -n 'model_provider: str = ' "$D/web_app.py" | head -2
echo

echo "— compila?"
WIN_WEB_APP="$(wslpath -w "$D/web_app.py" 2>/dev/null || echo "$D/web_app.py")"
"$PY" -m py_compile "$WIN_WEB_APP" && echo "   ✓ web_app.py compila" || {
  echo "❌ web_app.py NON compila: ripristino il backup"
  ls -t "$D"/web_app.py.bak-* 2>/dev/null | head -1 | xargs -r -I{} cp {} "$D/web_app.py"
  exit 1
}
echo

# ── 3. IL COLLAUDO (parla, e sa dire NO) ─────────────────────────────────
echo "### 3. Collaudo dal vivo"
# Il server di Deep Dog gira come processo WINDOWS (lo lancia il .bat) e WSL
# non lo vede: se lo "uccidessi" rischierei di parlare col server VECchio
# (codice non patchato) e di diagnosticare il sintomo invece della causa.
# Perciò il collaudo parte su una PORTA SEPARATA (8766): stesso .env, stesso
# setup_state.json, codice nuovo. Il tuo server sulla 8765 resta intatto.
cd "$D" || exit 1
nohup "$PY" -c "import web_app; web_app.PORT=8766; web_app.main()" > /tmp/dd_fix.log 2>&1 &
SRV=$!
echo "— server di collaudo avviato (pid $SRV) sulla porta 8766, aspetto…"
PRONTO=0
for i in $(seq 1 30); do
  sleep 2
  if curl -s -m 3 http://127.0.0.1:8766/api/status >/dev/null 2>&1; then PRONTO=1; break; fi
done
if [ "$PRONTO" -ne 1 ]; then
  echo "❌ il server di collaudo non ha aperto la porta 8766"
  head -25 /tmp/dd_fix.log
  exit 1
fi
echo "   ✓ porta 8766 aperta"

echo "— /api/setup (la configurazione):"
SETUP_JSON=$(curl -s -m 10 http://127.0.0.1:8766/api/setup)
echo "   $SETUP_JSON" | head -c 600; echo
MISSING=$(echo "$SETUP_JSON" | python3 -c "
import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    print('NONJSON'); raise SystemExit
m = d.get('missing') or []
print(','.join(m) if m else 'NESSUNA')
" 2>/dev/null)
MODEL_PROV=$(echo "$SETUP_JSON" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('model_provider','?'))
except Exception: print('?')
" 2>/dev/null)
if echo "$MISSING" | grep -qi "DEEPSEEK"; then
  echo "❌ il Setup chiede ancora DEEPSEEK: il cane va sulla piattaforma a pagamento"
  exit 1
fi
echo "   ✓ missing: $MISSING · provider: $MODEL_PROV"

echo
echo "— una MICRO-ricerca vera (deve rispondere, niente 402):"
curl -s -m 15 -X POST -H 'Content-Type: application/json' \
     -d '{"prompt":"In una riga sola: qual e la capitale d Italia?"}' \
     http://127.0.0.1:8766/api/start >/dev/null
FINITO=0
ST=""
for i in $(seq 1 90); do
  sleep 4
  ST=$(curl -s -m 8 http://127.0.0.1:8766/api/status)
  S=$(echo "$ST" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('status','?'))
except Exception: print('?')
" 2>/dev/null)
  case "$S" in
    done|failed|completed)
      FINITO=1; break ;;
  esac
done
echo "   stato: $S"
echo "   eventi:"
echo "$ST" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    for e in (d.get('events') or []): print('     -', e)
    err = d.get('error') or ''
    if err: print('   ERRORE:', err[:300])
    rep = (d.get('report') or '').strip()
    if rep: print('   estratto del report:'); print('     ', rep[:400].replace(chr(10),' '))
except Exception as e:
    print('     (status non JSON)', e)
" 2>/dev/null
if echo "$ST" | grep -qi "402\|Insufficient Balance"; then
  echo "❌ ancora il 402: il cane va ancora sulla piattaforma DeepSeek"
  exit 1
fi
if [ "$FINITO" -ne 1 ]; then
  echo "❌ la micro-ricerca non è finita in tempo"
  exit 1
fi
if ! echo "$ST" | grep -q '"report": *"[^"]'; then
  echo "❌ la ricerca è finita ma il report è vuoto"
  exit 1
fi

# ── 4. CHIUDO ────────────────────────────────────────────────────────────
kill "$SRV" 2>/dev/null || true
# il kill su un processo WINDOWS lanciato da WSL non è affidabile: riprovo
# con il pattern esatto (NON coincide con la riga di comando di questo job,
# che è "bash da_me/deepdog_fix.sh")
pkill -f "web_app.PORT=8766" 2>/dev/null || true
sleep 1
echo
echo "✅ CEROTTO APPLICATO E COLLAUDATO — la ricerca è uscita pulita (niente 402)"
echo "   il TUO server sulla 8765 non è stato toccato: riavvialo col .bat"
echo "   (la scelta del Setup ora resta su disco: setup_state.json)"
exit 0
