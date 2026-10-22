#!/usr/bin/env bash
# openclaw_fix.sh — fa partire OpenClaw sul TUO PC, senza indovinare.
#
# PERCHÉ NON SI RISOLVE "INSTALLANDO NODE 24":
#   OpenClaw (dalla v2026.9.3) vuole Node >= 24.16, ma su WSL1 i Node 23/24 non partono
#   proprio ("cannot execute binary file: Exec format error", bug nodejs/node#63735:
#   hanno un segmento a 2 MB che WSL1 rifiuta). Il v22 funziona, ma OpenClaw non lo accetta.
#   Quindi le strade buone sono DUE: Windows nativo (consigliata) oppure Bun dentro Ubuntu.
#
# Ordine di questo script (si ferma alla prima che riesce):
#   1. OpenClaw già presente (Ubuntu / Bun / Windows)  → non tocca niente
#   2. Windows nativo: PowerShell installa anche il Node che gli serve
#   3. Bun dentro WSL1: runtime alternativo, Node non serve
#   4. niente funziona → ti dice esattamente cosa fare a mano (INSTALLA_OPENCLAW.bat)
#
# Uso:
#   ./openclaw_fix.sh            prova a installarlo (o a ripararlo)
#   ./openclaw_fix.sh --prova    NON installa niente: dice solo cosa farebbe
#   ./openclaw_fix.sh -f         ignora il timbro dei 7 giorni
#
# Codici d'uscita: 0 = c'è e risponde · 1 = non ci sono riuscito · 2 = già tentato da poco
# 3 = serve la tua mano (doppio clic sul .bat su Windows)
set -u
QUI=$(cd "$(dirname "$0")" && pwd)
PROVA=0; FORZA=0
for a in "$@"; do case "$a" in --prova|-n) PROVA=1;; -f|--forza) FORZA=1;; -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0;; esac; done

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
BLU="\033[36m"; VER="\033[32m"; ROS="\033[31m"; GIA="\033[33m"; OFF="\033[0m"
d(){ printf "  ${BLU}▸${OFF} %s\n" "$*"; }
ok(){ printf "  ${VER}✓${OFF} %s\n" "$*"; }
ko(){ printf "  ${ROS}✗${OFF} %s\n" "$*"; }
at(){ printf "  ${GIA}!${OFF} %s\n" "$*"; }
c_e(){ command -v "$1" >/dev/null 2>&1 && return 0
       local c; for c in "$HOME/.bun/bin/$1" "$HOME/.local/bin/$1" "$HOME/bin/$1" \
         "$HOME/.nvm/versions/node/"*/bin/"$1"; do [ -x "$c" ] && return 0; done; return 1; }
apri_path(){ case ":$PATH:" in *":$1:"*) ;; *) [ -d "$1" ] && export PATH="$1:$PATH";; esac; }
apri_path "$HOME/.bun/bin"; apri_path "$HOME/.local/bin"

STAMP_DIR="$HOME/.stato_aggiorna"; STAMP="$STAMP_DIR/openclaw_provato"; GIORNI=7
stato_oc(){ local v; v=$(bash "$QUI/apri_openclaw.sh" --stato 2>/dev/null); echo "${v:-no}"; }

echo "══════════════════════════════════════════════════════════"
echo " 🦾 OPENCLAW — messa in funzione ($(date '+%d/%m %H:%M'))"
echo "══════════════════════════════════════════════════════════"
[ "$PROVA" = 1 ] && at "MODALITÀ PROVA: guardo soltanto, non installo niente"

# ── 1 · ce l'hai già? (Ubuntu, Bun o Windows)
TIPO=$(stato_oc)
if [ "$TIPO" != "no" ]; then
  case "$TIPO" in
    wsl)         ok "OpenClaw già installato in Ubuntu: $(openclaw --version 2>&1 | head -1)" ;;
    bun)         ok "OpenClaw già installato con Bun: $("$HOME/.bun/bin/openclaw" --version 2>&1 | head -1)" ;;
    windows-exe) ok "OpenClaw è già installato su Windows: $(bash "$QUI/apri_openclaw.sh" --trova 2>/dev/null)" ;;
    windows-app) ok "C'è l'app grafica di OpenClaw: $(bash "$QUI/apri_openclaw.sh" --trova 2>/dev/null)" ;;
  esac
  ok "Niente da fare. Aprilo con:  ./apri_openclaw.sh   (oppure [1]→[e] nella Centrale)"
  exit 0
fi

# ── 2 · che sistema è?
WSL1=0; WSL=0; WIN=0
if grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease /proc/version 2>/dev/null; then
  WSL=1
  grep -qi 'microsoft-standard' /proc/version 2>/dev/null && WSL1=0 || WSL1=1
  grep -qi 'wsl2' /proc/sys/kernel/osrelease 2>/dev/null && WSL1=0
fi
command -v powershell.exe >/dev/null 2>&1 && WIN=1
[ "$WSL" = 1 ] && { [ "$WSL1" = 1 ] && d "Sistema: WSL1 (niente systemd; e i Node 23/24 non partono)" || d "Sistema: WSL2"; }
[ "$WIN" = 1 ] && d "Windows raggiungibile da qui: posso installare la versione nativa"

