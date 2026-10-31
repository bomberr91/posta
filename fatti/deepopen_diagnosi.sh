#!/bin/bash
echo "## DIAGNOSI DEEPOPEN — $(date '+%H:%M')"
echo "### Disco WSL"
df -h ~ | tail -1
echo "### RAM"
free -h | head -2
echo "### Peso della cache HuggingFace"
du -sh ~/.cache/huggingface 2>/dev/null || echo "cache assente"
du -sh ~/deepopen_venv 2>/dev/null
echo "### Gli ultimi morti nel registro di sistema (OOM killer?)"
dmesg 2>/dev/null | grep -i -E "killed process|out of memory" | tail -3 || echo "dmesg non leggibile"
