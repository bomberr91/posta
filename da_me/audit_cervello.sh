#!/bin/bash
cd ~/posta
chmod +x lavori/giudice_lusso.sh
nohup bash -c '
cd ~/posta
A=dal_pc/audit_cervello.md
{
echo "# 🔬 AUDIT DEL CERVELLO by giudice di lusso — $(date +%H:%M)"
head -c 55000 cervello.py > /tmp/cervello_p1.py
tail -c +55001 cervello.py | head -c 55000 > /tmp/cervello_p2.py
echo; echo "## Parte 1 (righe iniziali)"
bash lavori/giudice_lusso.sh "You are a senior security+reliability auditor. Review this Python code (part 1 of 2 of a local LLM router called Portiere). List ONLY real issues: bugs, race conditions, security risks, edge cases. For each: [SEVERITY] file-area: issue + one-line fix. Max 15 findings, no style nitpicks. Answer in Italian." /tmp/cervello_p1.py
sleep 10
echo; echo "## Parte 2 (righe finali)"
bash lavori/giudice_lusso.sh "Same auditor, part 2 of 2 of the same Python router. Same rules: only real issues, [SEVERITY] + one-line fix, max 15, Italian." /tmp/cervello_p2.py
sleep 10
echo; echo "## Sintesi del giudice"
bash lavori/giudice_lusso.sh "You are the chief auditor. Here are findings from two partial reviews of one Python router. Write in Italian: the TOP 5 issues worth fixing (ranked), one line each, then a one-line overall verdict (SOLID / NEEDS FIXES / FRAGILE)." dal_pc/audit_cervello.md
echo; echo "FINE AUDIT $(date +%H:%M)"
} > "$A" 2>&1
git pull -q --rebase 2>/dev/null; git add "$A" lavori/giudice_lusso.sh
git commit -q -m "audit cervello by giudice di lusso (AgentRouter)"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
' > /dev/null 2>&1 &
echo "🔬 audit avviato in sottofondo (pid $!) — 2 parti + sintesi, pause gentili"
