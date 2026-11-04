# cura_low.py — 2 migliorie LOW a cervello.py, patch a stringa esatta.
# Ogni vecchia stringa DEVE comparire esattamente una volta: se no, si ferma e non scrive.
import io
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
PERCORSO = sys.argv[1] if len(sys.argv) > 1 else "/home/agenti/posta/cervello.py"
src = open(PERCORSO, encoding="utf-8").read()

PATCH = [
    # (nome, vecchia, nuova) — la vecchia deve comparire ESATTAMENTE una volta
    ("helper escape in pagina()",
     'def pagina():\n    """La pagina del Portiere: la SUA lista, provider per provider."""',
     'def pagina():\n    """La pagina del Portiere: la SUA lista, provider per provider."""\n'
     '    from html import escape as _esc   # CURA-AUDIT LOW-1: i valori della lista non finiscono in HTML'),
    ("etichetta provider",
     "{icona}</span> <b>{ETICHETTE.get(pid, pid)}</b> ",
     "{icona}</span> <b>{_esc(ETICHETTE.get(pid, pid))}</b> "),
    ("tipo e classe provider",
     '{TIPI.get(pid, "chat")} · {CLASSI.get(pid, "")}</span></td>',
     '{_esc(TIPI.get(pid, "chat"))} · {_esc(CLASSI.get(pid, ""))}</span></td>'),
    ("indirizzo e modello",
     "f'{url.replace(\"https://\", \"\")} · {modello}</td>'",
     "f'{_esc(url.replace(\"https://\", \"\"))} · {_esc(modello)}</td>'"),
    ("nota provider",
     "f'{nota}</td></tr>')",
     "f'{_esc(nota)}</td></tr>')"),
    ("da confermare: nome",
     "border-bottom:1px solid #ffffff0d\"><b>' + n + '</b>'",
     "border-bottom:1px solid #ffffff0d\"><b>' + _esc(n) + '</b>'"),
    ("da confermare: modello",
     "'<span style=\"color:#9aa4b2\">' + m + '</span></div>'",
     "'<span style=\"color:#9aa4b2\">' + _esc(m) + '</span></div>'"),
    ("banner sentinella",
     " + STATO.get(\"sentinella\", {}).get(\"avviso\", \"\") + '</div>')",
     " + _esc(STATO.get(\"sentinella\", {}).get(\"avviso\", \"\")) + '</div>')"),
    ("stato_salva: errore non muto",
     "_ultimo_salvataggio[0] = time.time()\n    except Exception:\n        pass",
     "_ultimo_salvataggio[0] = time.time()\n    except Exception as e:\n"
     "        logga(tipo=\"errore-stato\", nota=\"salvataggio stato fallito: %s\" % str(e)[:120])"),
]

ok = 0
for nome, vecchia, nuova in PATCH:
    n = src.count(vecchia)
    if n != 1:
        print(f"✗ '{nome}': trovate {n} occorrenze (attesa 1) — MI FERMO, nessuna modifica")
        sys.exit(1)
    src = src.replace(vecchia, nuova)
    ok += 1
    print(f"✓ {nome}")

tmp = PERCORSO + ".tmp_cura"
open(tmp, "w", encoding="utf-8").write(src)
os.replace(tmp, PERCORSO)
print(f"applicate {ok}/{len(PATCH)} patch, scrittura atomica OK")
