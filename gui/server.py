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
import glob
import json, os, re, shutil, subprocess, sys, time, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

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
    try:
        with socket.create_connection((host, porta), timeout=2):
            return True
    except Exception:
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


def omni_bin():
    """Il programma del motore, se c'è: altrimenti stringa vuota."""
    p = shutil.which("omniroute")
    if p:
        return p
    for p in sorted(glob.glob(os.path.join(HOME, ".nvm", "versions", "node", "*", "bin", "omniroute")))[::-1]:
        if os.access(p, os.X_OK):
            return p
    return ""


def _niente_schede():
    """OmniRoute, quando parte, apre la sua Dashboard nel browser: due avvii = due schede
    (il fastidio che si è visto). Qui gli mettiamo davanti un «apri browser» finto, così
    la scheda la apre solo la GUI quando la chiedi tu."""
    d = "/tmp/omni_senza_schede"
    try:
        os.makedirs(d, exist_ok=True)
        for nome in ("xdg-open", "wslview", "sensible-browser", "x-www-browser",
                     "open", "powershell.exe", "cmd.exe"):
            f = os.path.join(d, nome)
            if not os.path.exists(f):
                with open(f, "w") as fh:
                    fh.write("#!/bin/sh\nexit 0\n")
                os.chmod(f, 0o755)
        return d
    except Exception:
        return ""


_PREFISSO_SENZA_SCHEDE = ('export PATH="' + _niente_schede() + ':$PATH"; '
                          if _niente_schede() else "")


def omniroute_avvia(attesa=25):
    """Accende OmniRoute se è spento e aspetta che risponda (era il comportamento di prima)."""
    if porta_viva(20128):
        return True
    script = (_PREFISSO_SENZA_SCHEDE +
              "export NVM_DIR=$HOME/.nvm; . $NVM_DIR/nvm.sh >/dev/null 2>&1; "
              "B=$(ls -d $HOME/.nvm/versions/node/v22*/bin 2>/dev/null | sort -V | tail -1); "
              "[ -x \"$B/omniroute\" ] || B=$(dirname \"$(command -v omniroute)\") ; "
              "cd \"$HOME\" ; nohup \"$B/omniroute\" >/tmp/omniroute.log 2>&1 &")
    try:
        subprocess.Popen(["bash", "-lc", script], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        return False
    for _ in range(attesa):
        if porta_viva(20128):
            return True
        time.sleep(1)
    return porta_viva(20128)


_omni_lav = {"quando": 0.0, "cosa": ""}


def lavoro_omni():
    """Cosa sta facendo il motore ADESSO. Guardo i processi veri e il registro,
    così anche se la GUI si riavvia non si perde il conto."""
    r = {"cosa": "", "secondi": 0, "log": ""}
    for nome, etichetta in (("omni_free.sh", "provider gratis"), ("omni_chiavi.sh", "chiavi")):
        try:
            out = subprocess.run(["pgrep", "-af", nome], capture_output=True,
                                 text=True, timeout=8).stdout
        except Exception:
            out = ""
        trovato = False
        for riga in out.splitlines():
            pid, _, cmd = riga.partition(" ")
            if not pid.isdigit():
                continue
            # deve essere proprio «... /omni_free.sh» (non una shell che lo nomina)
            if cmd.strip().endswith(nome):
                trovato = True
                break
        if not trovato:
            continue
        r["cosa"] = etichetta
        log = "/tmp/omni_lav_" + ("free" if nome == "omni_free.sh" else "chiavi") + ".log"
        try:
            r["secondi"] = int(time.time() - os.path.getmtime(log))
            righe = [l.strip() for l in open(log, encoding="utf-8", errors="replace").read().splitlines() if l.strip()]
            r["log"] = " · ".join(righe[-2:])[-220:]
        except Exception:
            pass
        return r
    return r


def omni_pids():
    """I processi VERI di OmniRoute. Prima si usava «pkill -f omniroute», che ammazzava
    anche il curl che stava chiamando /api/omniroute (l'indirizzo contiene la parola):
    risultato, la GUI sembrava bloccarsi. Qui si guarda il comando, non l'indirizzo."""
    pids = []
    try:
        out = subprocess.run(["pgrep", "-af", "omniroute"], capture_output=True,
                             text=True, timeout=10).stdout
    except Exception:
        return pids
    for riga in out.splitlines():
        pid, _, cmd = riga.partition(" ")
        if not pid.isdigit():
            continue
        if int(pid) in (os.getpid(), os.getppid()):
            continue
        if ("gui/server.py" in cmd or "curl" in cmd or "wget" in cmd
                or "prova_agenti" in cmd or "agenti_stato" in cmd):
            continue
        if "omniroute" in cmd.lower():
            pids.append(int(pid))
    return pids


def omni_spegni(attesa=6):
    """Spegne il motore senza toccare altro."""
    pids = omni_pids()
    for sig in ("TERM", "KILL"):
        if not pids:
            break
        for p in pids:
            try:
                os.kill(p, getattr(__import__("signal"), sig))
            except Exception:
                pass
        for _ in range(attesa):
            if not porta_viva(20128):
                return True
            time.sleep(1)
        pids = omni_pids()
    return not porta_viva(20128)


def omniroute_riavvia():
    omni_spegni()
    time.sleep(2)
    return omniroute_avvia(attesa=30)


def chiave_omni():
    """La chiave che OmniRoute si aspetta, se ne ha una configurata."""
    k = chiave(r"omniroute", r"sk-[A-Za-z0-9-]{12,}")
    if k:
        return k
    for f in (os.path.join(HOME, ".omniroute", "config.json"),
              os.path.join(HOME, ".config", "omniroute", "config.json")):
        try:
            dati = json.loads(open(f, encoding="utf-8").read())
            for campo in ("apiKey", "key", "token", "masterKey"):
                if isinstance(dati.get(campo), str) and dati[campo]:
                    return dati[campo]
        except Exception:
            pass
    return ""


def modelli_omni():
    v = _cache.get("mod")
    if v and time.time() - v[0] < 30:
        return v[1]
    r = {"modelli": 0, "linee": 0, "errore": ""}
    if not porta_viva(20128):
        r["errore"] = "motore spento"
        _cache["mod"] = (time.time(), r)
        return r
    import urllib.request
    for k in [chiave_omni(), "sk-omniroute", ""]:
        try:
            intest = {"Accept": "application/json"}
            if k:
                intest["Authorization"] = "Bearer " + k
            req = urllib.request.Request("http://127.0.0.1:20128/v1/models", headers=intest)
            dati = json.loads(urllib.request.urlopen(req, timeout=12).read().decode())
            lista = dati.get("data", dati if isinstance(dati, list) else [])
            if lista:
                r["modelli"] = len(lista)
                r["linee"] = len({(m.get("owned_by") or "?") for m in lista if isinstance(m, dict)})
                r["errore"] = ""
                _cache["mod"] = (time.time(), r)
                return r
            r["errore"] = "il motore è acceso ma non ha modelli: attiva i provider col [9] (voce f)"
        except Exception as e:
            r["errore"] = "non riesco a leggere i modelli (" + type(e).__name__ + ")"
    _cache["mod"] = (time.time(), r)
    return r


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


def sveglia_checkin():
    """Riscatta da solo, una volta al giorno, SOLO dalle 18:05 italiane.
    Se il PC era spento alle 18:05, riscatta appena lo accendi. Max 3 tentativi."""
    while True:
        try:
            if (finestra_aperta() and not os.path.exists(flag_checkin())
                    and not serve_login_manuale() and tentativi_oggi() < MAX_TENTATIVI
                    and time.time() - _ultimo_tentativo[0] > 1800):
                _ultimo_tentativo[0] = time.time()
                fai_checkin(forza=False)
        except Exception:
            pass
        time.sleep(60)


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
         "righe": [], "secondi": 0, "ora": time.strftime("%H:%M:%S")}
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
            if r[:1] in ("✓", "✗", "·"):
                esito = {"✓": "ok", "✗": "no", "·": "att"}[r[0]]
                resto = r[1:].strip()
                nome = resto[:26].strip()
                dettaglio = resto[26:].strip() if len(resto) > 26 else ""
                voce = {"esito": esito, "nome": nome, "dettaglio": dettaglio}
                v["righe"].append(voce)
                if esito == "no":
                    v["rossi"].append(voce)
                elif esito == "att":
                    v["gialli"].append(voce)
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
    "Skill": ("le skill degli agenti (le istruzioni che si portano dietro)",
              "non serve per chattare: si sistema con l'aggiornamento del PC ([8]). "
              "Se ti serve solo la chat, puoi ignorarlo."),
    "OpenClaw": ("l'assistente OpenClaw",
                 "si sistema con ./openclaw_fix.sh oppure col pulsante «Accendi» nella sua scheda."),
    "Node v22": ("il programma che fa girare l'Hub",
                 "serve per il motore: si sistema con l'aggiornamento del PC ([8])."),
    "motore": ("OmniRoute, il cervello degli agenti",
               "parte da solo: se è spento, aspetta un minuto. Se resta spento, premi Avvia."),
    "chiavi": ("il portachiavi delle chiavi API",
               "controlla che ~/CHIAVI_LOCALI.md esista e sia leggibile (chmod 600)."),
    "postino": ("il postino che porta le novità sul ponte GitHub",
                "si riaccende da solo; se resta spento, riapri la Centrale."),
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
    return {"verdetto": v.get("verdetto", ""), "colore": v.get("colore", "grigio"),
            "rossi": len(v.get("rossi", [])), "gialli": len(v.get("gialli", [])),
            "voci": righe, "ora": v.get("ora", ""), "secondi": v.get("secondi", 0)}


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


