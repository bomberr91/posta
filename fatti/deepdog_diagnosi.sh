#!/bin/bash
D="[CHIAVE-RIMOSSA]"
echo "## 🐕 DIAGNOSI CONFIG — $(date '+%H:%M')"
echo "### 1. .env reale (nomi attivi, valori mascherati)"
grep -E "^[A-Z_]+=." "$D/.env" | sed 's/=\(.\{6\}\).*/=\1•••/' 
echo
echo "### 2. Cosa controlla l'app per dire 'configurato'?"
grep -rn -i "OPENROUTER_API_KEY\|DEEPSEEK_API_KEY\|MODEL_PROVIDER\|configur" "$D/web_app.py" 2>/dev/null | head -12
echo
grep -rn -i "OPENROUTER\|provider" "$D/deep_research/config.py" 2>/dev/null | head -15
echo
echo "### 3. Il .env viene letto da dove? (load_dotenv e percorso)"
grep -rn "load_dotenv\|dotenv" "$D/web_app.py" "$D/deep_research/config.py" 2>/dev/null | head -6
