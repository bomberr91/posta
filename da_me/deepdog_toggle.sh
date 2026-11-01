#!/bin/bash
D="/mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog"
echo "## 🐕 TOGGLE + VERITÀ SUI REQUISITI — $(date '+%H:%M')"
echo "### 1. chiave deepseek-piattaforma nel portachiavi PC?"
grep -i "platform.deepseek\|deepseek.com" ~/CHIAVI_LOCALI.md | head -2 || echo "  nessuna traccia di chiave deepseek dedicata"
echo
echo "### 2. nomi esatti dei toggle (config.py)"
grep -n "WEB_SEARCH_ENGINE" "$D/deep_research/config.py" | head -4
grep -rn "DEEPSEEK_KEY\b" "$D" --include="*.py" | head -3
grep -n "def.*valid\|richieste\|required" "$D/web_app.py" | head -6
echo
echo "### 3. innesto toggle nel .env"
grep -q "^ROUTE_VIA_OPENROUTER" "$D/.env" || echo "ROUTE_VIA_OPENROUTER=true" >> "$D/.env"
grep -q "^WEB_SEARCH_ENGINE" "$D/.env" || echo "WEB_SEARCH_ENGINE=tavily" >> "$D/.env"
grep -E "^[A-Z_]+=." "$D/.env" | sed 's/=\(.\{6\}\).*/=\1•••/'
