#!/usr/bin/env bash
# sanifica_repo_chiavi.sh — 4/11: SBLOCCA IL PONTE (push protection GitHub).
#
# Cosa e' successo: l'agente (goose, issue #31) ha stampato la configurazione
# di Deep Dog con le chiavi vere dentro la consegna. Il repo `posta` e' PUBBLICO
# e GitHub ha respinto la push: "GH013 - Push cannot contain secrets". Da quel
# momento OGNI push dal PC fallisce (anche quelli del postino): il ponte resta
# fermo e le consegne non arrivano piu'.
#
# Cosa fa questo script, in quest'ordine:
#  1. ferma il poller (cosi' nessuna consegna "sporca" viene committata
#     mentre puliamo)
#  2. reset "soft" dei commit locali: i commit con il segreto NON vengono
#     piu' pushati, i file restano nella working tree
#  3. maschera le chiavi in tutta la working tree (dal_pc, fatti, consegne, ...)
#  4. un commit pulito + push (la protezione passa)
#  5. riavvia il poller: cosi' carica il poller.py patchato, che maschera le
#     chiavi PRIMA di committare (non si blocca piu')
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }
export GIT_TERMINAL_PROMPT=0

echo "### 1. FERMARE IL POLLER (prima di pulire)"
cd "$REPO/lavori/ponte" 2>/dev/null && {
  if pgrep -f 'python3 poller[.]py' >/dev/null 2>&1; then
    pkill -f 'python3 poller[.]py'; sleep 3; echo "poller fermato"
  else
    echo "poller non era in giro"
  fi
  rm -f _stato/poller.lock
}
cd "$REPO" || exit 1

echo
echo "### 2. STATO"
git log --oneline -3 2>/dev/null
git fetch origin 2>&1 | tail -2
echo "commit locali avanti sul remote: $(git rev-list --count origin/main..HEAD 2>/dev/null)"

echo
echo "### 3. RESET SOFT (i commit col segreto non verranno pushati)"
git reset --soft origin/main 2>&1 | tail -2
echo "ora avanti sul remote: $(git rev-list --count origin/main..HEAD 2>/dev/null)"

echo
echo "### 4. MASCHERA CHIAVI NELLA WORKING TREE"
python3 - << 'PYEOF'
import os, re
RE = re.compile(
    r"sk-or-v1-[A-Za-z0-9]{16,}"
    r"|sk-[A-Za-z0-9]{24,}"
    r"|tvly-[A-Za-z0-9_-]{16,}"
    r"|ghp_[A-Za-z0-9]{20,}"
    r"|gho_[A-Za-z0-9]{20,}"
    r"|github_pat_[A-Za-z0-9_]{20,}"
    r"|cc3a11cf-[0-9a-fA-F-]{20,}"
    r"|exa_[A-Za-z0-9]{16,}"
    r"|oc_sk_[A-Za-z0-9_-]{16,}"
    r"|AIza[0-9A-Za-z_-]{20,}"
    r"|xox[baprs]-[A-Za-z0-9-]{10,}")
percorsi = []
for radice, dirs, files in os.walk("."):
    dirs[:] = [d for d in dirs if d not in (".git", "node_modules", "__pycache__")]
    for fn in files:
        p = os.path.join(radice, fn)
        try:
            if os.path.getsize(p) > 4 * 1024 * 1024:
                continue
            b = open(p, "rb").read()
            if b"\x00" in b[:2000]:
                continue
            t = b.decode("utf-8", errors="replace")
        except Exception:
            continue
        t2 = RE.sub("«chiave mascherata»", t)
        if t2 != t:
            try:
                open(p, "w", encoding="utf-8").write(t2)
                percorsi.append(p)
            except Exception:
                pass
print("file con chiavi mascherate:", len(percorsi))
for p in percorsi[:40]:
    print("   -", p)
PYEOF

echo
echo "### 5. COMMIT + PUSH"
git add -A >/dev/null 2>&1
git -c user.email=agente@localhost -c user.name=agente commit -q \
  -m "4/11: pulizia chiavi (push protection GitHub) + consegna issue #31" || echo "(nessuna modifica da committare)"
timeout 120 git push origin HEAD:main 2>&1 | tail -6

echo
echo "### 6. RIAVVIO DEL POLLER (carica il poller.py patchato: maschera le chiavi prima di committare)"
cd "$REPO/lavori/ponte" || exit 1
grep -c "maschera_chiavi" poller.py | sed 's/^/maschera_chiavi nel poller.py: /'
nohup python3 poller.py >> poller.log 2>&1 &
sleep 12
if pgrep -f 'python3 poller[.]py' >/dev/null 2>&1; then
  echo "poller riavviato (pid $(pgrep -f 'python3 poller[.]py' | head -1))"
else
  echo "ATTENZIONE: il poller non riparte"
  tail -20 poller.log
fi
echo "FINE"
exit 0
