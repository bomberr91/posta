#!/usr/bin/env python3
"""aggiorna_catalogo.py — rigenera `lavori/catalogo_freellmapi.json`.

FONTE: il catalogo firmato e PUBBLICO di freellmapi (https://api.freellmapi.co/v1/latest).
Non serve nessuna chiave. Il catalogo si aggiorna da solo ogni ~12 ore lato
freellmapi: noi lo rischiamo quando la sentinella passa.

COSA CONTIENE (per ogni provider che ci serve):
  · i modelli GRATIS con l'id ESATTO da mettere nella richiesta
  · il rango (1 = migliore: e' l'intelligence rank di freellmapi)
  · rpm/rpd (limiti) e contesto
  · i "quirk": le istruzioni operative del provider (formato della chiave,
    header speciali, max_tokens minimi, rate limit)

COME SI USA:
  python3 lavori/aggiorna_catalogo.py                # scarica e riscrive il file
  python3 lavori/aggiorna_catalogo.py --file /tmp/cat.json   # usa una copia locale
  python3 lavori/aggiorna_catalogo.py --dry           # non scrive, solo riassunto
"""
import json
import os
import re
import sys
import time
import urllib.request

URL_CATALOGO = "https://api.freellmapi.co/v1/latest"
QUI = os.path.dirname(os.path.abspath(__file__))
DESTINAZIONE = os.path.join(QUI, "catalogo_freellmapi.json")
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

# Le etichette della nostra lista (portiere_lista.txt) per ogni piattaforma
# del catalogo. Il catalogo chiama i provider con il nome "ufficiale", noi li
# chiamiamo come nel nostro elenco: qui si fa il ponte.
PIATTAFORME = {
    "agnes": "Agnes AI",
    "aihorde": "AI Horde (senza chiave)",
    "aion": "Aion Labs",
    "airforce": "Api.Airforce",
    "bazaarlink": "BazaarLink",
    "cloudflare": "Cloudflare Workers AI",
    "clod": "CLōD",
    "cohere": "Cohere",
    "dreamprompting": "DreamPrompting",
    "electronhub": "ElectronHub",
    "google": "Google AI Studio",
    "groq": "Groq",
    "kilo": "Kilo (senza chiave)",
    "llm7": "LLM7",
    "llmtr": "LLMTR",
    "logfare": "Logfare",
    "mistral": "Mistral",
    "moondream": "Moondream",
    "nara": "NaraRouter",
    "nvidia": "NVIDIA",
    "openrouter": "OpenRouter",
    "ovh": "OVH",
    "requesty": "Requesty",
    "routeway": "Routeway",
    "router9": "Router9",
    "sealion": "SeaLION",
    "septor": "Septor Labs",
    "speka": "Speka",
    "speechify": "Speechify",
    "unorouter": "UnoRouter",
    "waterfall": "Waterfall",
    "xkiro": "xKiro",
    "zhipu": "Zhipu",
}

# Modelli che NON sono da chat (il catalogo li tiene in liste a parte, e poi
# qualche id che sembra un modello ma serve per altro).
NON_CHAT = re.compile(
    r"embed|whisper|tts|audio|image|vision|rerank|moderation|guard|safety|"
    r"dall|stable-diffusion|sd-|flux|ocr|document|deepgram|leonardo|aura|"
    r"phoenix|dreamshaper|lucid|parse|voxtral|asr|search|decide|clef|mercury",
    re.I)


def scarica(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8", "replace"))


def costruisci(cat):
    non_chat = set()
    for chiave in ("embeddings", "transcriptionModels", "videoModels",
                   "decisionModels", "searchEngines"):
        for v in cat.get(chiave) or []:
            if isinstance(v, str):
                non_chat.add(v)
            elif isinstance(v, dict):
                for k in ("modelId", "model_id", "id", "name"):
                    if v.get(k):
                        non_chat.add(str(v[k]))

    # quirk del catalogo, raggruppati per piattaforma
    quirk_piattaforma = {}
    for q in cat.get("quirks") or []:
        for tgt in q.get("targets") or []:
            pid = tgt.get("platform")
            if not pid:
                continue
            quirk_piattaforma.setdefault(pid, []).append({
                "slug": q.get("slug"),
                "titolo": q.get("title"),
                "testo": q.get("body"),
                "gravita": q.get("severity"),
            })

    provider = {}
    for m in cat.get("models") or []:
        pid = m.get("platform")
        if pid not in PIATTAFORME:
            continue
        mid = m.get("modelId") or m.get("model_id")
        if not isinstance(mid, str) or not mid:
            continue
        if mid in non_chat or NON_CHAT.search(mid):
            continue
        if m.get("enabled") is False:
            continue
        lim = m.get("limits") or {}
        voce = {
            "id": mid,
            "rank": m.get("intelligenceRank"),
            "vel": m.get("speedRank"),
            "rpm": lim.get("rpm"),
            "rpd": lim.get("rpd"),
            "ctx": m.get("contextWindow"),
            "strumenti": bool(m.get("supportsTools")),
            "visione": bool(m.get("supportsVision")),
        }
        p = provider.setdefault(pid, {
            "nome": next((x["name"] for x in cat.get("platforms", []) if x.get("id") == pid), pid),
            "etichetta": PIATTAFORME[pid],
            "modelli": [],
            "quirk": [],
        })
        p["modelli"].append(voce)
        for q in m.get("quirks") or []:
            p["quirk"].append({"slug": q.get("slug"), "titolo": q.get("title"),
                               "testo": q.get("body"), "gravita": q.get("severity")})

    for pid, p in provider.items():
        # rango 1 = migliore (e' l'intelligence rank di freellmapi)
        p["modelli"].sort(key=lambda v: (v["rank"] is None, v["rank"] or 9999))
        visti = set()
        qfinal = []
        for q in quirk_piattaforma.get(pid, []) + p["quirk"]:
            k = q.get("slug")
            if k in visti:
                continue
            visti.add(k)
            qfinal.append(q)
        p["quirk"] = qfinal

    return {
        "generato": time.strftime("%d/%m/%Y %H:%M"),
        "versione": cat.get("version"),
        "tier": cat.get("tier"),
        "provider": provider,
        "quirk": quirk_piattaforma,
    }


def main():
    args = sys.argv[1:]
    dry = "--dry" in args
    solo_file = None
    if "--file" in args:
        solo_file = args[args.index("--file") + 1]
    try:
        cat = json.load(open(solo_file, encoding="utf-8")) if solo_file else scarica(URL_CATALOGO)
    except Exception as e:
        print("catalogo non letto:", e)
        return 1

    dati = costruisci(cat)
    n_mod = sum(len(p["modelli"]) for p in dati["provider"].values())
    n_q = sum(len(p["quirk"]) for p in dati["provider"].values())
    print(f"catalogo {dati['versione']} · {len(dati['provider'])} provider · {n_mod} modelli · {n_q} quirk")
    if not dry:
        tmp = DESTINAZIONE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(dati, f, ensure_ascii=False, indent=1)
        os.replace(tmp, DESTINAZIONE)
        print("scritto:", DESTINAZIONE)
    else:
        for pid, p in sorted(dati["provider"].items()):
            migliori = ", ".join(m["id"] for m in p["modelli"][:3])
            print(f"  {p['etichetta']:<26} {migliori[:70]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
