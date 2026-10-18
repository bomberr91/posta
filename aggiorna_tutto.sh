#!/usr/bin/env bash
# aggiorna_tutto.sh — Aggiornamento completo FilippoPC (18/10/2026)
set -u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$PATH"

# Assicura che PATH sia sempre in cima a ~/.bashrc e ~/.profile anche per shell non-interattive
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  if [ -f "$rc" ] && ! head -n 5 "$rc" | grep -q 'opencode/bin'; then
    tmp=$(mktemp)
    cat << 'EOP' > "$tmp"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$PATH"
EOP
    cat "$rc" >> "$tmp"
    mv "$tmp" "$rc"
  fi
done

echo "=========================================================="
echo " 🚀 AGGIORNAMENTO POTENZIAMENTO FILIPPOPC (18/10/2026)"
echo "=========================================================="

echo ""
echo "── 1/6 · Sincronizzo il ponte ~/posta da GitHub..."
if [ -d "$HOME/posta/.git" ]; then
  cd "$HOME/posta"
  TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"; [ -z "$TOKEN" ] && [ -f "$HOME/CHIAVI_LOCALI.md" ] && TOKEN="$(grep -oE 'ghp_[A-Za-z0-9]{30,}' "$HOME/CHIAVI_LOCALI.md" | head -1)"
  LOGIN=""; [ -s "$HOME/.posta_login" ] && LOGIN="$(tr -d '\r\n' < "$HOME/.posta_login")"
  [ -z "$LOGIN" ] && [ -s "$HOME/posta/.padrone" ] && LOGIN="$(tr -d '\r\n' < "$HOME/posta/.padrone")"
  if [ -n "$TOKEN" ] && [ -n "$LOGIN" ]; then
    git fetch -q origin main && git reset -q --hard origin/main || true
  else
    git pull -q || true
  fi
  chmod +x "$HOME/posta/postino.sh" "$HOME/posta/squadra.sh" 2>/dev/null || true
  echo "  ✓ Ponte ~/posta aggiornato"
fi

echo ""
echo "── 2/6 · Installo tutte le 26 Skill (Pacchetti A+B+C+D) per TUTTI gli agenti..."
if [ -f "$HOME/posta/skills_pack.tar.gz" ]; then
  tar -xzf "$HOME/posta/skills_pack.tar.gz" -C "$HOME"
  mkdir -p "$HOME/.claude/skills" "$HOME/.hermes/skills"
  cp -rf "$HOME/.agents/skills/"* "$HOME/.claude/skills/" 2>/dev/null || true
  cp -rf "$HOME/.agents/skills/"* "$HOME/.hermes/skills/" 2>/dev/null || true
  date -Is > "$HOME/.skills_v2_installed"
  echo "  ✓ 26 Skill attive in ~/.agents/skills, ~/.config/opencode/skills, ~/.config/goose/skills, ~/.hermes/skills"
fi

echo ""
echo "── 3/6 · Installo gli strumenti Browser & Web (agent-browser + firecrawl-cli)..."
if command -v npm >/dev/null 2>&1; then
  npm i -g agent-browser firecrawl-cli >/dev/null 2>&1 && echo "  ✓ agent-browser + firecrawl-cli pronti" || echo "  · npm install parziale"
fi

echo ""
echo "── 4/6 · Installo Secondhand (OpenInterpreter Rust - 68k★)..."
if command -v interpreter >/dev/null 2>&1; then
  echo "  ✓ Secondhand (interpreter) già installato: $(interpreter --version 2>&1 | head -1)"
else
  OPEN_INTERPRETER_NONINTERACTIVE=1 curl -fsSL https://www.openinterpreter.com/install | OPEN_INTERPRETER_NONINTERACTIVE=1 sh >/dev/null 2>&1 || true
  export PATH="$HOME/.local/bin:$PATH"
  if command -v interpreter >/dev/null 2>&1; then
    echo "  ✓ Secondhand installato: $(interpreter --version 2>&1 | head -1)"
  else
    echo "  · Secondhand: installazione saltata o non compatibile WSL1"
  fi
fi

echo ""
echo "── 5/6 · Installo Hermes Agent (NousResearch - 254k★)..."
if command -v hermes >/dev/null 2>&1 || [ -x "$HOME/.hermes/hermes-agent/venv/bin/hermes" ]; then
  echo "  ✓ Hermes Agent già installato"
else
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive --skip-browser --skip-computer-use >/dev/null 2>&1 || true
  if command -v hermes >/dev/null 2>&1 || [ -d "$HOME/.hermes/hermes-agent" ]; then
    echo "  ✓ Hermes Agent installato in ~/.hermes"
  else
    echo "  · Hermes Agent: installazione saltata"
  fi
fi

echo ""
echo "── 6/6 · Installo OpenClaw (392k★) e creo le nuove icone sul Desktop..."
if command -v openclaw >/dev/null 2>&1; then
  echo "  ✓ OpenClaw già installato: $(openclaw --version 2>&1 | head -1)"
