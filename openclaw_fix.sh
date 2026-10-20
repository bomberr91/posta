#!/usr/bin/env bash
# openclaw_fix.sh — fa partire OpenClaw sul TUO PC, senza indovinare.
#
# Perché serve un file a parte: OpenClaw (dalla v2026.9.3) vuole Node >= 24.16, ma su WSL1
# i Node 23/24 non partono proprio ("Exec format error", bug nodejs/node#63735). Quindi non è
# questione di reinstallare: va scelto un ALTRO runtime. Questo script prova le strade in ordine
# di costo e si ferma alla prima che funziona:
#
#   1. OpenClaw già installato      → non tocca niente, esce subito (0,1 s)
#   2. Node 24+ che gira davvero    → installazione normale (`install.sh`)
#   3. Bun (runtime alternativo)    → `install.sh --runtime bun` — resta dentro WSL1, niente Node 24
#   4. Windows nativo               → `powershell.exe … install.ps1` (OpenClaw supporta Windows)
#
# Uso:
#   ./openclaw_fix.sh            prova a installarlo (o a ripararlo)
#   ./openclaw_fix.sh --prova    NON installa niente: stampa solo cosa farebbe (diagnosi)
#   ./openclaw_fix.sh -f         ignora il timbro dei 7 giorni e riprova lo stesso
#
# Codici d'uscita: 0 = openclaw c'è e risponde · 1 = non ci sono riuscito · 2 = già tentato da poco
# 3 = serve la tua mano (Windows nativo / admin)
set -u
PROVA=0; FORZA=0
for a in "$@"; do case "$a" in --prova|-n) PROVA=1;; -f|--forza) FORZA=1;; -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0;; esac; done

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1

BLU="\033[36m"; VER="\033[32m"; ROS="\033[31m"; GIA="\033[33m"; OFF="\033[0m"
d(){ printf "  ${BLU}▸${OFF} %s\n" "$*"; }
ok(){ printf "  ${VER}✓${OFF} %s\n" "$*"; }
ko(){ printf "  ${ROS}✗${OFF} %s\n" "$*"; }
at(){ printf "  ${GIA}!${OFF} %s\n" "$*"; }

STAMP_DIR="$HOME/.stato_aggiorna"
STAMP="$STAMP_DIR/openclaw_provato"
GIORNI=7

# ── helper (gli stessi di aggiorna_tutto.sh: il PATH non interattivo non vede tutto)
c_e(){  command -v "$1" >/dev/null 2>&1 && return 0
        local c; for c in "$HOME/.nvm/versions/node/"*/bin/"$1" "$HOME/.local/bin/$1" \
          "$HOME/.bun/bin/$1" "$HOME/.opencode/bin/$1" "$HOME/bin/$1"; do [ -x "$c" ] && return 0; done; return 1; }
