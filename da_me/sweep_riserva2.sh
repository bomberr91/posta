#!/usr/bin/env bash
# 4/11 notte - ARENA: SECONDA MISURA DELLA RISERVA (il primo sweep era falsato)
# Perche' la seconda: nel primo sweep NON mandavo User-Agent -> 12 provider
# hanno risposto 403 "error code 1010" (= Cloudflare che blocca la firma del
# client), non "morti". Il cervello invece manda gia' un UA da browser.
# Migliorie rispetto al primo sweep:
#   - User-Agent da browser (come cervello.py/leggi_video.py)
#   - max_tokens 20 (AI Horde rifiuta < 16: era un falso negativo)
#   - se il modello di partenza non esiste, si riprova con il primo modello
#     della lista "extra" del roster -> distingue "provider morto" da
#     "modello sbagliato nel roster"
#   - i provider non-chat (modo=modelli / tipo!=chat) non vengono testati come chat
# Sola lettura: nessuna scrittura, nessuna cancellazione, nessuna chiave stampata.
# Esce: dal_pc/sweep_riserva2.md
set -u
REPO="$HOME/posta"
OUT="$REPO/dal_pc/sweep_riserva2.md"
mkdir -p "$REPO/dal_pc"
cd "$REPO" || { echo "non trovo $REPO" > "$OUT"; exit 1; }

{
  echo "# MISURA DI VITALITA' DELLA RISERVA - SECONDA PASSATA - $(date '+%d/%m/%Y %H:%M')"
  echo ""
  echo "User-Agent da browser, max_tokens 20, riprova sul primo modello della lista."
  echo "Nessuna scrittura, nessuna cancellazione."
  echo ""
} > "$OUT"

python3 - "$REPO" >> "$OUT" 2>&1 << 'PYEOF'
import json, os, subprocess, sys, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor

REPO = sys.argv[1]
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

def leggi(path):
    out = []
    for r in open(path, encoding="utf-8", errors="replace"):
        r = r.rstrip("\n")
        if not r.strip() or r.lstrip().startswith("#"):
            continue
        out.append(r)
    return out

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

def chat(url, modello, k):
    payload = {"model": modello, "messages": [{"role": "user", "content": "Say only: OK"}],
               "max_tokens": 20}
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json",
                                          "Accept": "application/json",
                                          "User-Agent": UA,
                                          "Authorization": "Bearer " + k})
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            corpo = r.read().decode("utf-8", "replace")
            ok = '"choices"' in corpo
            return (str(r.status), "OK" if ok else "200-non-chat", "risponde" if ok else "200 ma non e' una chat", False)
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", "replace")
        msg = raw[:160].replace("\n", " ")
        try:
            j = json.loads(raw).get("error", {})
            if isinstance(j, dict):
                msg = str(j.get("message") or j.get("code") or j)[:160]
            elif j:
                msg = str(j)[:160]
        except Exception:
            pass
        return (str(e.code), "ERR", msg, False)
    except Exception as e:
        return ("TIMEOUT/RETE", "-", str(e)[:120], False)

def prova(riga):
    f = riga.split("|")
    if len(f) < 5 or not f[3].strip() or not f[3].strip().startswith("http"):
        return None
    pid = f[0].strip()
    nome = f[2].strip() if len(f) > 2 else ""
    indirizzo = f[3].strip()
    modello = f[4].strip()
    modo = f[5].strip() if len(f) > 5 else "chat"
    tipo = f[6].strip() if len(f) > 6 else ""
    extra = f[8].strip() if len(f) > 8 else ""
    if modo == "modelli" or (tipo and tipo != "chat"):
        return (pid, nome, "NON-CHAT", "-", "tipo=%s modo=%s (non e' una chat: non la provo)" % (tipo or "chat", modo), False, "")
    k = chiave(nome)
    if not k:
        return (pid, nome, "NO-CHIAVE", "-", "chiave assente dal portachiavi", False, "")
    url = indirizzo.rstrip("/")
    if not url.endswith("/chat/completions"):
        url += "/chat/completions"
    modelli = [modello] if modello else []
    for m in extra.split(";"):
        m = m.strip()
        if m and m not in modelli:
            modelli.append(m)
    primo = None
    for m in modelli[:3]:
        code, stato, nota, ok = chat(url, m, k)
        if ok:
            return (pid, nome, code, stato, "risponde col modello %s" % m, True, m)
        if primo is None:
            primo = (code, stato, nota, m)
        if code in ("404", "400") and "model" in nota.lower():
            continue   # modello sbagliato: prova il prossimo
        break
    code, stato, nota, m = primo
    return (pid, nome, code, stato, nota, False, m)

righe = leggi(os.path.join(REPO, "portiere_lista.txt"))
lavorabili = [r for r in righe if len(r.split("|")) >= 5 and r.split("|")[3].strip().startswith("http")]
with ThreadPoolExecutor(max_workers=6) as ex:
    risultati = [x for x in ex.map(prova, lavorabili) if x]

verdi = [r for r in risultati if r[4]]
nonverdi = [r for r in risultati if not r[4]]
print("provider misurati: %d | VERDI: %d | non verdi: %d | non-chat scartati: %d"
      % (len(risultati), len(verdi), len(nonverdi), len([r for r in risultati if r[2] == "NON-CHAT"])))
print("")
print("## VERDI (rispondono davvero)")
for pid, nome, code, stato, nota, ok, mod in sorted(verdi, key=lambda x: x[0]):
    print("  %-18s %-6s %s" % (pid, code, nota[:72]))
print("")
print("## NON VERDI (ora con User-Agent: questi sono i veri problemi)")
for pid, nome, code, stato, nota, ok, mod in sorted(nonverdi, key=lambda x: x[0]):
    extra = (" [modello provato: %s]" % mod) if mod else ""
    print("  %-18s %-14s %s%s" % (pid, code, nota[:88], extra))
print("")
print("## in squadra (non propongo di toccarli)")
print("  " + (", ".join(sorted(gruppi)) or "(nessuna squadra)"))
PYEOF

echo "" >> "$OUT"
echo "--- sweep_riserva2: scritto in dal_pc/sweep_riserva2.md ---"
