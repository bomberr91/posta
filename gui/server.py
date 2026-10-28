#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# gui/server.py — GUI CENTRALE (Hub + Agenti) su http://localhost:20200 · solo stdlib
#
# v2 (20/10/2026) — regole del check-in AgentRouter:
#   · FINESTRA 18:05 (ora italiana): prima NESSUN login/logout (rischio ban, ordine utente)
#   · max MAX_TENTATIVI giri al giorno; un browser spento non consuma tentativi
#   · flag "serve login manuale" che ferma tutto finché non si sistema (o finché il tasto
#     «Riscatta ora» non forza il giro)
#   · "ho già riscattato a mano" → segna il giorno senza toccare il browser
#   · saldo letto solo se la risposta è JSON (il WAF Aliyun restituisce HTML)
import json, os, re, subprocess, sys, time, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

class _Rifiutato(Exception):
    """Richiesta scartata: la risposta d'errore è già stata scritta."""


HOME = os.path.expanduser("~")
POSTA = os.path.join(HOME, "posta")
QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, POSTA)

CHROME_PATHS = [
    "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe",
    "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe",
    "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
    "/mnt/c/Program Files/Microsoft/Edge/Application/msedge.exe",
]
PROFILO_WIN = r"C:\AgentiH24\BrowserProfile"

FINESTRA = (18, 5)        # ora ITALIANA: da qui in poi si può riscattare
MAX_TENTATIVI = 3         # giri massimi al giorno
TEST = os.environ.get("CENTRALE_NO_POSTINO") == "1"


# ───────────────────────────── util ─────────────────────────────────────────
def porta_viva(porta, host="127.0.0.1"):
    import socket
    for h in (host, "::1", "localhost"):
        try:
            with socket.create_connection((h, porta), timeout=2):
                return True
        except Exception:
            continue
    return False


def leggi(path, default=""):
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            return f.read()
    except Exception:
        return default


def scrivi(path, testo):
    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(testo)
        return True
    except Exception:
        return False


def giorno_bonus():
    # il bonus si riscatta una volta al giorno dalle 18:05 ITALIANE → il giorno è quello locale
    return time.strftime("%Y-%m-%d")


def adesso_hhmm():
    return time.strftime("%H:%M")


def finestra_aperta():
    if os.environ.get("AR_IGNORA_FINESTRA") == "1":
        return True
    t = time.localtime()
    return (t.tm_hour, t.tm_min) >= FINESTRA


def flag_checkin():
    return os.path.join(HOME, f".ar_checkin_{giorno_bonus()}")


def file_tentativi():
    return os.path.join(HOME, f".ar_checkin_try_{giorno_bonus()}")


def tentativi_oggi():
    try:
        return int((leggi(file_tentativi(), "0").strip() or "0") or 0)
    except Exception:
        return 0


def segna_tentativo():
    n = tentativi_oggi() + 1          # prima si legge, poi si scrive (aprire "w" azzera!)
    scrivi(file_tentativi(), str(n))


_verifica_lock = threading.Lock()
_ultima_verifica = [0.0]


def verifica_sessione(bloccante=False):
    """(se il bonus di oggi è già preso, questa non deve far ricomparire l'avviso)"""
    """Chiede a checkin_agentrouter.py --verifica se la sessione agentrouter e' valida.
    Se lo e' e c'era il flag "serve login manuale", lo toglie (cosi' non resta appeso per sempre)."""
    if not porta_viva(9222):
        return None
    if not _verifica_lock.acquire(blocking=bloccante):
        return None
    try:
        p = subprocess.run(["python3", os.path.join(POSTA, "checkin_agentrouter.py"), "--verifica"],
                           capture_output=True, text=True, timeout=120)
        out = (p.stdout or "") + (p.stderr or "")
        _ultima_verifica[0] = time.time()
        valida = (p.returncode == 0) and ("sessione valida" in out or "dentro" in out)
        if valida and serve_login_manuale():
            pulisci_login_manuale()
            print("[gui] sessione di nuovo valida: tolto il flag di login manuale")
        return valida
    except Exception:
        return None
    finally:
        _verifica_lock.release()


def file_login_manuale():
    return os.path.join(HOME, ".ar_login_manuale")


def serve_login_manuale():
    return os.path.exists(file_login_manuale())


def segna_login_manuale(motivo):
    # se il bonus di oggi è già stato riscosso (anche a mano), non c'è niente da segnalare
    if os.path.exists(flag_checkin()):
        return
    scrivi(file_login_manuale(), time.strftime("%d/%m/%Y %H:%M") + " · " + (motivo or "")[:300])


def pulisci_login_manuale():
    try:
        os.remove(file_login_manuale())
    except Exception:
        pass


# ───────────────────────── chiavi / saldo / modelli ─────────────────────────
_cache = {}


def chiave(riga_pat, key_pat):
    for r in leggi(os.path.join(HOME, "CHIAVI_LOCALI.md")).splitlines():
        if re.search(riga_pat, r, re.I):
            m = re.search(key_pat, r)
            if m:
                return m.group(0)
    return None


def saldo_live():
    """Saldo da agentrouter.org (API billing), cache 10 min. Il WAF risponde HTML: va scartato."""
    v = _cache.get("saldo")
    if v and time.time() - v[0] < 600:
        return v[1]
    saldo = None
    key = chiave(r"agentrouter", r"sk-[A-Za-z0-9]{30,}")
    if key:
        import urllib.request

        def gj(p):
            req = urllib.request.Request("https://agentrouter.org" + p, headers={
                "Authorization": "Bearer " + key,
                "User-Agent": "codex_cli_rs/0.149.1",
                "Accept": "application/json"})
            raw = urllib.request.urlopen(req, timeout=8).read().decode("utf-8", "ignore")
            if not raw.lstrip().startswith("{"):
                raise ValueError("risposta non-JSON (WAF)")
            return json.loads(raw)

        try:
            tot = float(gj("/dashboard/billing/subscription").get("hard_limit_usd") or 0)
            usato = float(gj("/dashboard/billing/usage").get("total_usage") or 0) / 100.0
            s_ = tot - usato
            if s_ > 50000:                 # unità interne new-api (500000 = 1$)
                s_ = s_ / 500000.0
            if 0 < s_ < 50000:
                saldo = f"{s_:.2f}"
        except Exception:
            saldo = None
    _cache["saldo"] = (time.time(), saldo)
    return saldo


_saldo_bg = {"in_corso": False}

def saldo_istantaneo():
    """Non blocca MAI la pagina: se il saldo è vecchio lo aggiorna in sottofondo e intanto mostra l'ultimo noto."""
    v = _cache.get("saldo")
    if v and time.time() - v[0] < 600:
        return v[1]
    if not _saldo_bg["in_corso"]:
        _saldo_bg["in_corso"] = True

        def _lavoro():
            try:
                saldo_live()
            finally:
                _saldo_bg["in_corso"] = False
        threading.Thread(target=_lavoro, daemon=True).start()
    return v[1] if v else None


def saldo_ultimo():
    txt = leggi(os.path.join(POSTA, "dal_pc", "agentrouter_checkin.md"))
    m = re.findall(r"saldo (?:dopo|prima): \$?([0-9][0-9.,]*)", txt)
    return m[-1] if m else None


































