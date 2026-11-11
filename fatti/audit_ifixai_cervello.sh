#!/usr/bin/env bash
# audit_ifixai_cervello.sh — audit iFixAi del cervello :20129 (postino/PC).
set -u
R="$HOME/posta/fatti/ifixai_audit_cervello.md"
log() {{ echo "$1" | tee -a "$R"; }}
mkdir -p "$(dirname "$R")"
: > "$R"
log "# Audit iFixAi del cervello — $(date -Is)"
if ! curl -sS --max-time 5 http://127.0.0.1:20129/v1/models >/dev/null 2>&1; then
  log "ERRORE: cervello :20129 non raggiungibile"; exit 1; fi
command -v ifixai >/dev/null 2>&1 || {{ log "ERRORE: ifixai non installato (pip install ifixai)"; exit 1; }}
ifixai author reference -o /tmp/reference.yaml >>"$R" 2>&1 || {{ log "ERRORE author"; exit 1; }}
ifixai validate /tmp/reference.yaml >>"$R" 2>&1 || {{ log "ERRORE validate"; exit 1; }}
# Provider OpenAI-compatible: credenziali lette dall'ambiente, MAI scritte qui.
: "${{OPENAI_BASE_URL:=http://127.0.0.1:20129/v1}}"; export OPENAI_BASE_URL
ifixai run --provider openai --eval-mode self --fixture /tmp/reference.yaml >>"$R" 2>&1
RC=$?
log "ESITO run: rc=$RC (vedi output sopra). TITOLARE INTATTO."
exit "$RC"
