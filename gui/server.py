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
import json, os, re, subprocess, sys, time, threading
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


def modelli_omni():
    v = _cache.get("mod")
    if v and time.time() - v[0] < 60:
        return v[1]
    r = {"modelli": 0, "linee": 0}
    if porta_viva(20128):
        try:
            import urllib.request
            key = chiave(r"^omniroute", r"sk-[A-Za-z0-9-]+") or ""
            req = urllib.request.Request("http://127.0.0.1:20128/v1/models",
                                         headers={"Authorization": "Bearer " + key})
            data = json.loads(urllib.request.urlopen(req, timeout=10).read().decode()).get("data", [])
            r["modelli"] = len(data)
            r["linee"] = len({(m.get("owned_by") or "?") for m in data})
        except Exception:
            pass
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
            "fusion": fus, "risultati": ultimi, "salute": sl, "openclaw": openclaw_stato(),
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
                self._json({"testo": d["choices"][0]["message"]["content"], "modello": d.get("model") or "?"})
            except Exception as e:
                self._json({"testo": f"⚠️ Non riesco a parlare con OmniRoute: {e}", "modello": "-"})
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
        elif self.path == "/api/omniroute":
            az = self._body().get("azione")
            if az == "avvia":
                subprocess.Popen(["bash", "-lc",
                                  "export NVM_DIR=$HOME/.nvm; . $NVM_DIR/nvm.sh >/dev/null 2>&1; "
                                  "B=$(ls -d $HOME/.nvm/versions/node/v22*/bin 2>/dev/null | sort -V | tail -1); "
                                  "nohup $B/omniroute >/tmp/omniroute.log 2>&1 &"])
                self._json({"stato": "avvio richiesto"})
            elif az == "spegni":
                subprocess.run(["pkill", "-f", "omniroute"])
                self._json({"stato": "spento"})
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
    if os.environ.get("CENTRALE_NO_SVEGLIA") != "1":
        threading.Thread(target=sveglia_checkin, daemon=True).start()
    else:
        print("[gui] sveglia disattivata (CENTRALE_NO_SVEGLIA=1)")
    print(f"GUI CENTRALE su http://localhost:20200 · finestra bonus dalle {FINESTRA[0]:02d}:{FINESTRA[1]:02d}")
    ThreadingHTTPServer(("0.0.0.0", 20200), H).serve_forever()
