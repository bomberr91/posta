#!/usr/bin/env bash
# prova_provider.sh — collaudo dei provider MIGLIORI (decisione di Filippo: si fa domani mattina)
#
# Fa una domanda VERA a ogni provider e misura: risponde / quanto ci mette / che modello ha usato.
# Scrive il rapporto in dal_pc/prova_provider.md e i dati in ~/.posta_prova_provider.json
#
#   ./prova_provider.sh              solo i migliori (12, ~1-2 minuti)
#   ./prova_provider.sh --tutti      tutti quelli con una chiave nel portachiavi
#   ./prova_provider.sh --svelto     solo "esiste la chiave?" (10 secondi)
set -u
QUI=$(cd "$(dirname "$0")" && pwd)
K="$HOME/CHIAVI_LOCALI.md"
D="$QUI/dal_pc"; mkdir -p "$D"
SVELTO=0; TUTTI=0
for a in "$@"; do
  [ "$a" = "--svelto" ] && SVELTO=1
  [ "$a" = "--tutti" ] && TUTTI=1
done
G=$(printf '\033[32m'); R=$(printf '\033[31m'); Y=$(printf '\033[33m'); O=$(printf '\033[0m')

# id | nome | base url | modello di partenza   (i "migliori" per qualità dichiarata)
MIGLIORI=$(cat <<'LISTA'
agentrouter|AgentRouter (Claude/GPT)|https://agentrouter.org/v1|auto
openrouter|OpenRouter|https://openrouter.ai/api/v1|openrouter/auto
nvidia|NVIDIA NIM|https://integrate.api.nvidia.com/v1|z-ai/glm-5.3
groq|Groq (velocissimo)|https://api.groq.com/openai/v1|allam-2-7b
gemini|Google AI Studio|https://generativelanguage.googleapis.com/v1beta/openai|gemma-4-31b-it
mistral|Mistral|https://api.mistral.ai/v1|mistral-small-latest
cohere|Cohere|https://api.cohere.ai/compatibility/v1|command-r-plus-08-2024
github|GitHub Models|https://models.github.ai/inference|openai/gpt-4o-mini
huggingface|HuggingFace Router|https://router.huggingface.co/v1|Qwen/Qwen3-8B
pollinations|Pollinations|https://text.pollinations.ai/openai|openai-fast
opencode-zen|OpenCode Zen|https://opencode.ai/zen/v1|glm-5.3
LISTA
)
[ "$TUTTI" = "1" ] && MIGLIORI=$(grep -v '^#' "$QUI/mappa_innesto.txt" | grep -v '^$' | while IFS='|' read -r pid riga; do
  echo "$pid|$pid||auto"; done)

chiave(){
  local riga="$1" txt key=""
  txt=$(grep -iE "\*\*$riga" "$K" 2>/dev/null)
  [ -z "$txt" ] && txt=$(grep -iE "$riga" "$K" 2>/dev/null | head -1)
  for PAT in 'oc_sk_[A-Za-z0-9_]+' 'gsk_[A-Za-z0-9_-]+' 'AQ\.[A-Za-z0-9_.-]{20,}' \
             'nvapi-[A-Za-z0-9_-]+' 'mstrl_[A-Za-z0-9_-]+' 'hf_[A-Za-z0-9]+' \
             'sk-or-[A-Za-z0-9_-]+' 'sk-bl-[A-Za-z0-9_-]+' 'sk-air-[A-Za-z0-9_-]+' \
             'sk-nry-[A-Za-z0-9_-]+' 'sk-orca-[A-Za-z0-9_-]+' 'sk-navy-[A-Za-z0-9_-]+' \
             'sk-xt-[A-Za-z0-9_-]+' 'rqsty-sk-[A-Za-z0-9+/=_-]+' 'ek-[A-Za-z0-9]{20,}' \
             'sk_[A-Za-z0-9]{20,}' 'ak_[A-Za-z0-9]+' 'alv2_[A-Za-z0-9]+' 'cfut_[A-Za-z0-9]+' \
             'lfu_[A-Za-z0-9]+' 'sk-free-[A-Za-z0-9_-]+' 'ghp_[A-Za-z0-9]+' 'sk-[A-Za-z0-9_-]{16,}'; do
    key=$(printf '%s' "$txt" | grep -oE "$PAT" | head -1); [ -n "$key" ] && break
  done
  [ -z "$key" ] && key=$(printf '%s' "$txt" | grep -oE '[A-Za-z0-9_+=.-]{24,}' | grep -v '/' \
      | awk '{print length" "$0}' | sort -rn | head -1 | cut -d' ' -f2-)
  printf '%s' "$key"
}

