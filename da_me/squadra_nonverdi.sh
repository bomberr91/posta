#!/usr/bin/env bash
# squadra_nonverdi.sh — squadra per AnyAPI, Typhoon e Gizmo: spiega gli errori
# e trova la strada che funziona. Prima la misura meccanica (deterministica),
# poi tre agenti in parallelo che leggono la misura e scrivono il referto.
set -u
cd "$HOME/posta" || exit 1
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
if [ -s "$HOME/CHIAVI_LOCALI.md" ]; then
  OC_KEY=$(grep -oE 'oc_sk_[A-Za-z0-9_-]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
  [ -n "$OC_KEY" ] && export OPENCODE_API_KEY="$OC_KEY"
fi
mkdir -p fatti dal_pc

# ── 1) MISURA: per ogni provider, quanti modelli gratuiti e una chat vera ────
echo "=== MISURA (chat vera su piu' modelli) ==="
python3 - > fatti/prova_nonverdi.txt 2>&1 << 'PY'
import json, re, subprocess, urllib.request, urllib.error

TARGET = ["anyapi", "gizmo", "typhoon"]
righe = {}
for l in open("portiere_lista.txt", encoding="utf-8"):
    l = l.strip()
    if not l or l.startswith("#"):
        continue
    p = (l + "||||||||||").split("|")
    if re.match(r"^[a-z0-9_-]+$", p[0]):
        righe[p[0]] = p

def chiave(etichetta):
    out = subprocess.run(["python3", "chiave_di.py", etichetta],
                         capture_output=True, text=True).stdout.strip().splitlines()
    return out[0].strip() if out else ""

def get(url, key):
    h = {"User-Agent": "Mozilla/5.0", "Accept": "application/json"}
    if key:
        h["Authorization"] = "Bearer " + key
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=40) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return 0, "ERR %s" % e

def chat(base, modello, key):
    h = {"User-Agent": "Mozilla/5.0", "Accept": "application/json",
         "Content-Type": "application/json"}
    if key:
        h["Authorization"] = "Bearer " + key
    body = json.dumps({"model": modello,
                       "messages": [{"role": "user", "content": "Say OK"}],
                       "max_tokens": 128}).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(
                base.rstrip("/") + "/chat/completions", data=body, headers=h), timeout=45) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return 0, "ERR %s" % e

for pid in TARGET:
    r = righe.get(pid)
    if not r:
        print("== %s: non e' nel roster ==" % pid); continue
    etichetta, base, modello, extra = r[2], r[3], r[4], r[8]
    key = chiave(etichetta)
    print("=" * 78)
    print("== %s (%s) base=%s modello-nostro=%s chiave=%s" %
          (pid, etichetta, base, modello, "SI" if key else "NO"))
    s, b = get(base.rstrip("/") + "/models", key)
    print("-- /models -> %s" % s)
    ids = []
    if s == 200:
        try:
            dati = json.loads(b)
            lista = dati.get("data") if isinstance(dati, dict) else dati
            for m in (lista or []):
                i = m.get("id") if isinstance(m, dict) else m
                if isinstance(i, str):
                    ids.append(i)
        except Exception as e:
            print("   (catalogo non leggibile: %s)" % e)
    free = [i for i in ids if re.search(r"(?i)free", i)]
    print("-- modelli totali: %d · con 'free': %d" % (len(ids), len(free)))
    candidati = []
    for c in ([modello] + extra.split(";") + free[:8] + ids[:4]):
        c = (c or "").strip()
        if c and c not in candidati and not re.search(r"(?i)embed|whisper|tts|image|vision|audio|rerank|moderation", c):
            candidati.append(c)
    candidati = candidati[:10]
    print("-- candidati provati: %s" % ", ".join(candidati))
    for m in candidati:
        code, body = chat(base, m, key)
        if code == 200:
            try:
                txt = (json.loads(body).get("choices") or [{}])[0].get("message", {}).get("content")
            except Exception:
                txt = None
            print("   >>> %-46s HTTP 200  %r" % (m, (txt or "")[:80]))
        else:
            print("   %-46s HTTP %s  %s" % (m, code, body[:120].replace("\n", " ")))
    print()
