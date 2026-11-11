#!/usr/bin/env bash
# searxng_persistente.sh — rende PERSISTENTE la riserva di ricerca (postino/PC).
# Deterministico: scrive SEMPRE un referto; esce 0 solo se il collaudo passa.
set -u
REPO="${POSTA_DIR:-$HOME/posta}"
R="$REPO/fatti/searxng_persistente.md"
log(){ echo "$1" | tee -a "$R"; }
mkdir -p "$(dirname "$R")"; : > "$R"
log "# SearXNG persistente — $(date -Is) — repo=$REPO"
URL='http://127.0.0.1:8080/search?q=test&format=json'
controlla(){
  python3 - <<'PY' 2>/dev/null
import json,urllib.request
u='http://127.0.0.1:8080/search?q=test&format=json'
try:
    with urllib.request.urlopen(u,timeout=8) as f: d=json.load(f)
    print('OK',len(d.get('results') or []))
except Exception as e: print('NO',type(e).__name__)
PY
}
GIA="$(controlla)"
if [ "${GIA%% *}" = "OK" ]; then log "GIÀ ATTIVO: JSON valido, ${GIA#* } results"; log "FINE rc=0"; exit 0; fi
log "non attivo: avvio l'istanza"
SRC="$HOME/.local/share/searxng-src"; VENV="$HOME/.local/share/searxng-venv"; SET="$HOME/.local/share/searxng_settings.yml"
if command -v docker >/dev/null 2>&1; then
  log "via Docker"
  mkdir -p "$HOME/.local/share"
  cp "$REPO/fatti/searxng_settings.yml" "$SET" 2>/dev/null || true
  docker rm -f searxng >/dev/null 2>&1 || true
  docker run -d --restart unless-stopped --name searxng -p 8080:8080 -v "$SET:/etc/searxng/settings.yml" searxng/searxng:latest >>"$R" 2>&1 || { log "ERRORE docker run rc=$?"; exit 1; }
else
  log "Docker assente: via nativa (collaudata l'11/11 nel sandbox)"
  mkdir -p "$HOME/.local/share"
  [ -d "$SRC/.git" ] || git clone -q --depth 1 https://github.com/searxng/searxng.git "$SRC" >>"$R" 2>&1 || { log "ERRORE clone"; exit 1; }
  [ -x "$VENV/bin/python" ] || { python3 -m venv "$VENV" >>"$R" 2>&1 && "$VENV/bin/pip" install -q -r "$SRC/requirements.txt" >>"$R" 2>&1; } || { log "ERRORE venv/pip"; exit 1; }
  python3 - "$SRC/searx/settings.yml" "$SET" <<'PY'
import sys,re,yaml
s=open(sys.argv[1],encoding='utf-8').read()
s=s.replace('  formats:\n    - html\n','  formats:\n    - html\n    - json\n',1).replace('  port: 8888','  port: 8080',1)
s=re.sub(r'secret_key:.*','secret_key: "riserva-persistente"',s,count=1)
open(sys.argv[2],'w',encoding='utf-8').write(s)
PY
  cd "$SRC" || { log "ERRORE cd $SRC"; exit 1; }
  SEARXNG_SETTINGS_PATH="$SET" nohup "$VENV/bin/python" -m searx.webapp > /tmp/searxng_persistente.log 2>&1 &
  echo $! > "$HOME/.local/share/searxng.pid"
  log "avviato pid $(cat "$HOME/.local/share/searxng.pid")"
fi
for i in $(seq 1 15); do sleep 2; ES="$(controlla)"; [ "${ES%% *}" = "OK" ] && break; done
log "collaudo: $ES"
if [ "${ES%% *}" != "OK" ]; then log "ERRORE: istanza non risponde (vedi /tmp/searxng_persistente.log)"; tail -8 /tmp/searxng_persistente.log >>"$R" 2>/dev/null || true; exit 1; fi
log "PERSISTENTE: JSON valido, ${ES#* } results; usata solo in freno di Tavily da lavori/cerca.sh"
log "FINE rc=0"
