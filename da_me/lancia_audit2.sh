#!/bin/bash
cd ~/posta
chmod +x lavori/giudice_lusso.sh
nohup bash -c '
cd ~/posta
A=dal_pc/esito_audit_v2.md
{
echo "# 🔬 AUDIT v2 — bocconi da 15KB — $(date +%H:%M)"
split -b 15000 cervello.py /tmp/cerv_ 2>/dev/null
N=0
for F in /tmp/cerv_a?; do
  N=$((N+1)); [ $N -gt 4 ] && break
  echo; echo "## Boccone $N"
  bash lavori/giudice_lusso.sh "Senior security+reliability auditor. This is chunk $N of a local Python LLM router. ONLY real issues: bugs, races, security, edge cases. Format: [SEV] area: issue → one-line fix. Max 8 findings. Italian." "$F" 2>>/tmp/giudice_err.log
  sleep 12
done
echo; echo "## Errori di varco (se presenti)"
cat /tmp/giudice_err.log 2>/dev/null | tail -10
echo; echo "## Sintesi finale"
bash lavori/giudice_lusso.sh "Chief auditor. Merge these partial findings about one Python router into: TOP 5 ranked issues (one line each) + one-line verdict (SOLID/NEEDS FIXES/FRAGILE). Italian." "$A" 2>>/tmp/giudice_err.log
echo "FINE $(date +%H:%M)"
} > "$A" 2>&1
git pull -q --rebase 2>/dev/null; git add "$A"; git commit -q -m "audit v2 del cervello"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
' > /dev/null 2>&1 &
echo "audit v2 in sottofondo (pid $!)"
