#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
O=dal_pc/diagnosi_cervello.md
{
echo "# DIAGNOSI CERVELLO $(date)"
echo "## 1. Portiere :20129 vivo?"
curl -s -m 5 http://127.0.0.1:20129/v1/models | head -c 400; echo
echo "## 2. OmniRoute :20128 vivo?"
curl -s -m 5 -H "Authorization: Bearer sk-be311327ce941004-4df42c-cf76ba39" http://127.0.0.1:20128/v1/models | head -c 300
[ -z "$(curl -s -m 5 http://127.0.0.1:20128/v1/models 2>/dev/null)" ] && echo "(nessuna risposta dalla 20128 = OMNIROUTE SPENTO)"
echo
echo "## 3. prova PICCOLA via Portiere (auto)"
curl -s -m 60 http://127.0.0.1:20129/v1/chat/completions -H "Content-Type: application/json" \
 -d '{"model":"auto","messages":[{"role":"user","content":"rispondi solo: OK"}],"max_tokens":10}' | head -c 500; echo
echo "## 4. processi"
pgrep -af "omni|cervello|opencode" 2>/dev/null | head -10
} > "$O" 2>&1
git add dal_pc; git commit -m "diagnosi cervello" >/dev/null 2>&1
git pull --rebase >/dev/null 2>&1; git push >/dev/null 2>&1
echo "diagnosi scritta e pushata"
