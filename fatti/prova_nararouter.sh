#!/usr/bin/env bash
# prova_nararouter.sh — prova mirata di NaraRouter.
#
# Il piano free di NaraRouter comprende UN solo modello (Laguna S 2.1, prezzo
# $0): gli altri 43 costano crediti e rispondono "Insufficient credits".
# Endpoint /v1/me = stato dell'account: piano, quota residua e ora di reset.
# La chiave si legge dal portachiavi: nessuna chiave in questo file.
set -u
cd "$HOME/posta" 2>/dev/null || cd "$(dirname "$0")/.." || exit 1
K=$(python3 chiave_di.py "NaraRouter" 2>/dev/null)
if [ -z "$K" ]; then echo "NaraRouter: nessuna chiave nel portachiavi"; exit 1; fi
BASE="https://router.bynara.id/v1"
echo "NaraRouter: chiave trovata (${#K} caratteri)"

ME=$(curl -s -m 40 -A "Mozilla/5.0" -H "Authorization: Bearer $K" "$BASE/me" 2>/dev/null)
if [ -n "$ME" ]; then
  printf '%s' "$ME" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print("  /me: risposta non leggibile"); raise SystemExit
a = d.get("account", {}) or {}
q = d.get("quota", {}) or {}
u = d.get("usage", {}) or {}
c = d.get("credit", {}) or {}
print("  account:", a.get("email"), "| piano:", a.get("plan"), "| credito:", c.get("usd_equivalent"), c.get("currency"))
print("  quota:", q.get("remaining"), "/", q.get("limit"), q.get("unit", ""), "| reset:", q.get("reset_at"))
print("  richieste oggi:", u.get("requests_today"), "| success rate:", u.get("success_rate"))
'
else
  echo "  /me: nessuna risposta"
fi

for M in "laguna-s-2.1" "minimax-m3.1-flash"; do
  BODY=$(curl -s -m 40 -w "\n%{http_code}" -A "Mozilla/5.0" \
    -H "Authorization: Bearer $K" -H "Content-Type: application/json" \
    -d "{\"model\":\"$M\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with the single word OK\"}],\"max_tokens\":64}" \
    "$BASE/chat/completions" 2>/dev/null)
  CODE=$(printf '%s' "$BODY" | tail -1)
  RIS=$(printf '%s' "$BODY" | grep -oE '"content":"[^"]{0,40}' | head -1)
  ERR=$(printf '%s' "$BODY" | grep -oE '"message":"[^"]{0,90}' | head -1)
  echo "  $M -> HTTP $CODE ${RIS:-${ERR:-}}"
  sleep 7
done
