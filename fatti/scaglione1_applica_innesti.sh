#!/usr/bin/env bash
set -u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
NODE22_BIN="$HOME/.nvm/versions/node/v22.22.2/bin"
export PATH="$NODE22_BIN:$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$PATH"
mkdir -p "$HOME/.local/bin"

echo "=== 1. Installazione Beads (bd — memoria a grafo per agenti) ==="
if ! command -v bd >/dev/null 2>&1; then
  BD_URL=$(curl -fsSL https://api.github.com/repos/gastownhall/beads/releases/latest | python3 -c "import sys,json; assets=json.load(sys.stdin).get('assets',[]); print(next((a['browser_download_url'] for a in assets if 'linux_amd64' in a['name'] and a['name'].endswith('.tar.gz')), ''))" 2>/dev/null)
  if [ -n "$BD_URL" ]; then
    curl -fsSL "$BD_URL" -o /tmp/bd.tar.gz && tar -xzf /tmp/bd.tar.gz -C /tmp && mv -f /tmp/bd "$HOME/.local/bin/bd" && chmod +x "$HOME/.local/bin/bd"
    rm -f /tmp/bd.tar.gz
  fi
fi
echo "BEADS: $(bd version 2>&1 | head -1 || bd --version 2>&1 | head -1 || echo non installato)"

echo "=== 2. Installazione Microsoft MarkItDown (lettore universale documenti per agenti) ==="
if ! command -v markitdown >/dev/null 2>&1; then
  if command -v uv >/dev/null 2>&1; then
    uv tool install markitdown --force 2>&1 | tail -5 || true
  else
    pip install --user -q markitdown 2>&1 | tail -5 || true
  fi
fi
echo "MARKITDOWN: $(command -v markitdown || echo non installato)"

echo "=== 3. Installazione Gemini CLI (@google/gemini-cli su Node 22) ==="
if [ -x "$NODE22_BIN/npm" ] && [ ! -x "$NODE22_BIN/gemini" ]; then
  "$NODE22_BIN/npm" install -g @google/gemini-cli --no-audit --no-fund 2>&1 | tail -5 || true
fi
echo "GEMINI CLI: $($NODE22_BIN/gemini --version 2>&1 | head -1 || echo non installato)"
echo "OPENCLAW: $($NODE22_BIN/openclaw --version 2>&1 | head -1 || openclaw --version 2>&1 | head -1 || echo non trovato)"
echo "HEADROOM: $(headroom --version 2>&1 | head -1 || echo non trovato)"
echo "XERJ: $(xerj --version 2>&1 | head -1 || echo non trovato)"