PY
cat fatti/prova_nonverdi.txt
echo

# ── 2) TRE AGENTI IN PARALLELO: spiegano l'errore e scrivono la soluzione ───
cat > fatti/prompt_anyapi.txt << 'EOF'
Sei l'agente "AnyAPI". Devi spiegare l'errore di AnyAPI e trovare come si usa.
LEGGI PRIMA: ~/posta/fatti/prova_nonverdi.txt (la sezione "== anyapi"). Ci sono i
modelli gratuiti e l'esito di una chat vera per ciascuno.
FATTI: base https://api.anyapi.ai/v1 ; la riga del roster è
anyapi|AnyAPI|AnyAPI|https://api.anyapi.ai/v1|nvidia/nemotron-3.5-lightning:free|modelli||free-ricorrente|
Il 3/11 la chat dava 429 "Rate limit reached: free-tier daily cap is shared
across users" (il tetto giornaliero del free è condiviso fra tutti gli utenti).
IL TUO COMPITO:
1. Spiega l'errore: cosa significa "free-tier daily cap is shared across users",
   quando si azzera, se conviene riprovare più tardi, e che modelli gratuiti
   esistono davvero (id esatti presi da /models e dal catalogo
   ~/posta/lavori/catalogo_freellmapi.json).
2. Prova tu stesso (bash + python3 urllib, NON stampare la chiave: si prende con
   "python3 ~/posta/chiave_di.py AnyAPI") altri modelli gratuiti finche' non ne
   trovi uno che risponde 200 con un contenuto vero.
3. Verifica se esiste un modo per NON incappare nel tetto condiviso (header,
   endpoint diversi, modelli con quota propria, piano free separato).
