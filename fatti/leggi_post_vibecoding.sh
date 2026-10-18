#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
node "$HOME/posta/leggi_fb_cdp.mjs" "https://www.facebook.com/groups/vibecodinglife/permalink/2167430827178776" "$HOME/posta/dal_pc/fb_vibecoding_145_commenti.md"
