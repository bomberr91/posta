#!/usr/bin/env bash
# hermes_al_cervello.sh — 4/11: Hermes ufficialmente sul cervello locale, come Secondhand.
#
# FATTI (dal referto hermes_chiavi):
#   - config.yaml: provider "custom", base_url http://127.0.0.1:20129/v1  → gia' sul cervello
#   - api_key: len 54, sha12 c48a3514bbbd → NON e' una chiave del roster (non e' nel vault)
#   - .env GOOGLE_API_KEY: len 53, sha12 ce0dea903a90 → NON e' nel vault, e' esclusiva di Hermes
#
# Cosa fa qui: scrive la chiave fissa del portone (sk-cervello) al posto di quella
# chiave non tracciata, con backup, e ricollauda con una chiamata vera.
# Non tocca GOOGLE_API_KEY (Gemini): e' esclusiva di Hermes, non e' nel roster.
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

echo "### 1. STATO (Niente pull dentro lo script: il postino ha gia' fatto il pull)"
echo "commit in testa: $(git log --oneline -1 2>/dev/null)"
echo

echo "### 2. BACKUP E SCRITTURA DI api_key = sk-cervello"
python3 - << 'PY'
import os, re, shutil, hashlib, time
CFG = "/mnt/c/Users/giopi/AppData/Local/hermes/config.yaml"
if not os.path.exists(CFG):
    print("  config.yaml NON TROVATO:", CFG)
    raise SystemExit(1)
bak = CFG + ".bak-" + time.strftime("%Y%m%d-%H%M%S")
shutil.copy2(CFG, bak)
print("  backup:", bak)
s = open(CFG, encoding="utf-8", errors="replace").read()
n = 0
def repl(m):
    global n
    n += 1
    return m.group(1) + 'api_key: "sk-cervello"'
s2 = re.sub(r"^(\s*)api_key\s*:.*$", repl, s, flags=re.M)
open(CFG, "w", encoding="utf-8").write(s2)
print("  righe api_key sostituite:", n)
# rilettura
s3 = open(CFG, encoding="utf-8", errors="replace").read()
for k in ("provider", "base_url"):
    m = re.search(r"^\s*%s\s*:\s*(.+)$" % k, s3, re.M)
    print("  %s = %s" % (k, m.group(1).strip() if m else "(assente)"))
for m in re.finditer(r"^\s*api_key\s*:\s*(.+)$", s3, re.M):
    v = m.group(1).strip().strip('"').strip("'")
    print("  api_key -> len=%d sha12=%s sk_cervello=%s"
          % (len(v), hashlib.sha256(v.encode()).hexdigest()[:12], "SI" if v == "sk-cervello" else "no"))
PY
echo

echo "### 3. COLLAUDO (chiamata vera a Hermes)"
CMD='Rispondi esattamente con la parola OK e nient altro.'
timeout 300 /mnt/c/Users/giopi/AppData/Local/hermes/bin/hermes.exe -z "$CMD" > /tmp/hermescerv_test.txt 2>&1
RC=$?
echo "--- exit hermes: $RC"
echo "--- prime righe:"
head -c 1200 /tmp/hermescerv_test.txt
echo
if grep -qi "OK" /tmp/hermescerv_test.txt; then
  echo "VERDETTO: HERMES RISPONDE (collaudo reale)"
else
  echo "VERDETTO: HERMES NON RISPONDE (exit $RC) — errore qui sopra"
fi
exit 0
