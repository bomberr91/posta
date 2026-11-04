"""Secondhand 0.4.3 — patch dei due profili WINDOWS (solo se esistono).

Chiamato da da_me/secondhand_profilo_win_sicuro.sh.
Non tocca il profilo WSL del ponte.
"""
import os
import re
import sys

YAML_W = "/mnt/c/Users/giopi/.config/open-interpreter/profiles/default.yaml"
TOML_W = "/mnt/c/Users/giopi/.openinterpreter/config.toml"

PATCHES = {
    YAML_W: [
        (r"(?m)^auto_run:\s*True\s*$", "auto_run: False"),
        (r'(?m)^safe_mode:\s*"off"\s*$', 'safe_mode: "ask"'),
    ],
    TOML_W: [
        (r'(?m)^sandbox_mode\s*=\s*"danger-full-access"\s*$', 'sandbox_mode = "workspace-write"'),
        (r'(?m)^approval_policy\s*=\s*"never"\s*$', 'approval_policy = "on-request"'),
    ],
}

for path, coppie in PATCHES.items():
    if not os.path.exists(path):
        print("%s: ASSENTE (niente da fare)" % path)
        continue
    try:
        s = open(path, encoding="utf-8", errors="replace").read()
    except Exception as e:  # noqa
        print("%s: ERRORE lettura %s" % (path, e))
        continue
    for pat, rep in coppie:
        s2, n = re.subn(pat, rep, s)
        if n == 0:
            print("%s: NON TROVATO %s" % (path, pat))
        s = s2
    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(s)
        print("%s: aggiornato" % path)
    except Exception as e:  # noqa
        print("%s: ERRORE scrittura %s" % (path, e))
        sys.exit(1)
print("patch finita")