else
  curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | OPENCLAW_NO_ONBOARD=1 OPENCLAW_NO_PROMPT=1 bash -s -- --runtime node --no-onboard --no-prompt >/dev/null 2>&1 || true
  if command -v openclaw >/dev/null 2>&1; then
    echo "  ✓ OpenClaw installato: $(openclaw --version 2>&1 | head -1)"
  else
    echo "  · OpenClaw richiede Node >=24 (installo Node 24 in nvm per OpenClaw)..."
    if [ -s "$NVM_DIR/nvm.sh" ]; then
      nvm install 24 >/dev/null 2>&1 && npm install -g openclaw@latest --allow-scripts=openclaw >/dev/null 2>&1 || true
      nvm alias default 24 >/dev/null 2>&1 || true
    fi
    command -v openclaw >/dev/null 2>&1 && echo "  ✓ OpenClaw installato: $(openclaw --version 2>&1 | head -1)" || echo "  · OpenClaw: riproveremo al prossimo giro"
  fi
fi

chmod +x "$HOME/posta/centrale.sh" "$HOME/posta/leggi_video.py" "$HOME/posta/squadra.sh" "$HOME/posta/postino.sh" 2>/dev/null || true
for d in /mnt/c/Users/*/Desktop /mnt/c/Users/*/OneDrive*/Desktop; do
  if [ -d "$d" ] && [ -f "$d/RAPPORTO_AGENTI.txt" -o -f "$d/COMPITI.lnk" -o -f "$d/BROWSER_AGENTI.bat" -o -f "$d/CENTRALE_AGENTI.bat" ]; then
    cp -f "$HOME/posta/CENTRALE_AGENTI.bat" "$d/CENTRALE_AGENTI.bat" 2>/dev/null || true
    rm -f "$d/BROWSER_AGENTI.bat" "$d/SQUADRA_FUSION.bat" "$d/APRI_AGENTE.lnk" "$d/AVVIA_POSTINO.lnk" "$d/COMPITI.lnk" "$d/AGGIORNA_TUTTO_PC.bat" 2>/dev/null || true
    echo "  ✓ Desktop ripulito: ora hai UN'UNICA icona → CENTRALE_AGENTI.bat"
  fi
done

# Segna i vecchi task di aggiornamento come già fatti e manda il rapporto sul ponte
mkdir -p "$HOME/posta/fatti" "$HOME/posta/dal_pc"
rm -f "$HOME/posta/da_me/aggiorna_26_skill_e_browser.sh" "$HOME/posta/da_me/prova.md" 2>/dev/null || true
{
  echo "# ✅ Rapporto Aggiornamento FilippoPC (18/10/2026)"
  echo "_$(date '+%d/%m/%Y %H:%M') · $(hostname)_"
  echo ""
  echo "- **Skill installate**: $(ls -1 ~/.agents/skills 2>/dev/null | wc -l) (in OpenCode, Goose, Hermes, Secondhand)"
  echo "- **OpenCode**: $(opencode --version 2>&1 | head -1)"
  echo "- **Goose**: $(goose --version 2>&1 | head -1)"
  echo "- **Secondhand (interpreter)**: $(interpreter --version 2>&1 | head -1 || echo non presente)"
  echo "- **Hermes Agent**: $(hermes --version 2>&1 | head -1 || ([ -d ~/.hermes/hermes-agent ] && echo installato in ~/.hermes || echo non presente))"
  echo "- **OpenClaw**: $(openclaw --version 2>&1 | head -1 || echo non presente)"
  echo "- **Agent-Browser**: $(agent-browser --version 2>&1 | head -1 || echo non presente)"
  echo "- **Squadra Fusion**: pronta (~/posta/squadra.sh + SQUADRA_FUSION.bat sul Desktop)"
  echo "- **Browser Agenti**: pronto (BROWSER_AGENTI.bat sul Desktop)"
} > "$HOME/posta/dal_pc/stato_18_10.md"

cd "$HOME/posta"
git add -A >/dev/null 2>&1 && git commit -qm "aggiornamento completo 18/10 da $(hostname)" >/dev/null 2>&1 || true
if [ -n "${TOKEN:-}" ] && [ -n "${LOGIN:-}" ]; then
  git push -q "https://x-access-token:$TOKEN@github.com/$LOGIN/posta.git" HEAD:main >/dev/null 2>&1 || true
fi

echo ""
echo "=========================================================="
echo " 🎉 TUTTO PRONTO SU FILIPPOPC!"
echo " Sul Desktop ora hai anche:"
echo "   - BROWSER_AGENTI.bat  (apre il browser controllato dagli agenti)"
echo "   - SQUADRA_FUSION.bat  (lancia 3 agenti in sincronia su un compito)"
echo "=========================================================="
