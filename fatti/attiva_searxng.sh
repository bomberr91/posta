#!/usr/bin/env bash
# attiva_searxng.sh — esecuzione deterministica della riserva di ricerca (postino/PC).
set -u
R="$HOME/posta/fatti/searxng_attivazione.md"
log() { echo "$1" | tee -a "$R"; }
mkdir -p "$(dirname "$R")"
: > "$R"
log "# Attivazione SearXNG — $(date -Is)"
# Fallback nativo (verificato nel sandbox l'11/11): se Docker manca, avviare
# searxng con venv + `python -m searx.webapp` e SEARXNG_SETTINGS_PATH con
# formats: [html, json] e port: 8080. Vedi fatti/searxng_attivazione.md § SEGUITO.
if ! command -v docker >/dev/null 2>&1; then
  log "Docker assente: usare la via nativa documentata in fatti/searxng_attivazione.md"; exit 1;
fi
if ! docker ps --format '{{.Names}}' | grep -qx searxng; then
  docker run -d --name searxng -p 8080:8080 searxng/searxng:latest >>"$R" 2>&1 || { log "ERRORE avvio container:"; tail -5 "$R"; exit 1; }
fi
sleep 5
OUT="$(curl -sS --max-time 10 'http://127.0.0.1:8080/search?q=test&format=json' 2>&1)"
RC=$?
if [ "$RC" -ne 0 ] || ! printf '%s' "$OUT" | grep -q '"results"'; then
  log "COLLAUDO NON RIUSCITO (curl rc=$RC)"; printf '%s
' "$OUT" | head -5 >>"$R"; exit 1; fi
log "COLLAUDO OK: JSON con risultati"
log "PROSSIMO (manuale, NON fatto dallo script): agganciare la riserva a cerca.sh / Deep Dog con switch solo in freno di Tavily. TITOLARE INTATTO."
log "FINE"
