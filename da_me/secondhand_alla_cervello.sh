#!/usr/bin/env bash
# secondhand_alla_cervello.sh — Secondhand (Open Interpreter) passa dal cervello locale.
#
# 4/11 (decisione del capo): Secondhand usava la chiave NVIDIA direttamente
# (config Windows, NVIDIA_API_KEY) ⇒ accavallamento con il roster del cervello
# (NVIDIA è nel roster, quota 35/min). Ora Secondhand parla col CERVELLO (20129)
# con la chiave finta "sk-cervello": zero chiavi provider toccate, come
# OpenClaw e OpenCode.
#
# Fa tre cose:
#   1) backup + riscrittura delle config di Open Interpreter (Windows e WSL)
#   2) imposta OPENAI_API_KEY=sk-cervello (variabile Windows, per l'app)
#   3) collauda: dal WSL (interpreter) e da Windows (curl.exe) sul cervello
#
# Tutto reversibile: i backup sono accanto ai file originali.
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }
WINHOME="/mnt/c/Users/giopi"

echo "### 1. CONFIG DI OPEN INTERPRETER (backup + riscrittura verso il cervello)"
python3 - << 'PYEOF'
import os, re, shutil, datetime

WIN = "/mnt/c/Users/giopi/.openinterpreter/config.toml"
WSL = os.path.expanduser("~/.config/interpreter/config.toml")
STAMP = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
BASE = "http://127.0.0.1:20129/v1"

def mask(t):
    def f(m):
        v = m.group(1)
        if v.startswith("http") or len(v) < 25:
            return m.group(0)
        return '"<%d caratteri>"' % len(v)
    return re.sub(r'"([^"]*)"', f, t)

for path in (WIN, WSL):
    if os.path.exists(path):
        print("--- config attuale: %s" % path)
        print(mask(open(path, encoding="utf-8", errors="replace").read()))
        bak = path + ".bak-" + STAMP
        shutil.copy2(path, bak)
        print("    backup: %s" % bak)
    else:
        print("--- config assente: %s (verra' creato)" % path)

def riscrivi(path, progetto):
    testo = ""
    if os.path.exists(path):
        testo = open(path, encoding="utf-8", errors="replace").read()
    nuovo = testo
    nuovo = re.sub(r'(?<![\w])model_provider\s*=\s*"[^"]*"', 'model_provider = "openai"', nuovo)
    nuovo = re.sub(r'(?<![\w])model\s*=\s*"[^"]*"', 'model = "auto"', nuovo)
    nuovo = re.sub(r'(?<![\w])base_url\s*=\s*"[^"]*"', 'base_url = "%s"' % BASE, nuovo)
    nuovo = re.sub(r'(?<![\w])env_key\s*=\s*"[^"]*"', 'env_key = "OPENAI_API_KEY"', nuovo)
    if progetto and "[projects." not in nuovo:
        nuovo += ("\n[projects.'%s']\nbase_url = \"%s\"\nenv_key = \"OPENAI_API_KEY\"\n"
                  "model_provider = \"openai\"\nmodel = \"auto\"\n" % (progetto, BASE))
    if not nuovo.endswith("\n"):
        nuovo += "\n"
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    open(path, "w", encoding="utf-8").write(nuovo)
    print("--- config nuovo: %s" % path)
    print(mask(nuovo))

riscrivi(WIN, None)
riscrivi(WSL, "/home/agenti/posta")
PYEOF
echo

echo "### 2. VARIABILE WINDOWS (per l'app desktop, che va riavviata)"
cmd.exe /c "setx OPENAI_API_KEY sk-cervello" 2>&1 | tr -d '\r' | tail -2
echo "(sk-cervello NON e' un segreto: e' la chiave fissa del portone del cervello)"
echo

echo "### 3a. COLLAUDO DAL WSL (interpreter sul cervello)"
cd "$REPO" || exit 1
echo "--- versione: $(interpreter --version 2>&1 | head -1)"
echo "--- prova A: interpreter exec --skip-git-repo-check"
OPENAI_API_KEY=sk-cervello OPENAI_BASE_URL="http://127.0.0.1:20129/v1" \
  timeout 240 interpreter exec --skip-git-repo-check "Rispondi esattamente con la parola OK e nient'altro." 2>&1 | tail -20
RCA=${PIPESTATUS[0]}
echo "--- exit prova A: $RCA"
if [ "$RCA" -ne 0 ]; then
  echo "--- prova B: interpreter --skip-git-repo-check exec"
  OPENAI_API_KEY=sk-cervello OPENAI_BASE_URL="http://127.0.0.1:20129/v1" \
    timeout 240 interpreter --skip-git-repo-check exec "Rispondi esattamente con la parola OK e nient'altro." 2>&1 | tail -20
  echo "--- exit prova B: ${PIPESTATUS[0]}"
fi
echo

echo "### 3b. COLLAUDO DA WINDOWS (stessa rete che usa l'app)"
echo "--- /v1/models"
cmd.exe /c "curl.exe -s -m 25 http://127.0.0.1:20129/v1/models -H \"Authorization: Bearer sk-cervello\"" 2>&1 | tr -d '\r' | head -c 400
echo
echo "--- chat vera dal portone"
cmd.exe /c "curl.exe -s -m 90 http://127.0.0.1:20129/v1/chat/completions -H \"Content-Type: application/json\" -H \"Authorization: Bearer sk-cervello\" -d \"{\\\"model\\\":\\\"auto\\\",\\\"messages\\\":[{\\\"role\\\":\\\"user\\\",\\\"content\\\":\\\"rispondi solo OK\\\"}],\\\"max_tokens\\\":60}\"" 2>&1 | tr -d '\r' | head -c 600
echo
echo "FINE"
