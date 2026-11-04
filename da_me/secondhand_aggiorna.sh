#!/usr/bin/env bash
# secondhand_aggiorna.sh — 4/11: eseguire l'aggiornamento di Open Interpreter (Secondhand).
#
# Il capo ha riavviato l'app e visto la notifica di aggiornamento: "fagli
# eseguire l'aggiornamento e verifica se è tutto a posto".
#
# RISCHI (gestiti qui):
#   1) un aggiornamento puo' AZZERARE config.toml  -> backup prima, confronto dopo
#   2) un aggiornamento puo' cambiare la CLI       -> collaudo reale sul cervello dopo
#   3) non voglio stampare chiavi                  -> solo versioni e config mascherata
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

STAMP=$(date +%Y%m%d-%H%M%S)
WIN_CFG=/mnt/c/Users/giopi/.openinterpreter/config.toml
WSL_CFG="$HOME/.config/interpreter/config.toml"
LOG=/tmp/sh_update.log
: > "$LOG"

echo "### 1. COME E' INSTALLATO ORA (WSL)"
command -v interpreter >/dev/null 2>&1 && echo "  interprete WSL: $(command -v interpreter)" || echo "  interprete WSL: NON IN PATH"
echo "  versione WSL: $(interpreter --version 2>&1 | head -1)"
echo "  pip show: $(python3 -m pip show open-interpreter 2>/dev/null | grep -i '^Version' || echo 'non via pip di sistema')"
echo "  pipx: $(command -v pipx >/dev/null 2>&1 && pipx list 2>/dev/null | grep -i open-interpreter || echo 'pipx assente o non presente')"
echo "  uv: $(command -v uv >/dev/null 2>&1 && uv tool list 2>/dev/null | grep -i open-interpreter || echo 'uv assente o non presente')"
echo "  python3: $(python3 --version 2>&1)"
echo

echo "### 2. COME E' INSTALLATO ORA (Windows)"
for p in /mnt/c/Users/giopi/AppData/Local/Programs/Python/Python*/Scripts/interpreter.exe \
         "/mnt/c/Users/giopi/AppData/Local/Programs/Open Interpreter/interpreter.exe" \
         "/mnt/c/Users/giopi/AppData/Local/Programs/open-interpreter/interpreter.exe"; do
  [ -f "$p" ] && echo "  trovato: $p" && echo "    versione: $("$p" --version 2>&1 | head -1)"
done
echo "  cartelle Programs:"
ls /mnt/c/Users/giopi/AppData/Local/Programs/ 2>/dev/null | head -20
echo "  python Windows:"
cmd.exe /c "python --version" 2>/dev/null | tr -d '\r' | head -2
cmd.exe /c "python -m pip show open-interpreter" 2>/dev/null | tr -d '\r' | grep -i -E "^Name|^Version|^Location" | head -5
echo

echo "### 3. BACKUP DELLE CONFIG (prima di toccare qualunque cosa)"
mkdir -p /tmp/sh_backup_$STAMP
[ -f "$WIN_CFG" ] && cp "$WIN_CFG" "/tmp/sh_backup_$STAMP/config_windows.toml" && echo "  backup Windows: /tmp/sh_backup_$STAMP/config_windows.toml"
[ -f "$WSL_CFG" ] && cp "$WSL_CFG" "/tmp/sh_backup_$STAMP/config_wsl.toml" && echo "  backup WSL: /tmp/sh_backup_$STAMP/config_wsl.toml"
sha256sum "$WIN_CFG" "$WSL_CFG" > "/tmp/sh_backup_$STAMP/sha.txt" 2>/dev/null
echo

echo "### 4. AGGIORNAMENTO"
echo "--- tentativo A: pipx upgrade (WSL)"
if command -v pipx >/dev/null 2>&1 && pipx list 2>/dev/null | grep -qi open-interpreter; then
  timeout 600 pipx upgrade open-interpreter >> "$LOG" 2>&1
  echo "  exit pipx: $?"
else
  echo "  non applicabile"
fi
echo "--- tentativo B: python3 -m pip install --upgrade open-interpreter (WSL)"
timeout 900 python3 -m pip install --upgrade open-interpreter >> "$LOG" 2>&1
echo "  exit pip WSL: $?"
echo "--- tentativo C: pip install --upgrade (Windows)"
cmd.exe /c "python -m pip install --upgrade open-interpreter" >> "$LOG" 2>&1
echo "  exit pip Windows: $?"
echo "--- ultime righe del log di installazione:"
tail -12 "$LOG"
echo
echo "--- versioni DOPO:"
echo "  versione WSL: $(interpreter --version 2>&1 | head -1)"
for p in /mnt/c/Users/giopi/AppData/Local/Programs/Python/Python*/Scripts/interpreter.exe; do
  [ -f "$p" ] && echo "  versione Windows ($p): $("$p" --version 2>&1 | head -1)"
done
echo

echo "### 5. LE CONFIG SONO ANCORA QUELLE DEL CERVELLO?"
python3 - << 'PY'
import os, re, hashlib
def leggi(p):
    return open(p, encoding="utf-8", errors="replace").read() if os.path.exists(p) else None
for etichetta, p in (("Windows", "/mnt/c/Users/giopi/.openinterpreter/config.toml"),
                     ("WSL", os.path.expanduser("~/.config/interpreter/config.toml"))):
    s = leggi(p)
    if s is None:
        print("  %s: CONFIG ASSENTE (l'aggiornamento l'ha rimossa o spostata)" % etichetta)
        continue
    print("  %s:" % etichetta)
    for k in ("model_provider", "model", "base_url", "env_key"):
        m = re.search(r"^%s\s*=\s*(.+)$" % k, s, re.M)
        if m:
            print("     %s = %s" % (k, m.group(1).strip()))
    ok = "http://127.0.0.1:20129/v1" in s
    print("     punta al cervello: %s" % ("SI" if ok else "NO — va rimessa"))
PY
echo

echo "### 6. COLLAUDO REALE (l'interpreter deve rispondere OK sul cervello)"
OUT=/tmp/sh_update_collaudo.log
cd "$REPO" || exit 1
OPENAI_API_KEY=sk-cervello timeout 240 interpreter exec --skip-git-repo-check \
  "Rispondi esattamente con la parola OK e nient'altro." > "$OUT" 2>&1
RC=$?
echo "--- exit: $RC"
head -c 1200 "$OUT"
echo
if [ "$RC" -eq 0 ] && grep -qi "^OK" "$OUT"; then
  echo "VERDETTO: AGGIORNAMENTO RIUSCITO E COLLAUDATO (risposta OK dal cervello)"
else
  echo "VERDETTO: PROBLEMA DOPO L'AGGIORNAMENTO (exit $RC) — vedi output sopra"
  echo "Se la config e' stata azzerata, si puo' rimettere dal backup:"
  echo "  /tmp/sh_backup_$STAMP/"
fi
echo
echo "FINE"
exit 0
