#!/usr/bin/env bash
# secondhand_auto.sh — 4/11: far partire Secondhand con il modello giusto.
#
# FATTO (da secondhand_dove): in 0.4.3 il modello di default nasce qui:
#   interpreter/core/llm/llm.py:54   self.model = "gpt-4o"
# e il config TOML dell'utente non viene letto (nessun .toml nel pacchetto:
# il loader e' il sistema di "profili", che conosce ~/.config/open-interpreter
# ma con una struttura diversa da quella che ho scritto).
# Il cervello rifiuta 'gpt-4o' (guardia solo-gratis) ⇒ ogni chiamata esce
# con errore.
#
# Fix pragmatico e REVERSIBILE: cambio la riga del default nel pacchetto
# installato (backup accanto) da "gpt-4o" a "auto" (il cervello sceglie:
# gratis/veloce/migliore). Poi collaudo reale col token univoco.
#
# Niente pipe verso tail.
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

TOKEN="PIPPO42"
PROMPT="Rispondi esattamente con la parola $TOKEN e nient'altro."
LLM="$HOME/.local/lib/python3.12/site-packages/interpreter/core/llm/llm.py"
export OPENAI_API_KEY=sk-cervello
export OPENAI_BASE_URL=http://127.0.0.1:20129/v1
export OPENAI_HOST=http://127.0.0.1:20129
BK=/tmp/sh_auto_$(date +%H%M%S); mkdir -p "$BK"

echo "### 1. PATCH DEL MODELO DI DEFAULT (con backup)"
if [ -f "$LLM" ]; then
  cp "$LLM" "$BK/llm.py.bak" && echo "  backup: $BK/llm.py.bak"
  python3 - "$LLM" << 'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r'(self\.model\s*=\s*)"gpt-4o"', r'\1"auto"', s, count=1)
if n:
    open(p, "w", encoding="utf-8").write(s2)
    print("  patchata la riga: self.model = \"auto\"")
else:
    print("  riga self.model = \"gpt-4o\" non trovata (gia' cambiata?)")
PY
  grep -n 'self.model = ' "$LLM" | head -3
else
  echo "  $LLM non trovato"
fi
echo

echo "### 2. COLLAUDO REALE"
timeout 240 interpreter exec --skip-git-repo-check "$PROMPT" > "$BK/prova.txt" 2>&1
RC=$?
echo "  exit: $RC"
if [ "$RC" -eq 0 ] && grep -qE "^[[:space:]]*$TOKEN[[:space:]]*$" "$BK/prova.txt"; then
  echo "  >>> FUNZIONA (risposta $TOKEN dal cervello)"
  echo "VERDETTO: SECONDHAND PRONTO"
else
  echo "  non funziona ancora — ultime righe:"
  tail -6 "$BK/prova.txt" | sed 's/^/    /'
  echo "VERDETTO: ANCORA NON PRONTO"
fi
echo
echo "### 3. PER CHI VOLLE LA CONFIG PULITA (niente patch)"
echo "  profili di 0.4.3: ls -R $HOME/.config/open-interpreter"
ls -R "$HOME/.config/open-interpreter" 2>/dev/null | head -20
echo "FINE"
exit 0
