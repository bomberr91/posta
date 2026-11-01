#!/bin/bash
cd ~/posta
nohup bash -c '
cd ~/posta
export PATH="$HOME/.opencode/bin:$PATH"
A=dal_pc/esito_audit_v3.md
{
echo "# 🔬 AUDIT v3 — operai locali + sintesi frontier — $(date +%H:%M)"
split -b 15000 cervello.py /tmp/cv_
N=0
for F in /tmp/cv_a?; do
  N=$((N+1)); [ $N -gt 4 ] && break
  while pgrep -f "opencode ru[n]" > /dev/null; do sleep 30; done
  echo; echo "## Boccone $N (operaio locale)"
  timeout 600 opencode run -m cervello/auto "Sei un auditor severo di sicurezza e affidabilita. Questo e il pezzo $N di 4 di un router LLM Python locale. SOLO problemi veri: bug, race, sicurezza, casi limite. Formato: [GRAVITA] area: problema -> fix in una riga. Max 8. Stile ASD-STE100.

$(cat $F)" 2>&1 | sed "s/\x1b\[[0-9;]*m//g" | grep -v "^> build"
done
echo; echo "## Distillato per il giudice (EN)"
while pgrep -f "opencode ru[n]" > /dev/null; do sleep 30; done
timeout 600 opencode run -m cervello/auto "Translate the following audit findings to concise English, keep [SEVERITY] tags, max 30 lines total:

$(cat $A)" 2>&1 | sed "s/\x1b\[[0-9;]*m//g" | grep -v "^> build" > /tmp/distillato_en.txt
cat /tmp/distillato_en.txt
echo; echo "## Verdetto del giudice di lusso"
bash lavori/giudice_lusso.sh "Chief auditor. These are audit findings (already in English) for one local Python LLM router. Output in ENGLISH: TOP 5 ranked issues, one line each, then one-line verdict: SOLID / NEEDS FIXES / FRAGILE." /tmp/distillato_en.txt 2>>/tmp/g_err.log
tail -3 /tmp/g_err.log 2>/dev/null
echo "FINE $(date +%H:%M)"
} > "$A" 2>&1
git pull -q --rebase 2>/dev/null; git add "$A" lavori/giudice_lusso.sh; git commit -q -m "audit v3: operai+frontier"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
' > /dev/null 2>&1 &
echo "audit v3 in sottofondo (pid $!) — operai sui bocconi, giudice sul distillato"
