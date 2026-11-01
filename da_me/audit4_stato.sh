#!/bin/bash
echo "## 🔬 FORNO V4 — $(date '+%H:%M')"
echo "### processi della catena vivi?"
ps aux | grep -E "audit_caten[a]|opencode" | grep -v grep | awk '{print " ", $2, substr($0, index($0,$11), 70)}' | head -4 || echo "  catena FERMA"
echo "### file LOCALE (dimensione + coda)"
wc -c ~/posta/dal_pc/esito_audit_v4.md
tail -8 ~/posta/dal_pc/esito_audit_v4.md
