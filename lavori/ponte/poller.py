#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
poller.py — Ponte arena → agenti locali via GitHub Issues (costo 0, senza gh).

Uso:
  python3 poller.py --once                 # un solo ciclo (per i test)
  python3 poller.py --once --dry-run       # mostra cosa farebbe, non tocca nulla
  python3 poller.py                        # loop continuo (intervallo da ponte.json)

GitHub via REST API con PAT letto in silenzio dal portachiavi (ponte.json → token_file/token_re).
Solo libreria standard Python.
"""

import argparse
import datetime
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
import traceback
import urllib.request
import urllib.error
import urllib.parse
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

# 4/11: git MAI chiede credenziali a terminale: se lo fa, il poller resta
# appeso per sempre (stesso buco del postino, che ha GIT_TERMINAL_PROMPT=0).
os.environ.setdefault("GIT_TERMINAL_PROMPT", "0")


BASE = Path(__file__).resolve().parent
STATO = BASE / "_stato"

CFG = json.loads((BASE / "ponte.json").read_text(encoding="utf-8"))
REPO = CFG["repo"]
INTERVALLO = int(CFG.get("intervallo_s", 40))
MAX_TENTATIVI = int(CFG.get("max_tentativi", 3))
MAX_PARALLELI = int(CFG.get("max_paralleli", 2))
REPO_PATH = CFG.get("repo_path")  # percorso locale del repo git (se impostato: commit+push)
CONSEGNE_REL = CFG.get("consegne_dir", "consegne")
TOKEN_FILE = CFG.get("token_file")
TOKEN_RE = CFG.get("token_re", "ghp_[A-Za-z0-9]{20,}")

API = f"https://api.github.com/repos/{REPO}"
_token_mem = None

# locks di concorrenza (il ponte esegue fino a MAX_PARALLELI task in parallelo)
GIT_LOCK = threading.Lock()      # un commit/push alla volta (index.lock del repo)
FILE_LOCK = threading.Lock()     # scritture su _stato/ponte_stato.json
AGENT_GUARD = threading.Lock()
AGENT_LOCKS = {}                 # un task per agente: goose non litiga con goose


def ag_lock(target):
    with AGENT_GUARD:
        if target not in AGENT_LOCKS:
            AGENT_LOCKS[target] = threading.Lock()
        return AGENT_LOCKS[target]


def stato_ponte(aggiungi=None, rimuovi=None):
    """Contatore condiviso: chi sta lavorando ora (leggibile da stato_ponte.sh e arena)."""
    with FILE_LOCK:
        s = {"pid": os.getpid(), "max_paralleli": MAX_PARALLELI,
             "aggiornato": datetime.datetime.now().isoformat(timespec="seconds")}
        f = STATO / "ponte_stato.json"
        if f.exists():
            try:
                vecchio = json.loads(f.read_text(encoding="utf-8"))
                s["in_corso"] = vecchio.get("in_corso", [])
            except Exception:
                s["in_corso"] = []
        else:
            s["in_corso"] = []
        s["in_corso"] = [t for t in s["in_corso"] if t["numero"] != rimuovi]
        if aggiungi:
            s["in_corso"].append(aggiungi)
        f.write_text(json.dumps(s, ensure_ascii=False, indent=1), encoding="utf-8")


def log(msg):
    ts = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}", flush=True)


# ------------------------------------------------------------------ GitHub API
def get_token():
    """Legge il PAT dal portachiavi in silenzio; prova i candidati finché uno funziona."""
    global _token_mem
    if _token_mem:
        return _token_mem
    candidati = re.findall(TOKEN_RE, Path(TOKEN_FILE).read_text(encoding="utf-8", errors="replace"))
    if not candidati:
        raise RuntimeError(f"nessun token trovato in {TOKEN_FILE} (pattern {TOKEN_RE})")
    for tok in candidati:
        try:
            st, _ = api("GET", "", token=tok)
            if st == 200:
                _token_mem = tok
                log("token del portachiavi OK (silenzioso)")
                return tok
        except Exception:
            continue
    raise RuntimeError("nessun token del portachiavi ha accesso al repo")


def api(method, path, body=None, token=None):
    tok = token or get_token()
    url = API + (f"/{path}" if path else "")  # senza barra finale: /repos/x/y/ darebbe 404
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {tok}")
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("User-Agent", "ponte-poller")
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            txt = r.read().decode()
            return r.status, (json.loads(txt) if txt else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:600]


def ensure_labels():
    for name, color in [("inbox", "0E8A16"), ("in-corso", "FBCA04"),
                        ("richiede-conferma", "D93F0B"), ("bloccato", "B60205")]:
        api("POST", "labels", {"name": name, "color": color})


def issue_inbox():
    st, out = api("GET", "issues?labels=inbox&state=open&per_page=10")
    if st != 200:
        raise RuntimeError(f"lettura issues: {st} {out}")
    return [i for i in out if "pull_request" not in i]  # solo issue vere


def labels_di(n):
    st, out = api("GET", f"issues/{n}/labels")
    return [l["name"] for l in out] if st == 200 else []


def set_labels(n, nomi):
    return api("PUT", f"issues/{n}/labels", {"labels": nomi})


def commenta(n, testo):
    api("POST", f"issues/{n}/comments", {"body": testo})


def chiudi(n):
    api("PATCH", f"issues/{n}", {"state": "closed"})


def claim(n):
    """inbox → in-corso mantenendo le altre etichette (es. richiede-conferma)."""
    nomi = [l for l in labels_di(n) if l != "inbox"]
    if "in-corso" not in nomi:
        nomi.append("in-corso")
    st, _ = set_labels(n, nomi)
    if st not in (200, 409):
        log(f"  claim # {n} fallito: {st}")
        return False
    return True


# ------------------------------------------------------------------ utilità
def git(cwd, *args):
    # Lezione del 3/11: il postino può tenere index.lock → attendi o rimuovi
    # il lock orfano PRIMA dell'operazione.
    lock = Path(cwd) / ".git" / "index.lock"
    for _ in range(3):
        if not lock.exists():
            break
        r = subprocess.run(["pgrep", "-x", "git"], capture_output=True)
        if r.returncode != 0:  # nessun git attivo → lock orfano
            lock.unlink(missing_ok=True)
            break
        time.sleep(20)
    # 4/11: git SENZA timeout poteva restare appeso per sempre (push su una
    # connessione GitHub stallata): il poller smetteva di girare e il ponte
    # sembrava morto. Ora ogni comando git ha un tetto e, se lo supera, solleva
    # un errore onesto invece di bloccare il ciclo.
    try:
        r = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, timeout=180)
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"git {' '.join(args)} → TIMEOUT dopo 180s")
    if r.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} → exit {r.returncode}: {r.stderr.strip()[:400]}")
    return r.stdout


def parse_campo(body, campo, successivi):
    """(fix 4/11) il campo e' TUTTO il testo fino al campo successivo.

    Prima veniva tagliato al PRIMO a capo (la regex "in linea" mangiava anche
    il newline): gli agenti ricevevano solo la prima riga del compito e
    rispondevano "dimmi il comando" senza eseguire nulla.
    """
    m = re.search(
        rf"^\s*{campo}\s*:\s*\n(.*?)(?=^\s*(?:{successivi})\s*:|\Z)",
        body, re.M | re.I | re.S,
    )
    if m and m.group(1).strip():
        return m.group(1).strip()
    m = re.search(rf"^\s*{campo}\s*:\s*(.+)$", body, re.M | re.I)
    if m and m.group(1).strip():
        return m.group(1).strip()
    return None


def slugify(s, n=40):
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s).strip("-").lower()
    return s[:n] or "task"


def leggi_tentativi(n):
    f = STATO / f"{n}.json"
    if f.exists():
        try:
            return json.loads(f.read_text(encoding="utf-8")).get("tentativi", 0)
        except Exception:
            return 0
    return 0


def salva_tentativi(n, k):
    STATO.mkdir(exist_ok=True)
    (STATO / f"{n}.json").write_text(json.dumps({"tentativi": k}, ensure_ascii=False), encoding="utf-8")


# ------------------------------------------------------------------ smistamento
def smista(numero, titolo, body, dry):
    target = (parse_campo(body, "target", "consegna|compito|contesto") or "").lower()
    compito = parse_campo(body, "compito", "contesto") or ""
    contesto = parse_campo(body, "contesto", "target|consegna|compito") or ""
    spec = CFG.get("agenti", {}).get(target)

    if not spec:
        commenta(numero, f"❌ `target: {target}` non esiste in ponte.json. Task ignorato.")
        nomi = [l for l in labels_di(numero) if l not in ("inbox", "in-corso")]
        nomi.append("bloccato")
        set_labels(numero, nomi)
        return

    slug = slugify(titolo.replace("PONTE:", "").strip())
    if dry:
        log(f"  [dry-run] eseguirebbe: {target} | compito {len(compito)} caratteri")
        return

    if REPO_PATH:
        d = Path(REPO_PATH) / CONSEGNE_REL / f"{numero}-{slug}"
    else:
        d = BASE / "consegne" / f"{numero}-{slug}"
    d.mkdir(parents=True, exist_ok=True)

    cmd = [c.format(compito=compito, contesto=contesto) for c in spec["cmd"]]
    timeout = int(spec.get("timeout", 1800))
    workdir = spec.get("workdir") or CFG.get("workdir_default") or str(Path.home())
    log(f"  dispatch #{numero} → {target}")
    inizio = time.time()
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, cwd=workdir,
                           timeout=timeout, env={**os.environ})
        exit_code, stdout, stderr = r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        exit_code, stdout, stderr = 124, "", f"TIMEOUT dopo {timeout}s"

    durata = int(time.time() - inizio)

    raccolti = []
    for pattern in spec.get("raccogli", []):
        for p in glob.glob(pattern):
            src = Path(p)
            if src.is_file() and d not in src.parents:
                dest = d / src.name
                try:
                    shutil.copy2(src, dest)
                    raccolti.append(src.name)
                except Exception as e:
                    log(f"  copia fallita {src}: {e}")

    ok = exit_code == 0
    esito = "✅ COMPLETATO" if ok else "❌ FALLITO"
    stdout_tail = "\n".join(stdout.strip().splitlines()[-120:]) or "(vuoto)"
    stderr_tail = "\n".join(stderr.strip().splitlines()[-40:]) if stderr.strip() else ""
    rel = f"/{CONSEGNE_REL}/{numero}-{slug}" if REPO_PATH else str(d)

    ris = [
        f"{esito} — issue #{numero} — {durata}s — exit {exit_code}",
        f"Agente: `{target}`",
        "",
        "### Output (coda)",
        "```", stdout_tail, "```",
    ]
    if stderr_tail:
        ris += ["### Errori (coda)", "```", stderr_tail, "```"]
    if raccolti:
        ris += ["### File raccolti", *[f"- {x}" for x in raccolti]]
    ris += ["", f"Consegna: `{rel}`"]
    (d / "RISULTATO.md").write_text("\n".join(ris), encoding="utf-8")

    if ok:
        if REPO_PATH:
            with GIT_LOCK:  # un commit/push alla volta anche con agenti in parallelo
                # 4/11 (fix bridge, diagnosticato dall'agente): il poller faceva
                # commit + push SENZA pull. Se nel frattempo arrivava un push dal
                # sandbox, Git rispondeva "rejected (fetch first)" e la consegna
                # si perdeva (ripartiva al tentativo successivo, con rumore).
                # Con la pull prima, la consegna va al primo colpo.
                try:
                    git(REPO_PATH, "pull", "--rebase", "--autostash")
                except Exception as e:  # una pull fallita NON deve perdere la consegna
                    log(f"  ⚠ pull prima del push fallito: {e}")
                    for _rim in ("rebase", "merge"):  # lascia il repo pulito
                        try:
                            subprocess.run(["git", _rim, "--abort"], cwd=REPO_PATH,
                                           capture_output=True, text=True, timeout=60)
                        except Exception:
                            pass
                git(REPO_PATH, "add", f"{CONSEGNE_REL}/{numero}-{slug}")
                git(REPO_PATH, "commit", "-m", f"ponte: consegna issue #{numero} ({target})")
                git(REPO_PATH, "push", "origin", "HEAD:main")
        commenta(numero, "\n".join(ris))
        nomi = [l for l in labels_di(numero) if l not in ("in-corso", "inbox")]
        set_labels(numero, nomi)  # issue chiusa e pulita
        chiudi(numero)
        (STATO / f"{numero}.json").unlink(missing_ok=True)
        log(f"  #{numero} completato in {durata}s")
    else:
        tent = leggi_tentativi(numero) + 1
        salva_tentativi(numero, tent)
        nomi = [l for l in labels_di(numero) if l != "in-corso"]
        if tent >= MAX_TENTATIVI:
            nomi.append("bloccato")
            set_labels(numero, nomi)
            commenta(numero, f"🛑 {MAX_TENTATIVI} tentativi falliti. Serve intervento umano.\n\n" + "\n".join(ris))
            log(f"  #{numero} → bloccato dopo {tent} tentativi")
        else:
            nomi.append("inbox")
            set_labels(numero, nomi)
            commenta(numero, f"⚠️ tentativo {tent}/{MAX_TENTATIVI} fallito (exit {exit_code}). Riprovo al prossimo giro.\n\n```\n{stderr_tail[:600]}\n```")
            log(f"  #{numero} fallito (exit {exit_code}), tentativo {tent}")


def riprendi_dopo_riavvio(dry):
    st, out = api("GET", "issues?labels=in-corso&state=open&per_page=20")
    if st != 200:
        return
    for it in out:
        if "pull_request" in it:
            continue
        n = it["number"]
        if dry:
            log(f"  [dry-run] riporterebbe # {n} su inbox (riavvio precedente)")
            continue
        nomi = [l for l in labels_di(n) if l != "in-corso"]
        nomi.append("inbox")
        set_labels(n, nomi)
        commenta(n, "🔄 il poller precedente è stato interrotto: task rimesso in coda (inbox).")
        log(f"  #{n} rimesso in coda dopo riavvio")


def riprendi_dopo_riavvio(dry):
    """Issue 'in-corso' senza esito: il poller precedente è morto a metà. Re-inbox."""
    riprese = []
    st, out = api("GET", "issues?labels=in-corso&state=open&per_page=20")
    if st != 200:
        return riprese
    for it in out:
        if "pull_request" in it:
            continue
        n = it["number"]
        if dry:
            log(f"  [dry-run] riporterebbe # {n} su inbox (riavvio precedente)")
            continue
        nomi = [l for l in labels_di(n) if l != "in-corso"]
        nomi.append("inbox")
        set_labels(n, nomi)
        commenta(n, "🔄 il poller precedente è stato interrotto: task rimesso in coda (inbox).")
        riprese.append((n, it["title"], it.get("body") or ""))
        log(f"  #{n} rimesso in coda dopo riavvio")
    return riprese


def esegui(n, titolo, body, dry):
    if dry:
        log(f"[dry-run] prenderei # {n}: {titolo}")
        smista(n, titolo, body or "", dry=True)
        return
    target = (parse_campo(body or "", "target", "consegna|compito|contesto") or "?").lower()
    # lock per agente: un task per ciascuno (niente due goose in gara),
    # il numero massimo di agenti contemporanei è MAX_PARALLELI (pool del ciclo)
    with ag_lock(target):
        log(f"presa # {n}: {titolo}")
        if not claim(n):
            return
        stato_ponte(aggiungi={"numero": n, "target": target,
                              "dal": datetime.datetime.now().strftime("%H:%M:%S")})
        try:
            smista(n, titolo, body or "", dry=False)
        except Exception as e:
            traceback.print_exc()
            tent = leggi_tentativi(n) + 1
            salva_tentativi(n, tent)
            msg = f"⚠️ errore interno del poller su # {n} (tentativo {tent}/{MAX_TENTATIVI}): `{e}`"
            log(msg)
            try:
                nomi = [l for l in labels_di(n) if l != "in-corso"]
                nomi.append("inbox")
                set_labels(n, nomi)
                commenta(n, msg)
            except Exception as e2:
                log(f"  nessun commento possibile: {e2}")
        finally:
            stato_ponte(rimuovi=n)


def ciclo(dry=False, extra=None):
    # le issue appena rimesse in coda non compaiono subito nelle query filtrate
    # (lag di propagazione dell'API): processale direttamente
    compiti = list(extra or [])
    issues = issue_inbox()
    compiti += [(it["number"], it["title"], it.get("body") or "") for it in issues]
    if not compiti:
        log("coda vuota")
        return
    # ordine preventivo: massimo MAX_PARALLELI agenti insieme, gli altri aspettano
    with ThreadPoolExecutor(max_workers=MAX_PARALLELI) as pool:
        futuri = [pool.submit(esegui, n, t, b, dry) for n, t, b in compiti]
        for f in futuri:
            f.result()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--once", action="store_true", help="un solo ciclo")
    ap.add_argument("--dry-run", action="store_true", help="nessuna modifica reale")
    args = ap.parse_args()

    STATO.mkdir(exist_ok=True)
    lock = STATO / "poller.lock"
    try:
        fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        os.write(fd, str(os.getpid()).encode())
        os.close(fd)
    except FileExistsError:
        log("un altro poller è già attivo (lock presente): esco")
        sys.exit(0)

    try:
        log(f"avvio — repo {REPO}, intervallo {INTERVALLO}s, repo_path={REPO_PATH or '(solo locale)'}")
        if not args.dry_run:
            ensure_labels()
        get_token()
        riprese = riprendi_dopo_riavvio(args.dry_run)
        while True:
            try:
                ciclo(args.dry_run, extra=riprese)
                riprese = []
            except Exception as e:
                log(f"errore nel ciclo: {e}")
            if args.once:
                break
            time.sleep(INTERVALLO)
    finally:
        lock.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
