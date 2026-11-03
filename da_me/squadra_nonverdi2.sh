#!/usr/bin/env bash
# squadra_nonverdi2.sh — i DUE agenti che nella squadra precedente sono morti
# ("locking protocol": opencode in parallelo si scontra sul lock).
# Qui girano uno dietro l'altro. La misura meccanica e' gia' in
# fatti/prova_nonverdi.txt e i prompt sono in fatti/prompt_*.txt.
set -u
cd "$HOME/posta" || exit 1
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
if [ -s "$HOME/CHIAVI_LOCALI.md" ]; then
  OC_KEY=$(grep -oE 'oc_sk_[A-Za-z0-9_-]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
  [ -n "$OC_KEY" ] && export OPENCODE_API_KEY="$OC_KEY"
fi

for n in anyapi gizmo; do
  echo "=== AGENTE $n (in sequenza) ==="
  if [ -f "fatti/rel_$n.md" ]; then
    echo "(il referto c'e' gia')"
  else
    P=$(cat "fatti/prompt_$n.txt")
    timeout 1100 opencode run "$P" > "fatti/out_${n}2.txt" 2>&1 \
      || timeout 1100 opencode run -m opencode/big-pickle "$P" > "fatti/out_${n}2.txt" 2>&1 \
      || echo "(agente $n non riuscito)" >> "fatti/out_${n}2.txt"
  fi
  if [ -f "fatti/rel_$n.md" ]; then
    sed -n '1,160p' "fatti/rel_$n.md"
  else
    echo "(nessun rel_$n.md — ultime righe)"
    tail -20 "fatti/out_${n}2.txt" 2>/dev/null
  fi
  echo
done
echo "=== FINE ==="