4. SCRIVI il referto in ~/posta/fatti/rel_anyapi.md (cartella del repo: puoi
   scrivere solo li', non in /tmp): l'errore spiegato, gli id gratuiti che
   rispondono, il modello da mettere nel roster, e cosa fare quando il tetto
   si esaurisce. Massimo 600 parole. Non stampare chiavi.
EOF

cat > fatti/prompt_gizmo.txt << 'EOF'
Sei l'agente "Gizmo". Devi spiegare l'errore di Gizmo e trovare come si usa.
LEGGI PRIMA: ~/posta/fatti/prova_nonverdi.txt (la sezione "== gizmo"). Ci sono i
modelli gratuiti e l'esito di una chat vera per ciascuno.
FATTI: base https://api.gizmoplatforms.com/api/v1 ; la riga del roster è
gizmo|Gizmo|Gizmo|https://api.gizmoplatforms.com/api/v1|nvidia/nemotron-3.5-lightning:free|chat||free-ricorrente|
Il 3/11 la chat dava 429 "Every provider for nvidia/nemotron-3.5-lightning:free
failed: openrouter 429 (Nothing was charged; try again shortly)" e /models
rispondeva 200. I modelli gratuiti su Gizmo finiscono con ":free".
IL TUO COMPITO:
1. Spiega l'errore: Gizmo e' un router che a sua volta chiama altri provider
   (openrouter, groq...): quale catena e' scesa e perche'. Cosa significa che
   "non e' stato addebitato niente" e in che momento conviene riprovare.
2. Trova i modelli gratuiti di Gizmo che rispondono davvero con un contenuto:
   prova con bash + python3 urllib (chiave con "python3 ~/posta/chiave_di.py
   Gizmo", non stamparla), sia con id ":free" sia con id di altri provider che
   Gizmo ruota (tipo "groq/...", "openrouter/...", "mistral/...").
3. Verifica se conviene un altro endpoint (es. /api/v1/chat/completions vs
   altre strade) o un altro UA.
4. SCRIVI il referto in ~/posta/fatti/rel_gizmo.md (cartella del repo: puoi
   scrivere solo li', non in /tmp): l'errore spiegato, gli id che funzionano, il
   modello da mettere nel roster e quando riprovare. Massimo 600 parole. Non
   stampare chiavi.
EOF

cat > fatti/prompt_typhoon.txt << 'EOF'
Sei l'agente "Typhoon". Devi spiegare perché Typhoon era segnato "strano" e
confermare che è usabile.
LEGGI PRIMA: ~/posta/fatti/prova_nonverdi.txt (la sezione "== typhoon").
FATTI: base https://api.opentyphoon.ai/v1 ; la riga del roster è
typhoon|Typhoon|Typhoon|https://api.opentyphoon.ai/v1|typhoon-v2.5-30b-a3b-instruct|modelli||free-ricorrente|
Il 3/11 la chat vera su typhoon-v2.5-30b-a3b-instruct ha risposto 200 "OK", ma
all'appello del 2/11 risultava "strano" (l'elenco modelli non rispondeva 200) e la
riga era in modo "modelli" (cioè il portiere non le faceva mai una domanda).
IL TUO COMPITO:
1. Spiega la differenza fra "elenco modelli" e "chat vera": perché il primo può
   fallire mentre il secondo funziona, e perché il roster adesso è in modo chat.
2. Verifica con una chat vera (bash + python3 urllib, chiave con
   "python3 ~/posta/chiave_di.py Typhoon", non stamparla) altri modelli
   gratuiti di Typhoon, e se ci sono limiti (richieste al minuto, quota).
3. Dì se Typhoon è pronto per entrare nella riserva del Portiere come chat di
   scorta e con quale modello.
4. SCRIVI il referto in ~/posta/fatti/rel_typhoon.md (cartella del repo: puoi
   scrivere solo li', non in /tmp). Massimo 500 parole. Non stampare chiavi.
EOF

P_ANY=$(cat fatti/prompt_anyapi.txt)
P_GIZMO=$(cat fatti/prompt_gizmo.txt)
P_TYPHOON=$(cat fatti/prompt_typhoon.txt)

echo "=== AGENTI IN PARALLELO (max 18 minuti) ==="
( timeout 1100 opencode run "$P_ANY" > fatti/out_anyapi.txt 2>&1 \
  || timeout 1100 opencode run -m opencode/big-pickle "$P_ANY" > fatti/out_anyapi.txt 2>&1 \
  || echo "(agente anyapi non riuscito)" >> fatti/out_anyapi.txt ) &
A1=$!
( timeout 1100 opencode run "$P_GIZMO" > fatti/out_gizmo.txt 2>&1 \
  || timeout 1100 opencode run -m opencode/big-pickle "$P_GIZMO" > fatti/out_gizmo.txt 2>&1 \
  || echo "(agente gizmo non riuscito)" >> fatti/out_gizmo.txt ) &
A2=$!
( timeout 1100 opencode run "$P_TYPHOON" > fatti/out_typhoon.txt 2>&1 \
  || timeout 1100 opencode run -m opencode/big-pickle "$P_TYPHOON" > fatti/out_typhoon.txt 2>&1 \
  || echo "(agente typhoon non riuscito)" >> fatti/out_typhoon.txt ) &
A3=$!
wait $A1 $A2 $A3

for n in anyapi gizmo typhoon; do
  echo
  echo "=== REFERTO $n ==="
  if [ -f "fatti/rel_$n.md" ]; then
    sed -n '1,200p' "fatti/rel_$n.md"
  else
    echo "(l'agente non ha scritto fatti/rel_$n.md — ultime righe del suo output)"
    tail -25 "fatti/out_$n.txt" 2>/dev/null
  fi
  echo
done
echo "=== FINE SQUADRA ==="
