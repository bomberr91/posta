#!/bin/bash
echo "## 🔬 STATO AUDIT V3 — $(date '+%H:%M')"
echo "### processi vivi della catena"
ps aux | grep -E "cv_a|opencode ru[n]|lancia_audit" | grep -v grep | head -5 || echo "  nessuno: catena FERMA"
echo
echo "### il file LOCALE (non committato) — dimensione e coda"
L=~/posta/dal_pc/esito_audit_v3.md
wc -c "$L" 2>/dev/null
tail -15 "$L" 2>/dev/null
echo
echo "### errori del giudice"
tail -5 /tmp/g_err.log 2>/dev/null || echo "  niente log errori"
echo "### bocconi creati?"
ls -la /tmp/cv_a? 2>/dev/null | head -5
