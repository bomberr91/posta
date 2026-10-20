#!/usr/bin/env bash
# omni_free.sh v2 — attiva i provider GRATIS su OmniRoute leggendo il catalogo VERO + rapporto sul ponte
set -u
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
V22BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
[ -n "$V22BIN" ] && export PATH="$V22BIN:$PATH"
OMNI=$(command -v omniroute || echo "$V22BIN/omniroute")
[ -x "$OMNI" ] || { echo "  ❌ omniroute non trovato"; exit 0; }
echo "== 0/4 Spengo il motore per sbloccare il database (lo riaccendo io alla fine)..."
pkill -x omniroute 2>/dev/null; pkill -f "bin/omniroute" 2>/dev/null; sleep 3
D="$HOME/posta/dal_pc"; mkdir -p "$D"
noansi(){ sed -e 's/\x1b\[[0-9;]*[A-Za-z]//g'; }

echo "== 1/4 Scarico il catalogo provider (max 2 min)..."
timeout 120 "$OMNI" providers available </dev/null 2>&1 | noansi > "$D/omni_catalogo.txt" || true
timeout 120 "$OMNI" providers available --json </dev/null 2>/dev/null > /tmp/omni_avail.json || true
timeout 60  "$OMNI" providers list      </dev/null 2>&1 | noansi > /tmp/omni_gia.txt || true
{ timeout 30 "$OMNI" setup --help; echo ---; timeout 30 "$OMNI" providers --help; echo ---; timeout 30 "$OMNI" provider --help; } </dev/null 2>&1 | noansi > "$D/omni_help.txt" || true
head -c 20000 /tmp/omni_avail.json > "$D/omni_catalogo_json_raw.txt" 2>/dev/null || true

echo "== 2/4 Cerco i free/keyless nel catalogo..."
python3 - "$D" << 'PY'
import json,re,sys
D=sys.argv[1]; ids=[]
try:
    raw=open('/tmp/omni_avail.json').read().strip()
    pos=[i for i in (raw.find('['),raw.find('{')) if i>=0]
    data=json.loads(raw[min(pos):]) if pos else None
    items=data if isinstance(data,list) else ((data.get('providers') or data.get('items') or data.get('data') or []) if isinstance(data,dict) else [])
    for p in items:
        if isinstance(p,dict):
            pid=str(p.get('id') or p.get('name') or '').strip()
            blob=json.dumps(p).lower()
            if pid and 'free' in blob:
                ids.append(pid)
except Exception as e:
    print('  (json illeggibile:',e,'- uso il testo)')
if not ids:
    for line in open(D+'/omni_catalogo.txt',errors='ignore'):
        if 'free' in line.lower():
            m=re.match(r'[\s|•·-]*([a-z0-9][a-z0-9._/-]{2,})',line.strip().lower())
            if m and m.group(1) not in ('free','freeforever'): ids.append(m.group(1))
ids=list(dict.fromkeys(ids))[:25]
open('/tmp/omni_free_ids.txt','w').write('\n'.join(ids))
print(f'  trovati {len(ids)} candidati')
PY

echo "== 3/4 Attivo i provider (puo' volerci qualche minuto)..."
R="$D/omni_setup_report.md"
{
  echo "# 🧠 Rapporto OmniRoute v2 — $(date '+%d/%m/%Y %H:%M')"
  echo
  echo "## Tentativi di attivazione"
  while IFS= read -r pid <&3; do
    [ -z "$pid" ] && continue
    if grep -qiE "(^|[ |])$pid([ |]|$)" /tmp/omni_gia.txt 2>/dev/null; then echo "- $pid: già attivo"; continue; fi
    OUT=$(timeout 90 "$OMNI" setup --non-interactive --add-provider --provider "$pid" </dev/null 2>&1 | noansi | tail -2 | tr '\n' ' ')
    if echo "$OUT" | grep -qiE "success|added|attiv|saved|configur"; then
      echo "- $pid: ✅ $OUT"
    else
      OUT2=$(timeout 90 "$OMNI" provider add "$pid" </dev/null 2>&1 | noansi | tail -2 | tr '\n' ' ')
      echo "- $pid: ① ${OUT:-nulla} ② ${OUT2:-nulla}"
    fi
  done 3< /tmp/omni_free_ids.txt
  echo
  echo "## Connessioni attive dopo i tentativi"
  timeout 60 "$OMNI" providers list </dev/null 2>&1 | noansi | head -50
  echo
  echo "## Riaccensione motore + test VERO"
  nohup "$OMNI" >/tmp/omniroute.log 2>&1 &
  sleep 12
  OKEY=$(grep -E '^omniroute ' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | grep -oE 'sk-[A-Za-z0-9-]+' | head -1)
  if [ -n "$OKEY" ]; then
    echo "### Domanda di prova al modello auto (deve rispondere OK):"
    curl -s --max-time 90 http://localhost:20128/v1/chat/completions -H "Authorization: Bearer $OKEY" -H "Content-Type: application/json" -d '{"model":"auto","messages":[{"role":"user","content":"Rispondi solo con la parola: OK"}],"max_tokens":20}' | head -c 1500
    echo
  else echo "chiave omniroute non in ~/CHIAVI_LOCALI.md"; fi
} > "$R" 2>&1

echo "== 4/4 Spedisco il rapporto sul ponte..."
cd "$HOME/posta" || exit 0
git add -A >/dev/null 2>&1; git commit -qm "rapporto omniroute v2" >/dev/null 2>&1 || true
TOK=$(grep -oE 'ghp_[A-Za-z0-9]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
git push -q origin main >/dev/null 2>&1 || { [ -n "$TOK" ] && git push -q "https://x-access-token:$TOK@github.com/bomberr91/posta.git" HEAD:main >/dev/null 2>&1; } || true
echo "✅ FATTO! Scrivi 'fatto' in chat."
