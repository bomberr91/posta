#!/usr/bin/env bash
# omni_free.sh — attiva da solo i provider GRATIS keyless su OmniRoute + rapporto sul ponte
set -u
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
V22BIN=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
[ -n "$V22BIN" ] && export PATH="$V22BIN:$PATH"
OMNI=$(command -v omniroute || echo "$V22BIN/omniroute")
[ -x "$OMNI" ] || { echo "  · omniroute non trovato: salto"; exit 0; }
mkdir -p "$HOME/posta/dal_pc"
R="$HOME/posta/dal_pc/omni_setup_report.md"
{
  echo "# 🧠 Rapporto OmniRoute — $(date '+%d/%m/%Y %H:%M')"
  echo
  echo "## 1. Catalogo provider FREE/keyless rilevati"
  "$OMNI" providers available --json > /tmp/omni_avail.json 2>/dev/null || true
  python3 << 'PY'
import json
free=[]
try:
    data=json.load(open('/tmp/omni_avail.json'))
    items = data if isinstance(data,list) else (data.get('providers') or data.get('items') or data.get('data') or [])
    for p in items:
        if not isinstance(p,dict): continue
        pid = p.get('id') or p.get('name') or ''
        cat = str(p.get('category','')).lower()
        auth = str(p.get('auth') or p.get('authType') or p.get('authentication') or '').lower()
        keyless = p.get('keyless') or p.get('noAuth') or auth in ('none','no-auth','keyless','')
        if 'free' in cat and keyless:
            free.append(str(pid))
    print(f"Trovati {len(free)} free keyless nel catalogo:")
    for f in free: print(f"- `{f}`")
except Exception as e:
    print(f"(catalogo JSON non leggibile: {e} — uso la lista nota)")
# fallback/integrazione: nomi noti dalla documentazione
noti = ['opencode-free','opencode','pollinations','qoder','duckduckgo','cloudflare-ai','cloudflare','kiro','longcat','qwen','felo','ai-horde','uncloseai']
tutti = list(dict.fromkeys(free + noti))
open('/tmp/omni_free_ids.txt','w').write('\n'.join(tutti))
PY
  echo
  echo "## 2. Attivazione automatica"
  "$OMNI" providers list > /tmp/omni_gia.txt 2>&1 || true
  while IFS= read -r pid; do
    [ -z "$pid" ] && continue
    if grep -qi "$pid" /tmp/omni_gia.txt 2>/dev/null; then echo "- $pid: già attivo"; continue; fi
    if "$OMNI" setup --non-interactive --add-provider --provider "$pid" >/dev/null 2>&1; then
      echo "- $pid: ✅ ATTIVATO"
    else
      echo "- $pid: · saltato (id inesistente o richiede OAuth/chiave)"
    fi
  done < /tmp/omni_free_ids.txt
  echo
  echo "## 3. Connessioni attive adesso"
  "$OMNI" providers list 2>&1 | head -40
  echo
  echo "## 4. Test gateway (/v1/models con la chiave centrale-agenti)"
  OKEY=$(grep -E '^omniroute ' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | grep -oE 'sk-[A-Za-z0-9-]+' | head -1)
  if [ -n "$OKEY" ]; then
    curl -s --max-time 15 http://localhost:20128/v1/models -H "Authorization: Bearer $OKEY" | head -c 3000
    echo
  else
    echo "chiave omniroute non trovata in ~/CHIAVI_LOCALI.md"
  fi
} > "$R" 2>&1
echo "  ✓ Rapporto OmniRoute scritto in dal_pc/ (arriva sul ponte col push)"
