#!/usr/bin/env bash
# secondhand_aggiorna2.sh — 4/11: riprendere l'aggiornamento di Secondhand.
#
# PERCHE' ESISTE (2° giro): il primo script (secondhand_aggiorna.sh) si e'
# incastrato su `cmd.exe /c python -m pip install --upgrade open-interpreter`:
# il pip di Windows non rispondeva e restava appeso (il bash aspetta il figlio
# in primo piano, quindi anche il `timeout 1800` del postino non lo staccava).
# Intanto il postino e il poller si sono bloccati sul repo.
#
# Cosa fa qui, in ordine, SENZA appendersi:
#   1) kill dei pip appesi (pattern con parentesi: non si uccide da solo)
#   2) stato delle versioni (WSL e Windows)
#   3) aggiornamento WSL con timeout (quello che conta per il ponte)
#   4) riallineamento delle config al cervello, se l'aggiornamento le ha toccate
#   5) collaudo reale: l'interpreter deve rispondere OK sul cervello
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

WIN_CFG=/mnt/c/Users/giopi/.openinterpreter/config.toml
WSL_CFG="$HOME/.config/interpreter/config.toml"
BASE="http://127.0.0.1:20129/v1"

echo "### 1. PULIZIA DEI PROCESSI APPESI"
pkill -f '[p]ip install --upgrade open-interpreter' 2>/dev/null && echo "  pip di Windows chiuso" || echo "  nessun pip appeso"
pkill -f '[c]md.exe /c python -m pip' 2>/dev/null && echo "  cmd.exe del pip chiuso" || echo "  nessun cmd.exe appeso"
sleep 2
echo "  rimasti: $(pgrep -c -f '[p]ip install' 2>/dev/null || echo 0)"
echo

echo "### 2. VERSIONI (prima)"
echo "  WSL: $(interpreter --version 2>&1 | head -1)"
for p in /mnt/c/Users/giopi/AppData/Local/Programs/Python/Python*/Scripts/interpreter.exe; do
  [ -f "$p" ] && echo "  Windows: $("$p" --version 2>&1 | head -1)"
done
echo

echo "### 3. AGGIORNAMENTO WSL (con tetto: 600s)"
timeout 600 python3 -m pip install --upgrade open-interpreter > /tmp/sh_upd2.log 2>&1
RC=$?
echo "  exit pip WSL: $RC"
tail -6 /tmp/sh_upd2.log
echo "  versione WSL dopo: $(interpreter --version 2>&1 | head -1)"
echo

echo "### 4. LE CONFIG PUNTANO ANCORA AL CERVELLO?"
python3 - << 'PY'
import os, re, shutil, glob
BASE = "http://127.0.0.1:20129/v1"
WSL = os.path.expanduser("~/.config/interpreter/config.toml")
WIN = "/mnt/c/Users/giopi/.openinterpreter/config.toml"

def sistema(path, progetto=None):
    if not os.path.exists(path):
        print("  ATTENZIONE: config assente:", path)
        return
    s = open(path, encoding="utf-8", errors="replace").read()
    bak = path + ".bak-pre-riallineamento"
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
    def metti(testo, chiave, valore, in_alto):
        if in_alto:
            testo = re.sub(r'(?m)^%s\s*=.*\n?' % chiave, "", testo)
            return '%s = "%s"\n' % (chiave, valore) + testo
        return re.sub(r'(?m)^%s\s*=.*$' % chiave, '%s = "%s"' % (chiave, valore), testo)
    s = metti(s, "base_url", BASE, True)
    s = metti(s, "env_key", "OPENAI_API_KEY", True)
    s = metti(s, "model_provider", "openai", True)
    s = metti(s, "model", "auto", True)
    open(path, "w", encoding="utf-8").write(s)
    print("  riallineata:", path)

for p in (WIN, WSL):
    if os.path.exists(p):
        s = open(p, encoding="utf-8", errors="replace").read()
        if BASE not in s:
            print("  %s: NON puntava al cervello -> riallineo" % p)
            sistema(p)
        else:
            print("  %s: gia' sul cervello" % p)
PY
echo

echo "### 5. COLLAUDO REALE"
OUT=/tmp/sh_upd2_collaudo.log
cd "$REPO" || exit 1
OPENAI_API_KEY=sk-cervello timeout 240 interpreter exec --skip-git-repo-check \
  "Rispondi esattamente con la parola OK e nient'altro." > "$OUT" 2>&1
RC=$?
echo "--- exit: $RC"
grep -E "^(OK|provider:|model:)" "$OUT" | head -6
head -c 400 "$OUT"
echo
if [ "$RC" -eq 0 ] && grep -qi "^OK" "$OUT"; then
  echo "VERDETTO: SECONDHAND FUNZIONA SUL CERVELLO"
else
  echo "VERDETTO: PROBLEMA (exit $RC) — vedi output sopra"
fi
echo
echo "### 6. NOTA SULL'APP DESKTOP"
echo "L'app Windows va riavviata per leggere OPENAI_API_KEY (setx vale per i processi nuivi)."
echo "FINE"
exit 0