NOMI_SCORTA = {
    "groq": "Groq", "gemini": "Google AI Studio", "mistral": "Mistral", "cohere": "Cohere",
    "openrouter": "OpenRouter", "nvidia": "NVIDIA", "huggingface": "HuggingFace Router",
    "pollinations": "Pollinations", "githubmodels": "GitHub Models", "agentrouter": "AgentRouter",
    "opencode": "OpenCode Zen", "aihorde": "AI Horde",
}


def _norm(x):
    return re.sub(r"[^a-z0-9]", "", (x or "").lower())


def contatori_chiavi():
    """I tre contatori: dove può lavorare ogni chiave.
    1) dentro OmniRoute (il motore)
    2) nella scorta (il portiere, se OmniRoute cade) — le doppie restano contate nel primo
    3) fuori da entrambi
    """
    omni_nomi = {}          # nome normalizzato → id omniroute
    try:
        for riga in open(os.path.join(POSTA, "mappa_innesto.txt"), encoding="utf-8"):
            riga = riga.strip()
            if not riga or riga.startswith("#"):
                continue
            pezzi = riga.split("|")
            if len(pezzi) >= 2:
                omni_nomi[_norm(pezzi[1])] = pezzi[0]
    except Exception:
        pass
    scorta_nomi = {_norm(v): k for k, v in NOMI_SCORTA.items()}

    nomi = []
    try:
        testo = open(os.path.join(HOME, "CHIAVI_LOCALI.md"), encoding="utf-8",
                     errors="replace").read()
        a = testo.find("## 4 · PROVIDER LLM")
        b = testo.find("## 5 · STRUMENTI")
        sez = testo[a:b if b > a else len(testo)]
        for riga in sez.splitlines():
            m = re.match(r"\s*[-*]\s+\*\*(.+?)\*\*", riga)
            if m:
                nome = m.group(1).strip()
                if nome and nome not in nomi:
                    nomi.append(nome)
    except Exception:
        pass

    in_omni, in_scorta, fuori = [], [], []
    for nome in nomi:
        n = _norm(nome)
        preso_omni = any(n == k or (len(n) > 5 and (k.startswith(n[:6]) or n.startswith(k[:6])))
                         for k in omni_nomi)
        preso_scorta = any(n == k or (len(n) > 5 and (k.startswith(n[:5]) or n.startswith(k[:5])))
                           for k in scorta_nomi)
        if preso_omni:
            in_omni.append(nome)
            if preso_scorta:
                in_scorta.append(nome)      # doppia: conta nel primo, usabile nel secondo
        elif preso_scorta:
            in_scorta.append(nome)
        else:
            fuori.append(nome)

    # i provider già preimpostati in OmniRoute che funzionano senza chiave
    try:
        noauth_omni = sum(1 for riga in open(os.path.join(POSTA, "dal_pc", "omni_catalogo.txt"),
                                             encoding="utf-8", errors="replace")
                          if " noauth " in riga)
    except Exception:
        noauth_omni = 10

    return {"omniroute": len(in_omni), "omniroute_totali": len(in_omni) + noauth_omni,
            "noauth_omni": noauth_omni,
            "cervello_totali": len(APP_BASE) + 1,      # + AI Horde (senza chiave)
            "doppie": len([x for x in in_omni if x in in_scorta]),
            "scorta": len(in_scorta),
            "scorta_solo": len([x for x in in_scorta if x not in in_omni]),
            "fuori": len(fuori), "fuori_nomi": fuori,
            "totali_portachiavi": len(nomi),
            "omni_nomi": in_omni, "scorta_nomi": in_scorta}


