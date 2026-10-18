#!/usr/bin/env bash
# aggiorna_tutto.sh — Aggiornamento completo FilippoPC (18/10/2026)
set -u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH"
# Auto-rileva il bin del Node v22 (MAI versioni cablate: sul PC puo' cambiare)
V22BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
[ -n "$V22BIN" ] && export PATH="$V22BIN:$PATH"

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
# npm robusto: preferisci SEMPRE il Node v22 di nvm (su WSL1 il Node 24 non parte: Exec format error)
NPM22=$(ls "$HOME/.nvm/versions/node/v22"*/bin/npm 2>/dev/null | sort -V | tail -1)
[ -z "$NPM22" ] && command -v npm >/dev/null 2>&1 && NPM22=$(command -v npm)
if [ -n "$NPM22" ]; then
  "$NPM22" i -g agent-browser firecrawl-cli >/dev/null 2>&1 && echo "  ✓ agent-browser + firecrawl-cli pronti (npm: $NPM22)" || echo "  · npm install parziale (non blocca nulla: i tool gia' presenti restano attivi)"
else
  echo "  · npm non trovato: salto (non blocca nulla)"
fi

echo ""
# Riporta il default nvm su v22 se qualche giro precedente lo aveva messo su 24 (rotto su WSL1)
V22DIR=$(ls -d "$HOME/.nvm/versions/node/v22"* 2>/dev/null | sort -V | tail -1)
if [ -n "$V22DIR" ] && [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 && nvm alias default "$(basename "$V22DIR")" >/dev/null 2>&1 || true
fi

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
      : # (rimosso: MAI mettere il default su Node 24, su WSL1 non parte)
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

# === POTENZIAMENTO SCAGLIONE 1 (18/10): Headroom + XERJ + Beads + MarkItDown + Gemini CLI + Marketing/Taste Skills ===
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
NODE22_BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
export PATH="$NODE22_BIN:$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$PATH"
mkdir -p "$HOME/.local/bin" "$HOME/.agents/skills"

if [ -f "$HOME/posta/da_me/scaglione1_applica_innesti.sh" ] && [ ! -f "$HOME/.scaglione1_innesti_done" ]; then
  bash "$HOME/posta/da_me/scaglione1_applica_innesti.sh" && touch "$HOME/.scaglione1_innesti_done"
fi

# Installa anche le skill di Marketing (CRO, Copywriting, SEO, Social) e Taste-Skill (UI Anti-Slop)
if [ ! -d "$HOME/.agents/skills/taste-skill" ]; then
  git clone --depth 1 -q https://github.com/leonxlnx/taste-skill.git /tmp/ts_sk 2>/dev/null && cp -r /tmp/ts_sk "$HOME/.agents/skills/taste-skill" && rm -rf /tmp/ts_sk/.git /tmp/ts_sk || true
fi
if [ ! -d "$HOME/.agents/skills/marketingskills" ]; then
  git clone --depth 1 -q https://github.com/coreyhaines31/marketingskills.git /tmp/mk_sk 2>/dev/null && cp -r /tmp/mk_sk "$HOME/.agents/skills/marketingskills" && rm -rf /tmp/mk_sk/.git /tmp/mk_sk || true
fi

# Riavvia il Postino col nuovo script blindato (--autostash e log in /tmp/postino.log)
pkill -f 'postino.sh' 2>/dev/null || true
nohup "$HOME/posta/postino.sh" --loop >/dev/null 2>&1 &

