#!/usr/bin/env bash
# Secondhand / Open Interpreter 0.4.3 — profilo WINDOWS reso "controllato".
#
# Perche' (4/11, ordine del capo): l'agente "continuava a lavorare da solo".
# Motivo trovato dagli agenti: il profilo aveva auto_run: True e safe_mode:
# "off" (YAML) e sandbox_mode = "danger-full-access" + approval_policy = "never"
# (TOML 0.4.x) => esegue il codice senza chiedere conferma.
#
# Cosa fa: SOLO sul profilo Windows (quello dell'app interattiva):
#   YAML  auto_run: True  -> auto_run: False
#         safe_mode: "off" -> safe_mode: "ask"
#   TOML  sandbox_mode = "danger-full-access" -> "workspace-write"
#         approval_policy = "never" -> "on-request"
# Il profilo WSL (quello del ponte, non interattivo) resta com'e': li' l'auto-run
# serve, altrimenti la CLI chiede "(y/n)" e va in EOFError.
# Backup dei due file in /tmp/secondhand_win_<timestamp>/ prima di toccarli.
#
# NOTA: il python e' QUI dentro (niente file .py in da_me/: il postino tratta
# ogni file di da_me/ come un compito e lo sposta in fatti/*.done).
set -u
OUT="/home/agenti/posta/dal_pc/secondhand_win_sicuro.md"
STAMP=$(date +%Y%m%d-%H%M%S)
BAK="/tmp/secondhand_win_$STAMP"
mkdir -p "$BAK"

YAML_W="/mnt/c/Users/giopi/.config/open-interpreter/profiles/default.yaml"
TOML_W="/mnt/c/Users/giopi/.openinterpreter/config.toml"
YAML_L="/home/agenti/.config/open-interpreter/profiles/default.yaml"

[ -f "$YAML_W" ] && cp -a "$YAML_W" "$BAK/default.yaml.bak"
[ -f "$TOML_W" ] && cp -a "$TOML_W" "$BAK/config.toml.bak"

python3 - > "$BAK/patch.log" 2>&1 << 'PYEOF'
import os
import re

YAML_W = "/mnt/c/Users/giopi/.config/open-interpreter/profiles/default.yaml"
TOML_W = "/mnt/c/Users/giopi/.openinterpreter/config.toml"

PATCHES = {
    YAML_W: [
        (r"(?m)^auto_run:\s*True\s*$", "auto_run: False"),
        (r'(?m)^safe_mode:\s*"off"\s*$', 'safe_mode: "ask"'),
    ],
    TOML_W: [
        (r'(?m)^sandbox_mode\s*=\s*"danger-full-access"\s*$', 'sandbox_mode = "workspace-write"'),
        (r'(?m)^approval_policy\s*=\s*"never"\s*$', 'approval_policy = "on-request"'),
    ],
}

for path, coppie in PATCHES.items():
    if not os.path.exists(path):
        print("%s: ASSENTE (niente da fare)" % path)
        continue
    s = open(path, encoding="utf-8", errors="replace").read()
    for pat, rep in coppie:
        s, n = re.subn(pat, rep, s)
        if n == 0:
            print("%s: NON TROVATO %s" % (path, pat))
    with open(path, "w", encoding="utf-8") as f:
        f.write(s)
    print("%s: aggiornato" % path)
print("patch finita")
PYEOF

{
  echo "# Secondhand — profilo Windows reso \"controllato\" (4/11)"
  echo
  echo "- backup: \`$BAK\`"
  echo "- YAML Windows: \`auto_run\` True->False, \`safe_mode\` \"off\"->\"ask\""
  echo "- TOML Windows: \`sandbox_mode\` danger-full-access->workspace-write,"
  echo "  \`approval_policy\` never->on-request"
  echo "- profilo WSL del ponte: **NON toccato** (auto_run True / safe_mode off:"
  echo "  lì l'auto-run serve, altrimenti la CLI chiede (y/n) e va in EOFError)"
  echo
  echo "## Esito delle sostituzioni"
  echo '```'
  cat "$BAK/patch.log" 2>/dev/null || echo "(nessun log)"
  echo '```'
  echo
  echo "## Dopo — YAML Windows"
  echo '```'
  cat "$YAML_W" 2>/dev/null || echo "(assente)"
  echo '```'
  echo
  echo "## Dopo — TOML Windows"
  echo '```'
  cat "$TOML_W" 2>/dev/null || echo "(assente)"
  echo '```'
  echo
  echo "## Profilo WSL del ponte (solo lettura, invariato)"
  echo '```'
  cat "$YAML_L" 2>/dev/null || echo "(assente)"
  echo '```'
} > "$OUT"

echo "OK report: $OUT"
