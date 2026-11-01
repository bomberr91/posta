#!/usr/bin/env python3
"""cervello.py — il PORTIERE (motore di riserva, porta 20129).  [FASE 1]

Perché esiste: tutti gli agenti parlano con UNA porta sola. Questo programma
sta sulla 20129 e fa da portiere:

  - se OmniRoute (20128) è vivo  → passa tutto a lui;
  - se OmniRoute è morto         → usa le chiavi dell'appello (la riserva).

FASE 1 (31/10/2026) — cosa è stato aggiunto, con il numero dell'idea:
   6  modelli-politica: "auto" / "gratis" / "veloce" / "migliore"
  10  hot-reload: portiere_lista.txt ricaricata da sola quando cambia
  14  disabilitazione automatica del canale malato (pagella)
  17  castigo per (chiave, modello): un 429 riposa solo quel modello
  18  tassonomia errori: 404/410 pensionato · 429 breve/quota · 401/403 chiave
      · 413/contesto failover senza castigo · 5xx passeggero
  20  castighi e pagella PERSISTENTI su disco (portiere_stato.json)
  21  guardia solo-gratis: modelli a pagamento rifiutati
  22  quota giornaliera finita → la chiave riposa 1 ora
  25  timeout per richiesta (numeri collaudati, CONFIG)
  27  salute = tasso di successo (soglia 0.8), non solo errori secchi
  32  errore di contesto → failover alla catena, senza punire nessuno
  33  numeri LiteLLM collaudati + drop_params gentile (parametri sicuri passano)
  39  tassonomia del gratis: campo "classe" nella lista (keyless/free/trial)
  46  richieste banali (titoli, ping) risposte in casa: 0 token spesi
  50  log glass-box: ogni richiesta → riga JSON con rotta, modello, ms, esito
  52  --sonda: verifica le chiavi con GET /models (costo zero token)
  58  sessione stabile: x-opencode-session inoltrato/generato per agente
  (23/34/35: motori keyless nuovi → vanno nella LISTA, vedi README_FASE1)

Aggiunte del saggio: cooldown statici, retry con jitter, log chiari, timeout brevi.

FASE 2 · BLOCCO 1 (31/10 pomeriggio) — pagella adulta + retry furbo:
   5  pagella = salute + velocita' (l'ordine della riserva lo decide lei)
   9  interruttore: 3 errori DI FILA → il canale riposa 60s
  15  il voto e' per chiave (ogni riga della lista ha la sua pagella)
  19  classifica latenze con SCADENZA 10 min (poi si torna all'appello)
  24  retry esponenziale con jitter SOLO sui codici giusti (429/5xx/rete; mai 400/401/404)
  51  429 intelligenti: se il provider manda Retry-After, obbediamo (max 5 min)
  60  velocita' = media mobile EWMA (70% storia, 30% ultima prova)
  61  periodo di grazia: niente giudizi sotto le 5 prove

FASE 2 · BLOCCO 2 — chiavi e quote:
   7  bilanciamento: stessa fascia di velocita' (250ms) → vince chi ha lavorato meno
  12  rotazione a quota esaurita: la gemella subentra da sola (castigo + ordine)
  26  conto per agente (chi consuma quanto, al giorno) + tetto opzionale
  31  routing per consumo osservato (il contatore comanda dentro la fascia)
  43  contatore quote per chiave con azzeramento giornaliero + countdown castighi
  44  multi-account: due righe in lista stesso indirizzo = round-robin automatico

  python3 cervello.py            resta acceso sulla porta 20129
  python3 cervello.py --stato    dice chi sta rispondendo adesso
  python3 cervello.py --sonda    controlla le chiavi senza spendere token
  python3 cervello.py --perdona  amnistia: azzera tutti i castighi
  python3 cervello.py --scopri   scopre i modelli di ogni provider (catalogo)
  python3 cervello.py --statistiche  il riassunto del lavoro (rotte, errori, agenti)

FASE 2 · BLOCCO 4 — finezze:
   3  cache locale: stessa domanda entro 10 min = risposta subito, 0 token
  38  regole per agente (portiere_regole.txt): politiche permesse + tetto
  47  tools inoltrati alla riserva + parser euristico dei tool-call nel testo
  48  freno preventivo (portiere_quote.txt): al_minuto / al_giorno / distanza
  53  --statistiche: il riassunto del glass-box
   +  igiene: risposta vuota dal motore → si passa alla riserva

FASE 3 — le ultime 4 idee del quaderno (moduli gemelli compressione.py + per_agente.py):
   1  system grassi → TOON · storia chilometrica → taglio protetto (mai coi tool-call)
   2  tools alleggeriti per la riserva (solo required, descrizioni a 110 char)
  13+16  profili per-agente (portiere_profili.json): max_tokens, temperature,
         politica di default, compressione on/off — hot-reload, default robusti

FASE 2 · BLOCCO 3 — scoperta e nomi:
   4  sessione appiccicosa: stesso agente → stesso provider per 15 min (prefix-cache)
  11  punteggio complessita': richiesta lunga o con codice → l'auto sceglie i FORTI
  30  gruppi-fallback con nome (portiere_gruppi.txt): "squadra = pid, pid/modello"
  36  --scopri: catalogo dei modelli dichiarati da ogni provider (timeout brevi)
  45  combo con nome: chiedi il nome del gruppo come modello
  55  catalogo != accesso: la lista e' un indizio, la prova vera e' la risposta
   +  migliore/veloce passano dal motore nuovo con auto/best-reasoning|fast
"""
import hashlib
import json
import os
import random
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# ── FASE 3: i due moduli gemelli (se mancano, il Portiere va come prima) ────
try:
    from compressione import alleggerisci_tools, comprimi_system, taglia_storia
    from per_agente import carica_profili, profilo_di, applica_profilo
    F3_OK = True
except Exception:
    F3_OK = False

QUI = os.path.dirname(os.path.abspath(__file__))
MOTORE = "http://127.0.0.1:20128/v1"
PORTA = 20129
APPELLO = os.path.join(os.path.expanduser("~"), ".posta_appello.json")

# ── FASE 1 · CONFIG: i numeri collaudati (idea 33 + saggio: statici, niente tuning) ──
CONFIG = {
    "cooldown_breve": 45,        # 429 semplice: quel (chiave,modello) riposa 45s
    "cooldown_quota": 3600,      # quota giornaliera finita: la chiave riposa 1 ora (idea 22)
    "cooldown_chiave": 1800,     # 401/403: chiave rifiutata, riposa 30 min
    "cooldown_pensionato": 21600,# 404/410: modello pensionato, 6 ore per tutti
    "cooldown_passeggero": 30,   # 5xx: incidente passeggero
    "timeout_riserva": 60,       # secondi per ogni provider di riserva (idea 25)
    "timeout_motore": 180,       # secondi per OmniRoute
    "soglia_successo": 0.8,      # sotto questo tasso il canale è malato (idea 27)
    "min_prove": 5,              # prima di giudicare servono almeno 5 prove
    "riposo_malato": 120,        # il canale malato riprova ogni 2 minuti
    "intercetta_banali": True,   # idea 46 (metti False per spegnere)
    "solo_gratis": True,         # idea 21: guardia anti-spesa
    # — FASE 2 · BLOCCO 1 —
    "max_tentativi": 5,          # idea 24: al massimo 5 tentativi totali per richiesta
    "retry_stesso": 1,           # idea 24: 1 ritento sullo STESSO provider (poi si cambia)
    "backoff_base": 2,           # idea 24: attesa 2^n secondi prima del ritento...
    "backoff_max": 8,            # ...ma mai piu' di 8s (+ jitter del saggio)
    "latenza_scadenza": 600,     # idea 19: la velocita' osservata vale 10 minuti
    "fila_ko_max": 3,            # idea 9: 3 errori DI FILA → interruttore
    "cooldown_fila": 60,         # idea 9: ...e il canale riposa 60s
    "retry_after_max": 300,      # idea 51: rispetta Retry-After, ma mai oltre 5 min
    # — FASE 2 · BLOCCO 2 —
    "fascia_ms": 250,            # idea 7/31: provider nella stessa fascia di velocita'
                                 #   (250ms) si alternano per consumo, round-robin
    "tetto_agente": 0,           # idea 26: tetto richieste/giorno per agente (0 = spento)
    # — FASE 2 · BLOCCO 3 —
    "sticky_scadenza": 900,      # idea 4: la sessione resta fedele al suo provider 15 min
    "complessita_soglia": 4000,  # idea 11: sopra questi caratteri (o con codice) l'auto
                                 #   preferisce i modelli FORTI
    "scoperta_timeout": 6,       # idea 36: timeout BREVI sulla scoperta (il saggio)
    # — FASE 2 · BLOCCO 4 —
    "cache_ttl": 600,            # idea 3: risposta identica entro 10 min = cache (0 = spenta)
    "cache_max": 200,            # idea 3: quante risposte tenere in pancia
    # — SENTINELLA QUOTE (31/10, 2 occhi): fonti sorvegliate una volta al giorno —
    "sentinella_repos": ["CYBIRD-D/FREE-LLM-API-Provider",
                         "open-free-llm-api/awesome-freellm-apis"],
    "sentinella_ore": 24,        # un controllo al giorno, a costo zero (0 = spenta)
    # — FASE 3 (idee 1-2: compressione · 13+16: profili per-agente) —
    "comprimi_riserva": True,    # la dieta vale SOLO per la riserva (il motore fa da se')
    "system_min_car": 1200,      # system sotto questa taglia: non si tocca
    "storia_max_car": 24000,     # storia oltre questa taglia: si taglia (mai con tool-call in mezzo)
}

