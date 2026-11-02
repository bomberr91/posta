#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
node "$HOME/posta/leggi_fb_cdp.mjs" "https://www.facebook.[CHIAVE-RIMOSSA]" "$HOME/posta/dal_pc/fb_vibecod....md"
