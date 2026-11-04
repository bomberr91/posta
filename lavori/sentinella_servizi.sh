#!/usr/bin/env bash
# sentinella_servizi.sh — la sentinella GIORNALIERA dei servizi parcheggiati.
#
# 3/11 sera (decisione del capo): Waterfall e NavyAI sono "parcheggiati" — non
# si contano nell'appello e non si chiamano a ogni giro, ma aspettiamo che il
# provider si muova da solo (le chiavi revocate, il free tier in pausa, ecc.).
# Una volta al giorno questo script bussa a entrambi con una richiesta vera e
# lascia il referto in dal_pc/sentinella_servizi.md: se uno risponde 200, vuol
# dire che è tornato e va reintegrato nel roster.
#
# Nessuna attesa, nessun loop: gira una volta al giorno e basta.
set -u
DIR="$HOME/posta"
[ -d "$DIR" ] || DIR="$HOME/posta_ponte"
cd "$DIR" 2>/dev/null || exit 1
mkdir -p fatti dal_pc

MARKER="$DIR/fatti/sentinella_servizi_giro"
OGGI=$(date +%F)
if [ -f "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$OGGI" ]; then
  exit 0
fi
date +%F > "$MARKER"

RAPPORTO="$DIR/dal_pc/sentinella_servizi.md"
{
  echo "# 📡 Sentinella dei servizi parcheggiati — $(date '+%d/%m/%Y %H:%M')"
  echo
  echo "Ogni giorno bussa a Waterfall e NavyAI (parcheggiati, fuori dal roster): aspettiamo che si muovano da soli."
  echo
} > "$RAPPORTO"

python3 - >> "$RAPPORTO" 2>&1 << 'PY'
import json, re, subprocess, urllib.request, urllib.error, datetime

# 4/11 notte (regola del capo): i parcheggiati stanno FUORI dal roster —
# non ha senso chiamarli in appello se sappiamo che non rispondono finche'
# non cambia qualcosa — MA la sentinella li guarda lo stesso. Percio' qui
# la tabella sta per conto suo e non piu' nel roster.
#   pid | nome nel portachiavi | indirizzo | modello
PARCHEGGIATI = [
    ("waterfall", "Waterfall", "https://api.getwaterfall.org/v1", "auto"),
    ("navy", "NavyAI", "https://api.navy/v1", "schizogpt"),
]

def chiave(etichetta):
    if not etichetta or etichetta.upper() == "SENZA":
        return ""
    out = subprocess.run(["python3", "chiave_di.py", etichetta],
                         capture_output=True, text=True).stdout.strip().splitlines()
    return out[0].strip() if out else ""

def chat(base, modello, key):
    h = {"User-Agent": "Mozilla/5.0", "Accept": "application/json"}
    if key:
        h["Authorization"] = "Bearer " + key
    h["Content-Type"] = "application/json"
    body = json.dumps({"model": modello,
                       "messages": [{"role": "user", "content": "Say OK"}],
                       "max_tokens": 128}).encode()
    req = urllib.request.Request(base.rstrip("/") + "/chat/completions", data=body, headers=h, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=45) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return 0, "ERR %s" % e

for pid, etichetta, base, modello in PARCHEGGIATI:
    key = chiave(etichetta)
    code, body = chat(base, modello, key)
    print("## %s (%s)" % (etichetta, pid))
    print("- indirizzo: %s · modello: %s · chiave: %s" % (base, modello, "presente" if key else "ASSENTE"))
    if code == 200:
        try:
            txt = (json.loads(body).get("choices") or [{}])[0].get("message", {}).get("content")
        except Exception:
            txt = None
        print("- **RISPOSTA 200: IL SERVIZIO E\' TORNATO.** Va reintegrato nel roster.")
        print("- contenuto: %r" % (txt or "")[:200])
    else:
        print("- esito: HTTP %s" % code)
        print("```")
        print(body[:400])
        print("```")
    print()
PY

echo "--- fine sentinella servizi ---" >> "$RAPPORTO"
exit 0
