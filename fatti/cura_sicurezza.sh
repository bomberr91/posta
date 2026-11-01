#!/bin/bash
cd ~/posta
echo "## 🚨 MESSA IN SICUREZZA POST-REVISORE — $(date '+%H:%M')"
echo "### 1. stato del repo sul PC"
git status --short | head -10
echo
echo "### 2. fotografo il diff dell'agente (materiale per il regista)"
git diff cervello.py > dal_pc/cura_diff_agente.patch
wc -l dal_pc/cura_diff_agente.patch
echo
echo "### 3. la versione dell'agente compila?"
python3 -m py_compile cervello.py && echo "✓ compila" || echo "✗ NON COMPILA (scampato pericolo)"
echo
echo "### 4. RIPRISTINO il file pulito dal repo (l'innesto lo fa il regista)"
git checkout -- cervello.py
python3 -m py_compile cervello.py && echo "✓ cervello.py = versione canonica, compila"
git status --short | head -5
git add dal_pc/cura_diff_agente.patch
git commit -q -m "cura: diff dell'agente fotografato, file ripristinato al canone"
git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
