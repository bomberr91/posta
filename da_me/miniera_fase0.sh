#!/bin/bash
echo "## ⛏️ MINIERA FASE 0 — ricognizione — $(date '+%H:%M')"
cd ~
[ -d ~/miniera ] && (cd ~/miniera && git pull -q) || git clone -q --depth 1 https://github.com/rohitg00/ai-engineering-from-scratch.git ~/miniera
cd ~/miniera
echo "### Struttura di primo livello"
ls -d */ 2>/dev/null | head -20
echo "### Dove vivono skills e prompt (cerco i pattern)"
find . -iname "SKILL.md" | head -3; find . -iname "SKILL.md" | wc -l
find . -ipath "*skill*" -name "*.md" | wc -l
find . -ipath "*prompt*" -name "*.md" | head -3; find . -ipath "*prompt*" -name "*.md" | wc -l
echo "### Conteggi grezzi"
echo "file .md totali: $(find . -name '*.md' | wc -l)"
echo "### Indice automatico (nome + prima descrizione di ogni skill)"
python3 << 'PYEOF' > ~/posta/dal_pc/miniera_indice.md
import os, re
print("# Indice automatico della miniera —", end=" ")
import time; print(time.strftime("%d/%m %H:%M"))
voci = []
for radice, dirs, files in os.walk("."):
    if ".git" in radice: continue
    for f in files:
        if f.lower() in ("skill.md",) or (f.endswith(".md") and ("skill" in radice.lower() or "prompt" in radice.lower())):
            p = os.path.join(radice, f)
            try:
                testo = open(p, encoding="utf-8", errors="replace").read(1200)
                nome = re.search(r"^#\s+(.+)$|^name:\s*(.+)$", testo, re.M)
                nome = (nome.group(1) or nome.group(2)).strip() if nome else os.path.basename(radice)
                desc = re.search(r"^description:\s*(.+)$", testo, re.M)
                if not desc:
                    righe = [r.strip() for r in testo.splitlines() if r.strip() and not r.startswith("#") and not r.startswith("---") and ":" not in r[:12]]
                    desc_t = (righe[0] if righe else "")[:160]
                else:
                    desc_t = desc.group(1).strip()[:160]
                voci.append((p, nome[:60], desc_t))
            except Exception: pass
print("TOTALE PEZZI INDICIZZATI:", len(voci))
print()
for p, n, d in voci:
    print("| %s | %s | %s |" % (p, n, d))
PYEOF
wc -l ~/posta/dal_pc/miniera_indice.md
cd ~/posta && git pull -q --rebase 2>/dev/null; git add dal_pc/miniera_indice.md; git commit -q -m "miniera: indice automatico fase 0"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
