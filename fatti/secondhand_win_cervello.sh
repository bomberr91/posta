#!/usr/bin/env bash
# secondhand_win_cervello.sh — 4/11: allinea la config Windows di Open Interpreter.
#
# FATTO: la config Windows (C:\Users\giopi\.openinterpreter\config.toml) aveva
# model_provider="openai" e model="auto", ma il base_url del CERVELLO era solo
# dentro [model_providers.nvidia]: in alto (dove legge l'app desktop) non c'era.
# Senza base_url l'app andrebbe su api.openai.com con la chiave finta sk-cervello
# => 401. Il WSL funzionava perche' il blocco [projects.'/home/agenti/posta']
# contiene base_url.
#
# Cosa fa: mette base_url + env_key in ALTO (prima di ogni [sezione]) e dentro
# il blocco del progetto Windows, con backup. Poi collauda la config Windows
# copiandola in un posto pulito e chiedendo all'interpreter della WSL di
# rispondere "OK": se risponde, la config Windows e' giusta per l'app.
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

echo "### 1. SCRITTURA DELLA CONFIG WINDOWS (backup + base_url in alto)"
python3 - << 'PY'
import os, re, shutil, datetime, hashlib
WIN = "/mnt/c/Users/giopi/.openinterpreter/config.toml"
BASE = "http://127.0.0.1:20129/v1"
if not os.path.exists(WIN):
    print("  config Windows ASSENTE:", WIN)
    raise SystemExit(1)
stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
bak = WIN + ".bak-" + stamp
shutil.copy2(WIN, bak)
print("  backup:", bak)
s = open(WIN, encoding="utf-8", errors="replace").read()

def set_toplevel(testo, chiave, valore):
    # toglie l'eventuale riga in alto, poi la reinserisce come prima riga
    testo = re.sub(r'(?m)^%s\s*=.*\n?' % chiave, "", testo)
    return '%s = "%s"\n' % (chiave, valore) + testo

s = set_toplevel(s, "base_url", BASE)
s = set_toplevel(s, "env_key", "OPENAI_API_KEY")
s = set_toplevel(s, "model_provider", "openai")
s = set_toplevel(s, "model", "auto")

# dentro il blocco del progetto Windows
def nel_progetto(testo, chiave, valore):
    m = re.search(r"(?ms)^\[projects\.'c:\\\\users\\\\giopi\\\\documents\\\\agentworkspace'\]\n(.*?)(?=^\[|\Z)", testo)
    if not m:
        return testo
    corpo = m.group(1)
    if re.search(r"(?m)^%s\s*=" % chiave, corpo):
        corpo = re.sub(r"(?m)^%s\s*=.*$" % chiave, '%s = "%s"' % (chiave, valore), corpo)
    else:
        corpo = corpo.rstrip("\n") + '\n%s = "%s"\n' % (chiave, valore)
    return testo[:m.start(1)] + corpo + testo[m.end(1):]

s = nel_progetto(s, "base_url", BASE)
s = nel_progetto(s, "env_key", "OPENAI_API_KEY")
open(WIN, "w", encoding="utf-8").write(s)

def mask(t):
    def f(mm):
        v = mm.group(1)
        if v.startswith("http") or len(v) < 25:
            return mm.group(0)
        return '"<%d caratteri>"' % len(v)
    return re.sub(r'"([^"]*)"', f, t)
print("  --- config nuova (mascherata):")
for riga in mask(s).splitlines():
    print("   ", riga)
PY
echo

echo "### 2. COLLAUDO: la config Windows, usata da una directory fuori progetto"
echo "(si copia la config Windows al posto di quella WSL, si esegue l'interpreter in /tmp, poi si ripristina)"
WINTOML=/mnt/c/Users/giopi/.openinterpreter/config.toml
WSL=/home/agenti/.config/interpreter/config.toml
cp "$WSL" /tmp/wsl_config_backup.toml 2>/dev/null
cp "$WINTOML" "$WSL" || { echo "  copia non riuscita"; exit 1; }
mkdir -p /tmp/sh_prova && cd /tmp/sh_prova
OUT=/tmp/sh_win_test.log
OPENAI_API_KEY=sk-cervello timeout 200 interpreter exec --skip-git-repo-check \
  "Rispondi esattamente con la parola OK e nient'altro." > "$OUT" 2>&1
RC=$?
cd "$REPO" || exit 1
cp /tmp/wsl_config_backup.toml "$WSL" 2>/dev/null
echo "--- exit: $RC"
head -c 1500 "$OUT"
echo
if [ "$RC" -eq 0 ] && grep -qi "^OK" "$OUT"; then
  echo "VERDETTO: LA CONFIG WINDOWS E' CORRETTA (l'app puo' parlare col cervello)"
else
  echo "VERDETTO: LA CONFIG WINDOWS NON VA ANCORA BENE (exit $RC) — vedi output sopra"
fi
echo
echo "### 3. NOTA"
echo "L'app desktop deve essere riavviata per leggere la variabile OPENAI_API_KEY (setx vale per i processi nuovi)."
echo "FINE"
exit 0