# aggancio al motore nuovo (3.8.52): le nostre politiche sulle sue auto/best-*
MAPPA_MOTORE = {"migliore": "auto/best-reasoning", "veloce": "auto/best-fast"}

# ── LA LISTA SUA (portiere_lista.txt) ─────────────────────────────────────────
# formato: id|etichetta|nome portachiavi|indirizzo API|modello|modo|tipo|classe
# classe (idea 39): keyless · free-ricorrente · trial · pin-only (vuoto = free-ricorrente)
LISTA = os.path.join(QUI, "portiere_lista.txt")
_lista_mtime = [0.0]


def carica_lista():
    """Legge la lista del Portiere. Ritorna (base, etichette, nomi, modi, tipi, classi)."""
    base, etichette, nomi, modi, tipi, classi = {}, {}, {}, {}, {}, {}
    try:
        righe = open(LISTA, encoding="utf-8", errors="replace").read().splitlines()
    except Exception:
        return base, etichette, nomi, modi, tipi, classi
    for riga in righe:
        r = riga.strip()
        if not r or r.startswith("#"):
            if r.startswith("##"):
                break                      # da qui in poi sono i "da confermare"
            continue
        pezzi = r.split("|")
        if len(pezzi) < 5:
            continue
        pid, eti, nome, url = pezzi[0], pezzi[1], pezzi[2], pezzi[3]
        modello = pezzi[4] if len(pezzi) > 4 else "auto"
        modo = pezzi[5] if len(pezzi) > 5 else "chat"
        tipo = (pezzi[6] if len(pezzi) > 6 else "chat").strip() or "chat"
        classe = (pezzi[7] if len(pezzi) > 7 else "").strip() or \
                 ("keyless" if nome == "SENZA" else "free-ricorrente")
        base[pid] = (url.rstrip("/"), modello)
        etichette[pid] = eti
        nomi[pid] = nome
        modi[pid] = modo
        tipi[pid] = tipo
        classi[pid] = classe
    return base, etichette, nomi, modi, tipi, classi


BASE, ETICHETTE, NOMI, MODI, TIPI, CLASSI = carica_lista()

# ── FASE 2 · B3 · GRUPPI E COMBO CON NOME (idee 30+45) ───────────────────────
# file portiere_gruppi.txt, una riga per gruppo:  nome = pid, pid/modello, ...
# chiedi "nome" come modello → si provano i membri in quell'ordine.
GRUPPI_FILE = os.path.join(QUI, "portiere_gruppi.txt")
GRUPPI = {}
_gruppi_mtime = [0.0]


def carica_gruppi():
    g = {}
    try:
        for riga in open(GRUPPI_FILE, encoding="utf-8", errors="replace").read().splitlines():
            r = riga.strip()
            if not r or r.startswith("#") or "=" not in r:
                continue
            nome, _, resto = r.partition("=")
            membri = []
            for m in resto.split(","):
                m = m.strip()
                if not m:
                    continue
                pid, _, modello = m.partition("/")
                membri.append((pid.strip(), modello.strip() or None))
            if membri:
                g[nome.strip().lower()] = membri
    except Exception:
        pass
    return g


def ricarica_gruppi():
    global GRUPPI
    try:
        m = os.path.getmtime(GRUPPI_FILE)
    except Exception:
        GRUPPI = {}
        return
    if m != _gruppi_mtime[0]:
        _gruppi_mtime[0] = m
        GRUPPI = carica_gruppi()


# ── FASE 2 · B3 · CATALOGO SCOPERTO (idee 36+55) ─────────────────────────────
CATALOGO_FILE = os.path.join(QUI, "portiere_catalogo.json")


def catalogo_leggi():
    try:
        return json.load(open(CATALOGO_FILE, encoding="utf-8"))
    except Exception:
        return {}


def chi_ha_modello(nome_modello):
    """Dal catalogo scoperto: quali provider dichiarano quel modello.
    ATTENZIONE (idea 55): catalogo != accesso — e' solo un indizio, la prova
    vera resta la risposta (e ai bugiardi pensano i castighi)."""
    cat = catalogo_leggi()
    m = (nome_modello or "").lower()
    return [pid for pid, voci in cat.items()
            if pid in BASE and any(m == str(v).lower() for v in voci.get("modelli", []))]


def ricarica():
    """Idea 10 · hot-reload: se portiere_lista.txt è cambiata, la ricarica da sola."""
    global BASE, ETICHETTE, NOMI, MODI, TIPI, CLASSI
    try:
        m = os.path.getmtime(LISTA)
    except Exception:
        return
    if m != _lista_mtime[0]:
        _lista_mtime[0] = m
        BASE, ETICHETTE, NOMI, MODI, TIPI, CLASSI = carica_lista()
        logga(tipo="hot-reload", nota="lista ricaricata: %d provider" % len(BASE))


try:
    _lista_mtime[0] = os.path.getmtime(LISTA)
except Exception:
    pass


def indirizzo(pid, k):
    """Indirizzo e intestazioni per quel provider (Cloudflare ha un formato suo)."""
    url, _ = BASE[pid]
    UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) cervello/2.1"}
    if url == "SPECIALE-CLOUDFLARE":
        acc, _, tok = (k or "").partition(":")
        return ("https://api.cloudflare.com/client/v4/accounts/%s/ai/v1" % acc,
                dict(UA, Authorization="Bearer " + tok))
    return url, dict(UA, Authorization="Bearer " + k)

NOME = "Portiere"


def vivo(url, secondi=1):
    import socket
    da = url.split("//")[-1].split("/")[0]
    host, _, porta = da.partition(":")
    try:
        s = socket.create_connection((host, int(porta or 80)), timeout=secondi)
        s.close()
        return True
    except Exception:
        return False


# ── INTERRUTTORE DI INDIPENDENZA ─────────────────────────────────────────────
# Se esiste il file SOLO_CERVELLO.txt accanto a cervello.py, il Portiere IGNORA
# OmniRoute anche se acceso: fa tutto da solo con la riserva. Cancella il file
# e torna a usare il motore. Acceso/spento come una lampadina, zero riavvii.
SOLO_CERVELLO = os.path.join(QUI, "SOLO_CERVELLO.txt")


def motore_vivo():
    if os.path.exists(SOLO_CERVELLO):
        return False
    return vivo(MOTORE)


def appello():
    try:
        d = json.loads(open(APPELLO, encoding="utf-8").read())
        return d.get("voci", [])
    except Exception:
        return []


_cache_chiavi = {}


def chiave(pid):
    """La chiave di quel provider, dal portachiavi (chiave_di.py). SENZA = gratis."""
    if pid in _cache_chiavi and time.time() - _cache_chiavi[pid][0] < 600:
        return _cache_chiavi[pid][1]
    nome = NOMI.get(pid, "")
    if nome == "SENZA":
        _cache_chiavi[pid] = (time.time(), "free")
        return "free"
    k = ""
    if nome:
        try:
            p = subprocess.run(["python3", os.path.join(QUI, "chiave_di.py"), nome],
                               capture_output=True, text=True, timeout=20)
            k = (p.stdout or "").strip()
        except Exception:
            k = ""
    _cache_chiavi[pid] = (time.time(), k)
    return k


# ── FASE 1 · STATO PERSISTENTE: castighi e pagella (idee 17-22-27, 20) ───────
STATO_FILE = os.path.join(QUI, "portiere_stato.json")
STATO = {"castighi": {}, "pagella": {}}
_ultimo_salvataggio = [0.0]


def stato_carica():
    global STATO
    try:
        d = json.load(open(STATO_FILE, encoding="utf-8"))
        if isinstance(d, dict):
            STATO = d
    except Exception:
        pass
    STATO.setdefault("castighi", {})
    STATO.setdefault("pagella", {})


def stato_salva(forza=False):
    """Scrive su disco al massimo ogni 2 secondi (idea 20: sopravvive al riavvio)."""
    if not forza and time.time() - _ultimo_salvataggio[0] < 2:
        return
    _ultimo_salvataggio[0] = time.time()
    try:
        ora = time.time()
        STATO["castighi"] = {k: v for k, v in STATO["castighi"].items() if v > ora}
        json.dump(STATO, open(STATO_FILE, "w", encoding="utf-8"))
    except Exception:
        pass


def castiga(pid, modello, secondi, globale=False):
    """Idea 17: il castigo colpisce la coppia (chiave, modello), non tutta la chiave.
    modello=None → tutta la chiave. globale=True → quel modello per TUTTI (pensionato)."""
    if globale:
        k = "*|" + (modello or "")
    elif modello is None:
        k = pid + "|*"
    else:
        k = pid + "|" + modello
    STATO["castighi"][k] = time.time() + secondi
    stato_salva(forza=True)              # i castighi DEVONO sopravvivere al riavvio


def punito(pid, modello):
    c = STATO["castighi"]
    ora = time.time()
    for k in (pid + "|" + (modello or ""), pid + "|*", "*|" + (modello or "")):
        if c.get(k, 0) > ora:
            return True
    return False


