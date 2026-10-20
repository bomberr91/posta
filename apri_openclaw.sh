#!/usr/bin/env bash
# apri_openclaw.sh — apre OpenClaw nel modo che FUNZIONA su questo PC.
#
# Ordine: 1) OpenClaw installato in WSL (o con Bun)  2) versione installata su Windows
#         3) app grafica OpenClaw Companion           4) niente → ti dice cosa fare
#
#   ./apri_openclaw.sh            apre OpenClaw
#   ./apri_openclaw.sh --trova    dice dov'è (senza aprirlo)
#   ./apri_openclaw.sh --stato    solo una parola: wsl | bun | windows-exe | windows-app | no
set -u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
WINROOT="${WINROOT:-/mnt/c}"     # sovrascrivibile per i collaudi
export PATH="$HOME/.bun/bin:$HOME/.local/bin:$HOME/bin:$PATH"
for b in "$HOME"/.nvm/versions/node/*/bin; do [ -d "$b" ] && case ":$PATH:" in *":$b:"*) ;; *) PATH="$b:$PATH";; esac; done
export PATH

# ── dove sta OpenClaw? (stampa "tipo|percorso")
trova(){
  local c
  for c in "$(command -v openclaw 2>/dev/null)" "$HOME/.bun/bin/openclaw" "$HOME/.local/bin/openclaw" "$HOME/bin/openclaw"; do
    [ -n "$c" ] && [ -f "$c" ] && { case "$c" in */.bun/*) echo "bun|$c" ;; *) echo "wsl|$c" ;; esac; return 0; }
  done
  for c in "$HOME"/.nvm/versions/node/*/bin/openclaw; do
    [ -f "$c" ] && { echo "wsl|$c"; return 0; }
  done
  # interop: la versione Windows compare nel PATH di WSL come openclaw.exe
  for c in "$(command -v openclaw.exe 2>/dev/null)" "$(command -v openclaw.cmd 2>/dev/null)"; do
    [ -n "$c" ] && { echo "windows-exe|$c"; return 0; }
  done
  for c in "$WINROOT"/Users/*/AppData/Roaming/npm/openclaw.cmd "$WINROOT"/Users/*/AppData/Local/Programs/openclaw*/openclaw.exe; do
    [ -f "$c" ] && { echo "windows-exe|$c"; return 0; }
  done
  # app grafica (Windows Hub / Companion)
  for c in "$WINROOT"/Users/*/AppData/Local/Programs/*OpenClaw*/*.exe "$WINROOT"/Program\ Files/*OpenClaw*/*.exe; do
    [ -f "$c" ] && { echo "windows-app|$c"; return 0; }
  done
  echo "no|"
  return 1
}

T=$(trova); TIPO=${T%%|*}; DOVE=${T#*|}

case "${1:-}" in
  --stato) echo "$TIPO"; [ "$TIPO" = "no" ] && exit 1 || exit 0 ;;
  --trova)
    case "$TIPO" in
      wsl)         echo "OpenClaw (dentro Ubuntu): $DOVE" ;;
      bun)         echo "OpenClaw (runtime Bun, dentro Ubuntu): $DOVE" ;;
      windows-exe) echo "OpenClaw (installato su Windows): $DOVE" ;;
      windows-app) echo "App grafica OpenClaw: $DOVE" ;;
      *)           echo "OpenClaw non è ancora installato. Doppio clic su INSTALLA_OPENCLAW.bat (una volta sola)." ;;
    esac
    [ "$TIPO" = "no" ] && exit 1 || exit 0 ;;
esac

case "$TIPO" in
  wsl|bun)
    cd "$HOME/posta" 2>/dev/null || true
    exec "$DOVE" "$@"
    ;;
  windows-exe)
    echo "▸ Apro OpenClaw installato su Windows… (se non parte niente, guarda la finestra di Windows)"
    case "$DOVE" in
      *.cmd|*.bat)
        cmd.exe /c "$(wslpath -w "$DOVE" 2>/dev/null || echo "$DOVE")" ;;
      *)
        cd "$HOME" 2>/dev/null || true
        "$DOVE" & ;;
    esac
    ;;
  windows-app)
    echo "▸ Apro l'app grafica di OpenClaw…"
    "$DOVE" >/dev/null 2>&1 &
    ;;
  *)
    echo "OpenClaw non c'è ancora su questo PC."
    echo ""
    echo "  Fai partire, UNA VOLTA SOLA, il file:   INSTALLA_OPENCLAW.bat"
    echo "  (sta in questa cartella ~/posta: doppio clic da Esplora Risorse, oppure)"
    echo "     cmd.exe /c start \"\" \"\\wsl.localhost\\Ubuntu$(wslpath -m "$HOME" 2>/dev/null)/posta/INSTALLA_OPENCLAW.bat\""
    echo ""
    echo "  Perché su Windows: OpenClaw vuole Node ≥24.16 e su WSL1 i Node 23/24 non partono."
    exit 1
    ;;
esac
