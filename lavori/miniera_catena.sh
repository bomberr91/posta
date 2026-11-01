#!/bin/bash
cd ~/posta
export PATH="$HOME/.opencode/bin:$PATH"
# indice deduplicato + blocchi
python3 << 'PYEOF'
import os, re
righe = open("dal_pc/miniera_indice2.md", encoding="utf-8").read().splitlines()
viste, voci = set(), []
for r in righe:
    m = re.match(r"\|\s*\d+\s*\|\s*([^|]+)\|\s*([^|]+)\|", r)
    if m:
        n, d = m.group(1).strip(), m.group(2).strip().lstrip("> ")
        if n not in viste:
            viste.add(n)
            voci.append((n, d))
print("uniche:", len(voci))
B = 4  # blocchi
per = (len(voci) + B - 1) // B
for i in range(B):
    blocco = voci[i*per:(i+1)*per]
    with open("/tmp/miniera_blocco_%d.md" % (i+1), "w") as f:
        for n, d in blocco:
            f.write("| %s | %s |\n" % (n, d))
PYEOF
SPEC=$(cat missione/DOSSIER_MINIERA.md)
for N in 1 2 3 4; do
  [ -s /tmp/miniera_blocco_$N.md ] || continue
  while pgrep -f "opencode ru[n]" > /dev/null; do sleep 45; done
  echo "— operaio blocco $N — $(date +%H:%M)"
  timeout 900 opencode run -m cervello/auto "$SPEC

ECCO IL BLOCCO $N (| skill | descrizione |):
$(cat /tmp/miniera_blocco_$N.md)" > dal_pc/miniera_verdetti_$N.md 2>&1
  git pull -q --rebase 2>/dev/null; git add dal_pc/miniera_verdetti_$N.md
  git commit -q -m "miniera: verdetti blocco $N"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
done
# revisore finale
while pgrep -f "opencode ru[n]" > /dev/null; do sleep 45; done
timeout 900 opencode run -m cervello/auto "Sei il revisore severo. Dossier e verdetti dei 4 blocchi qui sotto. Controlla: verdetti incoerenti con la descrizione, scarti frettolosi, FLOTTA gonfiati. Elenca SOLO le correzioni (| skill | verdetto giusto | perche' |) e chiudi con PROMOSSO o BOCCIATO per blocco. Stile ASD-STE100.

$(cat missione/DOSSIER_MINIERA.md)
$(cat dal_pc/miniera_verdetti_1.md dal_pc/miniera_verdetti_2.md dal_pc/miniera_verdetti_3.md dal_pc/miniera_verdetti_4.md 2>/dev/null)" > dal_pc/miniera_revisione.md 2>&1
git pull -q --rebase 2>/dev/null; git add dal_pc/miniera_revisione.md
git commit -q -m "miniera: revisione finale"; git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
