#!/bin/bash
echo "## WIDGET ZCODE → PENSIONE — $(date '+%H:%M')"
S="[CHIAVE-RIMOSSA] Menu/Programs/Startup"
A="[CHIAVE-RIMOSSA]"
mkdir -p "$A"
[ -f "$S/WIDGET_ZCODE.vbs" ] && mv "$S/WIDGET_ZCODE.vbs" "$A/" && echo "✓ WIDGET_ZCODE.vbs archiviato (non partirà più al boot)" || echo "già assente dallo startup"
ls "$S" | grep -i widget