_oc_cmd_cache = {"t": 0.0, "cmd": ""}

def openclaw_cmd():
    """Il comando openclaw eseguibile da qui (Ubuntu, Bun o Windows), con cache 5 min."""
    if time.time() - _oc_cmd_cache["t"] < 300 and _oc_cmd_cache["cmd"]:
        return _oc_cmd_cache["cmd"]
    cmd = ""
    try:
        fuori = subprocess.run(["bash", os.path.join(POSTA, "apri_openclaw.sh"), "--trova"],
                               capture_output=True, text=True, timeout=20).stdout.strip()
        if "(installato su Windows):" in fuori:
            cmd = fuori.split(":", 1)[1].strip()
        elif fuori and "non è ancora installato" not in fuori:
            # "OpenClaw (dentro Ubuntu): /percorso" / "runtime Bun"
            for marca in ("Ubuntu):", "Bun):"):
                if marca in fuori:
                    cmd = fuori.split(marca, 1)[1].strip()
                    break
    except Exception:
        cmd = ""
    _oc_cmd_cache.update(t=time.time(), cmd=cmd)
    return cmd


def openclaw_stato():
    """Stato OpenClaw per la scheda della GUI."""
    v = {"installato": False, "versione": "", "dove": "", "gateway": False, "configurato": False,
         "porta": 18789, "url": "http://localhost:18789", "base_api": "http://127.0.0.1:18789/v1"}
    try:
        out = subprocess.run(["bash", os.path.join(POSTA, "openclaw_stato.sh"), "--json"],
                             capture_output=True, text=True, timeout=30).stdout.strip()
        d = json.loads(out) if out.startswith("{") else {}
        v.update({"installato": d.get("tipo", "no") != "no", "versione": d.get("versione", ""),
                  "dove": d.get("dove", ""), "gateway": bool(d.get("gateway")),
                  "configurato": bool(d.get("configurato")), "porta": d.get("porta", 18789),
                  "url": f"http://localhost:{d.get('porta', 18789)}",
                  "base_api": d.get("base_api", "")})
    except Exception as e:
        v["errore"] = str(e)
    if not v["gateway"]:
        v["gateway"] = porta_viva(v["porta"])
    return v


def _utente_windows(cmd_in_corso=None):
    """Cartella utente di Windows in forma Linux (/mnt/c/Users/xxx)."""
    winroot = os.environ.get("WINROOT", "/mnt/c")
    try:
        r = subprocess.run(["cmd.exe", "/c", "echo", "%USERPROFILE%"], capture_output=True,
                           text=True, timeout=15, cwd=winroot)
        prof = (r.stdout or "").strip().splitlines()[-1].strip()
        lin = _w2l(prof) if prof and ":" in prof else ""
        if lin and os.path.isdir(lin):
            return lin
    except Exception:
        pass
    for d in sorted(glob.glob(os.path.join(winroot, "Users", "*"))):
        if os.path.isdir(os.path.join(d, "AppData", "Roaming")):
            return d
    return None


def _l2w(percorso):
    """percorso Linux -> percorso Windows (se wslpath non c'è, restituisce l'originale)."""
    if not percorso or not percorso.startswith("/mnt/"):
        return percorso
    try:
        r = subprocess.run(["wslpath", "-w", percorso], capture_output=True, text=True, timeout=5).stdout.strip()
        return r or percorso
    except Exception:
        return percorso


def _w2l(percorso):
    """percorso Windows -> percorso Linux."""
    if not percorso or percorso.startswith("/mnt/"):
        return percorso
    try:
        r = subprocess.run(["wslpath", "-u", percorso], capture_output=True, text=True, timeout=5).stdout.strip()
        return r or percorso
    except Exception:
        return percorso


def _oc_bat(cmd, argomenti, pausa=False, nome="_posta_openclaw.bat"):
    """Scrive un .bat con dentro la riga giusta e restituisce il suo percorso WINDOWS.
    Serve perché cmd.exe sbaglia sempre con le virgolette annidate passate da Linux."""
    cmd_lin = _w2l(cmd)                       # il comando in forma Linux (per copiarne la cartella)
    cmd_win = _l2w(cmd_lin)                   # ... e in forma Windows (per scriverlo dentro il .bat)
    cartella = os.environ.get("OC_BAT_DIR") or os.path.dirname(cmd_lin) or "/mnt/c/Windows/Temp"
    bat_lin = os.path.join(cartella, nome)
    righe = ["@echo off", "chcp 65001 >nul", "title OpenClaw",
             f'call "{cmd_win}" {" ".join(argomenti)}']
    if pausa:
        righe += ["echo.", "echo  Fatto. Puoi chiudere questa finestra.", "pause"]
    try:
        with open(bat_lin, "w", encoding="utf-8", newline="\r\n") as f:
            f.write("\n".join(righe) + "\n")
    except Exception:
        return None
    return _l2w(bat_lin)


_oc_in_corso = {"quando": 0.0, "azione": ""}


def _oc_libero(azione):
    """True se possiamo partire: evita che dieci clic aprano dieci terminali."""
    ora = time.time()
    if _oc_in_corso["azione"] and ora - _oc_in_corso["quando"] < 90:
        return False
    _oc_in_corso["azione"] = azione
    _oc_in_corso["quando"] = ora
    return True