# Node 24+ che gira DAVVERO (non basta che la cartella esista)
NODE_OK=""
for cand in "$HOME"/.nvm/versions/node/v2[4-9]*/bin "$HOME"/.nvm/versions/node/v3*/bin; do
  [ -x "$cand/node" ] || continue
  VV=$("$cand/node" -v 2>/dev/null) || continue
  MA=${VV#v}; MA=${MA%%.*}; MI=$(echo "${VV#v}" | cut -d. -f2)
  if [ -n "$MA" ] && { [ "$MA" -gt 24 ] || { [ "$MA" -eq 24 ] && [ "$MI" -ge 16 ]; }; }; then NODE_OK="$cand"; break; fi
done
if [ -n "$NODE_OK" ]; then ok "Node adatto: $("$NODE_OK/node" -v) ($NODE_OK)"
elif ls -d "$HOME"/.nvm/versions/node/v2[4-9]* >/dev/null 2>&1; then
  at "Il Node 24 che hai scaricato NON esegue su WSL1 → lo salto (bug node#63735, non è colpa tua)"
else d "Nessun Node 24 in Ubuntu (e comunque qui non servirebbe)."
fi

# timbro: non riprovo la stessa strada ogni volta
if [ "$PROVA" = 0 ] && [ "$FORZA" = 0 ] && [ -f "$STAMP" ]; then
  ULT=$(date -r "$STAMP" +%s 2>/dev/null || echo 0)
  if [ "$ULT" -gt 0 ] && [ $(( $(date +%s) - ULT )) -lt $(( GIORNI*86400 )) ]; then
    ETA=$(( (ULT + GIORNI*86400 - $(date +%s) + 86399) / 86400 ))
    at "Già provato il $(date -r "$STAMP" '+%d/%m %H:%M'). Riprovo tra ~$ETA giorni (oppure: ./openclaw_fix.sh -f)"
    exit 2
  fi
fi

PROVATE=""
# ── 3 · WINDOWS NATIVO (la strada consigliata: installer ufficiale, mette anche il Node)
prova_windows(){
  PROVATE="$PROVATE windows"
  if [ "$PROVA" = 1 ]; then d "[prova] powershell.exe: iwr -useb https://openclaw.ai/install.ps1 | iex  (con -NoOnboard)"; return 1; fi
  [ "$WIN" = 1 ] || return 1
  d "Installo OpenClaw SU WINDOWS (l'installer si porta dietro il Node che serve)…"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
    "& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -NoOnboard" 2>&1 | tail -8
  [ "$(stato_oc)" != "no" ]
}
# ── 4 · BUN dentro WSL1 (runtime alternativo: Node non serve)
prova_bun(){
  PROVATE="$PROVATE bun"
  if [ "$PROVA" = 1 ]; then d "[prova] curl -fsSL https://bun.sh/install | bash  →  bun add -g --trust openclaw@latest"; return 1; fi
  at "Uso Bun, che non ha bisogno di Node."
  if ! c_e bun; then
    d "Installo Bun (~/.bun)…"
    curl -fsSL https://bun.sh/install 2>/dev/null | bash 2>&1 | tail -4
    apri_path "$HOME/.bun/bin"; export BUN_INSTALL="$HOME/.bun"
    c_e bun || { ko "Bun non si è installato (rete/curl)"; return 1; }
  fi
  ok "Bun: $(bun --version 2>/dev/null)"
  d "Installo OpenClaw con Bun…"
  bun add -g --trust openclaw@latest 2>&1 | tail -5
  c_e openclaw
}

FATTO=0
if prova_windows; then FATTO=1
elif prova_bun; then FATTO=1
fi

# ── 5 · verdetto e timbro
echo "──────────────────────────────────────────────────────────"
TIPO=$(stato_oc)
if [ "$TIPO" != "no" ]; then
  mkdir -p "$STAMP_DIR"; date '+%F %H:%M' > "$STAMP"
  ok "OPENCLAW C'È: $(bash "$QUI/apri_openclaw.sh" --trova 2>/dev/null)"
  ok "Aprilo con:  ./apri_openclaw.sh     (oppure [1]→[e] nella Centrale)"
  echo "══════════════════════════════════════════════════════════"; exit 0
fi
if [ "$PROVA" = 1 ]; then
  echo " (prova: nessuna installazione eseguita)"
  echo "══════════════════════════════════════════════════════════"; exit 0
fi

mkdir -p "$STAMP_DIR"; date '+%F %H:%M' > "$STAMP"
ko "Da qui non ci sono riuscito (strade provate:$PROVATE)."
echo
echo " LA STRADA SICURA, 3 MINUTI E UNA VOLTA SOLA:"
echo "   1. In Windows apri la cartella del ponte:  \\\\wsl.localhost\\Ubuntu\\home\\agenti\\posta"
echo "      (oppure dalla Centrale: [6] apre la cartella)"
echo "   2. Doppio clic su:  INSTALLA_OPENCLAW.bat"
echo "   3. Scegli [1] TUTTO AUTOMATICO e lascia lavorare: installa su Windows,"
echo "      Node compreso. Lui ti dice alla fine se è andata."
echo "   4. Torna qui e scrivi:  ./apri_openclaw.sh"
echo
echo " Perché così: OpenClaw dalla v2026.9.3 vuole Node >=24.16, e quei Node su WSL1"
echo " non partono affatto (Exec format error, nodejs/node#63735). Su Windows girano."
echo "══════════════════════════════════════════════════════════"
exit 3