def segna(pid, ok, ms=None):
    """Idee 27+5+60+9: pagella con tasso di successo E velocita' osservata (media
    mobile EWMA), piu' l'interruttore: 3 errori di fila → il canale riposa 60s.
    La memoria sbiadisce (dimezza a 50 prove). Idea 61: niente giudizi sotto le
    5 prove (periodo di grazia, gia' garantito da in_salute)."""
    p = STATO["pagella"].setdefault(pid, {"ok": 0, "ko": 0, "ultimo_ko": 0, "fila_ko": 0})
    p["ok" if ok else "ko"] += 1
    if ok:
        p["fila_ko"] = 0
        if ms is not None:                               # idea 60: EWMA della velocita'
            vecchio = p.get("ms_ewma")
            p["ms_ewma"] = int(ms) if vecchio is None else round(0.7 * vecchio + 0.3 * ms)
            p["ms_quando"] = time.time()
    else:
        p["ultimo_ko"] = time.time()
        p["fila_ko"] = p.get("fila_ko", 0) + 1
        if p["fila_ko"] >= CONFIG["fila_ko_max"]:        # idea 9: circuit breaker
            p["fila_ko"] = 0
            castiga(pid, None, CONFIG["cooldown_fila"] + random.randint(0, 10))
    if p["ok"] + p["ko"] > 50:
        p["ok"] //= 2
        p["ko"] //= 2
    stato_salva(forza=not ok)            # i voti negativi vanno su disco subito


def velocita(pid, altrimenti):
    """Idea 19: la velocita' osservata (EWMA) comanda, ma SCADE dopo 10 minuti:
    poi si torna ai tempi dell'appello. Niente thread di pulizia (avviso saggio
    su WSL1): la scadenza si controlla al momento della lettura."""
    p = STATO["pagella"].get(pid) or {}
    if p.get("ms_ewma") is not None and \
            time.time() - p.get("ms_quando", 0) < CONFIG["latenza_scadenza"]:
        return p["ms_ewma"]
    return altrimenti


def in_salute(pid):
    """Sotto soglia 0.8 (dopo almeno 5 prove) il canale è malato: riprova ogni 2 min."""
    p = STATO["pagella"].get(pid)
    if not p or p["ok"] + p["ko"] < CONFIG["min_prove"]:
        return True
    if p["ok"] / (p["ok"] + p["ko"]) >= CONFIG["soglia_successo"]:
        return True
    return time.time() - p.get("ultimo_ko", 0) > CONFIG["riposo_malato"]


def oggi():
    return time.strftime("%Y-%m-%d")


def conta_uso(pid, token=0):
    """Idea 43: contatore di consumo per chiave, azzerato ogni giorno (lazy, niente thread)."""
    u = STATO.setdefault("uso", {}).setdefault(pid, {})
    if u.get("giorno") != oggi():
        u.clear()
        u.update(giorno=oggi(), n=0, token=0)
    u["n"] += 1
    u["token"] += int(token or 0)
    stato_salva()


def uso_oggi(pid):
    u = (STATO.get("uso") or {}).get(pid) or {}
    return u.get("n", 0) if u.get("giorno") == oggi() else 0


def conta_agente(sess, token=0):
    """Idea 26: quanto lavora ogni agente, al giorno (per capire chi consuma)."""
    a = STATO.setdefault("agenti", {}).setdefault((sess or "ignoto")[:24], {})
    if a.get("giorno") != oggi():
        a.clear()
        a.update(giorno=oggi(), n=0, token=0)
    a["n"] += 1
    a["token"] += int(token or 0)
    stato_salva()


def agente_oltre(sess):
    """Idea 26: se il tetto per agente e' acceso e superato, si ferma qui."""
    tetto = CONFIG.get("tetto_agente") or 0
    if not tetto:
        return False
    a = (STATO.get("agenti") or {}).get((sess or "ignoto")[:24]) or {}
    return a.get("giorno") == oggi() and a.get("n", 0) >= tetto


def classifica_errore(codice, testo):
    """Idea 18 · tassonomia: ogni errore ha la sua medicina."""
    t = (testo or "").lower()
    if codice in (404, 410):
        return "pensionato"
    if codice == 413 or "context" in t or "too long" in t or "token limit" in t:
        return "contesto"
    if codice == 429 or codice == 402:    # 402 = "payment required" dei piani
        if any(s in t for s in ("day", "daily", "quota", "exceeded", "per-day")):
            return "quota"                # gratis a raffica (es. Pollinations)
        return "breve"
    if codice in (401, 403) or "unauthorized" in t or "no access" in t:
        return "chiave"
    if codice and codice >= 500:
        return "passeggero"
    return "altro"


# ── FASE 1 · LOG GLASS-BOX (idea 50 + logger del saggio) ─────────────────────
LOG_FILE = os.path.join(QUI, "portiere_log.jsonl")


def sentinella():
    """Una volta al giorno guarda se le FONTI delle quote (CYBIRD-D +
    awesome-freellm-apis/freellm.net) hanno pubblicato aggiornamenti.
    Niente thread: controllo pigro sul primo traffico utile della giornata."""
    if not CONFIG.get("sentinella_ore"):
        return
    st = STATO.setdefault("sentinella", {})
    if time.time() - st.get("controllo", 0) < CONFIG["sentinella_ore"] * 3600:
        return
    st["controllo"] = time.time()
    visti = st.setdefault("visti", {})
    if st.get("push_visto"):                              # migrazione dal 1° occhio
        visti.setdefault(CONFIG["sentinella_repos"][0], st.pop("push_visto"))
    avvisi = []
    for repo in CONFIG.get("sentinella_repos", []):
        try:
            req = urllib.request.Request("https://api.github.com/repos/" + repo,
                                         headers={"User-Agent": "Mozilla/5.0 cervello/2.1"})
            d = json.loads(urllib.request.urlopen(req, timeout=6).read().decode())
            push = (d.get("pushed_at") or "")[:10]
            if push and visti.get(repo) and push != visti[repo]:
                avvisi.append("%s (push %s)" % (repo.split("/")[-1], push))
            if push:
                visti[repo] = push
        except Exception:
            continue
    if avvisi:
        st["avviso"] = "fonti quote aggiornate: " + " · ".join(avvisi) + \
            " — ricontrollare portiere_quote.txt"
        logga(tipo="sentinella", nota=st["avviso"])
    stato_salva(forza=True)


def logga(**voce):
    """Una riga JSON per ogni evento: chi, cosa, rotta, quanto ci ha messo, esito."""
    voce["quando"] = time.strftime("%Y-%m-%d %H:%M:%S")
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(voce, ensure_ascii=False) + "\n")
        if os.path.getsize(LOG_FILE) > 3_000_000:
            righe = open(LOG_FILE, encoding="utf-8").read().splitlines()[-2000:]
            open(LOG_FILE, "w", encoding="utf-8").write("\n".join(righe) + "\n")
    except Exception:
        pass


# ── FASE 1 · RICHIESTE BANALI (idea 46): risposte in casa, 0 token ───────────
RE_TITOLO = re.compile(r"(generate|write|create|produce)[^.\n]{0,50}\btitle\b", re.I)


