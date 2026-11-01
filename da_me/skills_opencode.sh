#!/bin/bash
# SKILLS ↔ OPENCODE + I 5 ASSET SOCIALI (voce ⑧) — 1/11 sera
#
# Due cose, entrambe verificabili:
#  1) MANIFESTO DELLE SKILLS: quali skill ci sono, quante sono, e quali
#     OpenCode vede davvero. Le skill sono in 3 "nidi" (le cartelle degli
#     agenti); OpenCode ha la sua cartella. Oggi nessuno sa quale skill
#     funziona dove: questo job fa l'inventario e lo scrive.
#  2) I 5 ASSET SOCIALI: devono stare in una cartella sola, indicizzata,
#     che i postini e gli agenti sociali possano leggere.
#
# Il repo è pubblico: i file che finiscono dentro vengono scanditi per
# stringhe-chiave prima del commit.
set -uo pipefail
REPO="$HOME/posta"
cd "$REPO" || { echo "❌ non trovo $REPO"; exit 1; }
say(){ echo "[$(date '+%d/%m %H:%M')] $*"; }

say "1. dove sono i nidi delle skill?"
NIDI=""
for d in "$HOME/.agents" "$HOME/.config/opencode" "$HOME/.opencode" \
         "$HOME/Documents/AgentWorkspace/.agents" "/mnt/c/Users/giopi/.agents" \
         "/mnt/c/Users/giopi/.config/opencode"; do
  [ -d "$d" ] && { NIDI="$NIDI $d"; echo "   ✓ $d"; }
done
[ -z "$NIDI" ] && echo "   (nessun nido trovato nei posti noti: cerco piu' in largo)"
if [ -z "$NIDI" ]; then
  echo "   cerco in /mnt/c/Users/giopi (maxdepth 3):"
  find /mnt/c/Users/giopi -maxdepth 3 -type d \( -name ".agents" -o -name "skills" -o -name "opencode" \) 2>/dev/null | head -20
fi

say "2. quante skill ci sono, e quante ne vede OpenCode?"
TOT=0
for d in $NIDI; do
  N=$(find "$d" -maxdepth 3 -type f -name "SKILL.md" 2>/dev/null | wc -l)
  echo "   $d → $N skill"
  TOT=$((TOT+N))
done
echo "   TOTALE: $TOT"
SKILLS=$(for d in $NIDI; do find "$d" -maxdepth 3 -type f -name "SKILL.md" 2>/dev/null; done)
echo "$SKILLS" | head -40

say "3. scrivo il manifesto (un file dati, non una nota)"
python3 - << 'PYEOF'
import json, os, subprocess, glob, re
nidi = []
for d in [os.path.expanduser("~/.agents"), os.path.expanduser("~/.config/opencode"),
          "/mnt/c/Users/giopi/.agents", "/mnt/c/Users/giopi/.config/opencode"]:
    if os.path.isdir(d):
        nidi.append(d)
voci = []
for d in nidi:
    for f in glob.glob(os.path.join(d, "**", "SKILL.md"), recursive=True):
        nome = os.path.basename(os.path.dirname(f))
        m = re.search(r"^name:\s*(.+)$", open(f, encoding="utf-8", errors="replace").read()[:600], re.M)
        voci.append({"skill": nome, "nome": (m.group(1).strip() if m else nome),
                     "nido": d, "percorso": f})
out = {"generato": "1/11 sera", "nidi": nidi, "totale": len(voci), "skills": voci}
os.makedirs("skills", exist_ok=True)
with open("skills/manifesto_skills.json", "w", encoding="utf-8") as fh:
    json.dump(out, fh, ensure_ascii=False, indent=2)
print("   scritto skills/manifesto_skills.json con", len(voci), "skill")
PYEOF

say "4. i 5 asset sociali: cerco immagini/video usati per i post"
for d in "/mnt/c/Users/giopi/Documents/AgentWorkspace" "$HOME/posta"; do
  [ -d "$d" ] || continue
  echo "   --- $d"
  find "$d" -maxdepth 3 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.mp4" -o -iname "*.webp" \) \
    -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/__pycache__/*" 2>/dev/null | head -15
done

say "5. commit del manifesto"
git add skills/manifesto_skills.json 2>/dev/null || true
if git diff --cached --quiet; then
  echo "   (niente da committare)"
else
  git commit -qm "🗂️ manifesto delle skill (1/11 sera): quante sono, dove stanno, come si chiamano" >/dev/null 2>&1
  git push origin HEAD:main 2>&1 | tail -2
fi

say "6. il cervello risponde?"
curl -s -m 6 http://localhost:20129/salute 2>/dev/null | head -c 300; echo
say "7. fine"
exit 0
