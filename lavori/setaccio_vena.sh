#!/bin/bash
# Setaccio vena Yoann (lavoro n.7) — sonda GET-only + schede, in sottofondo
cd ~/posta
S=dal_pc/setaccio_sonda.md
K=dal_pc/setaccio_schede.md
python3 << 'PYEOF' > "$S" 2>&1
import json, time, urllib.request, urllib.error
PROVIDER = {
 "A4F": "a4f.co", "AI Pooled": "pooled.dev", "AIchixia": "aichixia.xyz",
 "AIHubMix": "aihubmix.com", "Apertis": "apertis.ai", "Atessa": "atessa.top",
 "AwanLLM": "awanllm.com", "BlazeAI": "blazeai.boxu.dev", "CoderPlan": "coderplan.ai",
 "Completions": "completions.me", "EvolveX": "evolvex.gg", "FastRouter": "fastrouter.ai",
 "Flowbar": "flowbarai.com", "FreeInference": "freeinference.org", "FreeTheAI": "freetheai.xyz",
 "Hetzner": "experiments.hetzner.com", "Hubs02225": "hubs02225.snia.ch",
 "LiteRouter": "literouter.com", "MincAPI": "mincapi.ai.studio", "MNN": "mnnai.ru",
 "OhMyGPT": "ohmygpt.com", "Onomeo": "onomeo.com", "PaxSenix": "api.paxsenix.org",
 "Pixazo": "pixazo.ai", "Resurge": "resurge.one", "StudioLM": "studiolm.dev",
 "TokenReply": "tokenreply.com", "ValorGPT": "valorgpt.com",
 "Xeven(img)": "ai-image-api.xeven.workers.dev", "Yingsuan": "yingsuan.top",
}
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) cervello/2.1"}
print("# Setaccio vena — sonda GET /models (gentile: 4s di passo) —", time.strftime("%d/%m %H:%M"))
print()
print("| Provider | URL vincente | Esito |")
print("|---|---|---|")
riassunto = {"keyless?": [], "serve-chiave": [], "endpoint-ignoto": [], "morto": []}
for nome, dom in PROVIDER.items():
    candidati = []
    if dom.startswith("api."):
        candidati = ["https://%s/v1/models" % dom, "https://%s/models" % dom]
    else:
        candidati = ["https://api.%s/v1/models" % dom, "https://%s/v1/models" % dom,
                     "https://%s/api/v1/models" % dom]
    esito, vinta = "morto", "—"
    for url in candidati:
        try:
            r = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=8)
            corpo = r.read(400).decode(errors="replace")
            if '"data"' in corpo or '"models"' in corpo or corpo.strip().startswith("["):
                esito, vinta = "🟢 LISTA SENZA CHIAVE (keyless?)", url
            else:
                esito, vinta = "🟡 200 ma non-lista", url
            break
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                esito, vinta = "🔑 VIVO, serve chiave (%d)" % e.code, url
                break
            esito = "⚪ risponde %d" % e.code
        except Exception:
            continue
        finally:
            time.sleep(4)
    print("| %s | %s | %s |" % (nome, vinta.replace("https://", ""), esito))
    chiave = ("keyless?" if "keyless" in esito else
              "serve-chiave" if "serve chiave" in esito else
              "endpoint-ignoto" if ("200" in esito or "risponde" in esito) else "morto")
    riassunto[chiave].append(nome)
print()
print("## Riassunto")
for k, v in riassunto.items():
    print("- **%s (%d)**: %s" % (k, len(v), ", ".join(v) or "—"))
PYEOF
# ── fase 2: schede, SOLO quando nessun altro opencode sta girando (guardia WSL1)
export PATH="$HOME/.opencode/bin:$PATH"
ATTESA=0
while pgrep -f "opencode ru[n]" > /dev/null && [ $ATTESA -lt 6000 ]; do sleep 60; ATTESA=$((ATTESA+60)); done
timeout 900 opencode run -m cervello/auto "Sei l'analista della caccia provider. Qui sotto la sonda su 30 provider AI mai visti (fonte: tracker awesome-free-ai-api, collaudati dal suo autore il 31/10). Scrivi in italiano: ① i 5 BERSAGLI MIGLIORI per registrarsi (criteri: vivo, probabile free tier, niente carta — segnala se dal nome/dominio sospetti carta o scarsa serieta') con una riga di motivo ciascuno ② quali scartare subito e perche' ③ i keyless? da verificare per primi. Sii secco, formato scheda.

$(cat $S)" > "$K" 2>&1
git pull -q --rebase 2>/dev/null
git add "$S" "$K" 2>/dev/null
git commit -q -m "setaccio vena: sonda 30 provider + schede analista" 2>/dev/null
git push -q origin main 2>/dev/null || { git pull -q --rebase && git push -q origin main; }
