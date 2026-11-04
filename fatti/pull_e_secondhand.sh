#!/usr/bin/env bash
# pull_e_secondhand.sh — un colpo solo: pull, Secondhand sul cervello, caccia a Hermes.
#
# 4/11 (decisione del capo): (1) Secondhand deve passare dal cervello locale
# invece di usare la chiave NVIDIA in proprio; (2) Hermes: scoprire quale
# chiave usa e, se è una del roster, passarlo al cervello come Secondhand.
#
# Tutto su file (niente pipe verso tail): se un comando si impianta, il resto
# del giro va avanti e il referto arriva comunque.
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

echo "### 0. PULL (il PC potrebbe essere indietro)"
git pull --rebase --autostash > /tmp/pe_pull.log 2>&1
echo "exit pull: $?"
tail -12 /tmp/pe_pull.log
echo "commit in testa: $(git log --oneline -1 2>/dev/null)"
echo

echo "### 1. SECONDHAND SUL CERVELLO"
if [ -f "$REPO/da_me/secondhand_alla_cervello.sh" ]; then
  timeout 420 bash "$REPO/da_me/secondhand_alla_cervello.sh" > /tmp/pe_sh.log 2>&1
  echo "exit script: $?"
  cat /tmp/pe_sh.log
else
  echo "manca da_me/secondhand_alla_cervello.sh"
fi
echo

echo "### 2. HERMES: DOVE STA LA CONFIG"
if [ -f "$REPO/da_me/hermes_config_hunt.sh" ]; then
  timeout 300 bash "$REPO/da_me/hermes_config_hunt.sh" > /tmp/pe_hh.log 2>&1
  echo "exit script: $?"
  cat /tmp/pe_hh.log
else
  echo "manca da_me/hermes_config_hunt.sh"
fi
echo

echo "### 3. IL POSTINO E' VIVO?"
pgrep -af postino.sh > /tmp/pe_postino.log 2>&1
echo "exit pgrep: $?"
head -5 /tmp/pe_postino.log
echo "--- ultimi commit del postino:"
git log --oneline -5 -- dal_pc/ | cat
echo "FINE"