def _oc_win(argomenti, attesa=45, titolo="OpenClaw"):
    """Lancia un comando OpenClaw su Windows in modo pulito.

    Perché così: se gli passiamo stdout/stderr di Linux, il node di Windows muore con
    "Error: open EISDIR" (si porta dietro le nostre prese). Allora scriviamo un .bat che
    manda tutto in un file di log e lo lanciamo con 'start': il processo nasce con le sue
    prese di Windows, e l'output ce lo leggiamo dal log.
    """
    cmd = openclaw_cmd()
    if not cmd:
        return 127, "OpenClaw non risulta installato."
    base = _utente_windows()
    if not base:
        return 1, "Non trovo la cartella utente di Windows."
    log_lin = os.path.join(base, "openclaw_gui.log")
    bat_lin = os.path.join(base, "_posta_openclaw_run.bat")
    cmd_win, log_win, bat_win = _l2w(cmd), _l2w(log_lin), _l2w(bat_lin)
    arg = " ".join(argomenti)
    righe = ["@echo off", "chcp 65001 >nul", f"title {titolo}",
             f'echo ==== {arg} ==== > "{log_win}"',
             f'call "{cmd_win}" {arg} >> "{log_win}" 2>&1',
             f'echo EXIT=%ERRORLEVEL% >> "{log_win}"']
    try:
        with open(bat_lin, "w", encoding="utf-8", newline="") as f:
            f.write("\r\n".join(righe) + "\r\n")
    except Exception as e:
        return 1, f"Non riesco a scrivere il comando su Windows: {e}"
    try:
        # start "" /min = titolo vuoto e finestra ridotta a icona.
        # (con un titolo contenente spazi Windows cercava un programma chiamato cosi'
        #  e apriva/chIudeva terminali a raffica)
        subprocess.Popen(["cmd.exe", "/c", "start", "", "/min", bat_win],
                         cwd=os.environ.get("WINROOT", "/mnt/c"),
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        return 1, f"Windows non ha accettato il comando: {e}"
    # aspetto che finiscano e leggo il log
    finito = False
    for _ in range(int(attesa)):
        time.sleep(1)
        try:
            testo = open(log_lin, encoding="utf-8", errors="replace").read()
        except Exception:
            testo = ""
        if "EXIT=" in testo:
            finito = True
            break
    try:
        testo = open(log_lin, encoding="utf-8", errors="replace").read()
    except Exception:
        testo = "(nessun log)"
    return (0 if finito else 2), testo[-2500:]


def _oc_esegui(argomenti, attesa=90):
    """Esegue un comando openclaw: su Windows passa da _oc_win, dentro Ubuntu usa i pipe normali."""
    cmd = openclaw_cmd()
    if not cmd:
        return 127, "OpenClaw non risulta installato."
    if cmd.startswith("/mnt/") or (len(cmd) > 2 and cmd[1] == ":" and cmd[2] in "\\/"):
        return _oc_win(argomenti, attesa=min(attesa, 60))
    try:
        p = subprocess.run([cmd] + list(argomenti), capture_output=True, text=True,
                           timeout=attesa, cwd=POSTA)
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except subprocess.TimeoutExpired:
        return 124, f"Tempo scaduto dopo {attesa}s."
    except Exception as e:
        return 1, str(e)


_inst_agenti = {"in_corso": False, "log": "", "quando": ""}


def agenti_stato():
    """Stato di TUTTI gli agenti (installato? chiave? pronto?) — dal file agenti_stato.sh."""
    base = {"agenti": [], "chiavi": {}, "cervello": ""}
    try:
        out = subprocess.run(["bash", os.path.join(POSTA, "agenti_stato.sh"), "--json"],
                             capture_output=True, text=True, timeout=60).stdout.strip()
        if out.startswith("{"):
            base = json.loads(out)
    except Exception as e:
        base["errore"] = str(e)
    return base


def installa_agenti(quali=None):
    """Installa gli agenti mancanti in sottofondo (una volta per volta)."""
    if _inst_agenti["in_corso"]:
        return {"stato": "in_corso", "msg": "Sto già installando: aspetta (può volerci qualche minuto).",
                "log": _inst_agenti["log"][-2000:]}
    _inst_agenti.update({"in_corso": True, "log": "", "quando": time.strftime("%H:%M")})
    argomenti = ["bash", os.path.join(POSTA, "installa_agenti.sh")] + (list(quali) if quali else [])

    def _lavoro():
        try:
            p = subprocess.run(argomenti, capture_output=True, text=True, timeout=1800, cwd=POSTA)
            _inst_agenti["log"] = ((p.stdout or "") + (p.stderr or ""))[-3000:]
        except Exception as e:
            _inst_agenti["log"] = f"Errore: {e}"
        finally:
            _inst_agenti["in_corso"] = False
    threading.Thread(target=_lavoro, daemon=True).start()
    return {"stato": "avviato", "msg": "Installazione partita: 1-5 minuti. Puoi continuare a chattare.",
            "log": _inst_agenti["log"]}


def chiavi_conteggio():
    """Quante chiavi ci sono nel portachiavi (attive / totali) — senza mostrarle."""
    f = os.path.join(HOME, "CHIAVI_LOCALI.md")
    tot = att = 0
    try:
        for riga in open(f, encoding="utf-8", errors="replace"):
            # righe del tipo:  - **Nome** — chiave... — [data] — ✅ ...
            if not riga.lstrip().startswith(("-", "*", "|")):
                continue
            if re.search(r"(sk-|gsk_|ghp_|xai-|AIza|jina_|sk-or-|sk-orca|thk_|blaze-|auray_sk|cfut_|hf_)", riga) \
               or re.search(r"\b[0-9a-f]{32}\b", riga):
                tot += 1
                if "❌" not in riga and "morto" not in riga.lower() and "RITIRATO" not in riga:
                    att += 1
    except Exception:
        return {"attive": 0, "totali": 0}
    return {"attive": att, "totali": tot}


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

APP_BASE = {
    "groq": ("https://api.groq.com/openai/v1", "llama-3.3-70b-versatile"),
    "gemini": ("https://generativelanguage.googleapis.com/v1beta/openai", "gemma-4-31b-it"),
    "mistral": ("https://api.mistral.ai/v1", "mistral-small-latest"),
    "cohere": ("https://api.cohere.ai/compatibility/v1", "command-r-plus-08-2024"),
    "openrouter": ("https://openrouter.ai/api/v1", "openrouter/auto"),
    "nvidia": ("https://integrate.api.nvidia.com/v1", "z-ai/glm-5.3"),
    "huggingface": ("https://router.huggingface.co/v1", "Qwen/Qwen3-8B"),
    "pollinations": ("https://text.pollinations.ai/openai", "openai-fast"),
    "githubmodels": ("https://models.github.ai/inference", "openai/gpt-4o-mini"),
    "agentrouter": ("https://agentrouter.org/v1", "auto"),
    "opencode": ("https://opencode.ai/zen/v1", "glm-5.3"),
}


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


def chiave_provider(pid):
    """La chiave di un provider, presa dal portachiavi (una sola fonte)."""
    try:
        p = subprocess.run(["bash", os.path.join(POSTA, "appello_chiavi.sh"), "--chiave", pid],
                           capture_output=True, text=True, timeout=20)
        return (p.stdout or "").strip()
    except Exception:
        return ""


def chat_riserva(messaggi, esclusi=()):
    """Se il motore è caduto: gli agenti non restano fermi, si passa alle chiavi
    che hanno risposto all'appello. Ritorna (testo, nome, modello) o None."""
    import urllib.request
    for v in appello_dati().get("voci", []):
        if v.get("esito") != "risponde" or v.get("id") in esclusi:
            continue
        pid = v.get("id")
        if pid not in APP_BASE:
            continue
        base, modello = APP_BASE[pid]
        modello = v.get("modello") or modello
        k = chiave_provider(pid)
        if not k:
            continue
        try:
            req = urllib.request.Request(
                base + "/chat/completions",
                data=json.dumps({"model": modello, "messages": messaggi[-12:],
                                 "max_tokens": 1200}).encode(),
                headers={"Authorization": "Bearer " + k, "Content-Type": "application/json"})
            d = json.loads(urllib.request.urlopen(req, timeout=90).read().decode())
            testo = (d.get("choices") or [{}])[0].get("message", {}).get("content", "")
            if testo:
                return testo, v.get("nome") or pid, modello
        except Exception:
            continue
    return None


def omni_spegni_porta(porta):
    """Chiude il processo che ascolta su una porta (serve per riavviare il portiere)."""
    try:
        out = subprocess.run(["pgrep", "-af", "cervello.py"], capture_output=True,
                             text=True, timeout=8).stdout
        for riga in out.splitlines():
            pid, _, cmd = riga.partition(" ")
            if pid.isdigit() and cmd.strip().endswith("cervello.py") and int(pid) != os.getpid():
                try:
                    os.kill(int(pid), 15)
                except Exception:
                    pass
        for _ in range(6):
            if not porta_viva(porta):
                return True
            time.sleep(1)
    except Exception:
        pass
    return not porta_viva(porta)


def cervello_avvia():
    """Accende il portiere (cervello.py, porta 20129): è lui che fa continuare gli agenti
    a lavorare se OmniRoute cade. Nessun terminale, nessuna finestra."""
    if porta_viva(20129):
        return True
    script = os.path.join(POSTA, "cervello.py")
    if not os.path.exists(script):
        return False
    try:
        subprocess.Popen(["python3", script], stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL, start_new_session=True)
    except Exception:
        return False
    for _ in range(10):
        if porta_viva(20129):
            return True
        time.sleep(1)
    return porta_viva(20129)


def _avvio_automatico():
    """All'accensione, senza che tu prema niente:
    1) se il motore è su ma ha 0 modelli, gli innesto io le chiavi (una volta per avvio);
    2) faccio l'appello delle chiavi, così la riserva è pronta da subito."""
    time.sleep(8)
    try:
        if omni_bin() and porta_viva(20128) and (modelli_omni().get("modelli") or 0) == 0:
            flag = os.path.join(HOME, ".stato_appello", "chiavi_innestate_" + time.strftime("%Y%m%d"))
            os.makedirs(os.path.dirname(flag), exist_ok=True)
            if not os.path.exists(flag):
                scrivi(flag, time.strftime("%H:%M"))
                log = "/tmp/omni_lav_chiavi.log"
                subprocess.Popen(["bash", os.path.join(POSTA, "omni_chiavi.sh")],
                                 stdout=open(log, "w"), stderr=subprocess.STDOUT,
                                 start_new_session=True)
    except Exception:
        pass
    try:
        vecchio = True
        if os.path.exists(APPELLO_JSON):
            vecchio = (time.time() - os.path.getmtime(APPELLO_JSON)) > 3 * 3600
        if vecchio:
            appello_lancia(svelto=True)
    except Exception:
        pass


def _sorveglianza():
    """In sottofondo: se il motore è spento lo riaccende (come faceva prima)."""
    time.sleep(5)
    while True:
        try:
            if not omni_bin():          # motore non installato: non insisto
                time.sleep(600)
                continue
            if not porta_viva(20128):
                omniroute_avvia(attesa=30)
        except Exception:
            pass
        time.sleep(120)


def stato():
    fus = {}
    try:
        fus = json.loads(leggi(os.path.join(POSTA, "stato_fusion.json"), "{}"))
    except Exception:
        pass
    ris_dir = os.path.join(POSTA, "RISPOSTE_AGENTI")
    ultimi = sorted(os.listdir(ris_dir), reverse=True)[:5] if os.path.isdir(ris_dir) else []
    if serve_login_manuale() and not os.path.exists(flag_checkin()) \
            and porta_viva(9222) and time.time() - _ultima_verifica[0] > 120:
        threading.Thread(target=verifica_sessione, daemon=True).start()
    sl = salute()             # 0,1 s: il verdetto deve arrivare prima di tutto il resto
    sv = saldo_istantaneo()
    mo = modelli_omni()
    lo = lavoro_omni()
    ap = appello_dati()
    return {"omniroute": porta_viva(20128), "browser_agenti": porta_viva(9222),
            "checkin_oggi": os.path.exists(flag_checkin()),
            "checkin_ora": leggi(flag_checkin(), "").strip(),
            "login_manuale": serve_login_manuale() and not os.path.exists(flag_checkin()),
            "login_motivo": leggi(file_login_manuale(), "").strip(),
            "tentativi": tentativi_oggi(), "max_tentativi": MAX_TENTATIVI,
            "finestra_aperta": finestra_aperta(), "finestra": f"{FINESTRA[0]:02d}:{FINESTRA[1]:02d}",
            "adesso": adesso_hhmm(),
            "saldo": sv or saldo_ultimo(), "saldo_vivo": bool(sv),
            "modelli": mo["modelli"], "linee": mo["linee"],
            "motore": {"acceso": porta_viva(20128), "errore": mo.get("errore", ""),
                       "installato": bool(omni_bin()), "nome": "OmniRoute",
                       "lavoro": lo["cosa"], "lavoro_secondi": lo["secondi"],
                       "lavoro_log": lo["log"]},
            "appello": {"quando": ap.get("quando", ""),
                        "riserva": ap.get("riserva", []),
                        "pronti": sum(1 for v in ap.get("voci", []) if v.get("esito") == "risponde"),
                        "totali": len([v for v in ap.get("voci", []) if v.get("esito") != "no-chiave"]),
                        "in_corso": _appello_stato["in_corso"],
                        "portiere": porta_viva(20129)},
            "fusion": fus, "risultati": ultimi, "salute": sl,
            "salute_chiara": salute_chiara(), "avvisi": avvisi_accensione(),
            "contatori": contatori_chiavi(), "openclaw": openclaw_stato(),
            "ora": time.strftime("%H:%M:%S")}


# ─────────────────────────────── HTTP ───────────────────────────────────────
class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _json(self, obj, code=200):
        b = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
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
        if self.path in ("/", "/index.html"):
            b = leggi(os.path.join(QUI, "index.html"), "<h1>index mancante</h1>").encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(b)))
            self.end_headers()
            self.wfile.write(b)
        elif self.path == "/api/hub" or self.path == "/hub":
            b = leggi(os.path.join(QUI, "hub.html"), "<h1>hub.html mancante</h1>").encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(b)))
            self.end_headers()
            self.wfile.write(b)
        elif self.path.startswith("/api/salute"):
            self._json(salute(fresco=True))
        elif self.path.startswith("/api/agenti/andamento"):
            self._json({"in_corso": _inst_agenti["in_corso"], "log": _inst_agenti["log"][-2500:],
                        "quando": _inst_agenti["quando"]})
        elif self.path.startswith("/api/agenti"):
            self._json(agenti_stato())
        elif self.path.startswith("/api/chiavi"):
            self._json(chiavi_conteggio())
        elif self.path.startswith("/api/ponte"):
            self._json(ponte_stato())
        elif self.path == "/api/stato":
            self._json(stato())
        elif self.path.startswith("/api/risultato"):
            import urllib.parse
            q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            nome = os.path.basename((q.get("f") or [""])[0])
            self._json({"nome": nome, "testo": leggi(os.path.join(POSTA, "RISPOSTE_AGENTI", nome), "(vuoto)")})
        else:
            self._json({"err": "not found"}, 404)

    def do_POST(self):
        if self.path == "/api/checkin":
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
        elif self.path == "/api/fusion":
            missione = (self._body().get("missione") or "").strip()
            if len(missione) < 5:
                self._json({"stato": "errore", "msg": "missione troppo corta"})
                return
            out = os.path.join(POSTA, "RISPOSTE_AGENTI", f"FUSION_GUI_{time.strftime('%Y%m%d_%H%M%S')}.md")
            json.dump({"percentuale": 1, "fase": "Avvio dalla GUI...", "stato": "in_corso"},
                      open(os.path.join(POSTA, "stato_fusion.json"), "w"))
            subprocess.Popen(["bash", os.path.join(POSTA, "squadra.sh"), missione, out],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self._json({"stato": "avviata", "out": os.path.basename(out)})
        elif self.path == "/api/chat":
            msgs = self._body().get("messaggi") or []
            if not msgs:
                self._json({"err": "vuoto"}, 400)
                return
            key = chiave(r"^omniroute", r"sk-[A-Za-z0-9-]+") or ""
            try:
                import urllib.request
                req = urllib.request.Request("http://127.0.0.1:20128/v1/chat/completions",
                                             data=json.dumps({"model": "auto", "messages": msgs[-12:]}).encode(),
                                             headers={"Authorization": "Bearer " + key,
                                                      "Content-Type": "application/json"})
                d = json.loads(urllib.request.urlopen(req, timeout=180).read().decode())
                self._json({"testo": d["choices"][0]["message"]["content"],
                            "modello": d.get("model") or "?", "via": "OmniRoute"})
            except Exception as e:
                # il motore non risponde (o è caduto): provo le chiavi dell'appello
                r = chat_riserva(msgs)
                if r:
                    self._json({"testo": r[0], "modello": f"{r[2]} · riserva {r[1]}",
                                "via": "riserva " + r[1]})
                else:
                    self._json({"testo": f"⚠️ Il motore non risponde ({type(e).__name__}) e nessuna "
                                         f"chiave di riserva ha risposto. Apri 🤖 Agenti → 🗣️ Appello "
                                         f"e guarda chi è rosso.", "modello": "-"})
        elif self.path == "/api/agenti/prova":
            svelto = bool(self._body().get("svelto"))
            argomenti = ["bash", os.path.join(POSTA, "prova_agenti.sh")] + (["--svelto"] if svelto else [])
            try:
                p = subprocess.run(argomenti, capture_output=True, text=True, timeout=300, cwd=POSTA)
                testo = ((p.stdout or "") + (p.stderr or ""))
            except subprocess.TimeoutExpired:
                testo = "Tempo scaduto: la prova è troppo lunga (usa la versione svelta)."
            self._json({"stato": "ok", "log": testo[-4000:]})
        elif self.path == "/api/agenti/installa":
            b = self._body()
            quali = b.get("quali") or None
            self._json(installa_agenti(quali))
        elif self.path == "/api/pc/aggiorna":
            self._json(aggiorna_pc())
        elif self.path == "/api/openclaw":
            b = self._body()
            az = (b.get("azione") or "stato").strip()
            if az == "stato":
                self._json(openclaw_stato())
            elif az == "avvia":
                if not _oc_libero("avvia"):
                    self._json({"stato": "in_corso",
                                "msg": "⏳ Sto già accendendo OpenClaw: aspetta una trentina di secondi "
                                       "senza premere altro.", "gateway": porta_viva(18789)})
                    return
                porta = openclaw_stato().get("porta", 18789)
                rc, log = _oc_win(["gateway", "install"], attesa=45, titolo="accendo")
                acceso = porta_viva(porta)
                if not acceso:                      # aspetto che parta, senza lanciare altro
                    for _ in range(25):
                        if porta_viva(porta):
                            acceso = True
                            break
                        time.sleep(1)
                msg = (f"🟢 Gateway acceso su :{porta} — da adesso parte da solo col PC") if acceso else \
                      ("⚠️ Servizio registrato ma non risponde ancora: aspetta 30 secondi e premi "
                       "«Ricontrolla», non «Accendi».")
                self._json({"stato": "ok" if acceso else "attenzione", "msg": msg,
                            "gateway": acceso, "log": (log or "")[-2000:]})
            elif az == "riavvia":
                if not _oc_libero("riavvia"):
                    self._json({"stato": "in_corso", "msg": "⏳ Già un comando in corso: aspetta.",
                                "gateway": porta_viva(18789)})
                    return
                porta = openclaw_stato().get("porta", 18789)
                rc, log = _oc_win(["gateway", "restart"], attesa=45, titolo="OpenClaw - riavvio")
                for _ in range(15):
                    if porta_viva(porta):
                        break
                    time.sleep(1)
                self._json({"stato": "ok", "msg": "Riavvio fatto.", "log": (log or "")[-2000:],
                            "gateway": porta_viva(porta)})
            elif az == "doctor":
                if not _oc_libero("doctor"):
                    self._json({"stato": "in_corso", "msg": "⏳ Già un comando in corso: aspetta.",
                                "gateway": porta_viva(18789)})
                    return
                rc, log = _oc_win(["doctor"], attesa=60, titolo="diagnostica")
                self._json({"stato": "ok", "msg": "Diagnostica completata (vedi sotto).",
                            "log": (log or "")[-3000:]})
            elif az == "cartella":
                # apre la cartella posta in Esplora Risorse di Windows
                try:
                    subprocess.Popen(["explorer.exe", _l2w(POSTA)], cwd="/mnt/c",
                                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    self._json({"stato": "ok", "msg": "Ho aperto la cartella posta in una finestra di Windows."})
                except Exception as e:
                    self._json({"stato": "errore", "msg": f"Non riesco ad aprire la cartella ({e})."})
            elif az == "prepara":
                # NON dipende da file/cartelle/git: il .bat lo scrivo io, qui, adesso.
                contenuto = (
                    "@echo off\r\n"
                    "chcp 65001 >nul 2>&1\r\n"
                    "setlocal EnableExtensions\r\n"
                    "title OpenClaw - configurazione iniziale\r\n"
                    "color 0B\r\n"
                    "cd /d \"%USERPROFILE%\" 2>nul\r\n"
                    "set \"OC=\"\r\n"
                    "for /f \"delims=\" %%i in ('where openclaw.cmd 2^>nul') do if not defined OC set \"OC=%%i\"\r\n"
                    "if not defined OC for /f \"delims=\" %%i in ('where openclaw 2^>nul') do if not defined OC set \"OC=%%i\"\r\n"
                    "if not defined OC if exist \"%APPDATA%\\npm\\openclaw.cmd\" set \"OC=%APPDATA%\\npm\\openclaw.cmd\"\r\n"
                    "if not defined OC goto NON_TROVATO\r\n"
                    "echo.\r\n"
                    "echo   OpenClaw: %OC%\r\n"
                    "echo.\r\n"
                    "echo   Rispondi alle domande (lingua, provider, canali).\r\n"
                    "echo   Se non sai una cosa, premi INVIO e la salti.\r\n"
                    "echo   ------------------------------------------------------------\r\n"
                    "call \"%OC%\" onboard\r\n"
                    "echo   ------------------------------------------------------------\r\n"
                    "echo   Finito. Torna nella GUI e premi Accendi.\r\n"
                    "pause\r\n"
                    "exit /b 0\r\n"
                    ":NON_TROVATO\r\n"
                    "echo   OpenClaw non risulta installato su questo PC.\r\n"
                    "echo   Una volta sola: doppio clic su INSTALLA_OPENCLAW.bat\r\n"
                    "pause\r\n"
                    "exit /b 1\r\n"
                )
                # dove scriverlo: la home di Windows dell'utente
                dest_dir = None
                winroot = os.environ.get("WINROOT", "/mnt/c")
                try:
                    r = subprocess.run(["cmd.exe", "/c", "echo", "%USERPROFILE%"], capture_output=True,
                                       text=True, timeout=15, cwd=winroot)
                    prof = (r.stdout or "").strip().splitlines()[-1].strip()
                    lin = _w2l(prof) if prof and ":" in prof else ""
                    if lin and os.path.isdir(lin):
                        dest_dir = lin
                except Exception:
                    dest_dir = None
                if not dest_dir:
                    for d in sorted(glob.glob(os.path.join(winroot, "Users", "*"))):
                        if os.path.isdir(os.path.join(d, "AppData", "Roaming")):
                            dest_dir = d
                            break
                if not dest_dir:
                    self._json({"stato": "errore",
                                "msg": "Non trovo la cartella utente di Windows. Usa il comando a mano: "
                                       "apri il Prompt dei comandi e scrivi  openclaw onboard"}, 400)
                    return
                dest = os.path.join(dest_dir, "CONFIGURA_OPENCLAW.bat")
                try:
                    with open(dest, "w", encoding="utf-8", newline="") as f:
                        f.write(contenuto)
                except Exception as e:
                    self._json({"stato": "errore", "msg": f"Non riesco a scrivere il file: {e}"}, 500)
                    return
                dest_win = _l2w(dest)
                aperto = False
                try:
                    subprocess.Popen(["cmd.exe", "/c", "start", "", dest_win], cwd=winroot,
                                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    aperto = True
                except Exception:
                    aperto = False
                if aperto:
                    msg = ("Si è aperta una finestra su Windows con le domande di OpenClaw. "
                           "Rispondi, poi chiudila e torna qui.")
                else:
                    msg = ("Non sono riuscito ad aprirla da qui. Il file però È SCRITTO: "
                           f"apri il Prompt dei comandi e incolla questa riga:  {dest_win}")
                self._json({"stato": "ok", "msg": msg, "bat": dest_win,
                            "comando": "openclaw onboard"})
            else:
                self._json({"stato": "errore", "msg": f"Azione sconosciuta: {az}"}, 400)
        elif self.path == "/api/cervello":
            az = (self._body().get("azione") or "stato").strip()
            if az == "avvia":
                su = cervello_avvia()
                self._json({"stato": "ok" if su else "ko", "acceso": su,
                            "msg": "🟢 Cervello di scorta acceso (porta 20129)" if su else
                                   "⚠️ Non sono riuscito ad accenderlo: manca cervello.py"})
            elif az == "riavvia":
                omni_spegni_porta(20129)
                time.sleep(1)
                su = cervello_avvia()
                self._json({"stato": "ok" if su else "ko", "acceso": su,
                            "msg": "🔄 Cervello di scorta riavviato" if su else
                                   "⚠️ Non è ripartito"})
            elif az == "spegni":
                self._json({"stato": "ok", "acceso": not omni_spegni_porta(20129),
                            "msg": "🔴 Cervello di scorta spento"})
            else:
                su = porta_viva(20129)
                tot = contatori_chiavi().get("cervello_totali", len(APP_BASE) + 1)
                d = {"acceso": su, "porta": 20129, "totali": tot, "pronti": 0, "nome": "Cervello"}
                if su:      # le chiamate le fa SOLO se è acceso
                    try:
                        import urllib.request
                        info = json.loads(urllib.request.urlopen(
                            "http://127.0.0.1:20129/cervello", timeout=8).read().decode())
                        d["pronti"] = len(info.get("riserva", []))
                        d["motore"] = bool(info.get("motore"))
                    except Exception:
                        pass
                self._json(d)
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
        elif self.path == "/api/omniroute":
            az = self._body().get("azione")
            if az in ("avvia", "riavvia") and not omni_bin():
                self._json({"stato": "ko", "gateway": False,
                            "msg": "⚠️ OmniRoute non è installato su questo PC: aprilo una volta col [9] "
                                   "(voce Motore). Dopo parte da solo."})
                return
            if az == "avvia":
                su = omniroute_avvia()
                self._json({"stato": "ok" if su else "ko", "gateway": su,
                            "msg": "🟢 Motore acceso" if su else "⚠️ Non si è acceso: vedi /tmp/omniroute.log"})
            elif az == "riavvia":
                su = omniroute_riavvia()
                self._json({"stato": "ok" if su else "ko", "gateway": su,
                            "msg": "🔄 Motore riavviato" if su else "⚠️ Non è ripartito: vedi /tmp/omniroute.log"})
            elif az in ("free", "chiavi"):
                if porta_viva(20128) and az == "free":
                    # omni_free.sh spegne e riaccende il motore da sé: nessun blocco
                    pass
                if _omni_lav["quando"] and time.time() - _omni_lav["quando"] < 420:
                    self._json({"stato": "in_corso",
                                "msg": f"⏳ Sto già lavorando ({_omni_lav['cosa']}): 2-5 minuti, non premere altro."})
                    return
                script = os.path.join(POSTA, "omni_free.sh" if az == "free" else "omni_chiavi.sh")
                if not os.path.exists(script):
                    self._json({"stato": "ko", "msg": f"⚠️ Manca {os.path.basename(script)}"})
                    return
                _omni_lav["quando"] = time.time()
                _omni_lav["cosa"] = "provider gratis" if az == "free" else "chiavi"
                log = os.path.join("/tmp", "omni_lav_" + az + ".log")
                subprocess.Popen(["bash", script], stdout=open(log, "w"), stderr=subprocess.STDOUT,
                                 start_new_session=True)
                self._json({"stato": "avviato",
                            "msg": ("⏳ Attivo i provider gratis (2-5 minuti). Il motore si spegne e si "
                                    "riaccende da solo; a fine lavoro ricontrollo i modelli."
                                    if az == "free" else
                                    "⏳ Innesto le tue chiavi nei provider (2-3 minuti). Il motore si spegne e "
                                    "si riaccende da solo.")})
            elif az == "spegni":
                spento = omni_spegni()
                self._json({"stato": "ok" if spento else "ko", "gateway": porta_viva(20128),
                            "msg": "🔴 Motore spento (si riaccende da solo con la Centrale)"
                                   if spento else "⚠️ Non sono riuscito a spegnerlo: riprova"})
            else:
                self._json({"err": "azione?"}, 400)
        else:
            self._json({"err": "not found"}, 404)


def postino_bg():
    if TEST or os.environ.get("AR_IGNORA_FINESTRA") == "1":
        return                          # in collaudo non deve committare/pushare nulla
    if subprocess.run(["pgrep", "-f", "postino.sh"], capture_output=True).returncode != 0:
        subprocess.Popen(["bash", os.path.join(POSTA, "postino.sh"), "--loop"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


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
    libera_porta_20200()
    postino_bg()
    threading.Thread(target=_sorveglianza, daemon=True).start()   # il motore si accende da solo
    threading.Thread(target=_avvio_automatico, daemon=True).start()  # chiavi + appello, senza premere niente
    if os.environ.get("CENTRALE_NO_SVEGLIA") != "1":
        threading.Thread(target=sveglia_checkin, daemon=True).start()
    else:
        print("[gui] sveglia disattivata (CENTRALE_NO_SVEGLIA=1)")
    print(f"GUI CENTRALE su http://localhost:20200 · finestra bonus dalle {FINESTRA[0]:02d}:{FINESTRA[1]:02d}")
    ThreadingHTTPServer(("0.0.0.0", 20200), H).serve_forever()