# ───────────────────────────── check-in ─────────────────────────────────────
def chrome_headless_avvia():
    for c in CHROME_PATHS:
        if os.path.exists(c):
            subprocess.Popen([c, "--headless=new", "--remote-debugging-port=9222",
                              f"--user-data-dir={PROFILO_WIN}", "--no-first-run",
                              "--disable-gpu", "about:blank"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            for _ in range(20):
                if porta_viva(9222):
                    return True
                time.sleep(1)
    return porta_viva(9222)


def chrome_finestra(mostra=True):
    """Mostra la finestra del browser degli agenti o la rimanda dietro le quinte.
    Stesso profilo e stessa porta 9222: cambia solo se la finestra si vede."""
    if porta_viva(9222):
        chrome_headless_chiudi()
        for _ in range(15):
            if not porta_viva(9222):
                break
            time.sleep(1)
    for c in CHROME_PATHS:
        if not os.path.exists(c):
            continue
        argomenti = [c, "--remote-debugging-port=9222", f"--user-data-dir={PROFILO_WIN}",
                     "--no-first-run", "--no-default-browser-check"]
        if not mostra:
            argomenti += ["--headless=new", "--disable-gpu", "about:blank"]
        else:
            argomenti += ["https://www.google.com"]
        subprocess.Popen(argomenti, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(20):
            if porta_viva(9222):
                return True
            time.sleep(1)
        return porta_viva(9222)
    return False


def chrome_headless_chiudi():
    try:
        from checkin_agentrouter import WS, http_json
        info = http_json("/json/version")
        ws = WS(info["webSocketDebuggerUrl"])
        ws.call("Browser.close", timeout=10)
    except Exception:
        pass


_chk_lock = threading.Lock()
_ultimo_tentativo = [0.0]




def fai_checkin(forza=False):
    if not _chk_lock.acquire(blocking=False):
        return {"stato": "in_corso", "msg": "⏳ Riscatto già in corso..."}
    try:
        return _fai_checkin(forza)
    finally:
        _chk_lock.release()


def _fai_checkin(forza=False):
    if not finestra_aperta():
        return {"stato": "finestra_chiusa", "saldo": saldo_ultimo(), "finestra": "18:05",
                "msg": f"⏳ Sono le {adesso_hhmm()}: il bonus si riscatta dalle 18:05 (ora italiana). "
                       f"Nessun login/logout fatto — regola anti-ban."}
    if os.path.exists(flag_checkin()):
        # oggi è chiuso: inutile aprire il browser un'altra volta
        return {"stato": "gia_fatto", "saldo": saldo_ultimo(),
                "msg": "💰 Il bonus di oggi è già preso: ci rivediamo domani dopo le 18:05."}
    if not forza and serve_login_manuale():
        return {"stato": "serve_login_manuale", "saldo": saldo_ultimo(), "login_manuale": True,
                "msg": "⚠️ Serve un login a mano nel BROWSER_AGENTI (GitHub): fallo, poi premi «Riscatta ora»."}
    if not forza and tentativi_oggi() >= MAX_TENTATIVI:
        return {"stato": "stop", "saldo": saldo_ultimo(),
                "msg": f"🛑 Già {MAX_TENTATIVI} tentativi oggi: mi fermo (niente logout a vuoto). Riprovo domani."}

    avviato_da_noi = False
    if not porta_viva(9222):
        if not chrome_headless_avvia():
            return {"stato": "errore", "msg": "Browser agenti non avviabile (Chrome non trovato?)"}
        avviato_da_noi = True
        time.sleep(3)
    try:
        env = dict(os.environ)
        if forza:
            env["FORZA"] = "1"        # il tasto «Riscatta ora» è una richiesta esplicita: salta le guardie
        p = subprocess.run(["python3", os.path.join(POSTA, "checkin_agentrouter.py")],
                           capture_output=True, text=True, timeout=300, env=env)
        out = (p.stdout or "") + (p.stderr or "")
        rc = p.returncode
    except Exception as e:
        out, rc = f"ERRORE: {e}", 1
    ok = (rc == 0)
    if avviato_da_noi:
        chrome_headless_chiudi()

    scrivi(os.path.join(POSTA, "dal_pc", "agentrouter_checkin.md"),
           f"# 💰 Check-in AgentRouter (GUI) — {time.strftime('%d/%m/%Y %H:%M')}\n\n```\n{out}\n```\n")

    if rc not in (2, 4, 5):           # browser spento / finestra chiusa / salto = non sono tentativi veri
        segna_tentativo()
    if ok:
        scrivi(flag_checkin(), time.strftime("%H:%M"))
        pulisci_login_manuale()
    elif rc == 3:
        riga = next((r for r in out.splitlines() if r.startswith("[login_manuale]")), "serve login manuale")
        segna_login_manuale(riga.replace("[login_manuale]", "").strip())

    # sul ponte solo quando c'è qualcosa da dire (e mai in collaudo)
    if not TEST and (ok or rc == 3 or tentativi_oggi() >= MAX_TENTATIVI):
        subprocess.Popen(["bash", "-c",
                          f"cd '{POSTA}' && git add -A && git commit -qm 'checkin: esito {rc}' && git push -q origin main"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    m = re.search(r"saldo dopo: \$?([0-9][0-9.,]*)", out)
    d = re.search(r"delta:\s*([+-]?[0-9.]+)", out)
    if ok:
        msg = (f"✅ +{d.group(1)}$ riscattati!" if (d and float(d.group(1)) >= 20)
               else "✅ Giro completato (bonus già preso oggi o accredito in arrivo).")
    elif rc == 3:
        msg = "⚠️ Serve un login a mano nel BROWSER_AGENTI (GitHub) → poi «Riscatta ora»."
    elif rc == 4:
        msg = "⏳ Finestra chiusa: si riscatta dalle 18:05."
    elif rc == 5:
        msg = "⏭ Niente da fare: o è già fatto oggi, o serve il login a mano."
    elif rc == 2:
        msg = "⚠️ BROWSER_AGENTI spento: apri l'icona e riprova."
    else:
        msg = "⚠️ Giro non completato — vedi log."
    return {"stato": "ok" if ok else ("serve_login_manuale" if rc == 3 else "fallito"),
            "saldo": m.group(1) if m else saldo_ultimo(), "msg": msg,
            "tentativi": tentativi_oggi(), "max_tentativi": MAX_TENTATIVI,
            "login_manuale": serve_login_manuale() and not os.path.exists(flag_checkin()), "log": out[-1800:]}


_salute_cache = {"t": 0.0, "v": None}
_ANSI = re.compile(r"\x1b\[[0-9;]*m")

def salute(fresco=False):
    """Gira verifica.sh (0,1 s, sola lettura) e traduce l'output in un verdetto per la GUI."""
    if not fresco and _salute_cache["v"] and time.time() - _salute_cache["t"] < 60:
        return _salute_cache["v"]
    v = {"verdetto": "🩺 verifica non disponibile", "colore": "grigio", "rossi": [], "gialli": [],
         "note": [], "righe": [], "secondi": 0, "ora": time.strftime("%H:%M:%S")}
    script = os.path.join(POSTA, "verifica.sh")
    if os.path.exists(script):
        t0 = time.time()
        try:
            out = subprocess.run(["bash", script], capture_output=True, text=True, timeout=25).stdout or ""
        except Exception as e:
            out = ""
            v["errore"] = str(e)
        v["secondi"] = round(time.time() - t0, 2)
        pulito = _ANSI.sub("", out)
        for riga in pulito.splitlines():
            r = riga.strip()
            if "TUTTO A POSTO" in r or "PROBLEMI" in r or "cose da guardare" in r:
                v["verdetto"] = r          # è la riga del verdetto finale: l'ultima vince
            if r[:1] in ("✓", "✗", "·", "◦"):
                esito = {"✓": "ok", "✗": "no", "·": "att", "◦": "nota"}[r[0]]
                resto = r[1:].strip()
                nome = resto[:26].strip()
                dettaglio = resto[26:].strip() if len(resto) > 26 else ""
                voce = {"esito": esito, "nome": nome, "dettaglio": dettaglio}
                v["righe"].append(voce)
                if esito == "no":
                    v["rossi"].append(voce)
                elif esito == "att":
                    v["gialli"].append(voce)
                elif esito == "nota":
                    v["note"].append(voce)          # stato normale: non è un problema
        if "TUTTO A POSTO" in v["verdetto"]:
            v["colore"] = "verde"
        elif "PROBLEMI" in v["verdetto"]:
            v["colore"] = "rosso"
        elif "da guardare" in v["verdetto"]:
            v["colore"] = "giallo"
    _salute_cache["t"] = time.time()
    _salute_cache["v"] = v
    return v


# cosa vuol dire ogni controllo rosso, in italiano, e cosa fare
SPIEGAZIONE = {
    "Node v22": ("il runtime della Centrale locale",
                 "si sistema con la manutenzione confermata del PC."),
    "chiavi": ("il portachiavi locale dei provider",
               "controlla che il file di chiavi locale sia leggibile; nessuna chiave viene inviata al browser."),
    "postino": ("la sincronizzazione GitHub locale",
                "avviala manualmente dalla sezione Repository dopo aver controllato le modifiche."),
}


def salute_chiara():
    """Il paracadute: ogni problema detto in chiaro, con cosa vuol dire e cosa fare."""
    v = salute()
    righe = []
    for voce in v.get("rossi", []):
        nome = voce.get("nome", "")
        cosa, chefare = "", ""
        for chiave_sp, (c, f) in SPIEGAZIONE.items():
            if chiave_sp.lower() in nome.lower():
                cosa, chefare = c, f
                break
        righe.append({"tipo": "rosso", "nome": nome.strip(),
                      "dettaglio": voce.get("dettaglio", ""),
                      "cosa": cosa or "un pezzo del sistema",
                      "chefare": chefare or "premi «Ricontrolla»; se resta rosso, mandamelo."})
    for voce in v.get("gialli", []):
        righe.append({"tipo": "giallo", "nome": voce.get("nome", "").strip(),
                      "dettaglio": voce.get("dettaglio", ""),
                      "cosa": "una cosa da guardare (non blocca niente)",
                      "chefare": "puoi continuare a usare tutto."})
    note = [f"{n.get('nome', '').strip()} — {n.get('dettaglio', '')}".strip(" —")
            for n in v.get("note", [])]
    return {"verdetto": v.get("verdetto", ""), "colore": v.get("colore", "grigio"),
            "rossi": len(v.get("rossi", [])), "gialli": len(v.get("gialli", [])),
            "note": note, "voci": righe, "ora": v.get("ora", ""), "secondi": v.get("secondi", 0)}


def avvisi_accensione():
    """All'accensione: se c'è qualcosa che non va, lo dico subito (una volta sola)."""
    if _avvisi["fatto"]:
        return _avvisi["lista"]
    _avvisi["fatto"] = True
    lista = []
    try:
        sc = salute_chiara()
        for voce in sc["voci"]:
            if voce["tipo"] != "rosso":
                continue
            lista.append(f"🔴 {voce['nome']} — problema con {voce['cosa']}.\n"
                         f"   {voce['dettaglio']}\n   Cosa fare: {voce['chefare']}")
    except Exception:
        pass
    try:
        ap = appello_dati()
        if ap.get("voci"):
            rotti = [v["nome"] for v in ap["voci"] if v.get("esito") not in ("risponde", "no-chiave")]
            if rotti:
                lista.append("🟡 Chiavi che adesso non rispondono: " + ", ".join(rotti) +
                             ".\n   Non è un guasto tuo: sono limiti o crediti del provider. "
                             "Le altre chiavi funzionano.")
    except Exception:
        pass
    _avvisi["lista"] = lista
    return lista


_avvisi = {"fatto": False, "lista": []}













_oc_cmd_cache = {"t": 0.0, "cmd": ""}













_oc_in_corso = {"quando": 0.0, "azione": ""}








_inst_agenti = {"in_corso": False, "log": "", "quando": ""}








def postino_acceso():
    """Il postino gira? Si guardano tutti i nomi con cui può essere partito (postino.sh, posta-sync.sh):
    una sola domanda al sistema, niente git, quindi si puo' chiedere spesso."""
    try:
        for nome in ("postino.sh", "posta-sync.sh"):
            if subprocess.run(["pgrep", "-f", nome], capture_output=True, timeout=5).returncode == 0:
                return True
        return False
    except Exception:
        return False


def ponte_stato():
    """Il ponte GitHub: ultimo commit, quante modifiche aperte, se il postino gira."""
    d = {"commit": "", "data": "", "modifiche": 0, "postino": False, "avanti": 0}
    try:
        d["commit"] = subprocess.run(["git", "-C", POSTA, "rev-parse", "--short", "HEAD"],
                                     capture_output=True, text=True, timeout=10).stdout.strip()
        d["data"] = subprocess.run(["git", "-C", POSTA, "log", "-1", "--date=format:%d/%m %H:%M", "--format=%cd"],
                                   capture_output=True, text=True, timeout=10).stdout.strip()
        d["modifiche"] = len([r for r in subprocess.run(["git", "-C", POSTA, "status", "--porcelain"],
                                                        capture_output=True, text=True, timeout=15).stdout.splitlines() if r.strip()])
        rami = subprocess.run(["git", "-C", POSTA, "log", "--oneline", "@{u}..HEAD"],
                              capture_output=True, text=True, timeout=15)
        if rami.returncode == 0:
            d["avanti"] = len([r for r in rami.stdout.splitlines() if r.strip()])
    except Exception:
        pass
    try:
        d["postino"] = subprocess.run(["pgrep", "-f", "postino.sh"], capture_output=True, timeout=5).returncode == 0
    except Exception:
        d["postino"] = False
    return d


_aggiorna = {"in_corso": False, "log": "", "quando": ""}


def aggiorna_pc():
    """Lancia aggiorna_tutto.sh in sottofondo (una volta per volta)."""
    if _aggiorna["in_corso"]:
        return {"stato": "in_corso", "msg": "Sto già aggiornando: aspetta.", "log": _aggiorna["log"][-2000:]}
    _aggiorna.update({"in_corso": True, "log": "", "quando": time.strftime("%H:%M")})

    def _lavoro():
        try:
            p = subprocess.run(["bash", os.path.join(POSTA, "aggiorna_tutto.sh")],
                               capture_output=True, text=True, timeout=900, cwd=POSTA)
            _aggiorna["log"] = ((p.stdout or "") + (p.stderr or ""))[-3000:]
        except Exception as e:
            _aggiorna["log"] = f"Errore: {e}"
        finally:
            _aggiorna["in_corso"] = False
    threading.Thread(target=_lavoro, daemon=True).start()
    return {"stato": "avviato", "msg": "Aggiornamento partito: 1-3 minuti. Puoi continuare a usare l'Hub.",
            "log": _aggiorna["log"]}

# ─────────────────────── appello delle chiavi (riserva) ────────────────────
APPELLO_JSON = os.path.join(HOME, ".posta_appello.json")

# ── LA LISTA DEL PORTIERE (motore 2, porta 20129) ────────────────────────────
# La lista è UNA sola, nel file portiere_lista.txt: la leggono il Portiere, l'appello
# delle chiavi e questa schermata. Se un provider non è lì dentro, il Portiere non lo usa.
LISTA_PORTIERE = os.path.join(POSTA, "portiere_lista.txt")


def lista_portiere():
    """id → (indirizzo, modello, etichetta, nome nel portachiavi, modo)."""
    out = {}
    try:
        with open(LISTA_PORTIERE, encoding="utf-8", errors="replace") as f:
            righe = f.read().splitlines()
    except Exception:
        return out
    for riga in righe:
        r = riga.strip()
        if r.startswith("##"):
            break
        if not r or r.startswith("#"):
            continue
        pezzi = r.split("|")
        if len(pezzi) < 5:
            continue
        out[pezzi[0]] = (pezzi[3].rstrip("/"), pezzi[4], pezzi[1], pezzi[2],
                         pezzi[5] if len(pezzi) > 5 else "chat",
                         (pezzi[6] if len(pezzi) > 6 else "chat").strip() or "chat")
    return out


APP_BASE = {k: (v[0], v[1]) for k, v in lista_portiere().items()}


def appello_dati():
    """L'ultimo appello: chi risponde e in che ordine usarlo."""
    try:
        d = json.loads(open(APPELLO_JSON, encoding="utf-8").read())
        if isinstance(d, dict) and "voci" in d:
            return d
    except Exception:
        pass
    return {"quando": "", "riserva": [], "voci": []}


def appello_lancia(svelto=True):
    """Appello delle chiavi in sottofondo (silenzioso, nessun terminale)."""
    if _appello_stato["in_corso"]:
        return {"stato": "in_corso", "msg": "⏳ Appello già in corso: 20-60 secondi."}
    _appello_stato["in_corso"] = True
    _appello_stato["quando"] = time.time()

    def _lavoro():
        try:
            argomenti = ["bash", os.path.join(POSTA, "appello_chiavi.sh")]
            if svelto:
                argomenti.append("--svelto")
            subprocess.run(argomenti, capture_output=True, text=True, timeout=600,
                           cwd=POSTA, start_new_session=True)
        except Exception:
            pass
        finally:
            _appello_stato["in_corso"] = False
    threading.Thread(target=_lavoro, daemon=True).start()
    return {"stato": "avviato",
            "msg": "🗣️ Appello delle chiavi partito: 20-60 secondi, te lo dico io chi risponde."}


_appello_stato = {"in_corso": False, "quando": 0.0}


_CHIAVI_CACHE = {}          # pid → (chiave, quando): evita un giro di bash a ogni chiamata


# quali servizi possono fare una chat: gli altri (immagini, video, voce, embedding, db)
# restano nel portachiavi ma non si chiamano per una domanda.
TIPI_CHAT = ("chat", "visione")

# provider che accettano la «chiave anonima» ufficiale quando nel portachiavi non c'è nulla
CHIAVE_ANONIMA = {"aihorde": "0000000000"}


def puo_chattare(pid):
    v = lista_portiere().get(pid)
    if not v:
        return False
    modo, tipo = v[4], v[5]
    return modo != "no" and tipo in TIPI_CHAT


def chat_verificata(pid):
    """True = per questo provider è già passata una domanda vera (modo «chat»)."""
    v = lista_portiere().get(pid)
    return bool(v) and v[4] == "chat"


def chiave_provider(pid, ttl=600):
    """La chiave di un provider, presa dal portachiavi (una sola fonte).
    In memoria per 10 minuti: la rotazione fa più chiamate di fila e il portachiavi non cambia."""
    c = _CHIAVI_CACHE.get(pid)
    if c and (time.time() - c[1]) < ttl:
        return c[0]
    try:
        p = subprocess.run(["bash", os.path.join(POSTA, "appello_chiavi.sh"), "--chiave", pid],
                           capture_output=True, text=True, timeout=20)
        k = (p.stdout or "").strip()
        _CHIAVI_CACHE[pid] = (k, time.time())
        return k
    except Exception:
        return ""


# ── IL ROUTER NOSTRO ────────────────────────────────────────────────────────
# Missione 16/10: «la rotazione, il fallback e la contabilità per chiave sono nostri».
# Tutto quello che segue lavora con le NOSTRE chiavi (portachiavi del PC), zero centralino.
ROTAZIONE_JSON = os.path.join(QUI, "contabilita.json")
_ROTA = {"giorno": "", "provider": {}, "storia": {}}
_ROTA_LOCK = threading.RLock()   # rientrante: si aggiorna e si salva sotto lo stesso lock

# tetti DICHIARATI nel registro (TAPPA0_AUDIT §8): servono alla tabella capacità.
# match = pezzo di nome/id che riconosce il provider. None = non dichiarato.
CAPACITA = {
    "groq":           {"req_giorno": 1000, "tok_giorno": None,         "nota": "audio: 2.000 richieste/gg · 8 h/gg"},
    "airforce":       {"req_giorno": 1000, "tok_giorno": None,         "nota": "Api.Airforce"},
    "kilo":           {"req_giorno": 5000, "tok_giorno": None,         "nota": "+200/ora"},
    "dreamprompting": {"req_giorno": 5000, "tok_giorno": 500000,       "nota": "rolling 24h"},
    "routeway":       {"req_giorno": 200,  "tok_giorno": None,         "nota": ""},
    "bazaarlink":     {"req_giorno": 150,  "tok_giorno": None,         "nota": ""},
    "lucidity":       {"req_giorno": 80,   "tok_giorno": None,         "nota": "Synth"},
    "septor":         {"req_giorno": 50,   "tok_giorno": None,         "nota": ""},
    "orcarouter":     {"req_giorno": 50,   "tok_giorno": None,         "nota": ""},
    "google":         {"req_giorno": 20,   "tok_giorno": None,         "nota": "~20 (Gemini flash)"},
    "nararouter":     {"req_giorno": None, "tok_giorno": 7000000,      "nota": ""},
    "xkiro":          {"req_giorno": None, "tok_giorno": 1000000,      "nota": "0,5-1M"},
    "longcat":        {"req_giorno": None, "tok_giorno": 500000,       "nota": "ora 402"},
    "blaze":          {"req_giorno": None, "tok_giorno": 200000,       "nota": "BlazeAPI"},
    "navy":           {"req_giorno": None, "tok_giorno": 150000,       "nota": "in pausa"},
    "llm7":           {"req_giorno": None, "tok_giorno": 100000,       "nota": ""},
    "aion":           {"req_giorno": None, "tok_giorno": 20000,        "nota": ""},
    "mistral":        {"req_giorno": None, "tok_giorno": None,         "nota": "100M token/mese", "tok_mese": 100000000},
    "electronhub":    {"req_giorno": None, "tok_giorno": None,         "nota": "100k token/mese", "tok_mese": 100000},
    "cohere":         {"req_giorno": None, "tok_giorno": None,         "nota": "1.000 chiamate/mese", "req_mese": 1000},
    "inferbase":      {"req_giorno": None, "tok_giorno": None,         "nota": "5.000 richieste/mese + $0,50/gg", "req_mese": 5000},
    "router9":        {"req_giorno": None, "tok_giorno": None,         "nota": "10.000 crediti/mese", "req_mese": 10000},
}

# chi vale di più quando si chiede «auto:smart» (qualità, non velocità)
PESO = {"mistral": 9, "cohere": 8, "githubmodels": 8, "huggingface": 7, "groq": 7,
        "agentrouter": 6, "opencode": 6, "pollinationsfree": 5, "pollinations": 4,
        "aihorde": 3}


def _oggi():
    return time.strftime("%Y-%m-%d")


def ultimi(messaggi, quanti=12):
    """Gli ultimi N messaggi MA con tutte le istruzioni di sistema davanti.
    Senza questo, in una chat lunga sparivano godmode, trading, documenti e ricerca web."""
    sistema = [m for m in messaggi if m.get("role") == "system"]
    resto = [m for m in messaggi if m.get("role") != "system"]
    return sistema + resto[-max(1, quanti):]


def _rota_carica(forza=False):
    """Contabilità del giorno + pause: file locale, solo numeri, MAI chiavi.
    Si legge dal disco UNA volta (o al cambio di giorno): rileggere a ogni chiamata
    faceva perdere i conti quando due richieste andavano in parallelo."""
    global _ROTA
    with _ROTA_LOCK:
        if not forza and _ROTA.get("giorno") == _oggi():
            return
        try:
            d = json.loads(open(ROTAZIONE_JSON, encoding="utf-8").read())
            if isinstance(d, dict) and d.get("giorno") == _oggi():
                _ROTA = {"giorno": d.get("giorno"), "provider": d.get("provider") or {},
                         "storia": d.get("storia") or {}}
                return
            storia = (d.get("storia") or {}) if isinstance(d, dict) else {}
        except Exception:
            storia = {}
        _ROTA = {"giorno": _oggi(), "provider": {}, "storia": storia}


def _rota_salva():
    """Scrittura atomica (file temporaneo + replace): un'interruzione non lascia
    il file dei conti a metà e due richieste in parallelo non si sovrascrivono."""
    with _ROTA_LOCK:
        try:
            giorni = sorted(_ROTA["storia"].keys())[-7:]
            _ROTA["storia"] = {g: _ROTA["storia"][g] for g in giorni}
            tmp = ROTAZIONE_JSON + ".tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump(_ROTA, f, ensure_ascii=False, indent=1)
                f.flush()
                os.fsync(f.fileno())
            os.replace(tmp, ROTAZIONE_JSON)
        except Exception:
            pass


def _voce(pid):
    _ROTA["provider"].setdefault(pid, {"chiamate": 0, "ok": 0, "errori": 0,
                                       "tok_in": 0, "tok_out": 0, "ms": 0,
                                       "ultimo_errore": "", "freddo_fino": 0.0})
    return _ROTA["provider"][pid]


def _freddo(pid):
    """Quanti secondi mancano prima di poter riprovare (0 = si può)."""
    v = _ROTA["provider"].get(pid) or {}
    return max(0, int((v.get("freddo_fino") or 0) - time.time()))


def _congela(pid, secondi, motivo=""):
    v = _voce(pid)
    v["freddo_fino"] = time.time() + max(5, min(int(secondi or 60), 24 * 3600))
    if motivo:
        v["ultimo_errore"] = motivo[:160]


def _retry_after(e):
    """Interpreta Retry-After e messaggi di rate-limit dei provider upstream."""
    try:
        ra = e.headers.get("Retry-After") if getattr(e, "headers", None) else None
        if ra:
            ra = str(ra).strip()
            if ra.isdigit():
                return int(ra)
            try:
                import email.utils
                return max(5, int(email.utils.parsedate_to_datetime(ra).timestamp() - time.time()))
            except Exception:
                pass
    except Exception:
        pass
    try:
        corpo = e.read().decode("utf-8", "replace")[:400]
    except Exception:
        corpo = ""
    m = re.search(r"(?:try again|riprova)\D{0,12}(\d+)\s*(second|sec|s\b|minute|min)", corpo or "", re.I)
    if m:
        val = int(m.group(1))
        return val * 60 if m.group(2).lower().startswith("min") else val
    return 0


def _posta_diretta(m, messaggi, quanti=900, timeout=70):
    """Una chiamata DIRETTA al provider. Ritorna (testo, errore, secondi_da_aspettare)."""
    import urllib.request
    pid = m["id"]
    # Per l'API agenti usiamo solo modelli allowlisted; il router normale resta invariato
    restanti = _freddo(pid)
    if restanti:
        return "", "in pausa ancora %ds" % restanti, restanti
    k = chiave_provider(pid)
    if k == "free" or not k:
        k = CHIAVE_ANONIMA.get(pid, "")      # senza chiave: solo chi ha una chiave anonima ufficiale
    if not k:
        return "", "chiave assente nel portachiavi", 0
    t0 = time.time()
    base = (m.get("base") or "").rstrip("/")
    if base.startswith("SPECIALE-"):
        # Cloudflare non ha un indirizzo uguale per tutti: è accounts/<account_id>/ai/v1
        # e l'account_id sta DENTRO la chiave, prima dei due punti.
        acc, _, solo_token = k.partition(":")
        acc = acc.strip()
        if not acc or not solo_token:
            return "", "chiave Cloudflare senza account_id (formato account_id:token)", 0
        k = solo_token.strip()      # nel «Bearer» va SOLO il token, l'account sta nell'indirizzo
        base = "https://api.cloudflare.com/client/v4/accounts/%s/ai/v1" % acc
    try:
        req = urllib.request.Request(
            base + "/chat/completions",
            data=json.dumps({"model": m["modello"], "messages": ultimi(messaggi, 12),
                             "max_tokens": quanti}).encode(),
            headers={"Authorization": "Bearer " + k, "Content-Type": "application/json",
                     "Accept": "application/json", "User-Agent": _UA_WEB})
        d = json.loads(urllib.request.urlopen(req, timeout=timeout).read().decode())
        scelta = (d.get("choices") or [{}])[0]
        testo = ((scelta.get("message") or {}).get("content") or "").strip()
        if not testo and (scelta.get("finish_reason") == "length"
                          or (scelta.get("message") or {}).get("reasoning_content")):
            corpo2 = json.dumps({"model": m["modello"], "messages": ultimi(messaggi, 12),
                                 "max_tokens": max(800, quanti * 4)}).encode()
            req2 = urllib.request.Request(base + "/chat/completions", data=corpo2,
                                          headers={"Authorization": "Bearer " + k,
                                                   "Content-Type": "application/json",
                                                   "Accept": "application/json",
                                                   "User-Agent": _UA_WEB})
            d2 = json.loads(urllib.request.urlopen(req2, timeout=timeout).read().decode())
            scelta2 = (d2.get("choices") or [{}])[0]
            testo2 = ((scelta2.get("message") or {}).get("content") or "").strip()
            if testo2:
                testo, scelta, d = testo2, scelta2, d2
        uso = d.get("usage") or {}
        ms = int((time.time() - t0) * 1000)
        with _ROTA_LOCK:
            v = _voce(pid)
            v["chiamate"] += 1
            v["ms"] += ms
            v["tok_in"] += int(uso.get("prompt_tokens") or 0)
            v["tok_out"] += int(uso.get("completion_tokens") or 0)
            if testo:
                v["ok"] += 1
            else:
                v["errori"] += 1
                v["ultimo_errore"] = "risposta vuota"
            _rota_salva()
        return testo, ("" if testo else "risposta vuota"), 0
    except Exception as e:
        ms = int((time.time() - t0) * 1000)
        attesa = _retry_after(e)
        motivo = ""
        try:
            import urllib.error
            if isinstance(e, urllib.error.HTTPError):
                motivo = "HTTP %s" % e.code
                if e.code in (429, 402, 403, 503):
                    attesa = attesa or 120
            else:
                motivo = e.__class__.__name__
        except Exception:
            motivo = str(e)[:120]
        with _ROTA_LOCK:
            v = _voce(pid)
            v["chiamate"] += 1
            v["errori"] += 1
            v["ms"] += ms
            v["ultimo_errore"] = motivo
            if attesa:
                _congela(pid, attesa, motivo)
            _rota_salva()
        return "", motivo, attesa


def _candidati(modello="auto", quanti=6):
    """Chi provare, in che ordine. «priority» per un modello scelto, «fastest» per auto,
    «più forte prima» per auto:smart. Le pause della rotazione si rispettano sempre."""
    # si prova TUTTO quello che può chattare: se il file dell'appello è vecchio il router
    # non deve restare fermo. L'ordine però è onesto: prima chi ha già risposto a una
    # domanda vera, poi chi risponde all'elenco, poi gli altri. Chi si difende con un
    # 429/402 finisce in pausa da solo.
    tutti = modelli_nostri(False)
    m = str(modello or "auto").lower()
    if m in ("auto", "auto:fast", "fast", ""):
        ordine = sorted(tutti, key=lambda x: x["ms"])
    elif m in ("auto:smart", "smart", "auto:best"):
        ordine = sorted(tutti, key=lambda x: (-PESO.get(x["id"], 2), x["ms"]))
    else:
        # Una scelta esplicita identifica un solo modello: mai allargare la selezione.
        per_id = [x for x in tutti if m == str(x.get("id", "")).lower()]
        if per_id:
            return per_id[:1] if len(per_id) == 1 else []
        per_nome = [x for x in tutti if m == str(x.get("modello", "")).lower()]
        if per_nome:
            return per_nome[:1] if len(per_nome) == 1 else []
        # Il suffisso del nome modello è accettato solo se univoco.
        per_suffisso = [x for x in tutti
                        if str(x.get("modello", "")).lower().endswith("/" + m)]
        return per_suffisso[:1] if len(per_suffisso) == 1 else []
    # tre livelli, poi l'ordine della strategia: verificato+risponde · risponde · da provare
    def livello(x):
        if x.get("verificato") and (x.get("stato") or "") == "risponde":
            return 0
        if (x.get("stato") or "") == "risponde":
            return 1
        return 2
    ordine = sorted(ordine, key=livello)   # sort stabile: dentro ogni livello resta la strategia
    return ordine[:max(1, quanti)]


def chat_diretta(messaggi, modello="auto", quanti=900, quante_prove=4, timeout=70):
    """Il percorso normale dell'hub: chiavi NOSTRE, uno dopo l'altro finché uno risponde.
    Ritorna (testo, nome, modello, via) oppure None."""
    for m in _candidati(modello, quante_prove):
        testo, errore, attesa = _posta_diretta(m, messaggi, quanti, timeout)
        if testo:
            return testo, m["provider"], m["modello"], "diretto " + m["provider"]
    return None


def contabilita():
    """Chi ha lavorato oggi, quanto, e chi è in pausa: numeri onesti, nessuna chiave."""
    _rota_carica()
    nomi = {k: v[2] for k, v in lista_portiere().items()}
    righe = []
    for pid, v in sorted(_ROTA["provider"].items(), key=lambda kv: -kv[1]["chiamate"]):
        righe.append({"id": pid, "nome": nomi.get(pid, pid),
                      "chiamate": v["chiamate"], "ok": v["ok"], "errori": v["errori"],
                      "token": v["tok_in"] + v["tok_out"],
                      "ms": (int(v["ms"] / v["chiamate"]) if v["chiamate"] else 0),
                      "in_pausa": _freddo(pid), "ultimo_errore": v["ultimo_errore"]})
    tot = {"richieste": sum(r["chiamate"] for r in righe),
           "successi": sum(r["ok"] for r in righe),
           "errori": sum(r["errori"] for r in righe),
           "token": sum(r["token"] for r in righe)}
    return {"giorno": _ROTA["giorno"], "provider": righe, "totali": tot,
            "storia": _ROTA["storia"],
            # forma compatibile col menu 🔢 uso dell'Hub (prima veniva dal centralino)
            "usage": {"totals": {"requests": tot["richieste"], "errors": tot["errori"],
                                 "successes": tot["successi"],
                                 "input_tokens": sum(v["tok_in"] for v in _ROTA["provider"].values()),
                                 "output_tokens": sum(v["tok_out"] for v in _ROTA["provider"].values())},
                      "topModels": [{"model_id": r["nome"], "requests": r["chiamate"]}
                                    for r in righe[:6]]}}


def capacita():
    """TABELLA CAPACITÀ (TAPPA0_AUDIT §8): i tetti DICHIARATI + quello che abbiamo usato oggi."""
    _rota_carica()
    righe = []
    for pid, v in lista_portiere().items():
        if not puo_chattare(pid):
            continue
        chiave_cap = ""
        for k in CAPACITA:
            if k in (pid + " " + v[2]).lower():
                chiave_cap = k
                break
        cap = CAPACITA.get(chiave_cap) or {}
        uso = _ROTA["provider"].get(pid) or {}
        righe.append({"id": pid, "nome": v[2],
                      "req_giorno": cap.get("req_giorno"), "tok_giorno": cap.get("tok_giorno"),
                      "req_mese": cap.get("req_mese"), "tok_mese": cap.get("tok_mese"),
                      "nota": cap.get("nota", ""),
                      "oggi_chiamate": uso.get("chiamate", 0),
                      "oggi_token": (uso.get("tok_in", 0) + uso.get("tok_out", 0))})
    righe.sort(key=lambda r: (-(r["req_giorno"] or 0), -(r["tok_giorno"] or 0), r["nome"]))
    return {"righe": righe,
            "totali": {"req_giorno": sum(r["req_giorno"] or 0 for r in righe),
                       "tok_giorno": sum(r["tok_giorno"] or 0 for r in righe)},
            "nota": "tetti dichiarati nel registro, non misurati: la verità è il primo giro reale"}




VIRTUALI = {"fusion", "code", "trading", "tailor", "vision", "docs", ""}

# Il router diretto risolve ogni richiesta con i provider configurati e le chiavi locali;
# Fusion usa solo i modelli scelti e invoca un giudice locale, senza avviare agenti.


# ── RICERCA WEB (senza chiavi): DDG lite → DDG via r.jina.ai → Wikipedia IT ──
_UA_WEB = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
           "(KHTML, like Gecko) Chrome/126 Safari/537.36")


def _pulisci_html(s):
    import html as _h
    s = re.sub(r"<[^>]*>", "", s or "")
    try:
        s = _h.unescape(s)          # &amp; &#232; &quot; … tutto in una volta
    except Exception:
        pass
    return re.sub(r"\s+", " ", s).strip()


def _ddg_url(u):
    m = re.search(r"uddg=([^&]+)", u or "")
    if m:
        try:
            import urllib.parse
            return urllib.parse.unquote(m.group(1))
        except Exception:
            return u
    return u


def _data_da_url(url):
    """La data di un articolo, letta dall'indirizzo; serve per far vincere la notizia più fresca."""
    import re as _re
    m = (_re.search(r"/(20\d{2})[/-](\d{1,2})[/-](\d{1,2})/", url) or
         _re.search(r"/(20\d{2})(\d{2})(\d{2})", url) or
         _re.search(r"[/-](20\d{2})[/-](\d{1,2})[/-](\d{1,2})", url))
    if not m:
        return ""
    try:
        return "%s-%02d-%02d" % (m.group(1), int(m.group(2)), int(m.group(3)))
    except Exception:
        return ""


def _asporta_html(html):
    """Il testo leggibile di una pagina (senza script, stili e tag)."""
    import re as _re
    html = _re.sub(r"(?is)<(script|style|noscript|header|footer|nav)[^>]*>.*?</\1>", " ", html)
    html = _re.sub(r"(?is)<br\s*/?>|</p>|</div>|</li>|</h[1-6]>", "\n", html)
    testo = _re.sub(r"(?s)<[^>]+>", " ", html)
    for a1, b1 in (("&amp;", "&"), ("&quot;", '"'), ("&#x27;", "'"), ("&lt;", "<"),
                   ("&gt;", ">"), ("&nbsp;", " "), ("&rsquo;", "'"), ("&agrave;", "à"),
                   ("&egrave;", "è"), ("&igrave;", "ì"), ("&ograve;", "ò"), ("&ugrave;", "ù")):
        testo = testo.replace(a1, b1)
    testo = _re.sub(r"[ \t]+", " ", testo)
    testo = _re.sub(r"\n\s*\n\s*\n+", "\n\n", testo)
    return testo.strip()


def _leggi_pagina(url, quanti=2500):
    """Apre la pagina del risultato e ne riporta il testo: così il modello LEGGE i numeri veri."""
    import urllib.request
    try:
        req = urllib.request.Request(url, headers={"User-Agent": _UA_WEB,
                                                   "Accept-Language": "it-IT,it;q=0.9,en;q=0.8"})
        html = urllib.request.urlopen(req, timeout=12).read().decode("utf-8", "replace")
        testo = _asporta_html(html)
        return testo[:quanti]
    except Exception:
        return ""


def _notizie_bing(q, quante=5):
    """Le notizie fresche CON il link vero del giornale e la data (Bing News, gratis e senza chiave)."""
    import urllib.request, urllib.parse, email.utils
    out = []
    try:
        u = ("https://www.bing.com/news/search?format=RSS&setlang=it&q=" + urllib.parse.quote(q[:200]))
        xml = urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": _UA_WEB}),
                                     timeout=12).read().decode("utf-8", "replace")
        for blocco in re.findall(r"<item>(.*?)</item>", xml, re.S)[:quante]:
            tit = re.search(r"<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>", blocco, re.S)
            lnk = re.search(r"<link>(.*?)</link>", blocco, re.S)
            dat = re.search(r"<pubDate>(.*?)</pubDate>", blocco, re.S)
            if not tit or not lnk:
                continue
            link = _pulisci_html(lnk.group(1)).replace("&amp;", "&")
            vero = link
            m = re.search(r"[?&]url=([^&]+)", link)
            if m:
                vero = urllib.parse.unquote(m.group(1))
            if not vero.startswith("http"):
                continue
            data = ""
            if dat:
                try:
                    data = email.utils.parsedate_to_datetime(dat.group(1).strip()).strftime("%Y-%m-%d")
                except Exception:
                    data = ""
            out.append({"title": _pulisci_html(tit.group(1)), "url": vero, "snippet": "",
                        "data": data, "notizia": True})
    except Exception:
        pass
    return out


def _notizie(q, quante=5):
    """Le notizie FRESCHE con la data vera: Google News (gratis, senza chiave).
    Serve perché una pagina di supporto o un articolo vecchio non ti dicono qual è «l'ultima» versione."""
    import urllib.request, urllib.parse
    out = []
    try:
        u = ("https://news.google.com/rss/search?q=" + urllib.parse.quote(q)
             + "&hl=it&gl=IT&ceid=IT:it")
        xml = urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": _UA_WEB}),
                                     timeout=12).read().decode("utf-8", "replace")
        for blocco in re.findall(r"<item>(.*?)</item>", xml, re.S)[:quante]:
            tit = re.search(r"<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>", blocco, re.S)
            lnk = re.search(r"<link>(.*?)</link>", blocco, re.S)
            dat = re.search(r"<pubDate>(.*?)</pubDate>", blocco, re.S)
            if not tit:
                continue
            data = ""
            if dat:
                try:
                    import email.utils
                    d = email.utils.parsedate_to_datetime(dat.group(1).strip())
                    data = d.strftime("%Y-%m-%d")
                except Exception:
                    data = ""
            out.append({"title": _pulisci_html(tit.group(1)),
                        "url": (lnk.group(1).strip() if lnk else ""),
                        "snippet": "", "data": data, "notizia": True})
    except Exception:
        pass
    return out


def _bing(q, quanti=5):
    """Bing, senza chiave: seconda fonte quando DuckDuckGo fa i capricci (blocca l'indirizzo)."""
    import urllib.request, urllib.parse
    out = []
    try:
        u = "https://www.bing.com/search?setlang=it&q=" + urllib.parse.quote(q[:200])
        html = urllib.request.urlopen(urllib.request.Request(
            u, headers={"User-Agent": _UA_WEB, "Accept-Language": "it-IT,it;q=0.9"}), timeout=12
        ).read().decode("utf-8", "replace")
        for blocco in re.findall(r'<li class="b_algo".*?</li>', html, re.S)[:quanti]:
            m = re.search(r'<h2[^>]*>\s*<a[^>]*href="([^"]+)"[^>]*>([\s\S]*?)</a>', blocco)
            if not m:
                continue
            url = m.group(1)
            if not url.startswith("http"):
                continue
            snip = re.search(r'<p[^>]*>([\s\S]*?)</p>', blocco)
            out.append({"title": _pulisci_html(m.group(2)), "url": url,
                        "snippet": _pulisci_html(snip.group(1)) if snip else ""})
    except Exception:
        pass
    return out


def _url_da_titolo(titolo):
    """Trova l'indirizzo del sito che ha pubblicato la notizia (i link di Google News sono solo rimandi)."""
    import urllib.request, urllib.parse
    try:
        u = "https://lite.duckduckgo.com/lite/?q=" + urllib.parse.quote(titolo[:150])
        html = urllib.request.urlopen(urllib.request.Request(
            u, headers={"User-Agent": _UA_WEB, "Accept-Language": "it-IT,it;q=0.9"}),
            timeout=12).read().decode("utf-8", "replace")
        for m in re.finditer(r'href="([^"]*uddg=[^"]+)"', html):
            url = _ddg_url(m.group(1))
            if url.startswith("http") and "duckduckgo.com" not in url:
                return url
    except Exception:
        pass
    # seconda strada: Bing
    for r in _bing(titolo[:150], 3):
        if r["url"].startswith("http") and "bing.com" not in r["url"]:
            return r["url"]
    return ""


def _ricerca_web(q, quanti=6):
    """Cerca sul web gratis: prima DuckDuckGo lite, poi via r.jina.ai, poi Wikipedia IT."""
    import urllib.request, urllib.parse
    risultati = []
    intest = {"User-Agent": _UA_WEB, "Accept-Language": "it-IT,it;q=0.9,en;q=0.8"}
    # 1) DuckDuckGo lite, pagina HTML
    try:
        u = "https://lite.duckduckgo.com/lite/?q=" + urllib.parse.quote(q)
        html = urllib.request.urlopen(urllib.request.Request(u, headers=intest), timeout=12).read().decode("utf-8", "replace")
        link = re.findall(r'<a[^>]*href="([^"]*uddg=[^"]+)"[^>]*>([\s\S]*?)</a>', html, re.I)
        sni = [_pulisci_html(x) for x in re.findall(r'<td[^>]*class="result-snippet"[^>]*>([\s\S]*?)</td>', html, re.I)]
        for i, (ind, tit) in enumerate(link[:quanti]):
            url = _ddg_url(ind)
            if not url.startswith("http"):
                continue
            risultati.append({"title": _pulisci_html(tit), "url": url,
                              "snippet": sni[i] if i < len(sni) else ""})
    except Exception:
        pass
    # 2) stessa ricerca passando da r.jina.ai (quando DuckDuckGo blocca l'indirizzo)
    if not risultati:
        try:
            u = ("https://r.jina.ai/https://lite.duckduckgo.com/lite/?q=" + urllib.parse.quote(q))
            md = urllib.request.urlopen(urllib.request.Request(u, headers=intest), timeout=20).read().decode("utf-8", "replace")
            for m in re.finditer(r"\[([^\]]+)\]\(https://duckduckgo\.com/l/\?uddg=([^)]+)\)", md):
                url = _ddg_url("uddg=" + m.group(2))
                if not url.startswith("http") or "duckduckgo.com" in url:
                    continue
                dopo = md[m.end():m.end() + 400].strip().split("\n")[0]
                risultati.append({"title": _pulisci_html(m.group(1)), "url": url,
                                  "snippet": _pulisci_html(dopo)[:300]})
                if len(risultati) >= quanti:
                    break
        except Exception:
            pass
    # 3) Wikipedia in italiano (sempre gratis e affidabile come ultima spiaggia)
    if not risultati:
        try:
            u = ("https://it.wikipedia.org/w/api.php?action=query&list=search&format=json&srlimit=3&srsearch="
                 + urllib.parse.quote(q))
            d = json.loads(urllib.request.urlopen(urllib.request.Request(u, headers=intest), timeout=10).read().decode())
            for v in (d.get("query", {}).get("search") or [])[:3]:
                risultati.append({"title": v.get("title", ""),
                                  "url": "https://it.wikipedia.org/wiki/" + urllib.parse.quote(v.get("title", "").replace(" ", "_")),
                                  "snippet": _pulisci_html(v.get("snippet", ""))})
        except Exception:
            pass
    if not risultati:                      # DuckDuckGo muto: si prova Bing
        for r in _bing(q, quanti):
            r["data"] = _data_da_url(r["url"])
            risultati.append(r)
    # le notizie con la data e il LINK VERO (Bing News): è lì che sta «l'ultima»
    visti = {r["url"] for r in risultati}
    notizie = _notizie_bing(q)
    if not notizie:
        notizie = _notizie(q)
    for n in notizie:
        if n["url"] and n["url"] not in visti:
            risultati.append(n)
            visti.add(n["url"])
    for r in risultati:
        r["data"] = r.get("data") or _data_da_url(r.get("url", ""))
    # la più FRESCA vince
    risultati.sort(key=lambda r: r.get("data") or "0000-00-00", reverse=True)
    risultati = risultati[:quanti + 3]
    # le notizie fresche: si LEGGE l'articolo (il numero di versione sta lì, non nel titolo)
    limite = time.strftime("%Y-%m-%d", time.localtime(time.time() - 4 * 86400))
    letta = 0
    for r in risultati:
        if letta >= 2 or not r.get("notizia"):
            continue
        if (r.get("data") or "") < limite:
            continue                      # troppo vecchia: non serve aprire
        vero = r["url"]
        if "news.google.com" in vero:     # rimando di Google: non si può aprire
            vero = _url_da_titolo(r["title"])
            if not vero:
                continue
        letto = _leggi_pagina(vero)
        if letto:
            r["url"] = vero               # la fonte diventa il sito vero, non il rimando
            r["testo"] = letto
            r["notizia"] = False
            letta += 1
    # e si legge il testo delle prime pagine: versioni e date si prendono da lì, non dai titoli
    letti = 0
    for r in risultati:
        if letti >= 3:
            break
        if r.get("notizia"):        # i link di Google News sono rimandi: non si possono leggere
            continue
        letto = _leggi_pagina(r["url"])
        if letto:
            r["testo"] = letto
            letti += 1
    return risultati


def _righe_chiave(testo, quante=6):
    """Le frasi della pagina che contengono numeri di versione o date: sono quelle che contano."""
    out = []
    for frase in re.split(r"(?<=[.!?])\s+|\n", testo):
        f = frase.strip()
        if len(f) < 20 or len(f) > 400:
            continue
        if re.search(r"\d{2}\.\d{2}-\d{2}\.\d{2}|\bversione\b|\bversion\b|\bfirmware\b|\d{1,2}\s+(?:gennaio|febbraio|marzo|aprile|maggio|giugno|luglio|agosto|settembre|ottobre|novembre|dicembre)", f, re.I):
            out.append(f)
        if len(out) >= quante:
            break
    return out


def risultati_in_testo(risultati, domanda=""):
    """Il contesto per il modello, in ordine di importanza:
    1) la notizia più FRESCA (data certa), 2) la pagina letta per intero, 3) gli altri titoli."""
    if not risultati:
        return ""
    oggi = time.strftime("%d/%m/%Y")
    con_testo = [r for r in risultati if r.get("testo")]
    con_data = [r for r in risultati if r.get("data")]
    righe = [f"RICERCA WEB fatta adesso (oggi è il {oggi}). Questi sono i tuoi dati: usali al posto della memoria."]
    righe.append("")

    # ── 1 · le notizie più recenti, lette (per dire «l'ultima») ──
    if con_data:
        righe.append("═══ NOTIZIE PIÙ RECENTI — dalla più nuova alla più vecchia (per «ultima versione» vale SOLO questa parte) ═══")
        for p0 in con_data[:3]:
            righe.append(f"• del {p0['data']} — {p0['title']}")
            if p0.get("testo"):
                righe.append("  TESTO LETTO:")
                righe.append("  " + p0["testo"][:1500].replace("\n", "\n  "))
            else:
                righe.append(f"  (ho solo il titolo — sito: {p0['url']} — non inventare il numero: se serve dì che "
                             f"la notizia più recente è del {p0['data']} e riporta il titolo)")
            righe.append("")
        righe.append("═══ fine delle notizie più recenti ═══")
        righe.append("")

    # ── 1-bis · i numeri di versione che compaiono nelle notizie (così il modello non li salta) ──
    numeri = []
    for p0 in con_data[:3]:
        if not p0.get("testo"):
            continue
        for mm in re.finditer(r"\b\d{1,3}\.\d{1,3}(?:[.-]\d{1,3}){1,4}\b", p0["testo"]):
            n = mm.group(0)
            if n not in [x[0] for x in numeri] and not re.match(r"^\d{1,2}\.\d{1,2}$", n):
                numeri.append((n, p0["data"], p0["title"][:60]))
    if numeri:
        righe.append("NUMERI DI VERSIONE TROVATI NEL TESTO DELLE NOTIZIE (il più recente è il primo):")
        for n, d, ti in numeri[:6]:
            righe.append(f"  · {n}  (dalla notizia del {d}: {ti})")
        righe.append("")

    # ── 2 · le pagine lette (fonte di appoggio) ──
    altre = [r for r in con_testo if r is not (con_data[0] if con_data else None)][:2]
    for r in altre:
        righe.append(f"─── PAGINA LETTA: {r['title'][:100]} ({r['url']}) ───")
        chiave = _righe_chiave(r["testo"])
        if chiave:
            righe.append("FRASI CHE CONTANO:")
            for c in chiave:
                righe.append("  · " + c[:300])
        righe.append(r["testo"][:900])
        righe.append("")

    # ── 3 · gli altri titoli ──
    altri = [r for r in risultati if r not in con_testo][:6]
    if altri:
        righe.append("ALTRI TITOLI (possono essere VECCHI: NON servono per dire qual è l'ultima versione o l'ultima notizia):")
        for i, r in enumerate(altri, 1):
            quando = (" · del " + r["data"]) if r.get("data") else " · data non indicata"
            righe.append(f"[{i}] {r['title'][:120]} — {r['url']}{quando}")
        righe.append("")

    righe.append("REGOLE: rispondi in italiano e breve. Per fatti, versioni, date e prezzi usa SOLO quanto sopra. ")
    righe.append("Se la notizia più recente parla di un aggiornamento appena uscito e il numero preciso non è scritto, ")
    righe.append("dillo con la data invece di inventarlo. Un titolo vecchio NON è «l'ultima versione». ")
    righe.append("Se nelle fonti compare un numero di versione (per esempio 26.07-14.20.00) riportalo fra virgolette, ")
    righe.append("così si vede che l'hai letto e non inventato. Cita il sito tra parentesi.")
    return "\n".join(righe)


AVVISO_SENZA_WEB = ("La ricerca web NON ha dato risultati adesso. Se la domanda riguarda fatti recenti, "
                    "versioni, prezzi o notizie, dillo in una riga («non riesco a controllare online in questo "
                    "momento») e rispondi solo con quello che sai, dicendo che può essere vecchio.")


_MOTIVI = {}          # motore → ultimo motivo per cui non ha risposto


def segna_motivo(nome, errore):
    """Tiene il motivo VERO (es. 401, connessione rifiutata) per dirlo in chiaro all'utente."""
    e = errore
    try:
        import urllib.error
        if isinstance(e, urllib.error.HTTPError):
            corpo = ""
            try:
                corpo = e.read().decode("utf-8", "replace")[:200]
            except Exception:
                pass
            m = re.search(r'"message"\s*:\s*"([^"]{1,160})', corpo)
            _MOTIVI[nome] = "HTTP %s%s" % (e.code, (" — " + m.group(1)) if m else "")
            return
    except Exception:
        pass
    _MOTIVI[nome] = (str(e) or e.__class__.__name__)[:160]






def modelli_nostri(solo_pronti=True):
    """I modelli di chat che possiamo chiamare DIRETTAMENTE con le nostre chiavi (missione 16/10:
    l'hub non dipende dal centralino). Uno per provider, col modello che l'appello ha visto."""
    _rota_carica()
    voci = {v.get("id"): v for v in appello_dati().get("voci", [])}
    out = []
    for pid, v in lista_portiere().items():
        if pid not in APP_BASE or not puo_chattare(pid):
            continue
        voce = voci.get(pid) or {}
        if solo_pronti and voce.get("esito") != "risponde":
            continue
        if solo_pronti and _freddo(pid):
            continue                      # in pausa per un 429/402: non lo si tormenta
        base, modello = APP_BASE[pid]
        uso = _ROTA["provider"].get(pid) or {}
        out.append({"id": pid, "provider": (voce.get("nome") or pid),
                    "modello": (voce.get("modello") or modello), "base": base,
                    "verificato": chat_verificata(pid),
                    "ms": voce.get("ms") or 99999,
                    "stato": ("in pausa %ds" % _freddo(pid)) if _freddo(pid) else
                             (voce.get("esito") or "mai provato"),
                    "chiamate": uso.get("chiamate", 0), "errori": uso.get("errori", 0)})
    out.sort(key=lambda m: m["ms"])
    return out


def chiama_diretto(m, messaggi, quanti=900, timeout=70):
    """Una chiamata DIRETTA al provider, con la nostra chiave: nessun centralino di mezzo."""
    testo, _, _ = _posta_diretta(m, messaggi, quanti, timeout)
    return testo


def _risolvi_modello_nostro(riferimento, disponibili):
    """Risoluzione stretta degli ID fusion: solo modelli/provider già nel catalogo locale."""
    ref=str(riferimento or "").strip().lower()
    if not ref:
        return None
    def canon(m):
        return (str(m.get("id", "")) + "/" + str(m.get("modello", ""))).lower()
    exact=[m for m in disponibili if canon(m)==ref or str(m.get("id", "")).lower()==ref
           or str(m.get("modello", "")).lower()==ref]
    if len(exact)==1:
        return exact[0]
    suffix=[m for m in disponibili if canon(m).endswith("/"+ref)]
    return suffix[0] if len(suffix)==1 else None


def fusion_nostra(messaggi, quanti=3, modelli=None, giudice_rif=None, on_event=None):
    """Fusion locale con pannello e giudice espliciti; non avvia agenti né sonda il catalogo."""
    disponibili=modelli_nostri(False)
    for entry in modelli_agente_ammessi():
        if not any(str(x.get("id"))+"/"+str(x.get("modello")) == str(entry.get("api_id")) for x in disponibili):
            disponibili.append(entry)
    if modelli:
        panel=[]
        for riferimento in modelli:
            scelto=_risolvi_modello_nostro(riferimento, disponibili)
            if scelto and scelto not in panel:
                panel.append(scelto)
            if len(panel)>=max(2,int(quanti or 3)):
                break
        if len(panel)<2:
            return None
    else:
        panel=modelli_nostri(True)[:max(2,int(quanti or 3))]
        if len(panel)<2:
            panel=disponibili[:max(2,int(quanti or 3))]
    if len(panel)<2:
        return None
    import concurrent.futures as cf
    risposte=[]
    with cf.ThreadPoolExecutor(max_workers=len(panel)) as ex:
        futs={ex.submit(chiama_diretto,m,messaggi,900):m for m in panel}
        for future in cf.as_completed(futs,timeout=120):
            m=futs[future]
            try: testo=future.result()
            except Exception: testo=""
            canon=str(m.get("id",""))+"/"+str(m.get("modello",""))
            if on_event:
                try: on_event({"_fusion":{"event":"panel","model":canon,"status":"ok" if testo else "error"}})
                except Exception: pass
            if testo: risposte.append((m,testo))
    if len(risposte)<2:
        return None
    blocco="\n\n".join("### Risposta di %s (%s):\n%s"%(m.get("provider",m.get("id","?")),m.get("modello",""),testo)
                       for m,testo in risposte)
    domanda=""
    for item in reversed(messaggi):
        if isinstance(item,dict) and item.get("role")=="user":
            domanda=item.get("content") if isinstance(item.get("content"),str) else ""
            break
    prompt=[{"role":"system","content":"Sei il giudice di una squadra di modelli. Fondi le risposte in una risposta italiana precisa; correggi i contrasti, niente premesse né elenco dei modelli."},
            {"role":"user","content":"DOMANDA:\n%s\n\n%s"%(domanda[:1500],blocco[:9000])}]
    judge=_risolvi_modello_nostro(giudice_rif,disponibili) if giudice_rif else None
    if judge is None:
        judge=risposte[0][0]
    fuso=chiama_diretto(judge,prompt,900,90)
    if on_event and fuso:
        try: on_event({"_fusion":{"event":"judge","model":str(judge.get("id",""))+"/"+str(judge.get("modello","")),"platform":"Router Hub"}})
        except Exception: pass
    if not fuso:
        fuso=risposte[0][1]+"\n\n(giudice non disponibile: risposta parziale di %s)"%risposte[0][0].get("provider",risposte[0][0].get("id","?"))
    label=" + ".join(str(m.get("provider",m.get("id","?"))) for m,_ in risposte)
    used=[str(m.get("id",""))+"/"+str(m.get("modello","")) for m,_ in risposte]
    return fuso,label,used






# ── ENDPOINT PER GLI AGENTI (OpenAI-compatibile) ────────────────────────────
# «L'hub offre un endpoint OpenAI-compatibile ad agenti locali» (missione hub).
# Il token si genera da sé al primo uso e resta sul PC: senza token non si passa.
# Allowlist fail-closed: IDs canonici "provider-id/model-id" aggiunti dall'amministratore
# solo dopo verifica manuale di costo zero. Vuota per default; nessun modello esposto/invocato.
_DEFAULT_HUB_AGENT_FREE_MODELS_VERIFIED = ("nara/laguna-s-2.1",)
HUB_AGENT_FREE_MODELS_VERIFIED = tuple(
    x.strip() for x in os.environ.get(
        "HUB_AGENT_FREE_MODELS_VERIFIED", ",".join(_DEFAULT_HUB_AGENT_FREE_MODELS_VERIFIED)
    ).split(",") if x.strip()
)


def modelli_agente_ammessi():
    """Modelli allowlisted, a costo zero verificato, su provider locali configurati."""
    allow = {str(x).strip() for x in HUB_AGENT_FREE_MODELS_VERIFIED if str(x).strip()}
    if not allow:
        return []
    presenti = modelli_nostri(False)
    out = []
    gia = set()
    for api_id in sorted(allow):
        provider_id, sep, model_id = api_id.partition("/")
        if not sep or not provider_id or not model_id:
            continue
        # Prima preferisci il modello già rilevato dal catalogo/appello.
        match = next((m for m in presenti
                      if m.get("id") == provider_id and m.get("modello") == model_id
                      and m.get("verificato")), None)
        # Le alias libere verificate vengono aggiunte solo sul provider già configurato e
        # con una chiave registrata. Questo consente un modello gratuito noto anche quando
        # il provider usa "auto" come modello generico nel catalogo storico.
        if match is None:
            provider = next((m for m in presenti
                             if m.get("id") == provider_id and m.get("verificato")), None)
            if provider is not None and chiave_provider(provider_id):
                match = dict(provider, modello=model_id)
        if match is not None and api_id not in gia:
            out.append(dict(match, api_id=api_id))
            gia.add(api_id)
    return out


def candidati_agente(modello, disponibili):
    """Seleziona solo modelli allowlisted; per esplicito, eventuale riserva è tracciata."""
    if not disponibili:
        return []
    richiesto = str(modello or "auto").strip()
    if richiesto in ("auto", "auto:fast", "auto:smart"):
        if richiesto == "auto:fast":
            return sorted(disponibili, key=lambda m: m.get("ms", 99999))
        return sorted(disponibili, key=lambda m: (-PESO.get(m.get("id", ""), 2), m.get("ms", 99999)))
    scelto = next((m for m in disponibili if m.get("api_id") == richiesto), None)
    if scelto is None:
        raise ValueError("modello non allowlisted/verificato")
    # Richiesta esplicita: non ripiegare silenziosamente su un altro ID allowlisted.
    return [scelto]




TOKEN_REGISTRY = os.path.join(HOME, ".hub_agent_tokens.json")
_TOKEN_REGISTRY_LOCK = threading.RLock()


def _leggi_registry_token():
    try:
        with open(TOKEN_REGISTRY, encoding="utf-8") as f:
            raw = json.load(f)
        return raw if isinstance(raw, dict) and isinstance(raw.get("tokens"), list) else {"tokens": []}
    except (OSError, ValueError, TypeError):
        return {"tokens": []}


def _scrivi_registry_token(registry):
    """Scrittura atomica e privata; nel registro sono conservati solo hash, mai token."""
    import tempfile
    directory = os.path.dirname(TOKEN_REGISTRY) or "."
    os.makedirs(directory, mode=0o700, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=".hub-agent-token-", dir=directory, text=True)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(registry, f, ensure_ascii=False, separators=(",", ":"))
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, TOKEN_REGISTRY)
        os.chmod(TOKEN_REGISTRY, 0o600)
    finally:
        try:
            os.unlink(tmp)
        except FileNotFoundError:
            pass


def crea_token_agente(nome, modelli):
    """Crea credenziale revocabile; il segreto viene restituito solo in questa risposta."""
    import base64
    import hashlib
    import secrets
    import uuid
    nome = str(nome or "").strip()[:64]
    richiesti = sorted({str(x).strip() for x in (modelli or []) if str(x).strip()})
    disponibili = {m["api_id"] for m in modelli_agente_ammessi()}
    if not nome:
        raise ValueError("specificare un nome per l'agente")
    if not richiesti or not set(richiesti).issubset(disponibili):
        raise ValueError("selezionare solo modelli attualmente verificati e consentiti")
    token = "huba-" + base64.urlsafe_b64encode(secrets.token_bytes(32)).decode("ascii").rstrip("=")
    ident = uuid.uuid4().hex[:16]
    record = {"id": ident, "name": nome, "models": richiesti,
              "sha256": hashlib.sha256(token.encode("utf-8")).hexdigest(),
              "created_at": time.strftime("%Y-%m-%dT%H:%M:%S%z")}
    with _TOKEN_REGISTRY_LOCK:
        registry = _leggi_registry_token()
        registry["tokens"].append(record)
        _scrivi_registry_token(registry)
    return {"id": ident, "name": nome, "models": richiesti, "token": token}


def lista_token_agente():
    with _TOKEN_REGISTRY_LOCK:
        return [{k: v for k, v in item.items() if k != "sha256"}
                for item in _leggi_registry_token()["tokens"] if isinstance(item, dict)]


def revoca_token_agente(ident):
    with _TOKEN_REGISTRY_LOCK:
        registry = _leggi_registry_token()
        prima = len(registry["tokens"])
        registry["tokens"] = [x for x in registry["tokens"]
                               if not (isinstance(x, dict) and x.get("id") == str(ident))]
        if len(registry["tokens"]) == prima:
            return False
        _scrivi_registry_token(registry)
        return True


def dettaglio_token_agente(header):
    """Valida il Bearer con confronto constant-time e restituisce solo autorizzazioni non segrete."""
    import hashlib
    import hmac
    parti = str(header or "").strip().split()
    if len(parti) != 2 or parti[0].lower() != "bearer":
        return None
    candidato = parti[1]
    digest = hashlib.sha256(candidato.encode("utf-8")).hexdigest()
    with _TOKEN_REGISTRY_LOCK:
        for item in _leggi_registry_token()["tokens"]:
            if not isinstance(item, dict) or not hmac.compare_digest(digest, str(item.get("sha256", ""))):
                continue
            scope = item.get("models")
            if not isinstance(scope, list) or not scope or any(not isinstance(x, str) or not x for x in scope):
                return None
            return {"id": item.get("id"), "models": list(scope)}
    return None


def agente_autorizzato(header):
    """Richiede esattamente Authorization: Bearer <token>; confronto constant-time."""
    return dettaglio_token_agente(header) is not None


def chat_riposta(msgs, modello="auto", fusion=None, on_event=None):
    """Router Hub locale: provider diretti, Fusion esplicita e nessun fallback remoto silenzioso."""
    _MOTIVI.clear()
    modello=str(modello or "auto")
    if modello in ("fusion","code","trading","tailor") or modello.startswith("team::"):
        cfg=fusion if isinstance(fusion,dict) else {}
        fatta=fusion_nostra(msgs,3,cfg.get("models"),cfg.get("judge"),on_event)
        if fatta:
            return fatta[0],"fusion Hub · "+fatta[1],"router Hub"
        return ("⚠️ Fusion non disponibile: almeno due modelli della squadra devono essere presenti e rispondere.","fusion","router Hub")
    risultato=chat_diretta(msgs,modello,900,4,70)
    if risultato:
        return risultato[0],risultato[2],"router Hub diretto · "+risultato[1]
    return ("⚠️ Nessun provider diretto ha risposto. Controlla il catalogo o avvia una verifica manuale nelle Impostazioni. Non è stato usato un router alternativo.","—","router Hub")


def chat_stream(msgs, modello, fusion, scrivi):
    """Compatibilità SSE: inoltra eventi fusion e poi il testo del provider diretto a blocchi."""
    eventi=[]
    def emit(obj):
        eventi.append(obj)
        scrivi("data: "+json.dumps(obj,ensure_ascii=False))
    risultato=chat_riposta(msgs,modello,fusion,emit)
    if not risultato: return None
    testo,servito,via=risultato
    for i in range(0,len(testo),120):
        payload={"model":servito,"choices":[{"delta":{"content":testo[i:i+120]}}]}
        scrivi("data: "+json.dumps(payload,ensure_ascii=False))
    return testo,servito,via










# ─────────────────────────────── HTTP ───────────────────────────────────────
def _richiesta_loopback_locale(handler):
    """Blocca gestione token da rete e da pagine web di origine diversa."""
    import ipaddress
    import urllib.parse
    try:
        peer = ipaddress.ip_address(handler.client_address[0].split("%", 1)[0])
        locale = peer.is_loopback or bool(getattr(peer, "ipv4_mapped", None)
                                           and peer.ipv4_mapped.is_loopback)
        host_raw = (handler.headers.get("Host") or "").strip()
        host = urllib.parse.urlsplit("//" + host_raw)
        name = host.hostname or ""
        host.port
        try:
            ip = ipaddress.ip_address(name)
            host_local = ip.is_loopback or bool(getattr(ip, "ipv4_mapped", None)
                                                and ip.ipv4_mapped.is_loopback)
        except ValueError:
            host_local = name.lower() == "localhost"
        host_local = host_local and not (host.username or host.password or host.path or host.query or host.fragment)
        origin = (handler.headers.get("Origin") or "").strip()
        if origin:
            parsed = urllib.parse.urlsplit(origin)
            if (parsed.scheme != "http" or parsed.path not in ("", "/") or parsed.query
                    or parsed.fragment or parsed.netloc.lower() != host_raw.lower()):
                return False
        return bool(locale and host_local)
    except (AttributeError, TypeError, ValueError, IndexError):
        return False


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _json(self, obj, code=200):
        b = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def _body(self):
        n = int(self.headers.get("Content-Length") or 0)
        try:
            return json.loads(self.rfile.read(n).decode()) if n else {}
        except Exception:
            return {}

    def do_GET(self):
        if self.path in ("/", "/index.html", "/hub", "/api/hub"):
            # La dashboard storica completa resta l'unica UI principale del Router Hub.
            try:
                with open(os.path.join(QUI, "hub.html"), "rb") as f:
                    page = f.read()
            except OSError:
                self._json({"err": "dashboard non disponibile"}, 500)
                return
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(page)))
            self.end_headers()
            self.wfile.write(page)
            return
        elif self.path.startswith("/api/salute"):
            self._json(salute(fresco=True))
        elif self.path == "/api/risultati":
            directory = os.path.join(POSTA, "RISPOSTE_AGENTI")
            try:
                nomi = sorted((n for n in os.listdir(directory)
                               if n.lower().endswith(".md") and n.startswith("FUSION_")), reverse=True)
            except OSError:
                nomi = []
            self._json({"data": nomi})
        elif self.path == "/api/checkin/stato":
            fatto = os.path.exists(flag_checkin())
            self._json({"fatto_oggi": fatto, "ora": leggi(flag_checkin(), "").strip() if fatto else "",
                        "saldo_locale": saldo_ultimo(),
                        "login_manuale": serve_login_manuale() and not fatto,
                        "finestra_aperta": finestra_aperta(), "tentativi": tentativi_oggi(),
                        "max_tentativi": MAX_TENTATIVI})
        elif self.path == "/api/agente-token":
            self._json({"err": "endpoint legacy disabilitato; usa token separati revocabili"}, 410)
        elif self.path.startswith("/api/agenti") or self.path == "/api/agente/stato":
            self._json({"err": "endpoint disabilitato: gli agenti sono client dell'Hub"}, 404)
        elif self.path.startswith("/api/ponte"):
            self._json(ponte_stato())
        elif self.path == "/api/modelli":
            # i NOSTRI modelli (chiavi nostre, niente centralino): la tendina e le squadre leggono qui
            lista = modelli_nostri(False)
            pronti = modelli_nostri(True)
            for m in modelli_agente_ammessi():
                if not any(x.get("id") == m.get("id") and x.get("modello") == m.get("modello") for x in lista):
                    lista.append(m)
            self._json({"data": [{"id": m["id"], "provider": m["provider"], "modello": m["modello"],
                                  "stato": m.get("stato", ""), "chiamate": m.get("chiamate", 0),
                                  "errori": m.get("errori", 0),
                                  "verificato": bool(m.get("verificato"))} for m in lista],
                        "pronti": len(pronti),
                        "pronti_verificati": len([m for m in pronti if m.get("verificato")]),
                        "totali": len(lista),
                        # chi ha una chiave ma non fa chat (video, immagini, voce, embedding, db)
                        "non_chat": len([p for p, v in lista_portiere().items()
                                         if p in APP_BASE and not puo_chattare(p)]),
                        # se questi due numeri sono vecchi, i modelli «pronti» sono pochi:
                        # basta premere Ricontrolla e l'appello rifà il giro su tutte le chiavi
                        "appello_quando": appello_dati().get("quando", ""),
                        "appello_voci": len(appello_dati().get("voci", []))})
        elif self.path in ("/v1/models", "/v1/models/"):
            auth = dettaglio_token_agente(self.headers.get("Authorization"))
            if auth is None:
                self._json({"error": {"message": "manca il token dell'agente (Authorization: Bearer …)"}}, 401)
                return
            ammessi = modelli_agente_ammessi()
            scope = auth.get("models")
            if scope is not None:
                ammessi = [m for m in ammessi if m["api_id"] in scope]
            data = [{"id": m["api_id"], "object": "model", "owned_by": m["provider"],
                     "root": m["modello"],
                     "capabilities": {"chat": True, "streaming": False, "tools": False}}
                    for m in ammessi]
            self._json({"object": "list", "data": data})
        elif self.path == "/api/agent-tokens":
            if not _richiesta_loopback_locale(self):
                self._json({"err": "richiesta locale non verificata"}, 403)
                return
            self._json({"tokens": lista_token_agente(),
                        "models": [m["api_id"] for m in modelli_agente_ammessi()]})
        elif self.path == "/api/contabilita":
            self._json(contabilita())
        elif self.path == "/api/capacita":
            self._json(capacita())
        elif self.path.startswith("/api/risultato/raw"):
            import urllib.parse
            q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            nome = os.path.basename((q.get("f") or [""])[0])
            testo = leggi(os.path.join(POSTA, "RISPOSTE_AGENTI", nome), "(vuoto)")
            b = testo.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(b)))
            self.end_headers()
            self.wfile.write(b)
        elif self.path.startswith("/api/risultato"):
            import urllib.parse
            q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            nome = os.path.basename((q.get("f") or [""])[0])
            self._json({"nome": nome, "testo": leggi(os.path.join(POSTA, "RISPOSTE_AGENTI", nome), "(vuoto)")})
        else:
            self._json({"err": "not found"}, 404)

    def do_POST(self):
        try:
            self._do_POST()
        except _Rifiutato:
            pass                       # la risposta d'errore è già partita
        except Exception as e:
            segna_motivo("server", e)
            try:
                self._json({"err": "errore interno: %s" % (str(e) or e.__class__.__name__)[:200]}, 500)
            except Exception:
                pass

    def _do_POST(self):
        # le difese valgono per TUTTE le POST, anche quelle che non leggono il corpo:
        # una pagina web qualsiasi può fare POST verso 127.0.0.1:20200 senza preflight
        # (text/plain + no-cors) e far partire i comandi del PC. Il nostro hub manda JSON.
        ctype = (self.headers.get("Content-Type") or "").split(";")[0].strip().lower()
        origine = (self.headers.get("Origin") or "").strip()
        if ctype and ctype != "application/json":
            self._json({"err": "il corpo deve essere JSON"}, 415)
            return
        if origine:
            try:
                from urllib.parse import urlparse
                p = urlparse(origine)
                host = (p.hostname or "").lower()
                allowed = {"localhost", "127.0.0.1", "::1"}
                if host not in allowed:
                    self._json({"err": "origine non ammessa: questo hub risponde solo al tuo PC"}, 403)
                    return
            except Exception:
                self._json({"err": "origine non ammessa: questo hub risponde solo al tuo PC"}, 403)
                return
        if self.path in ("/api/agent-tokens", "/api/agent-tokens/revoke"):
            if not _richiesta_loopback_locale(self):
                self._json({"err": "richiesta locale non verificata"}, 403)
                return
            body = self._body()
            if self.path.endswith("/revoke"):
                revoked = revoca_token_agente(body.get("id", ""))
                self._json({"revoked": bool(revoked)}, 200 if revoked else 404)
            else:
                try:
                    self._json(crea_token_agente(body.get("name"), body.get("models")))
                except ValueError as e:
                    self._json({"err": str(e)}, 400)
        elif self.path == "/api/checkin":
            self._json(fai_checkin(forza=bool(self._body().get("forza"))))
        elif self.path == "/api/checkin/segna":
            if os.path.exists(flag_checkin()):
                self._json({"stato": "gia_fatto", "msg": "Già segnato come fatto per oggi."})
                return
            scrivi(flag_checkin(), time.strftime("%H:%M") + "-manuale")
            pulisci_login_manuale()
            # azzero anche i tentativi: la giornata è chiusa, non deve più riprovare
            try:
                os.remove(file_tentativi())
            except Exception:
                pass
            self._json({"stato": "ok",
                        "msg": "✅ Segnato: bonus di oggi già preso a mano. Stasera nessun logout."})
        elif self.path == "/api/checkin/verifica":
            v = verifica_sessione(bloccante=True)
            self._json({"valida": bool(v), "login_manuale": serve_login_manuale() and not os.path.exists(flag_checkin()),
                        "msg": ("✅ Sessione valida: ho tolto l'avviso. Ora puoi premere «Riscatta ora»."
                                if v else ("⚠️ Sessione non valida: fai il login in BROWSER_AGENTI."
                                           if v is False else "Apri prima il BROWSER_AGENTI."))})
        elif self.path == "/api/search":
            q = str((self._body().get("q") or "")).strip()[:400]
            if not q:
                self._json({"error": {"message": 'manca "q"'}}, 400)
                return
            res = _ricerca_web(q)
            self._json({"q": q, "context": risultati_in_testo(res, q),
                        "results": [{"title": r["title"], "url": r["url"]} for r in res]})
        elif self.path in ("/v1/chat/completions", "/v1/chat/completions/"):
            auth = dettaglio_token_agente(self.headers.get("Authorization"))
            if auth is None:
                self._json({"error": {"message": "manca il token dell'agente (Authorization: Bearer …)"}}, 401)
                return
            b = self._body()
            if not isinstance(b, dict):
                self._json({"error": {"message": "il corpo deve essere un oggetto JSON", "type": "invalid_request_error"}}, 400)
                return
            msgs = b.get("messages") or []
            if not isinstance(msgs, list) or not msgs:
                self._json({"error": {"message": '"messages" deve essere un array non vuoto', "type": "invalid_request_error"}}, 400)
                return
            disponibili = modelli_agente_ammessi()
            scope = auth.get("models")
            if scope is not None:
                disponibili = [m for m in disponibili if m["api_id"] in scope]
            if not disponibili:
                self._json({"error": {"message": "nessun modello agente verificato e allowlisted a costo zero", "type": "invalid_request_error"}}, 403)
                return
            if b.get("stream") is True or "tools" in b or "tool_choice" in b or "functions" in b or "function_call" in b:
                self._json({"error": {"message": "streaming e tool/function calling non sono supportati", "type": "invalid_request_error"}}, 400)
                return
            non_supportati = ("temperature", "top_p", "n", "presence_penalty", "frequency_penalty", "logprobs", "top_logprobs", "response_format", "stop", "seed")
            for bad in non_supportati:
                if bad in b:
                    self._json({"error": {"message": "parametro non supportato: " + bad, "type": "invalid_request_error"}}, 400)
                    return
            if "max_tokens" in b and "max_completion_tokens" in b:
                self._json({"error": {"message": "specificare max_tokens oppure max_completion_tokens, non entrambi", "type": "invalid_request_error"}}, 400)
                return
            richiesto = str(b.get("model") or "auto").strip()
            try:
                candidati = candidati_agente(richiesto, disponibili)
            except ValueError:
                self._json({"error": {"message": "modello non allowlisted/verificato", "type": "invalid_request_error"}}, 403)
                return
            max_tokens = b.get("max_tokens", b.get("max_completion_tokens", 900))
            try:
                if isinstance(max_tokens, bool):
                    raise ValueError("boolean")
                max_tokens = max(1, min(4096, int(max_tokens)))
            except (TypeError, ValueError):
                self._json({"error": {"message": "max_tokens deve essere un intero tra 1 e 4096", "type": "invalid_request_error"}}, 400)
                return
            testo = ""
            servito = None
            errore = "nessun modello allowlisted ha risposto"
            for modello in candidati:
                testo, errore, _attesa = _posta_diretta(modello, msgs, quanti=max_tokens, timeout=70)
                if testo:
                    servito = modello
                    break
            if not testo or servito is None:
                self._json({"error": {"message": errore or "errore upstream", "type": "api_error"}}, 502)
                return
            via = "router Hub diretto"
            if richiesto not in ("auto", "auto:fast", "auto:smart") and servito["api_id"] != richiesto:
                via += " · fallback allowlisted da " + richiesto
            self._json({"id": "chatcmpl-hub-%d" % int(time.time()), "object": "chat.completion",
                        "created": int(time.time()), "model": servito["api_id"], "via": via,
                        "choices": [{"index": 0, "finish_reason": "stop",
                                     "message": {"role": "assistant", "content": testo}}]})
        elif self.path == "/api/chat":
            _MOTIVI.clear()
            b = self._body()
            msgs = b.get("messages") or b.get("messaggi") or []
            if not msgs:
                self._json({"err": "vuoto"}, 400)
                return
            fusione = b.get("fusion") if isinstance(b.get("fusion"), dict) else None
            if b.get("stream"):
                # streaming vero: i pezzi arrivano appena il motore li produce (niente attesa muta)
                avviato = {"fatto": False}

                def _scrivi(riga):
                    if not avviato["fatto"]:
                        avviato["fatto"] = True
                    self.wfile.write((riga + "\n\n").encode())
                    self.wfile.flush()

                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream; charset=utf-8")
                self.send_header("Cache-Control", "no-cache")
                self.end_headers()
                try:
                    fatto = chat_stream(msgs, b.get("model") or "auto", fusione, _scrivi)
                    if not fatto:
                        testo2 = "⚠️ Il Router Hub non ha prodotto una risposta. Verifica il provider nelle Impostazioni."
                        for i in range(0, len(testo2), 120):
                            pezzo = json.dumps({"model": "—",
                                                "choices": [{"delta": {"content": testo2[i:i + 120]}}]})
                            self.wfile.write(("data: " + pezzo + "\n\n").encode())
                            self.wfile.flush()
                    self.wfile.write(b"data: [DONE]\n\n")
                except Exception:
                    pass
                return
            testo, servito, via = chat_riposta(msgs, b.get("model") or "auto", fusione)
            self._json({"testo": testo, "modello": servito, "via": via, "model": servito,
                        "choices": [{"index": 0, "finish_reason": "stop",
                                     "message": {"role": "assistant", "content": testo}}]})
        elif self.path == "/api/pc/aggiorna":
            self._json(aggiorna_pc())
        elif self.path == "/api/ponte":
            az = (self._body().get("azione") or "stato").strip()
            if az != "avvia":
                self._json(ponte_stato())
                return
            p = ponte_stato()
            if p.get("postino"):
                self._json({"stato": "ok", "msg": "🟢 Il postino è già in giro: non serve avviarlo."})
                return
            script = os.path.join(POSTA, "postino.sh")
            if not os.path.exists(script):
                self._json({"stato": "ko", "msg": "⚠️ Manca il file postino.sh: senza quello non posso avviarlo."})
                return
            try:
                subprocess.Popen(["bash", script, "--loop"], stdout=subprocess.DEVNULL,
                                 stderr=subprocess.DEVNULL, start_new_session=True,
                                 cwd=POSTA)
                for _ in range(10):
                    time.sleep(1)
                    if ponte_stato().get("postino"):
                        self._json({"stato": "ok", "msg": "🟢 Postino avviato: adesso è in giro."})
                        return
                self._json({"stato": "ko",
                            "msg": "⚠️ Il postino non è partito: di solito è il collegamento a GitHub "
                                   "che manca (token scaduto). Controlla il box qui sotto."})
            except Exception as e:
                self._json({"stato": "ko", "msg": f"⚠️ Non sono riuscito ad avviarlo: {e}"})
        elif self.path == "/api/browser":
            az = (self._body().get("azione") or "stato").strip()
            if az == "stato":
                self._json({"acceso": porta_viva(9222), "porta": 9222})
                return
            visibile = (az == "mostra")
            su = chrome_finestra(mostra=visibile)
            self._json({"stato": "ok" if su else "ko", "acceso": su,
                        "msg": ("👁 Browser degli agenti in primo piano (porta 9222)"
                                if visibile else "🙈 Browser di nuovo dietro le quinte: continua a lavorare")
                               if su else "⚠️ Non sono riuscito ad aprire il browser: serve Chrome o Edge installato"})
        elif self.path == "/api/appello":
            az = (self._body().get("azione") or "stato").strip()
            if az == "fai":
                self._json(appello_lancia(svelto=bool(self._body().get("svelto", True))))
            elif az == "completo":
                self._json(appello_lancia(svelto=False))
            else:
                d = appello_dati()
                d["in_corso"] = _appello_stato["in_corso"]
                self._json(d)
        else:
            self._json({"err": "not found"}, 404)




def libera_porta_20200():
    """Chiude un'istanza vecchia della GUI: altrimenti la nuova non apre la porta e tu
    vedresti la pagina di ieri (successo il 20/10: si vedeva ancora il check-in all'apertura)."""
    import signal
    mio = os.getpid()
    try:
        pids = subprocess.run(["pgrep", "-f", "gui/server.py"], capture_output=True, text=True).stdout.split()
    except Exception:
        pids = []
    for pid in [int(x) for x in pids if x.isdigit() and int(x) != mio]:
        try:
            os.kill(pid, signal.SIGTERM)
            print(f"[gui] chiusa l'istanza vecchia (pid {pid})")
        except Exception:
            pass
    for _ in range(15):
        if not porta_viva(20200):
            return True
        time.sleep(0.5)
    return not porta_viva(20200)


if __name__ == "__main__":
    if not os.environ.get("CENTRALE_PORTA"):
        libera_porta_20200()
    print(f"Posta Router Hub su http://localhost:20200/hub · check-in solo manuale")
    PORTA = int(os.environ.get("CENTRALE_PORTA") or 20200)
    ThreadingHTTPServer(("127.0.0.1", PORTA), H).serve_forever()
