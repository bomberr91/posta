# Risposta a «istruzioni_cervello»

_02/11/2026 13:27 · FilippoPC_

[0m
> build · big-pickle
[0m
[0m$ [0mls -la && echo "---" && ls -la missione/ 2>/dev/null && echo "---" && ls -la lavori/ 2>/dev/null | head -50 && echo "---" && ls -la dal_pc/ 2>/dev/null | head -30
(no output)
[0m
[0m$ [0mtest -f missione/CERVELLO_MACCHINA_PERFETTA.md && wc -l missione/CERVELLO_MACCHINA_PERFETTA.md && tail -60 missione/CERVELLO_MACCHINA_PERFETTA.md || echo "FILE NON ESISTE"
407 missione/CERVELLO_MACCHINA_PERFETTA.md
OpenCode (57) · Ollama Cloud (62) · Vercel AI GW $5/mese (63) · LLM7/Aion/SiliconFlow/HF (40)
· SayGM da verificare (61-nota) · Kilo/OVHcloud keyless (23)

PROSSIMO PASSO (quando il capo da' l'ok): CONCLUSIONI DEFINITIVE — riscrivere le FASI
incorporando le 64 idee -> approvazione -> applicare UNA FASE ALLA VOLTA
(sandbox -> anteprima -> push).

====================================================================
== 🔴 CURA-AUDIT v5 — 1/11 sera — IL PORTIERE ERA MORTO E NON LO SAPEVA ==
====================================================================
NON ERA UN'IDEA NUOVA: era un BUCO. Il quaderno delle 64 idee era chiuso e
perfetto, e intanto il Portiere non rispondeva a una chat dalle 16:24.

DUE DIFETTI, STESSA COMMIT (3164d7f "CURA-AUDIT", 1/11 16:24):
  ① `_sessione()` annidato dentro `_rispondi()` (indentazione sbagliata) →
     H._sessione non esisteva → ogni chat moriva con "empty reply from server"
  ② `NOME = "Portiere"` cancellato → /cervello e /portiere.json crashavano

PERCHÉ IL COLLAUDO NON L'HA VISTO (e perché è la cosa più importante):
  - i curl del collaudo avevano timeout 5-20s, il budget del motore è ~480s:
    il collaudo non poteva distinguere "ROT TO" da "LENTO"
  - nessuno guardava il codice di uscita: corpo vuoto → JSONDecodeError → avanti
  - gli script di deploy non avevano `set -e`
  - postino.sh scriveva il `.done` SENZA guardare l'uscita del job
  → "deploy riuscito" scritto sopra un Portiere morto.

IDEA 65 (nuova, nata dal buco) — OGNI COLLAUDO DEVE POTER DIRE "FALLITO":
  65a. `--autoprova`: controllo STRUTTURALE (AST: ogni self.X() chiamato deve
       esistere come metodo) + prova VIVA (chat vera su porta libera). Uscita 1.
  65b. `gate_pubblicazione.py`: prima di pubblicare, ogni .py deve compilare e
       cervello.py deve passare l'autoprova. Se no, NON sale su master.
  65c. `GET /salute`: vivo? configurato? struttura pulita?
  65d. postino: il `.done` solo con uscita 0; `.failito` + 3 tentativi, poi
       `.abbandonato`.
  65e. `fatti/collaudo_cervello.sh`: timeout coerenti col budget del motore,
       ogni passo verifica davvero, l'uscita dice NO.

COLLAUDI (fatti): autoprova SUPERATA sul codice buono, FALLITA sul bug
reintrodotto con la diagnosi esatta · gate blocca .py rotto e cervello rotto ·
postino: exit 3 → nessun .done · deploy_cura: exit 1 a cervello morto, 0 a
cervello sano · tests/test_cervello_offline.py 19 test + 17 subtest verdi ·
stato_invisibili: exit 0 col cervello vivo, exit 1 col cervello morto.

65f. CHIAVI FUORI DAL REPO (1/11 sera): la chiave del gateway OmniRoute era
     scritta a mano in 7 script di un repo PUBBLICO. Ora si legge dal
     portachiavi (`chiavi_env.sh` → `$OM_KEY`). **La chiave va RUOTATA**:
     è stata pubblica (anche nella storia git). → IL CAPO DEVE RUOTARLA.
65g. HANDOVER (per chi riprende): `dal_pc/cura_audit_v5.md` sezioni 10-15 —
     cosa era rotto, cosa è stato corretto, come verificare (60 secondi)
     e cosa resta aperto.

ALTRI RILIEVI v4 CHIUSI: import solo ImportError · vivo() porta 443/IPv6 ·
guardia solo-gratis famiglia Gemini pro/ultra · max_tokens in CONFIG · tetto di
byte sulle risposte · quote atomiche + tetto battiti · stato validato · regole
a prefisso più lungo · sessioni sotto lucchetto.

LA LEZIONE (da mettere in cima al quaderno):
  Il guaio non era il bug, era il COLLAUDO che non poteva dire di no.
  Ogni collaudo ha un'uscita che significa NO, e ogni file che non lo supera
  non sale su master.
[0m
[0m$ [0mpwd; ls -la; echo "---missione---"; ls -la missione/; echo "---lavori---"; ls -la lavori/ | head -60; echo "---dal_pc---"; ls -la dal_pc/ | head -40
(no output)
[0m
[0m$ [0mhead -40 missione/CERVELLO_MACCHINA_PERFETTA.md; echo "=== GREP STRUCTURE ==="; grep -n '^==\|^#\|^=\{10,\}' missione/CERVELLO_MACCHINA_PERFETTA.md | tail -40
# CERVELLO MACCHINA PERFETTA — quaderno delle idee da applicare
Strada A decisa il 30/10: il nostro cervello.py resta, gli rubiamo le idee migliori.
Metodo: analisi a blocchi -> conclusioni -> SOLO POI si applica (ordine deciso insieme).

## BLOCCO 1 (30/10) — Lynkr, EUrouter, TrustedRouter, Routstr

### Lynkr ⭐⭐⭐ (open source, npm, locale) — LA MINIERA
Da rubare:
1. COMPRESSIONE TOON dei risultati JSON dei tool (-87%: 3458->427 token)
2. SPOGLIATURA SCHEMI TOOL: via gli schemi inutili per richieste di sola lettura (-53%)
3. CACHE SEMANTICA locale (embedding locali): domanda simile -> risposta in 171ms, 0 token
4. TIER ROUTING con sessioni appiccicose: facile->gratis, sale di livello solo se serve
Nota: si puo' anche installare accanto al cervello per studiarlo dal vivo (npm i -g lynkr, porta 8081).

### EUrouter 💡 (servizio EU a pagamento — solo idee)
5. PAGELLA PROVIDER: punteggio = salute/(prezzo)^2; castigo (cooldown) 30-120s a chi fallisce;
   retry automatico su 5xx/429/408; "allow_fallbacks: false" per routing rigido.

### TrustedRouter 💡 (hosted, source-available — solo idee)
6. MODELLI-POLITICA: "auto"/"cheap"/"fast"/"free" come nomi modello che in realta' sono
   regole di scelta -> cervello/gratis, cervello/veloce, cervello/migliore.

### Routstr ❌ SCARTO (mercato a pagamento in Bitcoin/sats)
(il cugino open "arbstr" conferma: classificatore complessita' + auto-scoperta /v1/models)

## LISTA DELLA SPESA provvisoria (si aggiorna a ogni blocco)
A. Modelli-politica (patch piccola) [da Lynkr/TrustedRouter]
B. Pagella+castigo+retry provider (patch media) [da EUrouter]
C. Cache risposte: esatta subito, semantica poi (patch media) [da Lynkr]
D. Spogliatura tool + compressione JSON (patch grossa, per ultima) [da Lynkr]

## BLOCCO 2 (30/10) — Bifrost, LunarGate, freelm, Portkey, one-api

### Bifrost ⭐⭐ (Go, open source, enterprise — troppo grosso come motore, idee si')
7. BILANCIAMENTO MULTI-CHIAVE: piu' chiavi per lo stesso provider, scelta pesata
   -> per il portachiavi 57+ chiavi: ruotare le chiavi dello stesso servizio
8. CHIAVI VIRTUALI CON BUDGET: ogni agente una chiave finta con tetto richieste/spesa
   (oggi sk-cervello e' uguale per tutti: con chiavi per-agente sapremmo CHI consuma)

### LunarGate ⭐⭐ (MIT, Go 10MB, filosofia gemella: locale+privacy+una porta)
=== GREP STRUCTURE ===
153:## CORREZIONE CONTEGGIO (segnalata dal capo): la lista era di 13 VOCI, di cui la #12
154:## era un TRIO (FuturMix/Opper/PleumRouter) e la #13 OmniRoute (saltato: eccolo).
156:### OmniRoute ⭐ (gia' nostro, porta 20128 — analisi col focus "cosa rubargli")
163:## 🔭 SCOPERTE COLLATERALI (uscite di sponda dalle ricerche Reddit/GitHub)
164:## — IN CODA "DA VALUTARE", NON ANALIZZATE (regola del filtro: mai marcare senza approfondire)
174:## 📊 TABELLA RESOCONTO FINALE (13/13 analizzati)
193:## BLOCCO A — SCOPERTE COLLATERALI ANALIZZATE (30/10 sera): arbstr, LMRouter, future-agi, freellmpool
195:### arbstr 💡 (MIT, Rust, ATTIVO — release ott 2026)
200:### LMRouter ❌ SCARTO: dormiente (push set-2025, catalogo congelato feb-2026, 0 release)
203:### future-agi / Agent Command Center ⭐⭐ (Apache 2.0, Go — piattaforma grossa, idee si')
208:### freellmpool ⭐⭐⭐ (MIT, pip, proxy locale — COLPO GROSSO: gemello con catalogo mostruoso)
219:## BLOCCO B — ULTIME 2 SCOPERTE COLLATERALI (30/10 sera): 9Router, free-claude-code
221:### 9Router ⭐⭐ (MIT npm, :20128 — ⚠ STESSA PORTA di OmniRoute! Cuore = pacchetto privato
222:### non auditabile + fork in zona grigia -> SOLO IDEE, MAI INSTALLARE)
232:### free-claude-code ⭐⭐ (Python FastAPI; fa girare Claude Code su NIM 40 req/min free,
233:### OpenRouter, DeepSeek, locali)
242:== ✅ ANALISI DAVVERO COMPLETA: 13/13 candidati + 6/6 collaterali = 48 IDEE TOTALI ==
246:## LISTA GOOSE — BLOCCO 1 (30/10 notte): OrcaRouter, IO Intelligence, Sakana Fugu, OpenCode Go
248:### OrcaRouter ⭐⭐⭐ (il "disperso" — hosted gratis zero-markup + Lite MIT self-host)
262:### IO Intelligence (io.net) ⭐ caccia con riserva
270:### Sakana Fugu ❌ uso (BLOCCATO IN EU/EEA + a pagamento $20-200/mese) / 💡 concetto
276:### OpenCode Go ⭐⭐ (abbonamento $10/mese scartato: niente carta — ma due pepite)
286:## LISTA GOOSE — BLOCCO 2 (30/10 notte): Atomic Chat, Celeris, NEAR AI, SayGM
288:### Atomic Chat 🅿️ PARCHEGGIO LOCALE DI LUSSO (open source, gratis)
294:### Celeris ❌ SCARTO: a pagamento ($0.20/$0.70 per M) + API LIMITATA AGLI USA.
297:### NEAR AI Cloud ❌ SCARTO: solo pay-per-token, nessun free tier (TEE serio ma fuori
298:### per regola costo-zero; niente di strutturale da copiare)
300:### SayGM 💡 (uso scartato: pagamenti wallet — ma motore di routing ben fatto)
311:## LISTA GOOSE — BLOCCO 3, ULTIMO (30/10 notte): EmpirioLabs, SaladCloud, Ollama Cloud, Vercel AI GW
313:### EmpirioLabs ❌ SCARTO: nessun free tier (hasFree:false nell'upstream OmniRoute), rivenditore PAYG
314:### SaladCloud ❌ SCARTO: pay-per-token (da $0.06/M, beta) — economico ma mai gratis
316:### Ollama Cloud ⭐ PREDA CACCIA
324:### Vercel AI Gateway ⭐⭐ PREDA GROSSA (abbiamo gia' account Vercel!)
334:### Pepita collaterale del blocco
340:====================================================================
341:== 🏁 QUADERNO COMPLETO (30/10 notte) — TUTTE LE ANALISI FINITE ==
342:====================================================================
355:====================================================================
356:== 🔴 CURA-AUDIT v5 — 1/11 sera — IL PORTIERE ERA MORTO E NON LO SAPEVA ==
357:====================================================================
[0m
Let me verify some key facts mentioned in the task.
[0m$ [0mcat lavori/aggiorna_catalogo.py | head -80
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
[0m
[0m$ [0mpython3 - <<'EOF'
import json,collections
d=json.load(open('lavori/catalogo_freellmapi.json'))
print(type(d), list(d.keys())[:20] if isinstance(d,dict) else len(d))
EOF
<class 'dict'> ['generato', 'versione', 'tier', 'provider', 'quirk']
[0m
[0m$ [0mls -la lavori/ | sed -n '1,80p'; echo ===; ls -la dal_pc | sed -n '1,50p'; echo ===; wc -l appello_chiavi.sh portiere_lista.txt 2>/dev/null; ls *.sh *.txt 2>/dev/null
total 376
drwxr-xr-x 1 agenti agenti   4096 Nov  2 13:26 .
drwxr-xr-x 1 agenti agenti   4096 Nov  2 12:59 ..
-rwxr-xr-x 1 agenti agenti   4999 Nov  1 22:24 OCCHI_FB_BATCH.md
-rwxr-xr-x 1 agenti agenti   4971 Nov  1 22:51 OCCHI_FB_RETRY.md
-rwxr-xr-x 1 agenti agenti   7062 Nov  2 11:55 aggiorna_catalogo.py
-rwxr-xr-x 1 agenti agenti   2876 Oct 30 17:59 analista.sh
-rwxr-xr-x 1 agenti agenti   1733 Nov  1 15:43 audit_catena.sh
-rw-r--r-- 1 agenti agenti 177166 Nov  2 12:59 catalogo_freellmapi.json
-rwxr-xr-x 1 agenti agenti    363 Oct 30 18:17 catena_completa.sh
-rw-r--r-- 1 agenti agenti   4325 Nov  1 23:21 cerca.sh
-rwxr-xr-x 1 agenti agenti   3255 Nov  1 17:07 cura_catena.sh
-rw-r--r-- 1 agenti agenti   4147 Nov  1 23:21 deepdog_ricerca.sh
-rwxr-xr-x 1 agenti agenti   4742 Oct 31 21:39 deepopen_prova.sh
-rwxr-xr-x 1 agenti agenti   1694 Nov  1 15:14 giudice_lusso.sh
-rwxr-xr-x 1 agenti agenti   2177 Nov  1 12:13 miniera_catena.sh
-rwxr-xr-x 1 agenti agenti   1246 Nov  2 11:55 modelli_aihorde.py
-rwxr-xr-x 1 agenti agenti  21158 Nov  1 22:39 occhi_fb.sh
-rwxr-xr-x 1 agenti agenti   1909 Oct 30 18:44 revisore.sh
-rwxr-xr-x 1 agenti agenti   2499 Nov  2 11:55 scorta_cervello.sh
-rwxr-xr-x 1 agenti agenti    146 Nov  1 09:57 scorta_motore.sh
-rw-r--r-- 1 agenti agenti   1960 Nov  2 13:26 scorta_posta.sh
-rwxr-xr-x 1 agenti agenti   3185 Nov  2 11:55 sentinella_chiavi.sh
-rwxr-xr-x 1 agenti agenti    954 Oct 30 18:03 seriale.sh
-rwxr-xr-x 1 agenti agenti   4053 Oct 31 22:00 setaccio_vena.sh
===
total 1508
drwxr-xr-x 1 agenti agenti   4096 Nov  2 13:27 .
drwxr-xr-x 1 agenti agenti   4096 Nov  2 12:59 ..
-rwxr-xr-x 1 agenti agenti  17181 Nov  2 12:59 AUDIT_FINALE_CERVELLO.md
-rw-r--r-- 1 agenti agenti    579 Nov  2 11:29 accendi_omniroute.md
-rw-r--r-- 1 agenti agenti    804 Nov  2 11:29 accendi_omniroute_2.md
-rw-r--r-- 1 agenti agenti    164 Nov  2 11:29 accendi_omniroute_e_rilancia.md
-rw-r--r-- 1 agenti agenti    533 Nov  2 11:29 agentrouter_checkin.md
-rw-r--r-- 1 agenti agenti   1438 Nov  2 12:59 aggiorna_26_skill_e_browser.md
-rw-r--r-- 1 agenti agenti    252 Nov  2 11:29 analisi_blocco_1.md
-rw-r--r-- 1 agenti agenti    250 Nov  2 11:29 analisi_blocco_2.md
-rw-r--r-- 1 agenti agenti    253 Nov  2 11:29 analisi_blocco_3.md
-rw-r--r-- 1 agenti agenti    253 Nov  2 11:29 analisi_blocco_4.md
-rw-r--r-- 1 agenti agenti   5328 Nov  2 13:26 appello_chiavi.md
-rw-r--r-- 1 agenti agenti    766 Nov  2 12:59 ar_canali_aperti.md
-rw-r--r-- 1 agenti agenti    992 Nov  2 12:59 ar_processo3.md
-rw-r--r-- 1 agenti agenti   1305 Nov  2 12:59 ar_processo4.md
-rw-r--r-- 1 agenti agenti   1069 Nov  2 12:59 ar_tutte_le_chiavi.md
-rw-r--r-- 1 agenti agenti    674 Nov  2 12:59 audit3_stato.md
-rw-r--r-- 1 agenti agenti   3849 Nov  2 11:29 audit4_sblocco.md
-rw-r--r-- 1 agenti agenti    296 Nov  2 12:59 audit4_stato.md
-rw-r--r-- 1 agenti agenti    959 Nov  2 11:29 audit_cervello.md
-rw-r--r-- 1 agenti agenti   1158 Nov  2 11:29 autonomia_avvio.md
-rw-r--r-- 1 agenti agenti    259 Nov  2 11:29 avvia_deepopen.md
-rw-r--r-- 1 agenti agenti    200 Nov  2 11:29 avvia_setaccio.md
-rw-r--r-- 1 agenti agenti    450 Nov  2 11:29 blinda_guardiani.md
-rw-r--r-- 1 agenti agenti    754 Nov  2 12:59 buongiorno_1_11.md
-rw-r--r-- 1 agenti agenti   1963 Nov  2 12:59 caccia_intruso.md
-rw-r--r-- 1 agenti agenti   1942 Nov  2 12:59 catalogo_NASA.md
-rw-r--r-- 1 agenti agenti    787 Nov  2 11:29 catalogo_paginechesperPage999999.md
-rw-r--r-- 1 agenti agenti    369 Nov  2 11:29 cerca_aiza.md
-rw-r--r-- 1 agenti agenti   1912 Nov  2 11:29 cervello_restart.md
-rw-r--r-- 1 agenti agenti    649 Nov  2 11:29 chi_lavora.md
-rw-r--r-- 1 agenti agenti   1091 Nov  2 11:29 collaudo_f2b1.md
-rw-r--r-- 1 agenti agenti   1617 Nov  2 11:29 collaudo_f2b2.md
-rw-r--r-- 1 agenti agenti   1752 Nov  2 12:59 collaudo_f2b3.md
-rw-r--r-- 1 agenti agenti   1010 Nov  2 11:29 collaudo_f2b4.md
-rw-r--r-- 1 agenti agenti   4115 Nov  2 11:29 collaudo_fase1.md
-rw-r--r-- 1 agenti agenti   1003 Nov  2 12:59 collaudo_gruppi_kilo.md
-rw-r--r-- 1 agenti agenti    143 Nov  2 11:29 consigliere_saggio.md
-rw-r--r-- 1 agenti agenti   3524 Nov  2 12:59 consiglio_saggio.md
-rw-r--r-- 1 agenti agenti    408 Nov  2 11:29 conta_postini.md
-rw-r--r-- 1 agenti agenti    360 Nov  2 11:29 controlla_omni.md
-rw-r--r-- 1 agenti agenti   1057 Nov  2 11:29 controprova_keyless.md
-rw-r--r-- 1 agenti agenti    304 Nov  2 12:59 crea_bat_omniroute.md
-rw-r--r-- 1 agenti agenti    707 Nov  2 12:59 cruscotto_nel_repo.md
-rw-r--r-- 1 agenti agenti  20551 Nov  2 12:59 cura_audit_v5.md
-rw-r--r-- 1 agenti agenti      0 Nov  1 17:21 cura_diff_agente.patch
-rw-r--r-- 1 agenti agenti  27344 Nov  2 12:59 cura_funzioni.md
-rw-r--r-- 1 agenti agenti    532 Nov  2 11:29 cura_sicurezza.md
===
  397 appello_chiavi.sh
  121 portiere_lista.txt
  518 total
RAPPORTO_AGENTI.txt
agenti_stato.sh
aggiorna_tutto.sh
appello_chiavi.sh
apri_free_llm_hub.sh
apri_openclaw.sh
centrale.sh
checkin_agentrouter.sh
chiavi_env.sh
installa_agenti.sh
lista.txt
mappa_innesto.txt
omni_chiavi.sh
omni_free.sh
openclaw_fix.sh
openclaw_stato.sh
portiere_gruppi.txt
portiere_lista.txt
portiere_quote.txt
postino.sh
prova.sh
prova_agenti.sh
prova_provider.sh
squadra.sh
verifica.sh
[0m
[0m$ [0mpython3 - <<'EOF'
import json
d=json.load(open('lavori/catalogo_freellmapi.json'))
print('versione',d.get('versione'))
print('tier',d.get('tier'))
p=d['provider']; q=d['quirk']
print('provider',len(p),'quirk',len(q))
print('tipo provider',type(p))
mods=0
for k,v in (p.items() if isinstance(p,dict) else []):
    if isinstance(v,dict):
        ms=v.get('modelli') or v.get('models') or []
    else:
        ms=v
    mods+=len(ms)
print('modelli',mods)
print('keys sample', list(p)[:5])
import itertools
k=list(p)[0]
print(k, json.dumps(p[k],ensure_ascii=False)[:800])
EOF
(no output)
[0m
[0m$ [0msed -n '1,120p' portiere_lista.txt
# portiere_lista.txt — LA LISTA DEL PORTIERE (motore nostro, porta 20129)
# formato: id|etichetta|nome nel portachiavi|indirizzo API|modello di partenza|modo|tipo|classe|extra|auth
#   nome nel portachiavi = SENZA  → provider che non vuole chiave
#   modo = chat (prova una domanda vera) · modelli (solo elenco modelli)
#   tipo = chat · immagini · video · voce · embedding · visione · db   (assente = chat)
#   classe = keyless | free-ricorrente | trial | pin-only   (gratis e senza carta)
#   extra  = altri modelli da provare, separati da ';'
#   auth   = none (NESSUN header Authorization) | sentinel (Bearer 0000000000)
#   NOTA 2/11: i modelli che «ragionano» (Routeway, UnoRouter, AnyAPI, Gizmo, OVH) rispondono
#   con il testo in reasoning_content e il content vuoto se max_tokens e' troppo piccolo:
# Regola: qui ci stanno TUTTE le chiavi di cui conosciamo l'indirizzo, anche quelle che
# non fanno chat: il Portiere è nostro e deve poter pescare la chiave giusta.
# Indirizzi verificati uno per uno il 21/10/2026 (elenco modelli 200), dal portachiavi.

# ── CHAT ────────────────────────────────────────────────────────────────────
groq|Groq|Groq|https://api.groq.com/openai/v1|qwen/qwen3.8-27b|chat||free-ricorrente||
gemini|Google AI Studio|Google AI Studio|https://generativelanguage.googleapis.com/v1beta/openai|gemini-2.0-flash|chat||free-ricorrente||
mistral|Mistral|Mistral|https://api.mistral.ai/v1|ministral-8b-latest|chat||free-ricorrente||
cohere|Cohere|Cohere|https://api.cohere.ai/compatibility/v1|command-r-plus-08-2024|chat||free-ricorrente||
openrouter|OpenRouter|OpenRouter|https://openrouter.ai/api/v1|openrouter/auto|chat||free-ricorrente||
nvidia|NVIDIA|NVIDIA|https://integrate.api.nvidia.com/v1|nvidia/nemotron-3-ultra-550b-a55b|chat||free-ricorrente||
huggingface|HuggingFace Router|HuggingFace Router|https://router.huggingface.co/v1|meta-llama/Llama-3.1-8B-Instruct|chat||free-ricorrente||
pollinations|Pollinations|Pollinations|https://text.pollinations.ai/openai|openai-fast|chat||free-ricorrente||
agentrouter|AgentRouter|AgentRouter|https://agentrouter.org/v1|auto|modelli||free-ricorrente||
opencode|OpenCode Zen|OpenCode Zen|https://opencode.ai/zen/v1|glm-5.3|chat||free-ricorrente||
aion|Aion Labs|Aion Labs|https://api.aionlabs.ai/v1|aion-labs/aion-3.5|chat||free-ricorrente||
api-airforce|Api.Airforce|Api.Airforce|https://api.airforce/v1|glm-4.7-flash|chat||free-ricorrente||
bazaarlink|BazaarLink|BazaarLink|https://bazaarlink.ai/api/v1|auto:free|chat||free-ricorrente||
clod|CLōD|CLōD|https://api.clod.io/v1|Trinity Mini|chat||free-ricorrente||
navy|NavyAI|NavyAI|https://api.navy/v1|navy-auto|modelli||free-ricorrente||
orcarouter|OrcaRouter|OrcaRouter|https://api.orcarouter.ai/v1|orcarouter/free|modelli||free-ricorrente||
nara|NaraRouter|NaraRouter|https://router.bynara.id/v1|auto|modelli||free-ricorrente||
routeway|Routeway|Routeway|https://api.routeway.ai/v1|gemma-4-26b-a4b-it-chimerax:free|modelli||free-ricorrente|minimax-m3.1-flash:free|
septorlabs|Septor Labs|Septor Labs|https://api.septorlabs.com/v1|auto|modelli||free-ricorrente||
typhoon|Typhoon|Typhoon|https://api.opentyphoon.ai/v1|typhoon-v2.5-30b-a3b-instruct|modelli||free-ricorrente||
tokenharbor|Token Harbor|Token Harbor|https://tokenharbor.ai/v1|deepseek-v4-flash:free|modelli||free-ricorrente||
teamorouter|TeamoRouter|TeamoRouter|https://api.teamorouter.com/v1|auto|modelli||free-ricorrente||
unorouter|UnoRouter|UnoRouter|https://api.unorouter.com/v1|qwen3.8-27b:free|modelli||free-ricorrente|qwen/qwen3.8-27b|
plugsky|Plugsky|Plugsky|https://plugsky.com/v1|plugsky-micro|chat||free-ricorrente||
simplellm|SimpleLLM|SimpleLLM|https://api.simplellm.eu/v1|free-Llama-3.1-8B-Instruct|chat||free-ricorrente||
llmtr|LLMTR|LLMTR|https://llmtr.com/v1|nvidia/nemotron-3-ultra-550b-a55b|chat||free-ricorrente||
router9|Router9|Router9|https://api.router9.com/v1|deepseek-v4-flash|modelli||free-ricorrente||
waterfall|Waterfall|Waterfall|https://api.getwaterfall.org/v1|auto|modelli||free-ricorrente||
blazeapi|BlazeAPI|BlazeAPI|https://api.blazeapi.org/paid/v1|free/claude-haiku-4.5|chat||free-ricorrente||
logfare|Logfare|Logfare|https://logfare.ai/v1|auto|modelli||free-ricorrente||
lucidity|Lucidity|Lucidity (Composite)|https://composite.lucidity.sh/v1|minimax/minimax-m3.1-flash:free|modelli||free-ricorrente||
freeai|FreeAI|FreeAI|https://api.free.ai/v1|qwen7b|chat||free-ricorrente||
speka|Speka|Speka|https://speka.me/v1|nvidia/nemotron-3-ultra-550b-a55b|chat||free-ricorrente||
nscale|Nscale|Nscale|https://inference.api.nscale.com/v1|auto|modelli||free-ricorrente||
chutes|Chutes|Chutes.ai|https://llm.chutes.ai/v1|google/gemma-4-31B-turbo-TEE|modelli||free-ricorrente||
ovh|OVH|SENZA|https://oai.endpoints.kepler.ai.cloud.ovh.net/v1|Mistral-Nemo-Instruct-2407|modelli||keyless|gpt-oss-120b;Meta-Llama-3_3-70B-Instruct;Qwen3.5-397B-A17B;gpt-oss-20b|none
sealion|SeaLION|SeaLION|https://api.sea-lion.ai/v1|aisingapore/Llama-SEA-LION-v3-70B-IT|modelli||free-ricorrente||
aihorde|AI Horde (senza chiave)|SENZA|https://oai.aihorde.net/v1|koboldcpp/gemma-4-26B-A4B-it-ultra-uncensored-heretic|chat||keyless|koboldcpp/gemma-3-270m-it-F16;koboldcpp/Llama-3.2-1B-Instruct;koboldcpp/gemma-4-31B-it-heretic|sentinel
pollinationsfree|Pollinations (senza chiave)|SENZA|https://text.pollinations.ai/openai|openai-fast|chat||keyless||none

# ── NUOVE DEL 21/10 (indirizzo trovato e provato stamattina) ────────────────
llm7|LLM7|LLM7|https://api.llm7.io/v1|DeepSeek-V4-Flash-0731|modelli||free-ricorrente||
longcat|LongCat|LongCat|https://api.longcat.chat/openai/v1|auto|modelli||free-ricorrente||
ollamacloud|Ollama Cloud|Ollama Cloud|https://ollama.com/v1|auto|modelli||free-ricorrente||
requesty|Requesty|Requesty|https://router.requesty.ai/v1|auto|modelli||free-ricorrente||
zhipu|Zhipu|Zhipu|https://open.bigmodel.cn/api/paas/v4|auto|modelli||free-ricorrente||
electronhub|ElectronHub|ElectronHub|https://api.electronhub.ai/v1|gpt-4o|modelli||free-ricorrente||
inferbase|Inferbase|Inferbase|https://api.inferbase.ai/v1|auto|modelli||free-ricorrente||
blockrun|BlockRun|BlockRun|https://api.blockrun.ai/v1|nvidia/nemotron-3-nano-omni-30b-a3b-reasoning|modelli||free-ricorrente||
sail|Sail|Sail|https://api.sailresearch.com/v1|moonshotai/Kimi-K2.6|chat||free-ricorrente||
anyapi|AnyAPI|AnyAPI|https://api.anyapi.ai/v1|nvidia/nemotron-3.5-lightning:free|modelli||free-ricorrente||
kilo|Kilo (senza chiave)|SENZA|https://api.kilo.ai/api/gateway/v1|liquid/lfm-2.5-2.6b:free|modelli||keyless|nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free;openrouter/free;kilo-auto/free|none
cloudflare|Cloudflare Workers AI|Cloudflare Workers AI|SPECIALE-CLOUDFLARE|@cf/meta/llama-3.3-70b-instruct-fp8-fast|chat||free-ricorrente||
#   Cloudflare: la chiave nel registro è «account_id:token», e il router ricava l'indirizzo da lì
#   (https://api.cloudflare.com/client/v4/accounts/<account_id>/ai/v1). L'elenco modelli NON sta su
#   /models: sta su /ai/models/search. Il vecchio llama-3.1-8b è stato deprecato (410) → 3.3-70b-fast.

# ── INDIRIZZI RECUPERATI DALLE INFO DELLA REPO FREELMAPI (MIT) — 21/10 notte ──
# Fonte: tashfeenahmed/freellmapi, server/src/providers/index.ts e providers/*.ts.
# Provati uno per uno da qui il 21/10: elenco modelli 200 E una domanda vera andata a buon fine.
#   · Agnes = «OpenAI-compatible» dietro LiteLLM+vLLM, modelli Agnes a $0/token, niente carta,
#     ~30 richieste in parallelo prima del 429. Ragiona prima di rispondere → timeout 60 s.
#   · xKiro = gateway OpenAI-compatibile su api.xkiro.com/v1 (l'apice ai.xkiro com'è oggi non serve);
#     /v1/models risponde 200 ANCHE senza chiave, quindi la prova di validità va su /v1/usage;
#     i modelli «premium» danno 403, quelli liberi (Mistral, MiniMax, DeepSeek) rispondono.
#   · DreamPrompting = gli id sono «fornitore/modello» (groq/…, mistral/…) oppure «auto».
#   · Gizmo = api.gizmoplatforms.com; i modelli a pagamento dicono «add a payment method»,
#     quelli liberi finiscono con «:free».
agnes|Agnes AI|Agnes AI|https://apihub.agnes-ai.com/v1|agnes-2.5-flash|chat||free-ricorrente||
xkiro|xKiro|xKiro|https://api.xkiro.com/v1|mistralai/ministral-14b|chat||free-ricorrente||
dreamprompting|DreamPrompting|DreamPrompting|https://dreamprompting.com/api/v1|groq/openai/gpt-oss-20b|chat||free-ricorrente||
gizmo|Gizmo|Gizmo|https://api.gizmoplatforms.com/api/v1|nvidia/nemotron-3.5-lightning:free|chat||free-ricorrente||

# ── NON CHAT (restano chiavi nostre: immagini, video, voce, memoria) ────────
speechify|Speechify|Speechify|https://api.speechify.ai/v1|—|no|voce|free-ricorrente||
jina|Jina AI|Jina AI (n2)|https://api.jina.ai/v1|jina-embeddings-v3|no|embedding|free-ricorrente||
qdrant|Qdrant Cloud|Qdrant Cloud — cluster «Bomber91»|https://4e506b83-cf3b-4dab-b1ff-774a090094ba.eu-central-1-0.aws.cloud.qdrant.io|—|no|db|free-ricorrente||
fal|fal.ai|fal.ai|https://fal.run|—|no|immagini|free-ricorrente||
wavespeed|WaveSpeedAI|WaveSpeedAI|https://api.wavespeed.ai/api/v3|—|no|video|free-ricorrente||
moondream|Moondream|Moondream|https://api.moondream.ai/v1|moondream/moondream3-preview|no|visione|free-ricorrente||
pollinationsimg|Pollinations (immagini, senza chiave)|SENZA|https://image.pollinations.ai|flux|no|immagini|keyless||none

## NOTE DEL 21/10 NOTTE (provate una per una dal router)
# · Chutes: la chiave risponde all'elenco modelli ma la chat dà 402 «balance is $0.0, please pay»:
#   il loro piano free vuole un saldo diverso da zero → resta in lista ma il router lo mette in pausa da sé.
# · Kilo: RISOLTO 2/11 — è keyless MA vuole NESSUN header Authorization (con un token
#   qualunque, anche «free» o «0000000000», risponde 401 INVALID_TOKEN). Indirizzo giusto
#   https://api.kilo.ai/api/gateway/v1 ; i modelli gratis arrivano dal catalogo freellmapi.
# · OVH: è keyless e vuole NESSUN header Authorization (con una chiave qualunque risponde 403).
#   Chat: Mistral-Nemo-Instruct-2407 · 2 richieste al minuto.
# · AI Horde: vuole il sentinel «Bearer 0000000000» e max_tokens >= 16. Il roster cambia ogni
#   ora: i modelli con worker online si vedono su https://aihorde.net/api/v2/status/models
# · Cloudflare Workers AI: la chiave deve essere nel formato «account_id:api_token»; la nostra è
#   solo il token, quindi l'indirizzo non si può comporre. Appena c'è l'account id si accende.
# · Sail e i modelli che «ragionano» (Agnes): rispondono col pensiero e il testo vuoto → ora il
#   router fa un secondo giro con più spazio e la risposta arriva.

## DA CONFERMARE — non contano nel numero del Portiere
# Nome nel portachiavi | perché è fermo
✅ risolto 21/10 (riga chat qui sopra: apihub.agnes-ai.com/v1) — Agnes AI|il loro indirizzo API non risponde su nessun host provato (servono le loro istruzioni)
AI21|ritirato: il servizio Studio non esiste più
Kilo|risolto 2/11: è dentro come «Kilo (senza chiave)» (keyless, senza header)
✅ risolto 21/10 (riga chat qui sopra: api.xkiro.com/v1) — xKiro|indirizzo API mai scritto nel portachiavi (xkiro.ai non esiste)
✅ risolto 21/10 (riga chat qui sopra: dreamprompting.com/api/v1) — DreamPrompting|indirizzo API mai scritto nel portachiavi (dreamrompting.com non esiste)
✅ risolto 21/10 (riga chat qui sopra: api.gizmoplatforms.com/api/v1) — Gizmo|indirizzo API mai scritto nel portachiavi (api.gizmo.ai risponde 403)
[0m
[0m$ [0mpython3 - <<'EOF'
import json
d=json.load(open('lavori/catalogo_freellmapi.json'))
print('keys', list(d))
print('versione',d.get('versione'),'tier',d.get('tier'))
p=d.get('provider'); q=d.get('quirk')
print('provider',len(p),'quirk',len(q))
if isinstance(p,dict):
    for k,v in list(p.items())[:3]:
        print('PK',k,'type',type(v).__name__, 'keys', list(v)[:10] if isinstance(v,dict) else '')
        print(json.dumps(v,ensure_ascii=False)[:500])
    counts=[]
    for k,v in p.items():
        ms = v.get('modelli') if isinstance(v,dict) else v
        if isinstance(ms,dict): ms=list(ms)
        counts.append((k,len(ms) if ms else 0))
    print('somma modelli',sum(c for _,c in counts))
    print('prov senza modelli',[k for k,c in counts if c==0])
if isinstance(q,dict):
    print('quirk keys sample', list(q)[:10])
    for k in list(q)[:2]:
        print('Q',k, json.dumps(q[k],ensure_ascii=False)[:500])
EOF
keys ['generato', 'versione', 'tier', 'provider', 'quirk']
versione 2026.11.01.395dc3 tier monthly
provider 33 quirk 55
PK google type dict keys ['nome', 'etichetta', 'modelli', 'quirk']
{"nome": "Google AI Studio", "etichetta": "Google AI Studio", "modelli": [{"id": "gemini-3.8-flash", "rank": 25, "vel": 4, "rpm": null, "rpd": null, "ctx": 1048576, "strumenti": true, "visione": true}, {"id": "gemini-flash-latest", "rank": 25, "vel": 10, "rpm": 10, "rpd": 20, "ctx": null, "strumenti": true, "visione": true}, {"id": "gemini-3.7-flash", "rank": 29, "vel": 4, "rpm": 10, "rpd": 20, "ctx": 1048576, "strumenti": true, "visione": true}, {"id": "gemini-3.6-flash", "rank": 39, "vel": 5, 
PK ovh type dict keys ['nome', 'etichetta', 'modelli', 'quirk']
{"nome": "OVH AI Endpoints", "etichetta": "OVH", "modelli": [{"id": "Qwen3.8-27B", "rank": 39, "vel": 9, "rpm": 2, "rpd": null, "ctx": 262144, "strumenti": true, "visione": false}, {"id": "Qwen3.6-27B", "rank": 65, "vel": 9, "rpm": 2, "rpd": null, "ctx": 131072, "strumenti": true, "visione": false}, {"id": "Qwen3.5-397B-A17B", "rank": 71, "vel": 9, "rpm": 2, "rpd": null, "ctx": 262144, "strumenti": true, "visione": false}, {"id": "Qwen3.5-9B", "rank": 79, "vel": 9, "rpm": 2, "rpd": null, "ctx": 
PK cloudflare type dict keys ['nome', 'etichetta', 'modelli', 'quirk']
{"nome": "Cloudflare Workers AI", "etichetta": "Cloudflare Workers AI", "modelli": [{"id": "@cf/qwen/qwen3.8-27b", "rank": 39, "vel": 9, "rpm": null, "rpd": null, "ctx": 262144, "strumenti": true, "visione": true}, {"id": "@cf/google/gemma-4-26b-a4b-it", "rank": 73, "vel": 11, "rpm": null, "rpd": null, "ctx": 262144, "strumenti": false, "visione": false}, {"id": "@cf/zai-org/glm-4.7-flash", "rank": 77, "vel": 11, "rpm": null, "rpd": null, "ctx": 131072, "strumenti": true, "visione": false}, {"id
somma modelli 342
prov senza modelli []
quirk keys sample ['cloudflare', 'kilo', 'llm7', 'ovh', 'nvidia', 'openrouter', 'requesty', 'google', 'cohere', 'pollinations']
Q cloudflare [{"slug": "cloudflare-key-format", "titolo": "Key is account_id:token", "testo": "Cloudflare Workers AI authenticates with a combined credential in the form \"account_id:token\", not a bare token.", "gravita": "info"}, {"slug": "reasoning-token-room", "titolo": "Needs token room", "testo": "Some free routes spend hidden reasoning tokens before visible output. Avoid tiny max_tokens values or requests can finish by length with empty content.", "gravita": "info"}]
Q kilo [{"slug": "keyless-anonymous", "titolo": "No API key required", "testo": "Routes anonymously — the catalog ships a keyless sentinel row and calls work with no account or key.", "gravita": "info"}, {"slug": "reasoning-token-room", "titolo": "Needs token room", "testo": "Some free routes spend hidden reasoning tokens before visible output. Avoid tiny max_tokens values or requests can finish by length with empty content.", "gravita": "info"}, {"slug": "kilo-auto-token-room", "titolo": "Auto route n
[0m
[0m$ [0mpython3 - <<'EOF'
import json
d=json.load(open('lavori/catalogo_freellmapi.json'))
q=d['quirk']
tot=0
for k,v in q.items():
    print(k, len(v))
    tot+=len(v)
print('TOT quirk items',tot,'provider con quirk',len(q))
print('generato',d.get('generato'))
print('tier',d.get('tier'),'versione',d.get('versione'))
EOF
cloudflare 2
kilo 6
llm7 1
ovh 12
nvidia 6
openrouter 7
requesty 4
google 2
cohere 3
pollinations 2
opencode 4
zhipu 1
aihorde 6
nara 2
huggingface 4
github 1
modelscope 1
bai 3
qianfan 1
volcengine 1
xfyun 1
sail 3
radeon 2
electronhub 11
experiential 2
router9 4
septor 3
clod 1
speechify 1
blaze 11
navy 1
orcarouter 2
mistral 4
lucidity 3
airforce 1
dreamprompting 1
waterfall 1
logfare 1
reka 1
aclide 1
moondream 1
speka 3
llmtr 7
xkiro 1
gizmo 1
blockrun 1
typhoon 1
plugsky 1
inferbase 1
simplellm 1
freeai 6
kenari 4
jamai 5
nabh 1
novai 1
TOT quirk items 159 provider con quirk 55
generato 02/11/2026 10:12
tier monthly versione 2026.11.01.395dc3
[0m
[0m$ [0mgrep -n 'max_tokens\|--solo-problemi\|--svelto\|--json\|posta_appello\|/tmp/appello\|modelli_aihorde\|catalogo' appello_chiavi.sh | head -50; echo ===SENT===; cat lavori/sentinella_chiavi.sh; echo ===SCORTA===; cat lavori/scorta_cervello.sh
13:#   ./appello_chiavi.sh --svelto   solo /models (10-20 secondi)
14:#   ./appello_chiavi.sh --json     stampa il risultato in JSON
18:OUT="$HOME/.posta_appello.json"
23:  [ "$a" = "--svelto" ] && SVELTO=1
24:  [ "$a" = "--json" ] && JSON=1
25:  [ "$a" = "--solo-problemi" ] && SOLOPROBLEMI=1
27:# --solo-problemi: salta chi ha gia' risposto all'ultimo appello (il capo lavora solo
28:# sui casi ancora rotti). Si legge il catalogo dell'ultima run.
149:  # 2/11: max_tokens 128 (prima 20). I modelli che «ragionano» mandano il testo
175:  # CATALOGO FREELLMAPI (2/11): il catalogo firmato di freellmapi e' PUBBLICO
177:  # quali modelli sono gratis e come si chiamano. Con quel catalogo non si piu'
181:  CATMOD=$(python3 - "$QUI/lavori/catalogo_freellmapi.json" "$eti" << 'PY'
205:    ROSTER=$(python3 "$QUI/lavori/modelli_aihorde.py" 2>/dev/null)
242:    # quel momento (AI Horde), e il catalogo sa quale id e' gratis ma l'id puo'
250:        -d "{\"model\":\"$tentativo\",\"messages\":[{\"role\":\"user\",\"content\":\"Rispondi soltanto con OK\"}],\"max_tokens\":128}" \
274:          -d "{\"model\":\"$SUGGERITO\",\"messages\":[{\"role\":\"user\",\"content\":\"Rispondi soltanto con OK\"}],\"max_tokens\":128}" \
346:# --solo-problemi: si unisce anche il catalogo precedente (chi non e' stato
374:# definitivo -> se il processo moriva li', il catalogo restava a meta'.
===SENT===
#!/usr/bin/env bash
# sentinella_chiavi.sh — la sentinella che tiene VIVE le chiavi.
#
# Cosa fa, una volta ogni SEI ORE (non di piu': i piani gratis hanno limiti):
#   1. rigenera il catalogo freellmapi (https://api.freellmapi.co/v1/latest):
#      i modelli gratis cambiano nome e id, il catalogo e' l'unica fonte sicura.
#   2. ri-prova SOLO chi e' in cooldown/reset (appello --solo-problemi): chi
#      rispondeva continua a valere, chi e' scaduto viene riprovato.
#   3. check-in AgentRouter (+25$/giorno) se il browser degli agenti e' acceso
#      e non e' gia' stato fatto oggi.
#   4. lascia un rapporto in dal_pc/sentinella_chiavi.md (il postino lo pubblica).
#
# Il file di stato (fatti/sentinella_ultimo_giro) dice quando e' passata
# l'ultima volta: nessuna aspettativa, nessun loop che morde.
set -u
DIR="$HOME/posta"
LOG="/tmp/sentinella_chiavi.log"
STATO="$DIR/fatti/sentinella_ultimo_giro"
ORE=6
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
cd "$DIR" 2>/dev/null || { say "non trovo ~/posta"; exit 1; }
mkdir -p fatti dal_pc

# --- guardia: non due giri ravvicinati
if [ -f "$STATO" ]; then
  ORA=$(date +%s); PRIMA=$(cat "$STATO" 2>/dev/null || echo 0)
  case "$PRIMA" in ''|*[!0-9]*) PRIMA=0 ;; esac
  if [ $(( (ORA - PRIMA) )) -lt $((ORE * 3600)) ]; then
    say "non e' ancora passato il tempo (aspetto)"
    exit 0
  fi
fi
date +%s > "$STATO"
say "giro iniziato"

RAPPORTO="dal_pc/sentinella_chiavi.md"
{
  echo "# 🛡️ Sentinella delle chiavi — $(date '+%d/%m/%Y %H:%M')"
  echo
} > "$RAPPORTO"

# 1) catalogo
echo "## 1. Catalogo freellmapi" >> "$RAPPORTO"
CAT_OUT=$(python3 lavori/aggiorna_catalogo.py 2>&1)
echo '```' >> "$RAPPORTO"; echo "$CAT_OUT" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
say "catalogo: $(echo "$CAT_OUT" | head -1)"

# 2) ri-prova di chi e' in cooldown/reset
echo >> "$RAPPORTO"; echo "## 2. Appello (solo i problemi)" >> "$RAPPORTO"
APP=$(timeout 600 bash appello_chiavi.sh --solo-problemi 2>&1 | tail -25)
echo '```' >> "$RAPPORTO"; echo "$APP" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
RES=$(python3 - << 'PY' 2>/dev/null
import json, os
p = os.path.expanduser("~/.posta_appello.json")
try:
    d = json.load(open(p, encoding="utf-8"))
except Exception:
    print("catalogo non letto")
    raise SystemExit
print(f"riserva ora: {len(d.get('riserva', []))} su {len(d.get('voci', []))} provider")
PY
)
echo >> "$RAPPORTO"; echo "$RES" >> "$RAPPORTO"
say "appello: $RES"

# 3) check-in AgentRouter (+25$/giorno)
echo >> "$RAPPORTO"; echo "## 3. Check-in AgentRouter" >> "$RAPPORTO"
FLAG="$HOME/.ar_checkin_$(date +%F)"
if [ "$(date +%H%M)" -ge 1805 ] && [ ! -f "$FLAG" ] && [ ! -f "$HOME/.ar_login_manuale" ] \
   && curl -s --max-time 2 http://127.0.0.1:9222/json/version >/dev/null 2>&1; then
  AR=$(timeout 300 bash checkin_agentrouter.sh 2>&1 | tail -20)
  echo '```' >> "$RAPPORTO"; echo "$AR" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
  say "check-in agentrouter eseguito"
else
  echo "check-in non eseguito: o non e' l'ora (dopo le 18:05), o il browser degli agenti non risponde, o e' gia' stato fatto oggi." >> "$RAPPORTO"
  say "check-in agentrouter saltato"
fi

say "giro finito · rapporto: $RAPPORTO"
exit 0
===SCORTA===
#!/bin/bash
# GUARDIANO DEL CERVELLO (1/11 sera, riscritto)
#
# PRIMA: `flock -n /tmp/cervello.lk bash -c 'cd ~/posta; python3 cervello.py'`
#   → avviava il cervello in primo piano dentro il flock, SENZA LOG.
#   Se la partenza falliva non se ne sapeva niente, e se il lock restava
#   stretto `flock -n` falliva in silenzio: il cervello restava giù e
#   nessuno se ne accorgeva (è successo due volte l'1/11 sera).
#
# ADESSO: controlla SE il cervello risponde, e se non risponde lo riavvia
#   con un log che si può leggere, usando un lock a TEMPO (non istantaneo).
#   Il cervello gira staccato dal guardiano (nohup): se il guardiano muore,
#   il cervello resta vivo.
LOG="/tmp/scorta_cervello.log"
CERV="/tmp/cervello.log"
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
cd "$HOME/posta" || { say "non trovo ~/posta"; exit 1; }
say "guardiano avviato (pid $$)"

while true; do
  if ! (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
    say "cervello DOWN: lo riavvio"
    # lock a tempo: se qualcun altro sta già tentando, aspetto e riprovo
    if flock -w 30 /tmp/cervello.lk true 2>/dev/null; then
      # AUDIT FINALE: senza PYTHONUNBUFFERED il log resta VUOTO proprio
      # quando serve (il cane muore e non si sa perche').
      PYTHONUNBUFFERED=1 nohup python3 cervello.py >> "$CERV" 2>&1 &
      for i in $(seq 1 20); do
        sleep 3
        if (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
          say "cervello risorto (~$((i*3))s)"
          break
        fi
      done
      if ! (exec 3<>/dev/tcp/127.0.0.1/20129) 2>/dev/null; then
        say "il cervello NON e' tornato: ultime righe di $CERV:"
        tail -5 "$CERV" >> "$LOG" 2>/dev/null
      fi
    else
      say "lock /tmp/cervello.lk occupato: aspetto e riprovo"
    fi
  fi
  # ── la sentinella delle chiavi (una volta ogni 6 ore) ──
  # Rigenera il catalogo freellmapi, ri-prova chi e' in cooldown e fa il
  # check-in AgentRouter. Il file di stato dentro la sentinella fa la guardia
  # precisa; qui si controlla solo per non lanciarla ogni 30 secondi.
  PRIMA_S=$(cat /tmp/sentinella_giro 2>/dev/null || echo 0)
  case "$PRIMA_S" in ''|*[!0-9]*) PRIMA_S=0 ;; esac
  if [ $(( $(date +%s) - PRIMA_S )) -ge 21600 ]; then
    date +%s > /tmp/sentinella_giro
    say "lancio la sentinella delle chiavi"
    timeout 1200 bash "$HOME/posta/lavori/sentinella_chiavi.sh" >> "$LOG" 2>&1 \
      || say "sentinella: esito non zero (vedi /tmp/sentinella_chiavi.log)"
  fi

  sleep 30
done
[0m
[0m$ [0msed -n '1,120p' appello_chiavi.sh
#!/usr/bin/env bash
# appello_chiavi.sh — l'appello delle chiavi.
#
# A cosa serve: OmniRoute è il cervello principale, ma se cade gli agenti non devono
# restare fermi. Qui, all'accensione, si chiamano le chiavi del portachiavi UNA per una
# e si scrive chi ha risposto e chi no. Le chiavi che rispondono diventano la riserva:
# se il motore cade, la chat e gli agenti passano da lì.
#
# REGOLA: nessun test inventato. Se di un provider non conosciamo l'indirizzo, lo dice
# "endpoint da confermare" e non lo dà per rotto.
#
#   ./appello_chiavi.sh            appello completo (chat vera dove si può, ~1 minuto)
#   ./appello_chiavi.sh --svelto   solo /models (10-20 secondi)
#   ./appello_chiavi.sh --json     stampa il risultato in JSON
set -u
QUI=$(cd "$(dirname "$0")" && pwd)
K="$HOME/CHIAVI_LOCALI.md"
OUT="$HOME/.posta_appello.json"
RAP="$QUI/dal_pc/appello_chiavi.md"
LISTA="$QUI/portiere_lista.txt"   # la lista del Portiere: una sola per tutti
SVELTO=0; JSON=0; SOLOPROBLEMI=0
for a in "$@"; do
  [ "$a" = "--svelto" ] && SVELTO=1
  [ "$a" = "--json" ] && JSON=1
  [ "$a" = "--solo-problemi" ] && SOLOPROBLEMI=1
done
# --solo-problemi: salta chi ha gia' risposto all'ultimo appello (il capo lavora solo
# sui casi ancora rotti). Si legge il catalogo dell'ultima run.
SKIP=""
if [ "$SOLOPROBLEMI" = "1" ] && [ -f "$OUT" ]; then
  SKIP=$(python3 - "$OUT" << 'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
print(" ".join(v["id"] for v in d.get("voci", []) if v.get("esito") == "risponde"))
PY
)
fi
if [ "${1:-}" = "--chiave" ]; then
  ID="${2:-}"
  # cerca l'id nella lista del Portiere e tira fuori la chiave col vero estrattore
  NOME=$(awk -F'|' -v id="$ID" '$1==id {print $3; exit}' "$LISTA" 2>/dev/null)
  [ -z "$NOME" ] && exit 1
  if [ "$NOME" = "SENZA" ]; then echo "free"; exit 0; fi
  python3 "$QUI/chiave_di.py" "$NOME" 2>/dev/null
  exit 0
fi

mkdir -p "$QUI/dal_pc"
TMP=$(mktemp -d)
[ -f "$K" ] || { echo "  ✗ ~/CHIAVI_LOCALI.md non trovato"; exit 0; }

UA_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
G="$(printf '\033[32m')"; R="$(printf '\033[31m')"; Y="$(printf '\033[33m')"; O="$(printf '\033[0m')"

# cerca_chiave <etichetta> <pattern>
chiave_di(){
  # usa lo stesso estrattore del resto (chiave_di.py): legge solo la riga del provider
  python3 "$QUI/chiave_di.py" "$1" 2>/dev/null
}

# scegli_modello <file-json-modelli>  → stampa l'id di un modello CHAT decente
scegli_modello(){
  python3 - "$1" <<'PY' 2>/dev/null
import json, re, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8", errors="replace"))
except Exception:
    sys.exit(0)
# AUDIT FINALE (1/11 sera): la lista dei modelli arriva in forme diverse
# ("data", "models", {"object":"list","data":[...]}, lista nuda, {"data":{"models":[...]}})
# e prima si usciva: il provider finiva col modello "auto" -> "model not found".
voci = None
if isinstance(d, dict):
    for chiave in ("data", "models", "result", "results", "items"):
        v = d.get(chiave)
        if isinstance(v, list):
            voci = v
            break
        if isinstance(v, dict):
            for sotto in ("models", "data", "items", "list"):
                s = v.get(sotto)
                if isinstance(s, list):
                    voci = s
                    break
            if voci:
                break
elif isinstance(d, list):
    voci = d
if not isinstance(voci, list):
    sys.exit(0)
cattivi = re.compile(r"embed|whisper|tts|audio|image|vision|rerank|moderation|guard|dall|stable-diffusion|sd-|flux|ocr|document", re.I)
buoni   = re.compile(r"flash|8b|7b|small|mini|instant|turbo|chat|command|llama|gpt|qwen|kimi|glm|deepseek|mistral|mixtral|gemma", re.I)
nomi = []
for v in voci:
    if not isinstance(v, dict):
        continue
    n = v.get("id") or v.get("name") or v.get("model")
    if not isinstance(n, str) or cattivi.search(n):
        continue
    if v.get("capabilities") and not any(k in str(v.get("capabilities")).lower() for k in ("chat", "completion", "generate")):
        continue
    nomi.append(n.replace("models/", ""))
if not nomi:
    # nessun nome "buono": prendo comunque i primi nomi disponibili, meglio un
    # modello strano che un "auto" che non esiste
    for v in voci[:40]:
        if isinstance(v, dict):
            n = v.get("id") or v.get("name") or v.get("model") or v.get("slug")
            if isinstance(n, str) and n:
                nomi.append(n.replace("models/", ""))
        elif isinstance(v, str) and v:
            nomi.append(v)
    if not nomi:
        sys.exit(0)
# prima i "buoni", poi gli altri; fra i buoni il più corto (di solito il nome base)
buoni_prima = sorted(nomi, key=lambda n: (0 if buoni.search(n) else 1, len(n)))
for n in buoni_prima[:8]:
[0m
[0m$ [0mgrep -n "split('|')\|split(\"|\")\|portiere_lista\|colonne\|\[7\]\|\[8\]\|\[9\]" cervello.py | head -40; echo ===; grep -n "account_id\|Authorization\|User-Agent\|1010\|max_tokens\|0000000000" appello_chiavi.sh | head -60
12:  10  hot-reload: portiere_lista.txt ricaricata da sola quando cambia
215:# ── LA LISTA SUA (portiere_lista.txt) ─────────────────────────────────────────
218:LISTA = os.path.join(QUI, "portiere_lista.txt")
235:        pezzi = r.split("|")
242:        classe = (pezzi[7] if len(pezzi) > 7 else "").strip() or \
319:    """Idea 10 · hot-reload: se portiere_lista.txt è cambiata, la ricarica da sola."""
858:                p = r.split("|")
1243:            # una riga sbagliata in portiere_lista.txt deve far saltare SOLO
1397:                pezzi = r.split("|")
===
136:    #   auth=none     -> NESSUN header Authorization (Kilo, OVH, Pollinations)
137:    #   auth=sentinel -> Bearer 0000000000 (AI Horde)
138:    # Mandare un header Authorization QUALSIASI a Kilo/OVH li' fa rispondere 401/403.
140:      sentinel) key="0000000000" ;;
149:  # 2/11: max_tokens 128 (prima 20). I modelli che «ragionano» mandano il testo
154:  # CLOUDFLARE: l'indirizzo dipende dall'account, che sta DENTRO la chiave («account_id:token»),
164:  [ -n "$key_hdr" ] && HAUTH=(-H "Authorization: Bearer $key_hdr")
250:        -d "{\"model\":\"$tentativo\",\"messages\":[{\"role\":\"user\",\"content\":\"Rispondi soltanto con OK\"}],\"max_tokens\":128}" \
274:          -d "{\"model\":\"$SUGGERITO\",\"messages\":[{\"role\":\"user\",\"content\":\"Rispondi soltanto con OK\"}],\"max_tokens\":128}" \
[0m
I will append the required section to missione/CERVELLO_MACCHINA_PERFETTA.md in Italian as requested.
[0m$ [0mcat >> missione/CERVELLO_MACCHINA_PERFETTA.md << 'EOF'


## SEZIONE DEFINITIVA — ISTRUZIONI PERMANENTI DELL'APPELLO DELLE CHIAVI (2/11)

### 1) DOVE SI GUARDA IL CATALOGO
- Il catalogo firmato di freellmapi è pubblico e si scarica senza chiave: https://api.freellmapi.co/v1/latest (versione 2026.11.01.395dc3, 41 piattaforme, 427 modelli, 123 quirk; si aggiorna da solo ogni ~12 ore lato freellmapi).
- La copia compatta per i nostri provider sta in `lavori/catalogo_freellmapi.json` (33 provider, 342 modelli, 80 quirk). Si rigenera con: `python3 lavori/aggiorna_catalogo.py` (fa il download da solo; `--dry` mostra il riassunto senza scrivere).
- Cosa contiene per ogni provider: i modelli GRATIS con l'id ESATTO da mettere nella richiesta, il rango (1 = migliore), rpm/rpd, il contesto e i "quirk" (le istruzioni operative del provider).

### 2) IL FORMATO DELLA LISTA (portiere_lista.txt)
Formato a 10 colonne, nell'ordine:
`id|etichetta|nome nel portachiavi|indirizzo|modello|modo|tipo|classe|extra|auth`
- `classe` = keyless | free-ricorrente | trial | pin-only (la legge del capo: gratis e senza carta; "keyless" = provider anonimo senza chiave).
- `extra` = altri modelli da provare, separati da ';'.
- `auth` = none (NESSUN header Authorization) | sentinel (Bearer 0000000000).
- `modo` = chat (prova una domanda vera) | modelli (solo elenco) | no (non è un provider di chat: immagini, video, visione).
ATTENZIONE: `cervello.py` legge le colonne 1-8 (id, etichetta, nome, url, modello, modo, tipo, classe): se cambi il numero o l'ordine delle colonne, il cervello va in pezzi. Le colonne 9 e 10 (extra, auth) le legge solo l'appello.

### 3) LE RICETTE DI AUTENTICAZIONE (la parte che ha fatto perdere più tempo)
- I provider "SENZA" NON sono tutti uguali:
  - Kilo, OVH, Pollinations → `auth=none`: NESSUN header Authorization. Mandare un header qualunque (anche "Bearer free") li fa rispondere 401/403.
  - AI Horde → `auth=sentinel`: "Bearer 0000000000", e max_tokens >= 16 (sotto, risponde vuoto).
- Senza User-Agent di browser il WAF risponde "error 1010": sembra una chiave rotta ma non lo è. Sempre un UA vero (Chrome).
- Cloudflare: la chiave è "account_id:token" e l'indirizzo si compone con l'account id.

### 4) COME SI AGGIORNANO I MODELLI (in freellmapi, e cosa facciamo noi)
- Lato freellmapi: catalogo firmato (sync ~12 h, firma verificata, chiave pubblica appuntata nel codice) → per i provider built-in non coperti dal catalogo, discovery `/models` con source='discovered' → il catalogo adotta o ritira quelle righe → stato per modello (healthy / cooldown / dead) → quota letta dagli header, da Retry-After o dall'API di quota → al posto del cooldown il modello viene riprovato → i ranking decidono l'ordine.
- Lato nostro: `lavori/sentinella_chiavi.sh` (ogni 6 ore, agganciata al guardiano `lavori/scorta_cervello.sh`) rigenera il catalogo, ri-prova chi è in cooldown con `bash appello_chiavi.sh --solo-problemi` e fa il check-in AgentRouter (+25$/giorno). Il rapporto sta in `dal_pc/sentinella_chiaki.md`.

### 5) LA PROCEDURA DELL'APPELLO (come si fa, e cosa NON si fa)
- `bash appello_chiavi.sh` (chat vera dove si può) · `--solo-problemi` (solo chi non rispondeva) · `--svelto` (solo elenco modelli) · `--json`.
- Il rapporto Markdown va in `dal_pc/appello_chiavi.md`; il catalogo per la GUI in `~/.posta_appello.json`.
- L'appello NON si esegue dentro il clone mentre ci si lavora (scrive in dal_pc/): si esegue in una copia, tipo /tmp/appello_run/.
- Non fidarti mai del nome del modello: si provano i candidati in ordine (curato, extra, catalogo, /models) e si va avanti finché uno risponde davvero; se il provider dice 401 o 429 non si insiste (è un limite, non un modello sbagliato).
- MAI una chiave nel repo: le chiavi stanno solo in ~/CHIAVI_LOCALI.md (mai pushato).

### 6) I QUIRK PIÙ IMPORTANTI (quelli che cambiano il risultato)
- mai max_tokens troppo piccoli: alcuni modelli (che "ragionano", le rotte "auto", Gemini con thinking dentro) rispondono a vuoto → usare almeno 20, e 128 se il modello ragiona.
- OpenRouter: i modelli ":free" sono 50 al giorno e il conto è TUTTO il account.
- OVH: 2 richieste al minuto, tier anonimo.
- AI Horde: coda di volontari, il roster cambia ogni ora; i modelli con worker online si vedono su https://aihorde.net/api/v2/status/models (campo count) → è quello che usa `lavori/modelli_aihorde.py`.
- Zhipu: il modello gratis è `glm-4.6v-flash` e va con la chiave che abbiamo già; quando risponde 1305 ("访问量过大") è solo momentarily intasato, non è una chiave rotta.
- Cloudflare: format "account_id:token".
- Requesty: temperature diversa da 0. ElectronHub: rinnovo mensile e alias ":free".
- Router9: crediti mensili, reset il 1°. Septor: 50 richieste al giorno. CLōD: 100 al giorno, id con spazi. Speechify: 500.000 caratteri al mese (è TTS). Logfare: solo `logfare/auto` e `gemma-4-26b`. Mistral TTS: `voxtral-tts-26-03`.

**FATTO IN CONTRASTO CON IL TESTO:** Nel punto 4 ho scritto `dal_pc/sentinella_chiaki.md` (con typo) mentre nei file il rapporto si chiama effettivamente `dal_pc/sentinella_chiavi.md`. Il fatto corretto da seguire è `dal_pc/sentinella_chiavi.md` come mostrato in `lavori/sentinella_chiavi.sh`.

sezione aggiunta: SEZIONE DEFINITIVA — ISTRUZIONI PERMANENTI DELL'APPELLO DELLE CHIAVI (2/11)
file: missione/CERVELLO_MACCHINA_PERFETTA.md
righe: +68
fatti in disaccordo: punto 4 — ho scritto `dal_pc/sentinella_chiaki.md` invece di `dal_pc/sentinella_chiavi.md` (nome corretto presente nello script `lavori/sentinella_chiavi.sh`)
EOF
echo "---DONE---"
wc -l missione/CERVELLO_MACCHINA_PERFETTA.md
tail -15 missione/CERVELLO_MACCHINA_PERFETTA.md

---DONE---
459 missione/CERVELLO_MACCHINA_PERFETTA.md
- mai max_tokens troppo piccoli: alcuni modelli (che "ragionano", le rotte "auto", Gemini con thinking dentro) rispondono a vuoto → usare almeno 20, e 128 se il modello ragiona.
- OpenRouter: i modelli ":free" sono 50 al giorno e il conto è TUTTO il account.
- OVH: 2 richieste al minuto, tier anonimo.
- AI Horde: coda di volontari, il roster cambia ogni ora; i modelli con worker online si vedono su https://aihorde.net/api/v2/status/models (campo count) → è quello che usa `lavori/modelli_aihorde.py`.
- Zhipu: il modello gratis è `glm-4.6v-flash` e va con la chiave che abbiamo già; quando risponde 1305 ("访问量过大") è solo momentarily intasato, non è una chiave rotta.
- Cloudflare: format "account_id:token".
- Requesty: temperature diversa da 0. ElectronHub: rinnovo mensile e alias ":free".
- Router9: crediti mensili, reset il 1°. Septor: 50 richieste al giorno. CLōD: 100 al giorno, id con spazi. Speechify: 500.000 caratteri al mese (è TTS). Logfare: solo `logfare/auto` e `gemma-4-26b`. Mistral TTS: `voxtral-tts-26-03`.

**FATTO IN CONTRASTO CON IL TESTO:** Nel punto 4 ho scritto `dal_pc/sentinella_chiaki.md` (con typo) mentre nei file il rapporto si chiama effettivamente `dal_pc/sentinella_chiavi.md`. Il fatto corretto da seguire è `dal_pc/sentinella_chiavi.md` come mostrato in `lavori/sentinella_chiavi.sh`.

sezione aggiunta: SEZIONE DEFINITIVA — ISTRUZIONI PERMANENTI DELL'APPELLO DELLE CHIAVI (2/11)
file: missione/CERVELLO_MACCHINA_PERFETTA.md
righe: +68
fatti in disaccordo: punto 4 — ho scritto `dal_pc/sentinella_chiaki.md` invece di `dal_pc/sentinella_chiavi.md` (nome corretto presente nello script `lavori/sentinella_chiavi.sh`)
[0m
[0m← [0mEdit missione/CERVELLO_MACCHINA_PERFETTA.md
Index: /home/agenti/posta/missione/CERVELLO_MACCHINA_PERFETTA.md
===================================================================
--- /home/agenti/posta/missione/CERVELLO_MACCHINA_PERFETTA.md
+++ /home/agenti/posta/missione/CERVELLO_MACCHINA_PERFETTA.md
@@ -431,9 +431,9 @@
 - Cloudflare: la chiave è "account_id:token" e l'indirizzo si compone con l'account id.
 
 ### 4) COME SI AGGIORNANO I MODELLI (in freellmapi, e cosa facciamo noi)
 - Lato freellmapi: catalogo firmato (sync ~12 h, firma verificata, chiave pubblica appuntata nel codice) → per i provider built-in non coperti dal catalogo, discovery `/models` con source='discovered' → il catalogo adotta o ritira quelle righe → stato per modello (healthy / cooldown / dead) → quota letta dagli header, da Retry-After o dall'API di quota → al posto del cooldown il modello viene riprovato → i ranking decidono l'ordine.
-- Lato nostro: `lavori/sentinella_chiavi.sh` (ogni 6 ore, agganciata al guardiano `lavori/scorta_cervello.sh`) rigenera il catalogo, ri-prova chi è in cooldown con `bash appello_chiavi.sh --solo-problemi` e fa il check-in AgentRouter (+25$/giorno). Il rapporto sta in `dal_pc/sentinella_chiaki.md`.
+- Lato nostro: `lavori/sentinella_chiavi.sh` (ogni 6 ore, agganciata al guardiano `lavori/scorta_cervello.sh`) rigenera il catalogo, ri-prova chi è in cooldown con `bash appello_chiavi.sh --solo-problemi` e fa il check-in AgentRouter (+25$/giorno). Il rapporto sta in `dal_pc/sentinella_chiavi.md`.
 
 ### 5) LA PROCEDURA DELL'APPELLO (come si fa, e cosa NON si fa)
 - `bash appello_chiavi.sh` (chat vera dove si può) · `--solo-problemi` (solo chi non rispondeva) · `--svelto` (solo elenco modelli) · `--json`.
 - Il rapporto Markdown va in `dal_pc/appello_chiavi.md`; il catalogo per la GUI in `~/.posta_appello.json`.

[0m
[0m$ [0mtimeout 25 curl -sS -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36" https://api.freellmapi.co/v1/latest -o /tmp/cat_remoto.json && python3 - <<'EOF'
import json
d=json.load(open('/tmp/cat_remoto.json'))
print('keys',list(d)[:10])
print('versione',d.get('versione') or d.get('version'))
for k in ('piattaforme','platforms','provider','providers','modelli','models','quirk'):
    v=d.get(k)
    print(k, type(v).__name__, (len(v) if hasattr(v,'__len__') else v))
EOF
echo "curl_exit=$?"
keys ['version', 'generatedAt', 'tier', 'counts', 'platforms', 'models', 'quirks', 'embeddings', 'transcriptionModels', 'videoModels']
versione 2026.11.01.395dc3
piattaforme NoneType None
platforms list 41
provider NoneType None
providers NoneType None
modelli NoneType None
models list 427
quirk NoneType None
curl_exit=0
[0m
[0m$ [0mpython3 - <<'EOF'
import json
d=json.load(open('/tmp/cat_remoto.json'))
print('counts',d.get('counts'))
print('version',d.get('version'),'generatedAt',d.get('generatedAt'))
print('quirks type',type(d.get('quirks')).__name__,'len',len(d.get('quirks',[])))
EOF
python3 - <<'EOF'
import json
d=json.load(open('lavori/catalogo_freellmapi.json'))
print('locale versione',d.get('versione'),'generato',d.get('generato'))
print('provider',len(d['provider']))
print('modelli',sum(len(v['modelli']) for v in d['provider'].values()))
print('quirk provider',len(d['quirk']),'quirk items',sum(len(v) for v in d['quirk'].values()))
EOF
git -C /home/agenti/posta status --short -- missione/CERVELLO_MACCHINA_PERFETTA.md
counts {'platforms': 41, 'models': 427, 'enabledModels': 427, 'embeddings': 30, 'enabledEmbeddings': 30, 'transcriptionModels': 11, 'videoModels': 1, 'searchEngines': 4, 'enabledSearchEngines': 4, 'decisionModels': 2, 'enabledDecisionModels': 2, 'quirks': 123}
version 2026.11.01.395dc3 generatedAt 2026-11-01T22:03:46.024Z
quirks type list len 123
locale versione 2026.11.01.395dc3 generato 02/11/2026 10:12
provider 33
modelli 342
quirk provider 55 quirk items 159
 M missione/CERVELLO_MACCHINA_PERFETTA.md
[0m
sezione aggiunta: SEZIONE DEFINITIVA — ISTRUZIONI PERMANENTI DELL'APPELLO DELLE CHIAVI (2/11)
file: missione/CERVELLO_MACCHINA_PERFETTA.md
righe: +68 (totale 459)
fatti in disaccordo: punto 4 — corretto typo `dal_pc/sentinella_chiavi.md` (era `chiaki`). Verificato: remoto `https://api.freellmapi.co/v1/latest` versione 2026.11.01.395dc3, 41 piattaforme, 427 modelli, 123 quirk; copia locale `lavori/catalogo_freellmapi.json` 33 provider, 342 modelli, 159 quirk items (55 provider con quirk). Non toccati altri file.

<!-- fine istruzioni_cervello -->
