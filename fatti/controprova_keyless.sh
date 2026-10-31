#!/bin/bash
cd ~/posta
nohup python3 - << 'PYEOF' > /dev/null 2>&1 &
import json, time, urllib.request, urllib.error
CANDIDATI = {
 "AI Pooled": "https://pooled.dev/v1", "AIHubMix": "https://api.aihubmix.com/v1",
 "BlazeAI": "https://blazeai.boxu.dev/v1", "Completions": "https://completions.me/api/v1",
 "EvolveX": "https://api.evolvex.gg/v1", "FastRouter": "https://api.fastrouter.ai/v1",
 "FreeInference": "https://freeinference.org/v1", "MincAPI": "https://mincapi.ai.studio/v1",
 "MNN": "https://api.mnnai.ru/v1", "OhMyGPT": "https://api.ohmygpt.com/v1",
 "PaxSenix": "https://api.paxsenix.org/v1",
}
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) cervello/2.1", "Content-Type": "application/json"}
righe = ["# Controprova keyless: micro-chat 10 token (passo 5s) — " + time.strftime("%d/%m %H:%M"), "", "| Provider | Modello provato | Esito CHAT |", "|---|---|---|"]
for nome, base in CANDIDATI.items():
    modello, esito = "?", "?"
    try:
        d = json.loads(urllib.request.urlopen(urllib.request.Request(base + "/models", headers=UA), timeout=10).read().decode())
        voci = d.get("data") or d.get("models") or []
        ids = [v.get("id") if isinstance(v, dict) else str(v) for v in voci]
        liberi = [i for i in ids if i and ("free" in i.lower() or "mini" in i.lower() or "flash" in i.lower() or "small" in i.lower())]
        modello = (liberi or ids or ["auto"])[0]
    except Exception as e:
        esito = "catalogo sparito: " + str(e)[:60]
    if esito == "?":
        corpo = json.dumps({"model": modello, "max_tokens": 10, "messages": [{"role": "user", "content": "Rispondi solo: ok"}]}).encode()
        try:
            d = json.loads(urllib.request.urlopen(urllib.request.Request(base + "/chat/completions", data=corpo, headers=UA), timeout=25).read().decode())
            msg = (d.get("choices") or [{}])[0].get("message", {})
            testo = msg.get("content") or msg.get("reasoning") or ""
            esito = "🟢 KEYLESS VERO → %s" % (str(testo)[:40].replace("\n", " ") or "(vuoto ma 200)")
        except urllib.error.HTTPError as e:
            esito = "🔑 chat chiusa (%d): solo catalogo pubblico" % e.code
        except Exception as e:
            esito = "⚪ " + str(e)[:60]
    righe.append("| %s | %s | %s |" % (nome, str(modello)[:40], esito))
    time.sleep(5)
open("dal_pc/controprova_keyless.md", "w").write("\n".join(righe) + "\n")
import subprocess
subprocess.run(["git", "pull", "-q", "--rebase"], cwd=".")
subprocess.run(["git", "add", "dal_pc/controprova_keyless.md"], cwd=".")
subprocess.run(["git", "commit", "-q", "-m", "controprova keyless 11 provider"], cwd=".")
subprocess.run(["git", "push", "-q", "origin", "main"], cwd=".")
PYEOF
echo "controprova keyless avviata in sottofondo (pid $!): ~3-4 minuti, si committa da sola"