def risposta_locale(testo, perche):
    return {"id": "locale-%d" % int(time.time() * 1000), "object": "chat.completion",
            "created": int(time.time()),
            "model": "cervello/locale (%s: risposta in casa, 0 token)" % perche,
            "choices": [{"index": 0, "message": {"role": "assistant", "content": testo},
                         "finish_reason": "stop"}],
            "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0}}


def banale(payload):
    """Solo i casi SICURI: titoli di conversazione (max_tokens piccolo) e ping."""
    msgs = payload.get("messages") or []
    ultimo = ""
    for m in reversed(msgs):
        if m.get("role") == "user":
            ultimo = str(m.get("content", ""))
            break
    if ultimo.strip().lower() in ("ping", "test", "say ok"):
        return risposta_locale("OK", "ping")
    mt = payload.get("max_tokens")
    if not (isinstance(mt, int) and mt <= 120):
        return None                      # i titoli veri viaggiano con max_tokens piccolo
    testo = " ".join(str(m.get("content", ""))[:400] for m in msgs[:2] + msgs[-1:])
    if RE_TITOLO.search(testo) and len(testo) < 2000:
        parole = re.sub(r"[^\w\s\u00c0-\u00ff]", " ", ultimo).split()
        return risposta_locale(" ".join(parole[:6]) or "Conversazione", "titolo")
    return None


# ── FASE 2 · B4 · CACHE LOCALE (idea 3, versione onesta: esatta normalizzata) ──
# Stessa domanda, stessa risposta, entro 10 minuti: 0 token spesi.
# Niente cache se ci sono tools o temperature alta (risposte volutamente varie).
_CACHE = {}


def cache_chiave(payload):
    if not CONFIG["cache_ttl"] or payload.get("tools") or             (payload.get("temperature") or 0) > 0.3:
        return None
    base = json.dumps([payload.get("model", ""),
                       [[m.get("role"), " ".join(str(m.get("content", "")).split())]
                        for m in payload.get("messages") or []],
                       payload.get("max_tokens")], ensure_ascii=False)
    return hashlib.sha1(base.encode()).hexdigest()


def cache_leggi(k):
    if not k:
        return None
    v = _CACHE.get(k)
    if v and time.time() - v[0] < CONFIG["cache_ttl"]:
        d = json.loads(v[1])
        d["model"] = str(d.get("model", "")) + " (cache)"
        return d
    _CACHE.pop(k, None)
    return None


def cache_scrivi(k, d):
    if not k:
        return
    _CACHE[k] = (time.time(), json.dumps(d, ensure_ascii=False))
    while len(_CACHE) > CONFIG["cache_max"]:
        _CACHE.pop(min(_CACHE, key=lambda x: _CACHE[x][0]))


# ── FASE 2 · B4 · QUOTE PREVENTIVE (idea 48): frenare PRIMA del 429 ──────────
# file portiere_quote.txt:  pid|al_minuto|al_giorno|distanza_secondi  (0 = senza freno)
QUOTE_FILE = os.path.join(QUI, "portiere_quote.txt")
QUOTE = {}
_quote_mtime = [0.0]
_battiti = {}            # pid → ultimi istanti di chiamata (finestra 60s)


def ricarica_quote():
    global QUOTE
    try:
        m = os.path.getmtime(QUOTE_FILE)
    except Exception:
        QUOTE = {}
        return
    if m != _quote_mtime[0]:
        _quote_mtime[0] = m
        q = {}
        try:
            for riga in open(QUOTE_FILE, encoding="utf-8", errors="replace").read().splitlines():
                r = riga.strip()
                if not r or r.startswith("#"):
                    continue
                p = r.split("|")
                if len(p) >= 2:
                    q[p[0].strip()] = (int(p[1] or 0), int(p[2] or 0) if len(p) > 2 else 0,
                                       float(p[3] or 0) if len(p) > 3 else 0.0)
        except Exception:
            pass
        QUOTE = q


def freno(pid):
    """True = NON chiamare adesso questo provider (sarebbe sopra i suoi limiti)."""
    lim = QUOTE.get(pid)
    if not lim:
        return False
    al_min, al_giorno, distanza = lim
    ora = time.time()
    batt = [t for t in _battiti.get(pid, []) if ora - t < 60]
    _battiti[pid] = batt
    if al_min and len(batt) >= al_min:
        return True
    if distanza and batt and ora - batt[-1] < distanza:
        return True
    if al_giorno and uso_oggi(pid) >= al_giorno:
        return True
    return False


def batte(pid):
    _battiti.setdefault(pid, []).append(time.time())


# ── FASE 2 · B4 · REGOLE PER AGENTE (idea 38, disegno S4/otari in piccolo) ───
# file portiere_regole.txt:  inizio-id-agente = politiche:gratis,auto · tetto:200
REGOLE_FILE = os.path.join(QUI, "portiere_regole.txt")
REGOLE = {}
_regole_mtime = [0.0]


def ricarica_regole():
    global REGOLE
    try:
        m = os.path.getmtime(REGOLE_FILE)
    except Exception:
        REGOLE = {}
        return
    if m != _regole_mtime[0]:
        _regole_mtime[0] = m
        rg = {}
        try:
            for riga in open(REGOLE_FILE, encoding="utf-8", errors="replace").read().splitlines():
                r = riga.strip()
                if not r or r.startswith("#") or "=" not in r:
                    continue
                chi, _, resto = r.partition("=")
                regola = {}
                for pezzo in resto.split("·"):
                    pezzo = pezzo.strip()
                    if pezzo.startswith("politiche:"):
                        regola["politiche"] = [x.strip().lower() for x in
                                               pezzo[len("politiche:"):].split(",") if x.strip()]
                    elif pezzo.startswith("tetto:"):
                        regola["tetto"] = int(pezzo[len("tetto:"):].strip() or 0)
                if regola:
                    rg[chi.strip()] = regola
        except Exception:
            pass
        REGOLE = rg


def regola_di(sess):
    for chi, regola in REGOLE.items():
        if (sess or "").startswith(chi):
            return regola
    return None


# ── FASE 2 · B4 · PARSER TOOL-CALL EURISTICO (idea 47) ───────────────────────
def ripara_tool_call(d, payload):
    """Se l'agente aveva chiesto dei TOOLS e il modello ha risposto col JSON nel
    testo invece che nel campo giusto, lo rimettiamo al suo posto."""
    if not payload.get("tools"):
        return d
    msg = (d.get("choices") or [{}])[0].get("message", {})
    if msg.get("tool_calls") or not msg.get("content"):
        return d
    testo = msg["content"].strip()
    m = re.search(r"\{.*\}", testo, re.S)
    if not m:
        return d
    try:
        j = json.loads(m.group(0))
    except Exception:
        return d
    nome = j.get("name")
    argomenti = j.get("arguments", j.get("parameters"))
    if not nome or not isinstance(argomenti, (dict, str)):
        return d
    if isinstance(argomenti, dict):
        argomenti = json.dumps(argomenti, ensure_ascii=False)
    msg["tool_calls"] = [{"id": "rip-%d" % int(time.time() * 1000), "type": "function",
                          "function": {"name": nome, "arguments": argomenti}}]
    msg["content"] = ""
    d["choices"][0]["finish_reason"] = "tool_calls"
    return d


# ── FASE 1 · GUARDIA SOLO-GRATIS (idea 21) ───────────────────────────────────
A_PAGAMENTO = ("gpt-5", "gpt-4.1", "gpt-4o", "o3", "o4-", "claude-opus",
               "claude-sonnet", "claude-haiku", "gemini-2.5-pro", "grok-4")


def a_pagamento(modello):
    m = (modello or "").lower()
    if not m or "free" in m or "oss" in m or "mini" in m:
        return False
    return any(p in m for p in A_PAGAMENTO)


# ── FASE 1 · MODELLI-POLITICA (idea 6) ───────────────────────────────────────
POLITICHE = ("auto", "gratis", "keyless", "veloce", "migliore")
FORTI = ("deepseek-v4", "glm-5", "kimi-k", "qwen3", "deepseek", "glm", "llama-3.3-70b")


def ordina_per_politica(ordine, politica):
    if politica in ("gratis", "keyless"):
        return [v for v in ordine if CLASSI.get(v["id"]) == "keyless"]
    if politica == "migliore":
        def forza(v):
            m = (v.get("modello") or "").lower()
            for i, pat in enumerate(FORTI):
                if pat in m:
                    return i
            return len(FORTI)
        return sorted(ordine, key=forza)
    return ordine                        # auto e veloce: già in ordine di velocità


def inoltra(corpo, percorso="chat/completions", secondi=None, sessione=""):
    """Passa la richiesta al motore. Ritorna il JSON o None."""
    try:
        intestazioni = {"Content-Type": "application/json"}
        if sessione:
            intestazioni["x-opencode-session"] = sessione   # idea 58
        req = urllib.request.Request(MOTORE + "/" + percorso, data=corpo,
                                     headers=intestazioni)
        return json.loads(urllib.request.urlopen(
            req, timeout=secondi or CONFIG["timeout_motore"]).read().decode())
    except Exception:
        return None


PARAMETRI_SICURI = ("temperature", "top_p", "stop", "presence_penalty",
                    "frequency_penalty", "seed")


def f3_prepara(payload, comprimi):
    """FASE 3 · idee 1-2: mette a dieta la richiesta PRIMA della riserva.
    System grassi → TOON · storia chilometrica → taglio (MAI se ci sono
    tool-call in mezzo: il formato va preservato) · tools → alleggeriti.
    Ritorna (messaggi, tools, caratteri_risparmiati). Mai distruttivo."""
    messaggi = payload.get("messages") or []
    tools = payload.get("tools")
    if not (F3_OK and comprimi and CONFIG.get("comprimi_riserva")):
        return messaggi, tools, 0
    risparmio = 0
    try:
        nuovi = []
        for m in messaggi:
            c = m.get("content")
            if m.get("role") == "system" and isinstance(c, str) and \
                    len(c) >= CONFIG["system_min_car"]:
                c2, r = comprimi_system(c)
                m = dict(m, content=c2)
                risparmio += r
            nuovi.append(m)
        ha_tool_msg = any(m.get("tool_calls") or m.get("role") == "tool" for m in nuovi)
        tot = sum(len(str(m.get("content") or "")) for m in nuovi)
        if tot > CONFIG["storia_max_car"] and not ha_tool_msg and \
                all(isinstance(m.get("content"), str) for m in nuovi):
            nuovi2 = taglia_storia(nuovi, CONFIG["storia_max_car"])
            risparmio += tot - sum(len(m.get("content") or "") for m in nuovi2)
            nuovi = nuovi2
        if tools:
            tools, r2 = alleggerisci_tools(tools)
            risparmio += r2
        return nuovi, tools, risparmio
    except Exception:
        return payload.get("messages") or [], payload.get("tools"), 0


# ── FASE 3 · idee 13+16: profili per-agente (portiere_profili.json) ─────────
PROFILI_FILE = os.path.join(QUI, "portiere_profili.json")
PROFILI = {}
_profili_mtime = [0.0]


def ricarica_profili():
    global PROFILI
    if not F3_OK:
        return
    try:
        m = os.path.getmtime(PROFILI_FILE)
    except Exception:
        PROFILI = {}
        return
    if m != _profili_mtime[0]:
        _profili_mtime[0] = m
        esito = carica_profili(PROFILI_FILE)
        prof, err = esito if isinstance(esito, tuple) else (esito, None)
        PROFILI = prof if isinstance(prof, dict) else {}
        if err:
            logga(tipo="profili", nota="file profili rotto: %s" % str(err)[:120])


def complessita(messaggi):
    """Idea 11: punteggio semplice — quanti caratteri e se c'e' codice."""
    testo = " ".join(str(m.get("content", ""))[:3000] for m in (messaggi or []))
    punti = len(testo)
    if "```" in testo or "def " in testo or "function " in testo:
        punti += CONFIG["complessita_soglia"]      # il codice pesa come un testo lungo
    return punti


def forza_modello(v):
    """Quanto e' FORTE il modello di una voce (0 = il piu' forte)."""
    m = (v.get("modello") or "").lower()
    for i, pat in enumerate(FORTI):
        if pat in m:
            return i
    return len(FORTI)


def riserva(payload, politica="auto", sessione="", comprimi=True):
    """Manda la richiesta alla riserva. FASE 2·B1: l'ordine lo decide la PAGELLA
    (salute prima, poi velocita' osservata EWMA con scadenza 10 min); sui codici
    che lo meritano (429 semplice, 5xx, rete) si ritenta UNA volta sullo stesso
    provider con attesa esponenziale + jitter; massimo 5 tentativi per richiesta.
    Ritorna (risposta, rotta) — rotta dice chi ha risposto, per il log glass-box."""
    messaggi, tools_f3, risparmio_f3 = f3_prepara(payload, comprimi)   # FASE 3
    capo, sostituti = classifica()
    ordine = ([capo] if capo else []) + sostituti
    ordine = ordina_per_politica(ordine, politica)
    # idea 11: l'auto con una richiesta COMPLESSA ragiona da "migliore"
    if politica == "auto" and complessita(messaggi) >= CONFIG["complessita_soglia"]:
        ordine.sort(key=lambda v: (not in_salute(v["id"]), forza_modello(v)))
    elif politica in ("auto", "veloce", "gratis", "keyless"):   # idee 5+19+60+7+31+44
        # salute prima; poi fascia di velocita' (250ms); dentro la stessa fascia
        # vince chi ha LAVORATO MENO oggi → le chiavi gemelle si alternano da sole
        ordine.sort(key=lambda v: (not in_salute(v["id"]),
                                   velocita(v["id"], v.get("ms") or 9999) // CONFIG["fascia_ms"],
                                   uso_oggi(v["id"])))
    chiesto = (payload.get("model") or "").strip().lower()
    if chiesto in GRUPPI:                                 # idee 30+45: gruppo con nome
        per_voce = {v["id"]: v for v in ordine}
        nuovo = []
        for gpid, gmod in GRUPPI[chiesto]:
            v = per_voce.get(gpid)
            if v is None and gpid in BASE:                # membro fuori appello: si prova lo stesso
                v = {"id": gpid, "nome": ETICHETTE.get(gpid, gpid),
                     "modello": BASE[gpid][1], "ms": 9999}
            if v is not None:
                v = dict(v)
                if gmod:
                    v["modello"] = gmod
                nuovo.append(v)
        if nuovo:
            ordine = nuovo
    elif chiesto and chiesto not in POLITICHE and not chiesto.startswith("cervello/"):
        pin = False
        for v in ordine:
            if chiesto in (v["id"].lower(), v["nome"].lower()) or chiesto == (v["modello"] or "").lower():
                ordine.remove(v)
                ordine.insert(0, v)
                pin = True
                break
        if not pin:                                       # idee 36+55: pesca nel catalogo
            for gpid in chi_ha_modello(chiesto):
                v = {"id": gpid, "nome": ETICHETTE.get(gpid, gpid),
                     "modello": chiesto, "ms": 9999}
                for vv in ordine:
                    if vv["id"] == gpid:
                        v["ms"] = vv.get("ms", 9999)
                        break
                ordine.insert(0, v)
    # idea 4: sessione appiccicosa — stesso agente, stesso provider (prefix-cache)
    st = (STATO.get("sessioni") or {}).get((sessione or "")[:24])
    if st and time.time() - st.get("quando", 0) < CONFIG["sticky_scadenza"]:
        for v in ordine:
            if v["id"] == st.get("pid"):
                ordine.remove(v)
                ordine.insert(0, v)
                break
    tentativi = 0                                         # idea 24: budget totale
    for v in ordine:
        if tentativi >= CONFIG["max_tentativi"]:
            break
        pid = v["id"]
        _, modello = BASE[pid]
        modello = v.get("modello") or modello
        if punito(pid, modello):                          # idea 17
            continue
        if not in_salute(pid):                            # idee 14+27 (61: grazia <5 prove)
            continue
        if CONFIG["solo_gratis"] and a_pagamento(modello):  # idea 21
            continue
        if freno(pid):                                    # idea 48: freno PRIMA del 429
            continue
        k = chiave(pid)
        if not k:
            continue
        base, intestazioni = indirizzo(pid, k)
        intestazioni["Content-Type"] = "application/json"
        if sessione:
            intestazioni["x-opencode-session"] = sessione  # idea 58
        dati = {"model": modello, "messages": messaggi,
                "max_tokens": payload.get("max_tokens", 1200)}
        for p in PARAMETRI_SICURI:                        # idea 33: drop_params gentile
            if p in payload:
                dati[p] = payload[p]
        if tools_f3:                                      # idea 47 + F3: alleggeriti
            dati["tools"] = tools_f3
            if payload.get("tool_choice"):
                dati["tool_choice"] = payload["tool_choice"]
        corpo = json.dumps(dati).encode()
        per_questo = 0                                    # ritenti su QUESTO provider
        while tentativi < CONFIG["max_tentativi"]:
            tentativi += 1
            per_questo += 1
            inizio = time.time()
            batte(pid)                                    # idea 48: segna il battito
            try:
                req = urllib.request.Request(base + "/chat/completions", data=corpo,
                                             headers=intestazioni)
                d = json.loads(urllib.request.urlopen(
                    req, timeout=CONFIG["timeout_riserva"]).read().decode())
                msg0 = (d.get("choices") or [{}])[0].get("message", {})
                if msg0.get("content") or msg0.get("tool_calls"):
                    d = ripara_tool_call(d, payload)      # idea 47
                    ms = int((time.time() - inizio) * 1000)
                    segna(pid, True, ms)                  # idea 60: nutre l'EWMA
                    conta_uso(pid, (d.get("usage") or {}).get("total_tokens", 0))
                    if sessione:                          # idea 4: ricorda la fedelta'
                        ses = STATO.setdefault("sessioni", {})
                        ses[(sessione or "")[:24]] = {"pid": pid, "quando": time.time()}
                        if len(ses) > 50:
                            ses.pop(min(ses, key=lambda k2: ses[k2].get("quando", 0)))
                    nome = v.get("nome") or pid
                    d["model"] = "%s (riserva %s)" % (modello, nome)
                    rotta = {"provider": pid, "modello": modello, "ms": ms,
                             "tentativi": tentativi}
                    if risparmio_f3 > 0:
                        rotta["risparmio_car"] = risparmio_f3
                    return d, rotta
                # ragionatore strozzato dal budget (reasoning pieno, content vuoto,
                # finish=length): non e' colpa sua — failover SENZA castigo
                if msg0.get("reasoning") or msg0.get("reasoning_content"):
                    logga(tipo="igiene", provider=pid, modello=modello,
                          nota="ragionatore senza budget (finish=length), nessun castigo")
                    break
                segna(pid, False)                         # 200 ma vuoto: failover (idea 18)
                castiga(pid, modello, CONFIG["cooldown_passeggero"])
                break
            except urllib.error.HTTPError as e:
                try:
                    testo = e.read(500).decode(errors="replace")
                except Exception:
                    testo = ""
                tipo = classifica_errore(e.code, testo)
                jitter = random.randint(0, 10)            # il saggio: sempre col jitter
                # idea 24: on_status_codes — si RITENTA solo dove ha senso
                if tipo in ("breve", "passeggero") and \
                        per_questo <= CONFIG["retry_stesso"] and \
                        tentativi < CONFIG["max_tentativi"]:
                    time.sleep(min(CONFIG["backoff_base"] ** per_questo,
                                   CONFIG["backoff_max"]) + random.uniform(0, 1))
                    continue
                if tipo == "breve":
                    # idea 51: se il provider dice QUANDO tornare, obbediamo
                    ra = 0
                    try:
                        ra = int(float(e.headers.get("Retry-After") or 0))
                    except Exception:
                        ra = 0
                    riposo = min(ra, CONFIG["retry_after_max"]) if ra > 0 \
                        else CONFIG["cooldown_breve"]
                    castiga(pid, modello, riposo + jitter)
                    segna(pid, False)
                elif tipo == "quota":                     # idea 22
                    castiga(pid, None, CONFIG["cooldown_quota"] + jitter)
                    segna(pid, False)
                elif tipo == "chiave":
                    castiga(pid, None, CONFIG["cooldown_chiave"] + jitter)
                    segna(pid, False)
                elif tipo == "pensionato":                # idea 18
                    castiga(pid, modello, CONFIG["cooldown_pensionato"], globale=True)
                elif tipo == "contesto":                  # idee 18+32: nessun castigo
                    pass
                else:
                    castiga(pid, modello, CONFIG["cooldown_passeggero"] + jitter)
                    segna(pid, False)
                logga(tipo="errore-riserva", provider=pid, modello=modello,
                      errore=tipo, codice=e.code, tentativo=tentativi)
                break
            except Exception as e:
                # rete: merita UN ritento (idea 24), poi castigo passeggero
                if per_questo <= CONFIG["retry_stesso"] and \
                        tentativi < CONFIG["max_tentativi"]:
                    time.sleep(min(CONFIG["backoff_base"] ** per_questo,
                                   CONFIG["backoff_max"]) + random.uniform(0, 1))
                    continue
                castiga(pid, modello, CONFIG["cooldown_passeggero"])
                segna(pid, False)
                logga(tipo="errore-riserva", provider=pid, modello=modello,
                      errore="rete", nota=str(e)[:120], tentativo=tentativi)
                break
    return None, None


def da_confermare():
    """Le voci in fondo alla lista (indirizzo mai scritto / non-chat): non contano."""
    fuori, dentro = [], False
    try:
        for riga in open(LISTA, encoding="utf-8", errors="replace").read().splitlines():
            r = riga.strip()
            if r.startswith("##"):
                dentro = True
                continue
            if dentro and r and not r.startswith("#"):
                pezzi = r.split("|")
                if len(pezzi) >= 2:
                    fuori.append((pezzi[0], pezzi[1]))
    except Exception:
        pass
    return fuori


# ── IL CAPO DELLA GIORNATA ───────────────────────────────────────────────────
SOSTITUTI_MAX = 12


def _appello_fresco(ore=2):
    try:
        return (time.time() - os.path.getmtime(APPELLO)) < ore * 3600
    except Exception:
        return False


def appello_da_solo():
    """Se l'appello è vecchio o non c'è, lo fa il Portiere in proprio."""
    if _appello_fresco():
        return
    subprocess.Popen(["bash", os.path.join(QUI, "appello_chiavi.sh"), "--svelto"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def classifica():
    """(capo, sostituti): solo provider di chat che hanno risposto, dal più veloce."""
    buoni = []
    for v in appello():
        pid = v.get("id")
        if v.get("esito") != "risponde" or pid not in BASE:
            continue
        if TIPI.get(pid, "chat") != "chat":
            continue
        buoni.append({"id": pid, "nome": v.get("nome") or ETICHETTE.get(pid, pid),
                      "modello": v.get("modello") or BASE[pid][1], "ms": v.get("ms") or 9999})
    buoni.sort(key=lambda x: x["ms"])
    if not buoni:
        return None, []
    return buoni[0], buoni[1:SOSTITUTI_MAX + 1]


def immagini(prompt):
    """Le chiavi di immagini della lista: se ti serve una foto, il Portiere pesca qui."""
    import urllib.parse
    if not prompt:
        return None
    for pid, tipo in TIPI.items():
        if tipo != "immagini":
            continue
        url, modello = BASE[pid]
        if "image.pollinations.ai" in url:
            q = urllib.parse.urlencode({"width": 1024, "height": 1024, "nologo": "true",
                                        "model": modello or "flux", "seed": int(time.time()) % 999999})
            return {"created": int(time.time()),
                    "data": [{"url": "%s/prompt/%s?%s" % (url, urllib.parse.quote(prompt), q)}],
                    "provider": "Pollinations (senza chiave)"}
    return None


def sonda():
    """Idea 52: verifica le chiavi con GET /models — zero token spesi."""
    ricarica()
    print("Sonda credenziali (GET /models, nessun token speso):")
    for pid, (url, modello) in BASE.items():
        eti = ETICHETTE.get(pid, pid)
        if NOMI.get(pid) == "SENZA":
            url_k = url if url != "SPECIALE-CLOUDFLARE" else ""
            if not url_k:
                print("  — %-22s keyless (formato suo, salto)" % eti)
                continue
            try:
                urllib.request.urlopen(urllib.request.Request(url_k + "/models",
                    headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) cervello/2.1"}),
                    timeout=8).read(200)
                print("  ✅ %-22s keyless RAGGIUNGIBILE" % eti)
            except urllib.error.HTTPError as e:
                print("  🟡 %-22s keyless risponde %d" % (eti, e.code))
            except Exception:
                print("  ⚪ %-22s keyless non raggiungibile" % eti)
            continue
        k = chiave(pid)
        if not k:
            print("  🔴 %-22s chiave ASSENTE nel portachiavi" % eti)
            continue
        base, intest = indirizzo(pid, k)
        try:
            urllib.request.urlopen(urllib.request.Request(base + "/models",
                                   headers=intest), timeout=8).read(200)
            print("  ✅ %-22s chiave valida" % eti)
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                print("  🔴 %-22s chiave RIFIUTATA (%d)" % (eti, e.code))
            else:
                print("  🟡 %-22s risponde %d (endpoint diverso?)" % (eti, e.code))
        except Exception:
            print("  ⚪ %-22s non raggiungibile" % eti)


def scopri():
    """Idea 36: interroga /v1/models di ogni provider (timeout brevi) e salva
    il catalogo in portiere_catalogo.json. Zero token spesi."""
    ricarica()
    cat, trovati = {}, 0
    print("Scoperta modelli (GET /v1/models, timeout %ds):" % CONFIG["scoperta_timeout"])
    for pid, (url, modello) in BASE.items():
        eti = ETICHETTE.get(pid, pid)
        if url == "SPECIALE-CLOUDFLARE" or TIPI.get(pid, "chat") != "chat":
            continue
        k = chiave(pid)
        if not k:
            continue
        base, intest = indirizzo(pid, k)
        try:
            d = json.loads(urllib.request.urlopen(
                urllib.request.Request(base + "/models", headers=intest),
                timeout=CONFIG["scoperta_timeout"]).read().decode())
            voci = [str(v.get("id", "")) for v in (d.get("data") or []) if v.get("id")][:500]
            if voci:
                cat[pid] = {"modelli": voci, "quando": time.strftime("%Y-%m-%d %H:%M")}
                trovati += len(voci)
                print("  ✅ %-22s %d modelli" % (eti, len(voci)))
        except Exception:
            print("  ⚪ %-22s niente lista" % eti)
    try:
        json.dump(cat, open(CATALOGO_FILE, "w", encoding="utf-8"))
        print("Catalogo: %d provider, %d modelli → %s" % (len(cat), trovati, CATALOGO_FILE))
        print("RICORDA (idea 55): catalogo != accesso, la prova vera e' la risposta.")
    except Exception as e:
        print("salvataggio fallito:", e)


def pagina():
    """La pagina del Portiere: la SUA lista, provider per provider."""
    voci = {v.get("id"): v for v in appello()}
    su_motore = motore_vivo()
    pronti = sum(1 for pid in BASE if (voci.get(pid) or {}).get("esito") == "risponde")
    ora = time.time()
    castigati = sum(1 for v in STATO["castighi"].values() if v > ora)
    corpo = []
    for pid, (url, modello) in BASE.items():
        v = voci.get(pid) or {}
        esito = v.get("esito", "")
        icona, colore = {"risponde": ("✅", "#39d98a"), "occupato": ("🟡", "#f5c451"),
                         "chiave-no": ("🔴", "#ff6b6b"), "rete": ("⚪", "#9aa4b2"),
                         "no-chiave": ("—", "#9aa4b2")}.get(esito, ("·", "#6b7280"))
        nota = v.get("nota") or ("mai provato: fai l'appello dalla Centrale" if not esito else esito)
        p = STATO["pagella"].get(pid)
        if p and p["ok"] + p["ko"] >= CONFIG["min_prove"]:
            nota += " · pagella %d%%" % round(100 * p["ok"] / (p["ok"] + p["ko"]))
            if p.get("ms_ewma") is not None:
                nota += " · ~%dms" % p["ms_ewma"]
        if punito(pid, modello):
            resta = max((v2 - ora) for k2, v2 in STATO["castighi"].items()
                        if v2 > ora and (k2.startswith(pid + "|") or
                                         k2 == "*|" + (modello or "")))
            nota += " · ⏸ castigo (%ds)" % int(resta)          # idea 43: countdown
        n_oggi = uso_oggi(pid)
        if n_oggi:
            nota += " · oggi %d" % n_oggi
        corpo.append(
            '<tr><td style="padding:7px 10px;border-bottom:1px solid #ffffff12">'
            f'<span style="color:{colore}">{icona}</span> <b>{ETICHETTE.get(pid, pid)}</b> '
            f'<span style="color:#6b7280;font-size:12px">{TIPI.get(pid, "chat")} · {CLASSI.get(pid, "")}</span></td>'
            '<td style="padding:7px 10px;border-bottom:1px solid #ffffff12;color:#9aa4b2">'
            f'{url.replace("https://", "")} · {modello}</td>'
            '<td style="padding:7px 10px;border-bottom:1px solid #ffffff12;color:#c9d1d9">'
            f'{nota}</td></tr>')
    fuori = da_confermare()
    righe_fuori = "".join(
        '<div style="display:flex;justify-content:space-between;padding:5px 0;'
        'border-bottom:1px solid #ffffff0d"><b>' + n + '</b>'
        '<span style="color:#9aa4b2">' + m + '</span></div>' for n, m in fuori)
    html = f"""<!doctype html><html lang="it"><head><meta charset="utf-8">
<title>Portiere — la sua lista</title></head>
<body style="margin:0;background:#0d1117;color:#e6edf3;font:15px/1.5 -apple-system,Segoe UI,Roboto,sans-serif">
<div style="max-width:1000px;margin:0 auto;padding:26px 20px">
  <h1 style="margin:0 0 4px;font-size:22px">🚪 Portiere <span style="font-size:14px;color:#9aa4b2">porta 20129 · FASE 3</span></h1>
  <div style="color:#9aa4b2;margin-bottom:16px">Il motore di riserva: fa passare tutto a OmniRoute
    quando è acceso, e se OmniRoute cade usa la sua lista qui sotto.
    Modelli-politica: <b>auto</b> · <b>gratis</b> · <b>veloce</b> · <b>migliore</b>.</div>
  <div style="display:flex;gap:10px;flex-wrap:wrap;margin-bottom:18px">
    <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">
      <div style="color:#9aa4b2;font-size:12px">provider nella sua lista</div>
      <div style="font-size:20px"><b>{pronti}/{sum(1 for _ in BASE)}</b> rispondono</div></div>
    <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">
      <div style="color:#9aa4b2;font-size:12px">OmniRoute (20128)</div>
      <div style="font-size:20px">{'🟢 vivo' if su_motore else '🔴 spento'}</div></div>
    <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">
      <div style="color:#9aa4b2;font-size:12px">appello</div>
      <div style="font-size:20px">{len(voci) and str(len(voci)) + ' prove fatte' or 'non ancora fatto'}</div></div>
    <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">
      <div style="color:#9aa4b2;font-size:12px">in castigo adesso</div>
      <div style="font-size:20px">{castigati or '—'}</div></div>
    {('<div style="background:#2d1f00;border:1px solid #f5c45155;border-radius:10px;padding:10px 14px;color:#f5c451">📡 ' + STATO.get("sentinella", {}).get("avviso", "") + '</div>') if STATO.get("sentinella", {}).get("avviso") else ''}
    <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">
      <div style="color:#9aa4b2;font-size:12px">riserva oggi</div>
      <div style="font-size:20px"><b>{sum(u.get('n', 0) for u in (STATO.get('uso') or {}).values() if u.get('giorno') == oggi())}</b> richieste</div></div>
  </div>
  <table style="width:100%;border-collapse:collapse;background:#161b22;border:1px solid #ffffff14;border-radius:10px;overflow:hidden">
    <tr style="background:#1c2430;text-align:left;color:#9aa4b2;font-size:12px">
      <th style="padding:8px 10px">PROVIDER</th><th style="padding:8px 10px">INDIRIZZO · MODELLO</th>
      <th style="padding:8px 10px">STATO</th></tr>
    {''.join(corpo)}
  </table>
  <h2 style="font-size:16px;margin:24px 0 6px">Da confermare ({len(fuori)})</h2>
  <div style="color:#9aa4b2;margin-bottom:10px">Fuori dal numero qui sopra: gli indirizzi che non
    abbiamo mai scritto, più le chiavi che non sono modelli di chat (voce, immagini, video, database).</div>
  <div style="background:#161b22;border:1px solid #ffffff14;border-radius:10px;padding:10px 14px">{righe_fuori}</div>
</div></body></html>"""
    return html


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _json(self, dati, codice=200):
        corpo = json.dumps(dati, ensure_ascii=False).encode()
        self.send_response(codice)
        self.send_header("Access-Control-Allow-Origin", "*")   # cruscotti locali (file://)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(corpo)))
        self.end_headers()
        self.wfile.write(corpo)

    def _rispondi(self, d, stream):
        """Risposta normale, oppure confezionata in streaming (SSE) se il
        client l'ha chiesta cosi: alcuni agenti (OpenCode, ai-sdk) parlano
        SOLO a pezzetti e con la risposta in blocco restano appesi."""
        if not stream:
            self._json(d)
            return
        msg = (d.get("choices") or [{}])[0].get("message", {})
        delta = {"role": "assistant", "content": msg.get("content", "") or ""}
        tc = msg.get("tool_calls") or []
        if tc:
            delta["tool_calls"] = [dict(v, index=i) for i, v in enumerate(tc)]
        base = {"id": d.get("id", "cervello"), "object": "chat.completion.chunk",
                "created": d.get("created", int(time.time())), "model": d.get("model", "")}
        fine = (d.get("choices") or [{}])[0].get("finish_reason") or "stop"
        pezzo1 = dict(base, choices=[{"index": 0, "delta": delta, "finish_reason": None}])
        pezzo2 = dict(base, choices=[{"index": 0, "delta": {}, "finish_reason": fine}])
        if d.get("usage"):
            pezzo2["usage"] = d["usage"]
        corpo = ("data: %s\n\ndata: %s\n\ndata: [DONE]\n\n" % (
            json.dumps(pezzo1, ensure_ascii=False), json.dumps(pezzo2, ensure_ascii=False))).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Content-Length", str(len(corpo)))
        self.end_headers()
        self.wfile.write(corpo)

    def _sessione(self):
        """Idea 58: un ID di sessione stabile per agente (o quello che manda lui)."""
        s = self.headers.get("x-opencode-session")
        if s:
            return s
        ua = self.headers.get("user-agent", "") or "agente"
        return "cervello-" + hashlib.sha1(ua.encode()).hexdigest()[:16]

    def do_GET(self):
        ricarica()
        if self.path.startswith("/portiere") and not self.path.startswith("/portiere.json"):
            b = pagina().encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(b)))
            self.end_headers()
            self.wfile.write(b)
            return
        if self.path.startswith("/portiere.json"):
            capo, sost = classifica()
            self._json({"nome": NOME, "porta": PORTA, "totali": len(BASE),
                        "capo": capo, "sostituti": len(sost),
                        "risponde": [v["id"] for v in appello()
                                     if v.get("esito") == "risponde" and v.get("id") in BASE],
                        "voci": [{"id": k, "nome": ETICHETTE.get(k, k), "tipo": TIPI.get(k, "chat"),
                                  "classe": CLASSI.get(k, ""),
                                  "indirizzo": v[0], "modello": v[1]} for k, v in BASE.items()],
                        "da_confermare": da_confermare()})
            return
        if self.path.startswith("/cervello"):
            su = motore_vivo()
            capo, sost = classifica()
            self._json({"motore": su, "nome": NOME,
                        "interruttore_solo_cervello": os.path.exists(SOLO_CERVELLO),
                        "capo": capo, "sostituti": [v["nome"] for v in sost],
                        "riserva": [v["id"] for v in appello() if v.get("esito") == "risponde"],
                        "risponde": (len([1 for v in appello() if v.get("esito") == "risponde"])),
                        "adesso": "motore" if su else (capo["nome"] if capo else "nessuna chiave")})
            return
        if self.path.startswith("/v1/models"):
            ricarica_gruppi()
            politiche = [{"id": p, "object": "model", "owned_by": "cervello"}
                         for p in POLITICHE if p != "keyless"]
            politiche += [{"id": g, "object": "model", "owned_by": "cervello-gruppo"}
                          for g in GRUPPI]
            d = inoltra(None, "models", secondi=10) if motore_vivo() else None
            if d and isinstance(d.get("data"), list):
                d["data"] = politiche + d["data"]        # idea 6: le politiche in testa
                self._json(d)
                return
            modelli = politiche + [
                {"id": v.get("modello") or BASE.get(v.get("id"), ("", "auto"))[1],
                 "object": "model", "owned_by": "riserva"}
                for v in appello() if v.get("esito") == "risponde" and v.get("id") in BASE]
            self._json({"object": "list", "data": modelli})
            return
        self._json({"errore": "usa /v1/chat/completions oppure /cervello"}, 404)

    def do_POST(self):
        ricarica()                                        # idea 10
        ricarica_gruppi()                                 # idee 30+45
        ricarica_quote()                                  # idea 48
        ricarica_regole()                                 # idea 38
        sentinella()                                      # tracker quote, 1 volta/giorno
        inizio = time.time()
        if self.path.startswith("/v1/images/generations"):
            n = int(self.headers.get("Content-Length") or 0)
            try:
                corpo = json.loads(self.rfile.read(n).decode() or "{}")
            except Exception:
                corpo = {}
            d = immagini((corpo.get("prompt") or "").strip())
            if d:
                self._json(d)
            else:
                self._json({"error": {"message": "Nessuna chiave di immagini in grado di rispondere adesso: "
                                                 "le altre (fal.ai, WaveSpeedAI) hanno un formato loro, "
                                                 "vanno collegate una per una."}}, 503)
            return
        if not self.path.startswith("/v1/chat/completions"):
            self._json({"errore": "solo /v1/chat/completions"}, 404)
            return
        n = int(self.headers.get("Content-Length") or 0)
        try:
            payload = json.loads(self.rfile.read(n).decode() or "{}")
        except Exception:
            self._json({"error": {"message": "corpo non valido"}}, 400)
            return
        vuole_stream = bool(payload.pop("stream", False))
        payload.pop("stream_options", None)
        sess = self._sessione()
        ricarica_profili()                                # FASE 3: idee 13+16
        comprimi_agente = True
        if F3_OK and PROFILI:
            prof = profilo_di(sess, PROFILI)
            if prof:
                try:
                    payload, note = applica_profilo(payload, prof)
                    if note:
                        logga(tipo="profilo", agente=sess, nota="; ".join(map(str, note)))
                except Exception as e:
                    logga(tipo="profili", nota="applica_profilo fallita: %s" % str(e)[:80])
                if prof.get("comprimi") is False:
                    comprimi_agente = False
        modello_chiesto = (payload.get("model") or "").strip()
        politica = modello_chiesto.lower()
        if politica.startswith("cervello/"):
            politica = politica[len("cervello/"):]

        regola = regola_di(sess)                          # idea 38: regole per agente
        if regola and regola.get("politiche") and politica and \
                politica in POLITICHE and politica not in regola["politiche"]:
            logga(tipo="vietato", agente=sess, politica=politica, rotta="regole")
            self._json({"error": {"message": "Regola dell'agente: puo' usare solo %s."
                                             % ", ".join(regola["politiche"])}}, 403)
            return
        if regola and regola.get("tetto"):
            a = (STATO.get("agenti") or {}).get((sess or "ignoto")[:24]) or {}
            if a.get("giorno") == oggi() and a.get("n", 0) >= regola["tetto"]:
                logga(tipo="tetto-agente", agente=sess, rotta="regole")
                self._json({"error": {"message": "Tetto giornaliero dell'agente (regola: %d) "
                                                 "raggiunto." % regola["tetto"]}}, 429)
                return
        if agente_oltre(sess):                            # idea 26: tetto per agente
            logga(tipo="tetto-agente", agente=sess, rotta="fermato")
            self._json({"error": {"message": "Tetto giornaliero dell'agente raggiunto "
                                             "(CONFIG tetto_agente). Riparte domani."}}, 429)
            return

        # idea 21: la guardia solo-gratis ferma i modelli a pagamento sul portone
        if CONFIG["solo_gratis"] and a_pagamento(modello_chiesto):
            logga(tipo="bloccato", agente=sess, modello=modello_chiesto, rotta="guardia")
            self._json({"error": {"message": "Guardia solo-gratis: '%s' sembra un modello "
                                             "a pagamento. Usa 'auto', 'gratis', 'veloce' o "
                                             "'migliore' (regola: costo zero)." % modello_chiesto}}, 403)
            return

        # idea 46: le richieste banali si rispondono in casa
        if CONFIG["intercetta_banali"]:
            d = banale(payload)
            if d:
                logga(tipo="banale", agente=sess, rotta="locale",
                      ms=int((time.time() - inizio) * 1000))
                self._rispondi(d, vuole_stream)
                return

        # idea 3: cache locale — stessa domanda entro 10 min = 0 token
        ck = cache_chiave(payload)
        d = cache_leggi(ck)
        if d:
            logga(tipo="cache", agente=sess, rotta="cache",
                  ms=int((time.time() - inizio) * 1000))
            self._rispondi(d, vuole_stream)
            return

        # aggancio B3: migliore/veloce passano dal MOTORE con le sue auto/best-*
        if politica in MAPPA_MOTORE and motore_vivo():
            p2 = dict(payload, model=MAPPA_MOTORE[politica])
            d = inoltra(json.dumps(p2).encode(), sessione=sess)
            if d:
                conta_agente(sess, (d.get("usage") or {}).get("total_tokens", 0))
                logga(tipo="richiesta", agente=sess, politica=politica,
                      rotta="motore-mappato", modello=MAPPA_MOTORE[politica],
                      ms=int((time.time() - inizio) * 1000))
                self._rispondi(d, vuole_stream)
                return
            # motore muto → si prosegue sulla riserva qui sotto

        # i GRUPPI con nome vanno dritti in riserva (sanno loro chi chiamare)
        if politica in GRUPPI:
            d, rotta = riserva(payload, "auto", sess, comprimi_agente)
            if d:
                conta_agente(sess, (d.get("usage") or {}).get("total_tokens", 0))
                logga(tipo="richiesta", agente=sess, politica="gruppo:" + politica,
                      rotta="riserva", **dict(rotta, ms=int((time.time() - inizio) * 1000)))
                self._rispondi(d, vuole_stream)
                return
            logga(tipo="fallita", agente=sess, politica="gruppo:" + politica, rotta="riserva")
            self._json({"error": {"message": "Nessun membro del gruppo '%s' ha risposto." % politica}}, 503)
            return

        # idea 6: le politiche diverse da "auto" scelgono direttamente dalla riserva
        if politica in POLITICHE and politica != "auto":
            d, rotta = riserva(payload, politica, sess, comprimi_agente)
            if d:
                conta_agente(sess, (d.get("usage") or {}).get("total_tokens", 0))
                logga(tipo="richiesta", agente=sess, politica=politica, rotta="riserva",
                      **dict(rotta, ms=int((time.time() - inizio) * 1000)))
                self._rispondi(d, vuole_stream)
                return
            logga(tipo="fallita", agente=sess, politica=politica, rotta="riserva")
            self._json({"error": {"message": "Nessun provider della politica '%s' ha risposto. "
                                             "Prova con 'auto'." % politica}}, 503)
            return

        corpo = json.dumps(payload).encode()
        if motore_vivo():
            d = inoltra(corpo, sessione=sess)
            msg0 = (d.get("choices") or [{}])[0].get("message", {}) if d else {}
            if d and not msg0.get("content") and not msg0.get("tool_calls"):
                d = None                                  # igiene: 200 vuoto → riserva
                logga(tipo="igiene", agente=sess, rotta="motore",
                      nota="risposta vuota dal motore, passo alla riserva")
            if d:
                d = ripara_tool_call(d, payload)          # idea 47 anche sul motore
                conta_agente(sess, (d.get("usage") or {}).get("total_tokens", 0))
                cache_scrivi(ck, d)                       # idea 3
                logga(tipo="richiesta", agente=sess, politica=politica or "auto",
                      rotta="motore", modello=modello_chiesto or "auto",
                      ms=int((time.time() - inizio) * 1000))
                self._rispondi(d, vuole_stream)
                return
        d, rotta = riserva(payload, "auto", sess, comprimi_agente)
        if d:
            conta_agente(sess, (d.get("usage") or {}).get("total_tokens", 0))
            cache_scrivi(ck, d)                           # idea 3
            logga(tipo="richiesta", agente=sess, politica="auto", rotta="riserva",
                  **dict(rotta, ms=int((time.time() - inizio) * 1000)))
            self._rispondi(d, vuole_stream)
            return
        logga(tipo="fallita", agente=sess, politica=politica or "auto", rotta="nessuna")
        self._json({"error": {"message": "motore giù e nessuna chiave di riserva ha risposto. "
                                         "Apri la Centrale → 🤖 Agenti → 🗣️ Appello delle chiavi."}}, 503)


def statistiche():
    """Idea 53 (OrcaRouter Lite in piccolo): il riassunto del lavoro dal glass-box."""
    rotte, errori, agenti_n, provider_n = {}, {}, {}, {}
    try:
        for riga in open(LOG_FILE, encoding="utf-8").read().splitlines():
            try:
                v = json.loads(riga)
            except Exception:
                continue
            rotte[v.get("rotta", "?")] = rotte.get(v.get("rotta", "?"), 0) + 1
            if v.get("tipo") == "errore-riserva":
                errori[v.get("errore", "?")] = errori.get(v.get("errore", "?"), 0) + 1
            if v.get("agente"):
                agenti_n[v["agente"][:20]] = agenti_n.get(v["agente"][:20], 0) + 1
            if v.get("provider"):
                provider_n[v["provider"]] = provider_n.get(v["provider"], 0) + 1
    except Exception:
        print("log vuoto")
        return
    print("── Rotte ──")
    for k, n in sorted(rotte.items(), key=lambda x: -x[1]):
        print("  %-16s %d" % (k, n))
    print("── Errori riserva ──")
    for k, n in sorted(errori.items(), key=lambda x: -x[1]) or [("nessuno", 0)]:
        print("  %-16s %d" % (k, n))
    print("── Provider piu' usati ──")
    for k, n in sorted(provider_n.items(), key=lambda x: -x[1])[:8]:
        print("  %-16s %d" % (k, n))
    print("── Agenti piu' attivi ──")
    for k, n in sorted(agenti_n.items(), key=lambda x: -x[1])[:8]:
        print("  %-16s %d" % (k, n))
    u = STATO.get("uso") or {}
    print("── Oggi ──")
    print("  richieste riserva:", sum(x.get("n", 0) for x in u.values() if x.get("giorno") == oggi()),
          "· token riserva:", sum(x.get("token", 0) for x in u.values() if x.get("giorno") == oggi()))


def stato():
    voci = appello()
    su = motore_vivo()
    print("Motore OmniRoute (20128):", "🟢 vivo" if su else "🔴 spento")
    pronti = [v for v in voci if v.get("esito") == "risponde"]
    print("Riserva pronta:", len(pronti), "provider")
    for v in pronti:
        print("  ✓", v.get("nome"), "·", v.get("modello") or "")
    ora = time.time()
    castigati = [(k, int(v - ora)) for k, v in STATO["castighi"].items() if v > ora]
    if castigati:
        print("In castigo:", ", ".join("%s (%ds)" % c for c in castigati))
    print("Portiere (20129):", "🟢 acceso" if vivo("http://127.0.0.1:%d" % PORTA) else "🔴 spento")


if __name__ == "__main__":
    stato_carica()                                        # idea 20
    if "--stato" in sys.argv:
        stato()
        sys.exit(0)
    if "--sonda" in sys.argv:                             # idea 52
        sonda()
        sys.exit(0)
    if "--scopri" in sys.argv:                            # idea 36
        scopri()
        sys.exit(0)
    if "--statistiche" in sys.argv:                       # idea 53
        statistiche()
        sys.exit(0)
    if "--perdona" in sys.argv:                           # amnistia: azzera i castighi
        quanti = len(STATO["castighi"])
        STATO["castighi"] = {}
        stato_salva(forza=True)
        print("Perdonati %d castighi. Se il Portiere è acceso, riavvialo per" % quanti)
        print("fargliela leggere (ACCENDI_CERVELLO.bat lo fa in un colpo).")
        sys.exit(0)
    ricarica_gruppi()
    ricarica_quote()
    ricarica_regole()
    print("Portiere FASE 3 su http://127.0.0.1:%d/v1 — %d chiavi · politiche: %s · gruppi: %d"
          % (PORTA, len(BASE), ", ".join(p for p in POLITICHE if p != "keyless"), len(GRUPPI)))
    appello_da_solo()
    ThreadingHTTPServer(("127.0.0.1", PORTA), H).serve_forever()
