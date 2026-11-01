#!/bin/bash
cd ~/miniera
echo "## ⛏️ INDICE v2 — $(date '+%H:%M')"
echo "### Skills VERE (solo SKILL.md)"
find . -name "SKILL.md" | wc -l
echo "### Dove sono i prompt? (cartelle candidate)"
for d in prompts outputs cheatsheets practice phases; do
  echo "  $d: $(find ./$d -name '*.md' 2>/dev/null | wc -l) md"
done
grep -rl "^# Prompt\|type: prompt" --include="*.md" . 2>/dev/null | head -5
python3 << 'PYEOF' > ~/posta/dal_pc/miniera_indice2.md
import os, re, time
print("# Indice v2 —", time.strftime("%d/%m %H:%M"))
skills = []
for radice, dirs, files in os.walk("."):
    if ".git" in radice: continue
    if "SKILL.md" in files:
        p = os.path.join(radice, "SKILL.md")
        t = open(p, encoding="utf-8", errors="replace").read(2000)
        fm = re.search(r"^---\s*\n(.*?)\n---", t, re.S)
        nome = os.path.basename(radice)
        desc = ""
        if fm:
            m = re.search(r"^description:\s*(.+?)(?=\n\w+:|\Z)", fm.group(1), re.S | re.M)
            if m: desc = " ".join(m.group(1).split())[:200]
        if not desc:
            m = re.search(r"^>\s*(.+)$", t, re.M)
            desc = (m.group(1).strip()[:200] if m else "")
        if not desc:
            righe = [r.strip() for r in t.splitlines() if r.strip() and not r.startswith(("#","---","name:","|"))]
            desc = (righe[0] if righe else "?")[:200]
        skills.append((nome, desc))
print("SKILLS VERE:", len(skills))
print()
print("| # | skill | descrizione |")
print("|---|---|---|")
for i, (n, d) in enumerate(sorted(skills), 1):
    print("| %d | %s | %s |" % (i, n, d))
PYEOF
tail -3 ~/posta/dal_pc/miniera_indice2.md | head -1
cd ~/posta && git pull -q --rebase 2>/dev/null; git add dal_pc/miniera_indice2.md; git commit -q -m "miniera indice v2"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
