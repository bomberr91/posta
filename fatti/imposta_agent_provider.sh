#!/usr/bin/env bash
# imposta_agent_provider.sh — imposta il provider di un agente standalone
# (Secondhand / Open Interpreter) scrivendo il suo config.toml.
#
# - la chiave NON sta in questo file: si legge dal portachiavi (~CHIAVI_LOCALI.md)
# - la chiave NON viene scritta nel config: il config dice solo env_key
# - non tocca il resto del file: sistema model_provider / model e il blocco
#   [model_providers.<id>]
#
# Uso:  bash fatti/imposta_agent_provider.sh [nvidia|groq|mistral] [model-id]
set -u
DIR="$HOME/posta"
[ -d "$DIR" ] || DIR="$HOME/posta_ponte"
cd "$DIR" || { echo "non trovo il clone del repo"; exit 1; }

PROV="${1:-nvidia}"
MODEL="${2:-}"
case "$PROV" in
  nvidia)
    NAME="NVIDIA"; ENVKEY="NVIDIA_API_KEY"; BASEURL="https://integrate.api.nvidia.com/v1"
    [ -n "$MODEL" ] || MODEL="deepseek-ai/deepseek-v4.1-flash" ;;
  groq)
    NAME="Groq"; ENVKEY="GROQ_API_KEY"; BASEURL="https://api.groq.com/openai/v1"
    [ -n "$MODEL" ] || MODEL="openai/gpt-oss-120b" ;;
  mistral)
    NAME="Mistral"; ENVKEY="MISTRAL_API_KEY"; BASEURL="https://api.mistral.ai/v1"
    [ -n "$MODEL" ] || MODEL="codestral-latest" ;;
  *)
    echo "provider non gestito: $PROV (usa nvidia, groq o mistral)"; exit 1 ;;
esac

KEY=$(python3 chiave_di.py "$NAME" 2>/dev/null | head -1)
if [ -z "$KEY" ]; then echo "$NAME: nessuna chiave nel portachiavi"; exit 1; fi
echo "provider: $NAME | modello: $MODEL | env: $ENVKEY | chiave: ${#KEY} caratteri"

# --- dove sta il config di Open Interpreter
CFG=""
for C in "/mnt/c/Users/giopi/.openinterpreter/config.toml" \
         "$HOME/.openinterpreter/config.toml" \
         "/mnt/c/Users/giopi/Documents/AgentWorkspace/.openinterpreter/config.toml"; do
  if [ -f "$C" ]; then CFG="$C"; break; fi
done
if [ -z "$CFG" ]; then
  CFG="/mnt/c/Users/giopi/.openinterpreter/config.toml"
  echo "config non trovato: lo creo in $CFG"
fi
# se il percorso scelto non e' scrivibile (es. non siamo sul PC), si ripiega
if ! mkdir -p "$(dirname "$CFG")" 2>/dev/null || ! touch "$CFG" 2>/dev/null; then
  CFG="$HOME/.openinterpreter/config.toml"
  mkdir -p "$(dirname "$CFG")"
  : > "$CFG"
  echo "percorso non scrivibile: uso $CFG"
fi
[ -f "$CFG" ] || : > "$CFG"
cp -a "$CFG" "$CFG.bak" 2>/dev/null || true

python3 - "$CFG" "$PROV" "$NAME" "$BASEURL" "$ENVKEY" "$MODEL" << 'PYEOF'
import re, sys
cfg, prov, name, base, envkey, model = sys.argv[1:7]
try:
    txt = open(cfg, encoding="utf-8").read()
except FileNotFoundError:
    txt = ""
# via il blocco vecchio del provider (se c'era)
txt = re.sub(r"(?ms)^\[model_providers\.%s\][^\[]*" % re.escape(prov), "", txt)
def set_top(t, key, val):
    if re.search(r"(?m)^%s\s*=" % key, t):
        return re.sub(r"(?m)^%s\s*=.*$" % key, '%s = "%s"' % (key, val), t, count=1)
    return '%s = "%s"\n%s' % (key, val, t)
txt = set_top(txt, "model_provider", prov)
txt = set_top(txt, "model", model)
blocco = ('\n[model_providers.%s]\nname = "%s"\nbase_url = "%s"\nenv_key = "%s"\nwire_api = "chat"\n'
          % (prov, name, base, envkey))
open(cfg, "w", encoding="utf-8").write(txt.rstrip() + "\n" + blocco)
print("config aggiornato:", cfg)
PYEOF

# --- variabile d'ambiente per Windows (il processo la eredita al prossimo avvio)
if command -v cmd.exe >/dev/null 2>&1; then
  cmd.exe /c "setx $ENVKEY $KEY" >/dev/null 2>&1 \
    && echo "setx $ENVKEY fatto (riavvia l'app perche' legga la variabile)" \
    || echo "setx fallito: metti $ENVKEY a mano nelle variabili d'ambiente di Windows"
else
  echo "cmd.exe non qui: la variabile $ENVKEY va messa a mano su Windows"
fi

# --- collaudo: una richiesta vera al provider
echo "collaudo con una richiesta vera..."
CODE=$(curl -s -m 60 -o /tmp/_ag.txt -w "%{http_code}" -X POST "$BASEURL/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Rispondi solo con OK\"}],\"max_tokens\":64}" 2>/dev/null)
echo "HTTP $CODE :: $(head -c 220 /tmp/_ag.txt | tr -d '\n')"
exit 0