apri_path(){ case ":$PATH:" in *":$1:"*) ;; *) [ -d "$1" ] && export PATH="$1:$PATH";; esac; }
apri_path "$HOME/.bun/bin"; apri_path "$HOME/.local/bin"
for b in "$HOME"/.nvm/versions/node/*/bin; do [ -d "$b" ] && apri_path "$b"; done

echo "══════════════════════════════════════════════════════════"
echo " 🦾 OPENCLAW — messa in funzione ($(date '+%d/%m %H:%M'))"
echo "══════════════════════════════════════════════════════════"
[ "$PROVA" = 1 ] && at "MODALITÀ PROVA: guardo soltanto, non installo niente"

# ── 1 · ce l'hai già?
if c_e openclaw; then
  V=$(openclaw --version 2>&1 | head -1)
  ok "OpenClaw già installato: $V"
  if openclaw --help >/dev/null 2>&1; then ok "e risponde ai comandi: niente da fare."; exit 0
  else at "ma non risponde bene: provo a rimetterlo a posto."; fi
fi

# ── 2 · che sistema è? (WSL1 vs WSL2 vs Windows vs Linux vero)
WSL1=0; WSL=0; WINNATIVO=0
if grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease /proc/version 2>/dev/null; then
  WSL=1
  case "$(grep -i microsoft /proc/sys/kernel/osrelease 2>/dev/null)" in *WSL2*|*wsl2*) WSL1=0;; *) WSL1=1;; esac
  grep -qi 'microsoft-standard' /proc/version 2>/dev/null && WSL1=0
fi
c_e powershell.exe || [ -x /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe ] && WINNATIVO=1
[ "$WSL" = 1 ] && { [ "$WSL1" = 1 ] && d "Sistema: WSL1 (niente systemd, e i Node 23+ non partono)" || d "Sistema: WSL2"; }
[ "$WINNATIVO" = 1 ] && d "Windows raggiungibile da qui: posso installare la versione nativa"

# ── 3 · Node 24+ che gira DAVVERO? (non basta che la cartella esista)
NODE_OK=""
for cand in "$HOME"/.nvm/versions/node/v2[4-9]*/bin "$HOME"/.nvm/versions/node/v3*/bin; do
  [ -x "$cand/node" ] || continue
  VV=$("$cand/node" -v 2>/dev/null) || continue
  MA=${VV#v}; MA=${MA%%.*}; MI=$(echo "${VV#v}" | cut -d. -f2)
  if [ -n "$MA" ] && { [ "$MA" -gt 24 ] || { [ "$MA" -eq 24 ] && [ "$MI" -ge 16 ]; }; }; then NODE_OK="$cand"; break; fi
done
if [ -n "$NODE_OK" ]; then ok "Node adatto: $("$NODE_OK/node" -v) ($NODE_OK)"
else
  CAND=$(ls -d "$HOME"/.nvm/versions/node/v2[4-9]* 2>/dev/null | sort -V | tail -1)
  if [ -n "$CAND" ]; then
    [ "$WSL1" = 1 ] && at "Node ${CAND##*/} è scaricato ma NON esegue su WSL1 → lo salto (bug node#63735, non è colpa tua)" \
                    || at "Node ${CAND##*/} è scaricato ma NON esegue → lo salto"
  else
    d "Nessun Node 24 installato."
  fi
fi

# ── 4 · timbro: non riprovo la stessa strada ogni volta
if [ "$PROVA" = 0 ] && [ "$FORZA" = 0 ] && [ -f "$STAMP" ]; then
  ULT=$(date -r "$STAMP" +%s 2>/dev/null || echo 0)
  ETA=$(( (ULT + GIORNI*86400 - $(date +%s) + 86399) / 86400 ))
  if [ "$ULT" -gt 0 ] && [ $(( $(date +%s) - ULT )) -lt $(( GIORNI*86400 )) ]; then
    at "Già provato il $(date -r "$STAMP" '+%d/%m %H:%M'). Riprovo tra ~$ETA giorni (oppure: ./openclaw_fix.sh -f)"
    exit 2
  fi
fi

# ── 5 · le tre strade, in ordine di costo
PROVATE=""
prova_install_classico(){
  PROVATE="$PROVATE install.sh"
  if [ "$PROVA" = 1 ]; then d "[prova] curl -fsSL https://openclaw.ai/install.sh | bash"; return 1; fi
  d "Provo l'installazione normale (Node $("$NODE_OK/node" -v 2>/dev/null || echo 24)+)…"
  curl -fsSL https://openclaw.ai/install.sh 2>/dev/null | bash 2>&1 | tail -6
  c_e openclaw
}
prova_bun(){
  PROVATE="$PROVATE bun"
  if [ "$PROVA" = 1 ]; then d "[prova] install.sh --runtime bun (resta dentro WSL1, non serve Node 24)"; return 1; fi
  at "Node 24 qui non può girare → uso Bun, che non ha bisogno di Node."
  if ! c_e bun; then
    d "Installo Bun (~/.bun)…"
    curl -fsSL https://bun.sh/install 2>/dev/null | bash 2>&1 | tail -4
    apri_path "$HOME/.bun/bin"; export BUN_INSTALL="$HOME/.bun"
    c_e bun || { ko "Bun non si è installato (probabile rete/curl)"; return 1; }
  fi
  ok "Bun: $(bun --version 2>/dev/null)"
  d "Installo OpenClaw col runtime Bun…"
  curl -fsSL https://openclaw.ai/install.sh 2>/dev/null | bash -s -- --runtime bun 2>&1 | tail -6
  c_e openclaw
}
prova_windows(){
  PROVATE="$PROVATE windows"
  if [ "$PROVA" = 1 ]; then d "[prova] powershell.exe -Command \"iwr -useb https://openclaw.ai/install.ps1 | iex\""; return 1; fi
  PS=$(command -v powershell.exe 2>/dev/null || echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe)
  [ -x "$PS" ] || [ -f "$PS" ] || return 1
  at "Provo la versione NATIVA di Windows (OpenClaw la supporta ufficialmente)."
  "$PS" -NoProfile -ExecutionPolicy Bypass -Command \
    "iwr -useb https://openclaw.ai/install.ps1 | iex" 2>&1 | tail -8
  # dopo l'installazione nativa il comando sta nel Windows, non qui: lo cerco lo stesso
  for w in "/mnt/c/Users/$USER/AppData/Local/Programs/openclaw/openclaw.exe" \
           "/mnt/c/Users/$USER/.local/bin/openclaw.exe" "/mnt/c/Users/$USER/AppData/Roaming/npm/openclaw.cmd"; do
    [ -f "$w" ] && { ok "Installato lato Windows: $w"; return 0; }
  done
  return 1
}

FATTO=0
if [ -n "$NODE_OK" ] && prova_install_classico; then FATTO=1
elif prova_bun; then FATTO=1
elif prova_windows; then FATTO=1
fi

# ── 6 · verdetto e timbro
echo "──────────────────────────────────────────────────────────"
if [ "$FATTO" = 1 ] || c_e openclaw; then
  apri_path "$HOME/.bun/bin"; hash -r 2>/dev/null
  ok "OPENCLAW C'È: $(openclaw --version 2>&1 | head -1)"
  ok "Aprilo con:  openclaw        (oppure: openclaw gateway)"
  mkdir -p "$STAMP_DIR"; date '+%F %H:%M' > "$STAMP"
  echo "══════════════════════════════════════════════════════════"; exit 0
fi

if [ "$PROVA" = 1 ]; then
  echo " (prova: nessuna installazione eseguita)"
  echo "══════════════════════════════════════════════════════════"; exit 0
fi

mkdir -p "$STAMP_DIR"; date '+%F %H:%M' > "$STAMP"
ko "Da qui non ci sono riuscito (strade provate:$PROVATE)."
if [ "$WSL1" = 1 ]; then
  echo
  echo " COSA FARE A MANO (5 minuti, si fa una volta sola):"
  echo "  1. Apri PowerShell come Amministratore su Windows (non dentro WSL)."
  echo "  2. Incolla questa riga e premi Invio:"
  echo "       iwr -useb https://openclaw.ai/install.ps1 | iex"
  echo "  3. Quando chiede, accetta il percorso proposto. Alla fine scrivi:  openclaw --version"
  echo "  4. Se vuoi che il ponte lo veda anche da qui, dimmelo e aggiungo il collegamento."
  echo
  echo " Perché non basta 'installare Node 24': su WSL1 i Node 23/24 non partono affatto"
  echo " (Exec format error, nodejs/node#63735). OpenClaw dalla v2026.9.3 li pretende."
else
  echo " Controlla la connessione (curl) e riprova con: ./openclaw_fix.sh -f"
fi
echo "══════════════════════════════════════════════════════════"
exit 3
