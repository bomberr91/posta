#!/bin/bash
# giudice_lusso.sh — una chiamata frontier via AgentRouter (cascata + pause).
# Uso: bash lavori/giudice_lusso.sh "prompt EN" [file_contesto] > risposta.txt
K=$(grep -oE "sk-mHof[A-Za-z0-9_-]{40,}" ~/CHIAVI_LOCALI.md | head -1)
PROMPT="$1"; CTX=""
[ -n "$2" ] && [ -f "$2" ] && CTX=$(head -c 60000 "$2")
for M in "claude-opus-5" "claude-opus-4-8" "claude-sonnet-4-5-20250929" "gpt-5.6-sol" "deepseek-v4-flash"; do
  R=$(python3 - "$M" "$K" "$PROMPT" "$CTX" << 'PYEOF'
import json, sys, urllib.request
m, k, p, c = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
testo = p + ("\n\n---\n" + c if c else "")
corpo = json.dumps({"model": m, "max_tokens": 3000, "messages": [{"role": "user", "content": testo}]}).encode()
req = urllib.request.Request("https://agentrouter.org/v1/messages", data=corpo, headers={
    "x-api-key": k, "anthropic-version": "2023-06-01", "Content-Type": "application/json",
    "User-Agent": "claude-cli/2.0.14 (external, cli)"})
try:
    d = json.loads(urllib.request.urlopen(req, timeout=180).read().decode())
    t = "".join(b.get("text", "") for b in d.get("content", []))
    if t.strip():
        print("GIUDICE=" + m); print(t)
except Exception as e:
    import sys as _s
    corpo_err = getattr(e, "read", lambda n=200: b"")(200)
    print("[%s → %s %s]" % (m, str(e)[:60], corpo_err.decode(errors="replace")[:120] if corpo_err else ""), file=_s.stderr)
PYEOF
)
  if [ -n "$R" ]; then echo "$R"; exit 0; fi
  sleep 8
done
echo "GIUDICE=nessuno (tutte le onde chiuse ora)"
