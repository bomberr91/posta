#!/usr/bin/env bash
# 4/11 notte - ARENA: MISURA DI VITALITA' DELLA RISERVA (sola lettura, nessuna cancellazione)
# Obiettivo: capire quali provider della riserva rispondono davvero, per poi
# proporre al capo la lista di quelli da togliere. NON toglie niente.
# Uscita: dal_pc/sweep_riserva.md
set -u
REPO="$HOME/posta"
OUT="$REPO/dal_pc/sweep_riserva.md"
mkdir -p "$REPO/dal_pc"
cd "$REPO" || { echo "non trovo $REPO" > "$OUT"; exit 1; }

{
  echo "# MISURA DI VITALITA' DELLA RISERVA — $(date '+%d/%m/%Y %H:%M')"
  echo ""
  echo "Metodo: una richiesta minima per provider (max_tokens 5). Nessuna scrittura,"
  echo "nessuna cancellazione, nessuna chiave stampata."
  echo ""
} > "$OUT"

python3 - "$REPO" >> "$OUT" 2>&1 << 'PYEOF'
import json, os, subprocess, sys, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor

REPO = sys.argv[1]

def leggi(path):
    out = []
    for r in open(path, encoding="utf-8", errors="replace"):
        r = r.rstrip("\n")
        if not r.strip() or r.lstrip().startswith("#"):
            continue
        out.append(r)
    return out

# squadre (provider gia' usati: non li tocchiamo, li misuriamo solo come riferimento)
gruppi = set()
try:
    for riga in open(os.path.join(REPO, "portiere_gruppi.txt"), encoding="utf-8"):
        riga = riga.strip()
        if not riga or riga.startswith("#") or "=" not in riga:
            continue
        for m in riga.split("=", 1)[1].split(","):
            m = m.strip()
            if m:
                gruppi.add(m.split("/")[0])
except Exception:
    pass

def chiave(nome):
    if not nome or nome == "SENZA":
        return "free"
    try:
        p = subprocess.run(["python3", os.path.join(REPO, "chiave_di.py"), nome],
                           capture_output=True, text=True, timeout=8)
        return (p.stdout or "").strip()
    except Exception:
        return ""

def prova(riga):
    f = riga.split("|")
    if len(f) < 5 or not f[3].strip() or not f[3].strip().startswith("http"):
        return None
    pid, nome, indirizzo, modello = f[0].strip(), (f[2].strip() if len(f) > 2 else ""), f[3].strip(), f[4].strip()
    k = chiave(nome)
    if not k:
        return (pid, nome, "NO-CHIAVE", "-", "chiave assente dal portachiavi", False)
    if not modello:
        return (pid, nome, "NO-MODELLO", "-", "nessun modello di partenza", False)
    url = indirizzo.rstrip("/")
    if not url.endswith("/chat/completions"):
        url += "/chat/completions"
    payload = {"model": modello, "messages": [{"role": "user", "content": "Rispondi solo: OK"}], "max_tokens": 5}
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "Authorization": "Bearer " + k})
    try:
        with urllib.request.urlopen(req, timeout=12) as r:
            corpo = r.read().decode("utf-8", "replace")
            ok = '"choices"' in corpo
            return (pid, nome, str(r.status), "OK" if ok else "200-strano",
                    "risponde" if ok else "200 ma non e' una chat", ok)
    except urllib.error.HTTPError as e:
        corpo = e.read().decode("utf-8", "replace")[:120].replace("\n", " ")
        try:
            msg = json.loads(corpo).get("error", {})
            if isinstance(msg, dict):
                msg = msg.get("message") or msg.get("code") or ""
        except Exception:
            msg = ""
        return (pid, nome, str(e.code), "ERR", (str(msg)[:110] or corpo[:110]), False)
    except Exception as e:
        return (pid, nome, "TIMEOUT/RETE", "-", str(e)[:100], False)

righe = leggi(os.path.join(REPO, "portiere_lista.txt"))
lavorabili = [r for r in righe if len(r.split("|")) >= 5 and r.split("|")[3].strip().startswith("http")]
with ThreadPoolExecutor(max_workers=6) as ex:
    risultati = [x for x in ex.map(prova, lavorabili) if x]

verdi = [r for r in risultati if r[5]]
morti = [r for r in risultati if not r[5]]

print("provider misurati: %d | verdi: %d | non verdi: %d" % (len(risultati), len(verdi), len(morti)))
print("")
print("## VERDI (rispondono davvero)")
for pid, nome, code, stato, nota, _ in sorted(verdi, key=lambda x: x[0]):
    print("  %-18s %-6s %s" % (pid, code, nota[:70]))
print("")
print("## NON VERDI (candidati da togliere — proposta, NESSUNA cancellazione fatta)")
for pid, nome, code, stato, nota, _ in sorted(morti, key=lambda x: x[0]):
    print("  %-18s %-14s %s" % (pid, code, nota[:90]))
print("")
print("## in squadra (non propongo di toccarli)")
print("  " + (", ".join(sorted(gruppi)) or "(nessuna squadra)"))
PYEOF

echo "" >> "$OUT"
echo "--- sweep_riserva: scritto in dal_pc/sweep_riserva.md ---"
