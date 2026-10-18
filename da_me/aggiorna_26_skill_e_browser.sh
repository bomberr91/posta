#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

echo "=== 1. Estraggo tutte le 26 Skill (OpenCode + Goose) ==="
if [ -f "$HOME/posta/skills_pack.tar.gz" ]; then
  tar -xzf "$HOME/posta/skills_pack.tar.gz" -C "$HOME"
  date -Is > "$HOME/.skills_v2_installed"
  echo "Skill installate in ~/.config/opencode/skills ($(ls -1 ~/.config/opencode/skills | wc -l)) e ~/.config/goose/skills ($(ls -1 ~/.config/goose/skills | wc -l))"
fi

echo "=== 2. Installo agent-browser CLI e firecrawl-cli ==="
npm i -g agent-browser firecrawl-cli >/dev/null 2>&1 && echo "agent-browser + firecrawl-cli installati" || echo "npm install parziale"

echo "=== 3. Copio BROWSER_AGENTI.bat sul Desktop di Windows ==="
for d in /mnt/c/Users/*/Desktop /mnt/c/Users/*/OneDrive*/Desktop; do
  if [ -d "$d" ] && [ -f "$d/RAPPORTO_AGENTI.txt" -o -f "$d/COMPITI.lnk" ]; then
    cp -f "$HOME/posta/6_BROWSER_AGENTI.bat" "$d/BROWSER_AGENTI.bat" 2>/dev/null && echo "Copiato in $d/BROWSER_AGENTI.bat"
  fi
done

echo "=== 4. Verifica versioni ==="
echo "OpenCode: $(opencode --version 2>&1 | head -1)"
echo "Goose: $(goose --version 2>&1 | head -1)"
echo "Agent-Browser: $(agent-browser --version 2>&1 | head -1)"
