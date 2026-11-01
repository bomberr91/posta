#!/bin/bash
# Audit del cervello: operai locali sui bocconi + giudice di lusso sulla sintesi EN
cd ~/posta
export PATH="$HOME/.opencode/bin:$PATH"
A=dal_pc/esito_audit_v4.md
echo "# 🔬 AUDIT v4 — $(date +%H:%M)" > "$A"
split -b 15000 cervello.py /tmp/cv4_
N=0
for F in /tmp/cv4_a?; do
  N=$((N+1)); [ $N -gt 4 ] && break
  while pgrep -f "opencode ru[n]" > /dev/null; do sleep 30; done
  echo "" >> "$A"; echo "## Boccone $N" >> "$A"
  timeout 600 opencode run -m cervello/auto "Sei un auditor severo di sicurezza e affidabilita. Pezzo $N di 4 di un router LLM Python locale. SOLO problemi veri: bug, race, sicurezza, casi limite. Formato: [GRAVITA] area: problema -> fix in una riga. Max 8. Stile ASD-STE100.

$(cat $F)" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -v "^> build" >> "$A"
done
echo "" >> "$A"; echo "## Distillato EN" >> "$A"
while pgrep -f "opencode ru[n]" > /dev/null; do sleep 30; done
timeout 600 opencode run -m cervello/auto "Translate these audit findings to concise English. Keep [SEVERITY] tags. Max 30 lines.

$(cat $A)" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -v "^> build" > /tmp/dist_en.txt
cat /tmp/dist_en.txt >> "$A"
echo "" >> "$A"; echo "## Verdetto giudice di lusso" >> "$A"
bash lavori/giudice_lusso.sh "Chief auditor. These are audit findings (English) for one local Python LLM router. Output in ENGLISH: TOP 5 ranked issues, one line each, then one-line verdict: SOLID / NEEDS FIXES / FRAGILE." /tmp/dist_en.txt >> "$A" 2>/tmp/g4_err.log
tail -3 /tmp/g4_err.log >> "$A" 2>/dev/null
echo "FINE $(date +%H:%M)" >> "$A"
git pull -q --rebase 2>/dev/null; git add "$A"; git commit -q -m "audit v4 completo"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
