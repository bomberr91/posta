#!/bin/bash
# patch_browser_agenti.sh — gli agenti devono usare il BROWSER ISOLATO, non il
# Chrome di lavoro del capo. Eseguito dal PC dal postino.
#
# IL BUCO: la skill `use-my-browser` insegnava `--autoConnect`, che aggancia il
# Chrome GIA' APERTO del capo (quello con le sue sessioni e login). Le
# alternative manuali citavano la porta 9222 (di un Chrome "normale").
# IL BRACCIO CORRETTO: il profilo isolato di OpenClaw, CDP 18800, lanciato dal
# collegamento sul desktop (non parte col boot, per scelta del capo).
#
# Cosa fa:
#   1. dice se il browser isolato (18800) e' vivo;
#   2. in tutte le copie della skill `use-my-browser` (agents, opencode, claude)
#      toglie `--autoConnect` e mette `--browserUrl=http://127.0.0.1:18800`,
#      e mette in testa un avviso che non si può ignorare;
#   3. aggiunge al config di OpenCode il MCP chrome-devtools che punta a 18800;
#   4. verifica e riporta.
# Parla solo con lo stdout: il referto arriva in dal_pc/patch_browser_agenti.md

BROWSER_URL="http://127.0.0.1:18800"
AGGIUNTA=$(cat <<'EOT'
> **REGOLA (3/11): questo agente NON deve toccare il Chrome di lavoro del capo.**
> Usare **solo** il browser isolato: `--browserUrl=http://127.0.0.1:18800`
> (profilo `openclaw` di OpenClaw, avviato dal collegamento sul desktop).
> **Mai `--autoConnect`**: aggancia il Chrome gia aperto del capo, con le sue
> sessioni. La porta 9222 non si usa piu.
EOT
)
echo "## 1. Browser isolato (CDP 18800)"
python3 - <<'PY'
import urllib.request, json
try:
    d = json.loads(urllib.request.urlopen("http://127.0.0.1:18800/json/version", timeout=5).read().decode())
    print("- 18800: VIVO ->", d.get("Browser", "?"))
except Exception as e:
    print(f"- 18800: non risponde ({type(e).__name__}) -> va avviato dal collegamento sul desktop")
PY

echo ""
echo "## 2. Skill use-my-browser: tolgo --autoConnect"
TROVATI=0
for RADICE in "$HOME/.agents/skills" "$HOME/.config/opencode/skills" "$HOME/.claude/skills"; do
  [ -d "$RADICE/use-my-browser" ] || continue
  TROVATI=$((TROVATI+1))
  echo "- copia: $RADICE/use-my-browser"
  # 2a. i parametri: --autoConnect -> --browserUrl del browser isolato
  for F in "$RADICE"/use-my-browser/*.md "$RADICE"/use-my-browser/references/*.md; do
    [ -f "$F" ] || continue
    if grep -q -- "--autoConnect" "$F" 2>/dev/null; then
      sed -i 's|--autoConnect|--browserUrl=http://127.0.0.1:18800|g' "$F"
      echo "    [parametro] $(basename "$F"): --autoConnect -> --browserUrl 18800"
    fi
    if grep -q "127.0.0.1:9222" "$F" 2>/dev/null; then
      sed -i 's|127\.0\.0\.1:9222|127.0.0.1:18800|g' "$F"
      echo "    [porta] $(basename "$F"): 9222 -> 18800"
    fi
  done
  # 2b. l'avviso in testa al README (una volta sola)
  R="$RADICE/use-my-browser/README.md"
  if [ -f "$R" ] && ! grep -q "REGOLA (3/11)" "$R" 2>/dev/null; then
    cp -p "$R" "/tmp/use-my-browser-README.bak.$(date +%s)" 2>/dev/null || true
    python3 - "$R" "$AGGIUNTA" <<'PY'
import sys
path, blocco = sys.argv[1], sys.argv[2]
try:
    d = open(path, encoding='utf-8', errors='replace').read()
    righe = d.splitlines()
    # inserisco dopo il titolo (prima riga non vuota)
    i = 0
    while i < len(righe) and not righe[i].strip():
        i += 1
    i += 1
    nuovo = "\n".join(righe[:i]) + "\n\n" + blocco + "\n\n" + "\n".join(righe[i:])
    open(path, 'w', encoding='utf-8').write(nuovo)
    print("    [avviso] inserito in README.md")
except Exception as e:
    print("    [avviso] non riuscito:", e)
PY
  fi
done
[ "$TROVATI" -eq 0 ] && echo "- nessuna copia trovata (percorsi: ~/.agents/skills, ~/.config/opencode/skills, ~/.claude/skills)"

echo ""
echo "## 3. Config OpenCode: MCP chrome-devtools sul browser isolato"
CFG="$HOME/.config/opencode/opencode.jsonc"
mkdir -p "$(dirname "$CFG")" 2>/dev/null || true
cp -p "$CFG" "/tmp/opencode.jsonc.bak.$(date +%s)" 2>/dev/null || true
python3 - "$CFG" "$BROWSER_URL" <<'PY'
import json, sys, re
path, browser_url = sys.argv[1], sys.argv[2]
d = open(path, encoding='utf-8').read() if __import__('os').path.exists(path) else '{}'
try:
    cfg = json.loads(d)
except Exception:
    # .jsonc: tolgo i commenti e riprovo
    pulito = re.sub(r'//.*', '', d)
    pulito = re.sub(r'/\*.*?\*/', '', pulito, flags=re.S)
    try:
        cfg = json.loads(pulito)
    except Exception:
        cfg = {"$schema": "https://opencode.ai/config.json"}
cfg.setdefault("$schema", "https://opencode.ai/config.json")
mcp = cfg.setdefault("mcp", {})
mcp["chrome-devtools"] = {
    "type": "local",
    "command": ["npx", "-y", "chrome-devtools-mcp@latest", "--browserUrl=" + browser_url],
    "enabled": True,
}
open(path, 'w', encoding='utf-8').write(json.dumps(cfg, indent=2) + "\n")
print("- MCP chrome-devtools aggiornato verso", browser_url)
PY
echo "- config finale:"
sed 's/^/    /' "$CFG"

echo ""
echo "## 4. Verifica"
RESIDUI=$(grep -rl -- "--autoConnect" "$HOME/.agents/skills" "$HOME/.config/opencode/skills" "$HOME/.claude/skills" 2>/dev/null | head -5)
if [ -n "$RESIDUI" ]; then
  echo "- ATTENZIONE: resta --autoConnect in:"
  echo "$RESIDUI" | sed 's/^/    /'
else
  echo "- nessun --autoConnect residuo nelle skill"
fi
grep -q "18800" "$CFG" 2>/dev/null && echo "- il config OpenCode punta a 18800: OK" || echo "- il config NON punta a 18800"
