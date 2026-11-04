#!/usr/bin/env bash
# Secondhand / Open Interpreter 0.4.3 — profilo WINDOWS reso "controllato".
#
# Perche' (4/11, ordine del capo): l'agente "continuava a lavorare da solo".
# Motivo trovato dagli agenti: il profilo aveva auto_run: True e safe_mode:
# "off" (YAML) e sandbox_mode = "danger-full-access" (TOML 0.4.x) => esegue
# il codice senza chiedere conferma.
#
# Cosa fa: SOLO sul profilo Windows (quello dell'app interattiva):
#   YAML  auto_run: True  -> auto_run: False
#         safe_mode: "off" -> safe_mode: "ask"
#   TOML  sandbox_mode = "danger-full-access" -> "workspace-write"
#         approval_policy = "never" -> "on-request"
# Il profilo WSL (quello del ponte, non interattivo) resta com'e': li' l'auto-run
# serve, altrimenti la CLI chiede "(y/n)" e va in EOFError.
# Backup dei due file in /tmp/secondhand_win_<timestamp>/ prima di toccarli.
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

python3 /home/agenti/posta/da_me/secondhand_patch_win.py > "$BAK/patch.log" 2>&1

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
