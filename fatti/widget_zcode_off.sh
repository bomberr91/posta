#!/bin/bash
echo "## WIDGET ZCODE → PENSIONE — $(date '+%H:%M')"
S="/mnt/c/Users/giopi/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
A="/mnt/c/Users/giopi/Documents/AgentWorkspace/vecchi_bat"
mkdir -p "$A"
[ -f "$S/WIDGET_ZCODE.vbs" ] && mv "$S/WIDGET_ZCODE.vbs" "$A/" && echo "✓ WIDGET_ZCODE.vbs archiviato (non partirà più al boot)" || echo "già assente dallo startup"
ls "$S" | grep -i widget
