#!/bin/bash
cd ~/miniera
echo "## ⛏️ APERTURA DEI 2 DUBBI + ANATOMIA — $(date '+%H:%M')"
echo
echo "### 1. 'benign' — cosa fa davvero"
find . -path "*skills/benign*" -name "SKILL.md" | head -1 | xargs cat 2>/dev/null | head -35
echo
echo "### 2. 'learn-reverse-engineering' — cosa fa davvero"
find . -path "*learn-reverse-engineering*" -name "SKILL.md" | head -1 | xargs cat 2>/dev/null | head -35
echo
echo "### 3. Anatomia di una 🟢 (check-tests)"
D=$(find . -path "*skills/check-tests*" -name "SKILL.md" | head -1 | xargs dirname)
ls "$D" 2>/dev/null
head -12 "$D/SKILL.md" 2>/dev/null
echo
echo "### 4. Dove vivono le skills sul PC?"
for d in ~/.claude/skills ~/.agents/skills "/mnt/c/Users/giopi/Documents/AgentWorkspace/.claude/skills" "/mnt/c/Users/giopi/Documents/AgentWorkspace/.agents/skills" ~/.config/opencode/skills; do
  [ -d "$d" ] && echo "  ✓ ESISTE: $d ($(ls "$d" | wc -l) voci)" || echo "  — manca: $d"
done
echo "### 5. opencode e le skills"
export PATH="$HOME/.opencode/bin:$PATH"
opencode --help 2>&1 | grep -i skill | head -3 || echo "  'skill' non nell'help CLI"
ls ~/.config/opencode/ 2>/dev/null | head -8
