#!/usr/bin/env bash
# hermes_config_hunt.sh — DOVE STA LA CONFIG DI HERMES e che chiavi usa.
#
# 4/11: Hermes è l'ultimo agente la cui assegnazione è sconosciuta. Nelle
# config viste finora (WSL e home Windows) non c'era: si cercano i file di
# configurazione di Hermes su entrambi i lati e si riportano solo nomi di
# provider, endpoint, modelli e nomi di variabili: nessuna chiave stampata.
set -uo pipefail

WIN="/mnt/c/Users/giopi"
echo "### 1. DOVE PUO' STARE"
for p in "$WIN/.hermes" "$WIN/AppData/Roaming/hermes" "$WIN/AppData/Local/hermes" "$WIN/Documents/AgentWorkspace/.hermes" "$HOME/.hermes" "$WIN/AppData/Roaming/Hermes" "$WIN/AppData/Local/Programs/Hermes"; do
  if [ -e "$p" ]; then
    echo "--- esiste: $p"
    find "$p" -maxdepth 2 -type f 2>/dev/null | head -20 | while read -r f; do
      echo "      %8d byte  %s" "$(stat -c %s "$f" 2>/dev/null)" "$f"
    done
  fi
done
echo

echo "### 2. FILE DI CONFIG HERMES (contenuto, segreti mascherati)"
python3 - << 'PYEOF'
import os, re, glob

WIN = "/mnt/c/Users/giopi"
HOME = os.path.expanduser("~")
INTERESSA = re.compile(r"(provider|model|base_?url|host|url|endpoint|env|type|mode|cervello|motore|omni|gateway|profile)", re.I)
SEGRETO = re.compile(r"(key|token|secret|password)", re.I)

def mask(v):
    if isinstance(v, (bool, int, float)) or v is None:
        return v
    t = str(v)
    if len(t) >= 16 and not t.startswith("http") and " " not in t and "/" not in t:
        return "«presente (%d caratteri)»" % len(t)
    return t

candidati = []
for base in (WIN + "/.hermes", WIN + "/AppData/Roaming/hermes", WIN + "/AppData/Local/hermes",
             WIN + "/Documents/AgentWorkspace", HOME + "/.hermes"):
    if not os.path.isdir(base):
        continue
    for f in glob.glob(base + "/**/*", recursive=True):
        if os.path.isfile(f) and re.search(r"\.(ya?ml|json|toml|ini|cfg|conf|env)$", f) and os.path.getsize(f) < 200000:
            if re.search(r"hermes", f, re.I) or base.endswith(".hermes") or "/hermes" in f.lower():
                candidati.append(f)

if not candidati:
    print("   nessun file di config trovato nei posti noti")
else:
    for f in candidati[:25]:
        print("--- %s" % f)
        try:
            testo = open(f, encoding="utf-8", errors="replace").read()
        except Exception as e:
            print("    (non leggibile: %s)" % str(e)[:60]); continue
        if f.endswith(".json"):
            try:
                import json
                dati = json.loads(testo)
                def walk(o, p=""):
                    for k, v in o.items():
                        q = (p + "." + str(k)).strip(".")
                        if isinstance(v, dict):
                            walk(v, q)
                        elif isinstance(v, list):
                            for i, x in enumerate(v):
                                if isinstance(x, dict): walk(x, "%s[%d]" % (q, i))
                                else: print("   %-42s = %s" % (("%s[%d]" % (q, i))[:42], mask(x)))
                        else:
                            if SEGRETO.search(str(k)): print("   %-42s = %s" % (q[:42], mask(v)))
                            elif INTERESSA.search(str(k)): print("   %-42s = %s" % (q[:42], mask(v)))
                walk(dati)
                continue
            except Exception:
                pass
        for riga in testo.splitlines():
            s = riga.strip()
            if not s or s.startswith("#") or (":" not in s and "=" not in s):
                continue
            if SEGRETO.search(s):
                print("   %-42s = «presente (non stampata)»" % re.split(r"[:=]", s, 1)[0].strip()[:42])
            elif INTERESSA.search(s):
                print("   %-42s = %s" % (s[:42], s[43:][:140]))
PYEOF
echo

echo "### 3. VARIABILI D'AMBIENTE CHE RIGUARDANO HERMES (solo nomi)"
cmd.exe /c set 2>/dev/null | grep -i -E "^(GEMINI|GROQ|OPENCODE|OMNI|AGENTROUTER|ANTHROPIC|OPENAI|GOOGLE)[A-Z0-9_]*=" | sed -E 's/=.*/= (valore non stampato)/' | sort
echo "--- WSL:"
env | grep -i -E "^(GEMINI|GROQ|OPENCODE|OMNI|AGENTROUTER|ANTHROPIC|OPENAI|GOOGLE)[A-Z0-9_]*=" | sed -E 's/=.*/= (valore non stampato)/' | sort
echo

echo "### 4. HERMES: PROVA DI UNA CHIAMATA (con le chiavi gia' presenti nell'ambiente)"
HS="/mnt/c/Users/giopi/AppData/Local/hermes/bin/hermes.exe"
if [ -f "$HS" ]; then
  cd "$WIN/Documents" 2>/dev/null || cd /tmp
  timeout 180 "$HS" -z "Rispondi esattamente con la parola OK e nient'altro." > /tmp/hermes_prova.log 2>&1
  echo "--- exit hermes: $?"
  tail -25 /tmp/hermes_prova.log
else
  echo "hermes.exe non trovato"
fi
echo "FINE"
