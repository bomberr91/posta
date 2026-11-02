#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
# Ripristina Node 22 compatibile WSL1 (Node 24 dà Exec format error su WSL1)
nvm alias default 22 >/dev/null 2>&1 || true
nvm use 22 >/dev/null 2>&1 || true
nvm uninstall 24 >/dev/null 2>&1 || true
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

echo "=== Eseguo estrazione commenti FB con Python 3 nativo ==="
python3 "$HOME/posta/leggi_fb_cdp.py" "https://www.facebook.[CHIAVE-RIMOSSA]" "$HOME/posta/dal_pc/fb_vibecod....md"
cat "$HOME/posta/dal_pc/fb_vibecod....md" | head -c 1500
