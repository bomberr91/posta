#!/usr/bin/env bash
# secondhand_ripara.sh — 4/11: Secondhand (CLI WSL) aggiornato a 0.4.3 ma il
# collaudo sul cervello e' fallito: il riporto automatico a 0.0.56 non e' andato
# (0.0.56 richiede Python <3.12, il PC ha 3.12.3 => pip lo scarta).
#
# Questo script prova, in ordine, le POCHE cose sensate e si ferma alla prima
# che risponde OK sul cervello:
#   1) capire la nuova CLI e dove vuole la config (grep nel pacchetto installato)
#   2) matrici: config (vecchia / nuova / con api_key) x comando (exec, -y, ...)
#   3) se niente funziona: RIPORTO a 0.0.56 con --ignore-requires-python
#      (il flag serve perche' 0.0.56 vuole Python <3.12) + config di prima
#
# Esito onesto: collaudo reale (una chiamata vera al cervello, non un exit 0).
#
# Niente pipe verso tail (un pipe che non chiude tiene appeso il postino).
set -uo pipefail

REPO="$HOME/posta"
[ -d "$REPO" ] || REPO="$HOME/posta_ponte"
cd "$REPO" || { echo "repo non trovato"; exit 1; }

WSL_CFG="$HOME/.config/interpreter/config.toml"
STAMP=$(date +%Y%m%d-%H%M%S)
BK="/tmp/sh_ripara_$STAMP"
mkdir -p "$BK"
[ -f "$WSL_CFG" ] && cp "$WSL_CFG" "$BK/config.toml" && echo "backup config: $BK/config.toml"
echo

echo "### 1. DOVE SEI ADESSO"
echo "  interprete: $(command -v interpreter)"
echo "  versione: $(interpreter --version 2>&1 | head -1)"
echo "  python: $(python3 --version 2>&1)"
echo "--- aiuto della CLI (prime 40 righe):"
timeout 60 interpreter --help > "$BK/help.txt" 2>&1
head -40 "$BK/help.txt"
echo "--- dove cerca la config (grep nel pacchetto):"
PKG=$(python3 - << 'PY' 2>/dev/null
import importlib, os
for nome in ("interpreter", "open_interpreter", "interpreter.core"):
    try:
        m = importlib.import_module(nome)
        print(os.path.dirname(m.__file__))
        break
    except Exception:
        continue
PY
)
echo "  pacchetto: ${PKG:-non trovato}"
if [ -n "${PKG:-}" ]; then
  grep -rn --include=*.py -E "config\.toml|config_path|CONFIG_PATH|config_dir" "$PKG" 2>/dev/null | head -12
  echo "--- chiavi attese per provider/base_url:"
  grep -rn --include=*.py -E "\"env_key\"|'env_key'|\"base_url\"|'base_url'|\"api_key\"|'api_key'" "$PKG" 2>/dev/null | head -12
fi
echo

echo "### 2. ERRORE ESATTO DEL COLLAUDO (versione nuova)"
timeout 240 interpreter exec --skip-git-repo-check "Rispondi esattamente con la parola OK e nient'altro." > "$BK/errore.txt" 2>&1
echo "  exit: $?"
head -30 "$BK/errore.txt"
echo

echo "### 3. MATRICE: cerco una combinazione che risponda OK"
try_config() {
  # $1 = nome variante
  echo "--- config: $1"
  timeout 200 interpreter exec --skip-git-repo-check "Rispondi esattamente con la parola OK e nient'altro." > "$BK/prova.txt" 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ] && grep -qi "^OK" "$BK/prova.txt"; then
    echo "    >>> FUNZIONA (exit 0, risposta OK)"
    return 0
  fi
  echo "    non funziona (exit $rc)"
  head -6 "$BK/prova.txt" | sed 's/^/      /'
  return 1
}

# V1: config nuova con api_key esplicita
cat > "$WSL_CFG" << 'EOF'
model_provider = "openai"
model = "auto"
api_key = "sk-cervello"
base_url = "http://127.0.0.1:20129/v1"
EOF
if try_config "api_key in alto"; then OK=1; fi

# V2: config con blocco provider esplicito
if [ "${OK:-0}" != "1" ]; then
cat > "$WSL_CFG" << 'EOF'
model_provider = "openai"
model = "auto"
base_url = "http://127.0.0.1:20129/v1"
api_key = "sk-cervello"

[model_providers.openai]
name = "Cervello"
base_url = "http://127.0.0.1:20129/v1"
api_key = "sk-cervello"
wire_api = "chat"
EOF
if try_config "blocco [model_providers.openai]"; then OK=1; fi
fi

# V3: solo env (config minimale)
if [ "${OK:-0}" != "1" ]; then
cat > "$WSL_CFG" << 'EOF'
model_provider = "openai"
model = "auto"
EOF
export OPENAI_API_KEY=sk-cervello
export OPENAI_BASE_URL=http://127.0.0.1:20129/v1
if try_config "solo env (OPENAI_API_KEY/OPENAI_BASE_URL)"; then OK=1; fi
fi

echo
if [ "${OK:-0}" = "1" ]; then
  echo "### 4. RISULTATO: LA VERSIONE NUOVA (0.4.3) PARLA COL CERVELLO"
  echo "  config lasciata in: $WSL_CFG"
  echo "  versione: $(interpreter --version 2>&1 | head -1)"
  echo "FINE"
  exit 0
fi

echo "### 4. NESSUNA COMBINAZIONE FUNZIONA: RIPORTO A 0.0.56 (--ignore-requires-python)"
timeout 900 python3 -m pip install --user --break-system-packages --ignore-requires-python "open-interpreter==0.0.56" > "$BK/revert.log" 2>&1
echo "  exit pip: $?"
tail -6 "$BK/revert.log"
echo "  versione: $(interpreter --version 2>&1 | head -1)"
cp "$BK/config.toml" "$WSL_CFG" 2>/dev/null && echo "  config di prima ripristinata"
timeout 240 interpreter exec --skip-git-repo-check "Rispondi esattamente con la parola OK e nient'altro." > "$BK/collaudo.txt" 2>&1
RC=$?
echo "  collaudo finale — exit: $RC"
grep -E "^(OK|provider:|model:)" "$BK/collaudo.txt" | head -4
if [ "$RC" -eq 0 ] && grep -qi "^OK" "$BK/collaudo.txt"; then
  echo "  VERDETTO: RIPRISTINATO ALLA 0.0.56, COLLAUDATO (OK sul cervello)"
else
  echo "  VERDETTO: ANCORA NON FUNZIONA (exit $RC) — vedi $BK/collaudo.txt"
fi
echo "FINE"
exit 0