TMP=$(mktemp -d)
echo "── 🧪 PROVA PROVIDER MIGLIORI ($(date '+%d/%m %H:%M')) ──"
echo
printf '%s\n' "$MIGLIORI" > "$TMP/lista.txt"
while IFS='|' read -r id nome base modello; do
  [ -z "$id" ] && continue
  k=$(chiave "$(echo "$nome" | sed 's/ .*//')")
  [ -z "$k" ] && k=$(chiave "$id")
  if [ -z "$k" ]; then
    printf '%s\t%s\tno-chiave\t0\t\t\n' "$id" "$nome" > "$TMP/$id.res"; continue
  fi
  ( t0=$(date +%s%N)
    body=$(curl -s -m 60 -H "Authorization: Bearer $k" -H 'Content-Type: application/json' \
      -d "{\"model\":\"$modello\",\"messages\":[{\"role\":\"user\",\"content\":\"Rispondi soltanto con la parola OK\"}],\"max_tokens\":12}" \
      "$base/chat/completions" 2>/dev/null)
    t1=$(date +%s%N); ms=$(( (t1-t0)/1000000 ))
    primo=$(printf '%s' "$body" | tr -d '\r' | head -c 200)
    if printf '%s' "$body" | grep -qi 'choices' || printf '%s' "$primo" | grep -qiE '^\s*OK\s*$'; then
      usato=$(printf '%s' "$body" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("model") or "")
except Exception: print("")' 2>/dev/null)
      printf '%s\t%s\trisponde\t%s\t%s\t%s\n' "$id" "$nome" "$ms" "${usato:-$modello}" "OK" > "$TMP/$id.res"
    elif printf '%s' "$primo" | grep -qi '<!doctype\|<html'; then
      printf '%s\t%s\tbloccato\t%s\t\t%s\n' "$id" "$nome" "$ms" "risponde una pagina web (Cloudflare), non l'API" > "$TMP/$id.res"
    elif [ -z "$body" ]; then
      printf '%s\t%s\tnon-raggiungibile\t%s\t\t\n' "$id" "$nome" "$ms" > "$TMP/$id.res"
    else
      printf '%s\t%s\tko\t%s\t\t%s\n' "$id" "$nome" "$ms" "$(printf '%s' "$body" | head -c 100 | tr '\n\t' '  ')" > "$TMP/$id.res"
    fi ) &
  while [ "$(jobs -rp | wc -l)" -ge 5 ]; do sleep 0.3; done
done < "$TMP/lista.txt"
wait

{
  echo "# 🧪 Prova provider — $(date '+%d/%m/%Y %H:%M')"
  echo
  echo "| Provider | Esito | ms | Modello usato | Nota |"
  echo "|---|---|---|---|---|"
  for f in "$TMP"/*.res; do
    IFS=$'\t' read -r id nome esito ms usato nota < "$f"
    case "$esito" in
      risponde) icona="✅ risponde" ;;
      no-chiave) icona="— nessuna chiave" ;;
      non-raggiungibile) icona="⚪ non raggiungibile" ;;
      *) icona="🔴 errore" ;;
    esac
    echo "| $nome | $icona | $ms | ${usato:-} | ${nota:-} |"
  done
} > "$D/prova_provider.md"

python3 - "$TMP" "$HOME/.posta_prova_provider.json" <<'PY'
import glob, json, os, sys, time
tmp, out = sys.argv[1], sys.argv[2]
voci = []
for f in glob.glob(os.path.join(tmp, "*.res")):
    r = open(f, encoding="utf-8", errors="replace").read().rstrip("\n").split("\t")
    while len(r) < 6: r.append("")
    voci.append({"id": r[0], "nome": r[1], "esito": r[2], "ms": int(r[3] or 0),
                 "modello": r[4], "nota": r[5]})
voci.sort(key=lambda v: (0 if v["esito"] == "risponde" else 1, v["ms"]))
json.dump({"quando": time.strftime("%d/%m/%Y %H:%M"), "voci": voci}, open(out, "w"),
          ensure_ascii=False, indent=1)
for v in voci:
    icona = {"risponde": "✅", "no-chiave": "—", "non-raggiungibile": "⚪"}.get(v["esito"], "🔴")
    print(f"  {icona} {v['nome']:<26} {v['ms']:>6} ms  {v['modello'] or v['nota'][:50]}")
PY
echo
echo "  Rapporto: $D/prova_provider.md"
rm -rf "$TMP"
