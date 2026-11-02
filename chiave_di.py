#!/usr/bin/env python3
"""chiave_di.py — tira fuori UNA chiave dal portachiavi, in modo affidabile.

Perché esiste: con grep mi capitava di pescare la chiave del provider accanto
(le righe del registro sono vicine). Qui si prende SOLO la riga del provider
(e la riga subito sotto se dice «chiave completa») e da lì si estrae la chiave.

  python3 chiave_di.py "Groq"              → stampa la chiave (o niente)
  python3 chiave_di.py "Speka" --mostra    → stampa anche da quale riga l'ha presa
"""
import os
import re
import sys

# formati di chiave noti, in ordine di priorità (i più specifici prima)
FORMATI = [
    r"blaze-[a-z0-9]+",
    r"oc_sk_[A-Za-z0-9_]+",
    r"cpk_[A-Za-z0-9]{8,}(?:\.[A-Za-z0-9]+)+",
    r"eyJ[A-Za-z0-9_.-]{40,}",
    r"sk-speka-[A-Za-z0-9_-]+",
    r"gsk_[A-Za-z0-9_-]+",
    r"AQ\.[A-Za-z0-9_.-]{20,}",
    r"nvapi-[A-Za-z0-9_-]+",
    r"mstrl_[A-Za-z0-9_-]+",
    r"hf_[A-Za-z0-9]{20,}",
    r"sk-or-[A-Za-z0-9_-]+",
    r"sk-bl-[A-Za-z0-9_-]+",
    r"sk-air-[A-Za-z0-9_-]+",
    r"sk-nry-[A-Za-z0-9_-]+",
    r"sk-orca-[A-Za-z0-9_-]+",
    r"sk-navy-[A-Za-z0-9_-]+",
    r"sk-xt-[A-Za-z0-9_-]+",
    r"rqsty-sk-[A-Za-z0-9+/=_-]+",
    r"ek-[A-Za-z0-9]{20,}",
    r"fal_sk_[A-Za-z0-9]+:[A-Za-z0-9]+",  # fal.ai: chiave:segreto — PRIMA di sk_ generico
    r"sk_[A-Za-z0-9]{20,}",   # 2/11: ATTENZIONE: questo matcha DENTRO fal_sk_... -> il fal va prima
    r"ak_[A-Za-z0-9]+",
    r"alv2_[A-Za-z0-9_]+",   # 2/11: la chiave Aion finisce con _yQ058: il + tagliava via il coda e dava 401
    r"wf-[A-Za-z0-9_-]{20,}", # Waterfall
    r"[0-9a-f]{32}:cfut_[A-Za-z0-9]+",   # Cloudflare: la chiave è «account_id:token»
    r"cfut_[A-Za-z0-9]+",
    r"lfu_[A-Za-z0-9]+",
    r"sk-free-[A-Za-z0-9_-]+",
    r"sk-teamo-[A-Za-z0-9_-]{16,}",   # TeamoRouter
    r"ghp_[A-Za-z0-9]+",
    r"sk-[A-Za-z0-9_-]{16,}",
    r"AIza[A-Za-z0-9_-]{30,}",
]


def chiave(testo, percorso):
    """Tira fuori la chiave del provider giusto.

    Regola (2/11 sera-fix): si guarda PRIMA la riga che INIZIA col nome del
    provider in grassetto («- **OVH** — ...»). Solo se non esiste si passa alla
    parola semplice. Serve perche' la riga di Pollinations nomina OVH fra
    parentesi: con la sola parola semplice «OVH» prendeva la chiave di
    Pollinations (403 a runtime).
    """
    try:
        righe = open(percorso, encoding="utf-8", errors="replace").read().splitlines()
    except Exception:
        return "", ""

    rx_grassetto = re.compile(r"^\s*(?:[-|*#>\u2022]\s*)*\*\*" + re.escape(testo) + r"\*\*", re.I)
    rx_parola = re.compile(r"\b" + re.escape(testo.lower()) + r"\b", re.I)

    indici = [i for i, riga in enumerate(righe) if rx_grassetto.search(riga)]
    if not indici:
        indici = [i for i, riga in enumerate(righe) if rx_parola.search(riga)]

    for i in indici:
        riga = righe[i]
        pezzo = [riga]
        if i + 1 < len(righe) and "chiave completa" in righe[i + 1].lower():
            pezzo.append(righe[i + 1])
        testo_riga = "\n".join(pezzo)
        for f in FORMATI:
            trovati = re.findall(f, testo_riga)
            if trovati:
                return max(trovati, key=len), riga.strip()[:90]
        candidati = [t for t in re.findall(r"[A-Za-z0-9_+=.-]{24,}", testo_riga)
                     if "/" not in t and not t.lower().startswith(("https", "chiave"))
                     and not re.match(r"^[a-z0-9-]+(\.[a-z0-9-]+)+$", t)   # non e' un dominio
                     and not re.match(r"^[0-9a-f]{8}-", t)]                  # non e' un uuid
        if candidati:
            return max(candidati, key=len), riga.strip()[:90]
    return "", ""


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("uso: chiave_di.py <nome provider> [--mostra]", file=sys.stderr)
        sys.exit(2)
    nome = sys.argv[1]
    kf = os.environ.get("CHIAVI_FILE") or os.path.join(os.path.expanduser("~"), "CHIAVI_LOCALI.md")
    k, riga = chiave(nome, kf)
    if "--mostra" in sys.argv:
        print(k or "(nessuna chiave)", "| riga:", riga or "(provider non trovato)")
    else:
        print(k)
