#!/usr/bin/env bash
# avvio_centrale.sh — il lancio della Centrale: sync NON bloccante + menu
# (13/11: il fetch origin nudo si appendeva al prompt di credenziali e la Centrale non apriva mai)
set -u
export GIT_TERMINAL_PROMPT=0
cd ~/posta || exit 1
TOKEN=$(grep -oE '(github_pat_[A-Za-z0-9_]+|ghp_[A-Za-z0-9]+)' ~/CHIAVI_LOCALI.md | head -1)
if [ -n "${TOKEN:-}" ]; then
  if timeout 25 git fetch "https://x-access-token:${TOKEN}@github.com/bomberr91/posta.git" main >/dev/null 2>&1; then
    git reset --hard FETCH_HEAD >/dev/null 2>&1 && echo "Ponte sincronizzato."
  else
    echo "Sync remoto non riuscito (parto con la copia locale)."
  fi
else
  echo "Token non trovato: parto con la copia locale."
fi
chmod +x centrale.sh aggiorna_tutto.sh squadra.sh postino.sh leggi_video.py verifica.sh openclaw_fix.sh apri_openclaw.sh 2>/dev/null
exec bash ~/posta/centrale.sh
