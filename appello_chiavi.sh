#!/usr/bin/env bash
# appello_chiavi.sh — l'appello delle chiavi.
#
# A cosa serve: OmniRoute è il cervello principale, ma se cade gli agenti non devono
# restare fermi. Qui, all'accensione, si chiamano le chiavi del portachiavi UNA per una
# e si scrive chi ha risposto e chi no. Le chiavi che rispondono diventano la riserva:
# se il motore cade, la chat e gli agenti passano da lì.
#
# REGOLA: nessun test inventato. Se di un provider non conosciamo l'indirizzo, lo dice
# "endpoint da confermare" e non lo dà per rotto.
#
#   ./appello_chiavi.sh            appello completo (chat vera dove si può, ~1 minuto)
#   ./appello_chiavi.sh --svelto   solo /models (10-20 secondi)
#   ./appello_chiavi.sh --json     stampa il risultato in JSON
set -u
QUI=$(cd "$(dirname "$0")" && pwd)
K="$HOME/CHIAVI_LOCALI.md"
OUT="$HOME/.posta_appello.json"
RAP="$QUI/dal_pc/appello_chiavi.md"
SVELTO=0; JSON=0
for a in "$@"; do
  [ "$a" = "--svelto" ] && SVELTO=1
  [ "$a" = "--json" ] && JSON=1
done
if [ "${1:-}" = "--chiave" ]; then
  ID="${2:-}"
  RIGA=$(grep -E "^$ID\|" <<'REG' | cut -d'|' -f3,4
groq|Groq|groq|gsk_[A-Za-z0-9_-]+
gemini|Google AI Studio|google ai|AQ\.[A-Za-z0-9_-]+
mistral|Mistral|mistral|mstrl_[A-Za-z0-9_-]+
cohere|Cohere|cohere|[A-Za-z0-9]{40}
openrouter|OpenRouter|openrouter|sk-or-[A-Za-z0-9_-]+
nvidia|NVIDIA|nvidia|nvapi-[A-Za-z0-9_-]+
huggingface|HuggingFace|huggingface|hf_[A-Za-z0-9]+
pollinations|Pollinations|pollinations|sk_[A-Za-z0-9]+
githubmodels|GitHub Models|github models|ghp_[A-Za-z0-9]+
agentrouter|AgentRouter|agentrouter|sk-[A-Za-z0-9]{30,}
opencode|OpenCode Zen|opencode zen|oc_sk_[A-Za-z0-9_]+
REG
)
  R=$(printf '%s' "$RIGA" | cut -d'|' -f1)
  P=$(printf '%s' "$RIGA" | cut -d'|' -f2)
  [ -z "$R" ] && exit 1
  grep -iE "$R" "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | grep -oE "$P" | head -1
  exit 0
fi

mkdir -p "$QUI/dal_pc"
TMP=$(mktemp -d)
[ -f "$K" ] || { echo "  ✗ ~/CHIAVI_LOCALI.md non trovato"; exit 0; }

G="$(printf '\033[32m')"; R="$(printf '\033[31m')"; Y="$(printf '\033[33m')"; O="$(printf '\033[0m')"

# cerca_chiave <etichetta> <pattern>
chiave_di(){
  grep -iE "$1" "$K" 2>/dev/null | grep -oE "$2" | head -1
}

# scegli_modello <file-json-modelli>  → stampa l'id di un modello CHAT decente
scegli_modello(){
  python3 - "$1" <<'PY' 2>/dev/null
import json, re, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8", errors="replace"))
except Exception:
    sys.exit(0)
voci = d.get("data") if isinstance(d, dict) else d
if not isinstance(voci, list):
    sys.exit(0)
cattivi = re.compile(r"embed|whisper|tts|audio|image|vision|rerank|moderation|guard|dall|stable-diffusion|sd-|flux|ocr|document", re.I)
buoni   = re.compile(r"flash|8b|7b|small|mini|instant|turbo|chat|command|llama|gpt|qwen|kimi|glm|deepseek|mistral|mixtral|gemma", re.I)
nomi = []
for v in voci:
    if not isinstance(v, dict):
        continue
    n = v.get("id") or v.get("name") or v.get("model")
    if not isinstance(n, str) or cattivi.search(n):
        continue
    if v.get("capabilities") and not any(k in str(v.get("capabilities")).lower() for k in ("chat", "completion", "generate")):
        continue
    nomi.append(n.replace("models/", ""))
if not nomi:
    sys.exit(0)
# prima i "buoni", poi gli altri; fra i buoni il più corto (di solito il nome base)
buoni_prima = sorted(nomi, key=lambda n: (0 if buoni.search(n) else 1, len(n)))
for n in buoni_prima[:5]:
    print(n)
PY
}

# prova <id> <etichetta> <riga-portachiavi> <pattern> <base_url> <modello-suggerito> <chat|modelli>
prova(){
  local id="$1" eti="$2" riga="$3" pat="$4" base="$5" mod="$6" modo="$7"
  local key
  if [ "$pat" = "SENZA" ]; then key="free"; else key=$(chiave_di "$riga" "$pat"); fi
  if [ -z "$key" ]; then
    printf '%s\t%s\tno-chiave\t0\tnessuna chiave nel portachiavi\t\n' "$id" "$eti" > "$TMP/$id.res"; return
  fi
  local t0 t1 code esito extra modello
  t0=$(date +%s%N)

  # 1) elenco modelli: dice se la chiave vale e QUALE modello esiste OGGI
  code=$(curl -s -o "$TMP/$id.mod" -w '%{http_code}' -m 25 -H "Authorization: Bearer $key" "$base/models" 2>/dev/null)
  case "$code" in
    401|403) printf '%s\t%s\tchiave-no\t%s\tchiave rifiutata (%s)\t\n' "$id" "$eti" "$(( ($(date +%s%N)-t0)/1000000 ))" "$code" > "$TMP/$id.res"; return ;;
  esac
  CAND=$(scegli_modello "$TMP/$id.mod")
  [ -z "$CAND" ] && CAND="$mod"
  modello=$(printf '%s\n' "$CAND" | head -1)

  if [ "$SVELTO" = "1" ] || [ "$modo" = "modelli" ]; then
    if [ "$code" = "200" ]; then esito="risponde"; extra="chiave valida · modello visto: ${modello:-?}"
    elif [ "$code" = "429" ]; then esito="occupato"; extra="troppe richieste adesso (429)"
    elif [ "$code" = "000" ] || [ -z "$code" ]; then esito="rete"; extra="non raggiungibile"
    else esito="strano"; extra="elenco modelli: risposta $code"; fi
  else
    # 2) domanda vera, col modello che il provider DICE di avere adesso
    local body=""
    # provo i modelli che il provider dichiara di avere, dal più promettente in giù
    # (i nomi cambiano spesso: così non resta mai indietro)
    while IFS= read -r tentativo; do
      [ -z "$tentativo" ] && continue
      body=$(curl -s -m 45 -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
        -d "{\"model\":\"$tentativo\",\"messages\":[{\"role\":\"user\",\"content\":\"Rispondi soltanto con OK\"}],\"max_tokens\":10}" \
        "$base/chat/completions" 2>/dev/null)
      if printf '%s' "$body" | grep -qi 'choices'; then modello="$tentativo"; break; fi
      if printf '%s' "$body" | grep -qiE "model|not found|does not exist|no longer"; then
        modello="$tentativo"; continue          # modello cambiato: provo il prossimo
      fi
      modello="$tentativo"; break
    done <<< "$CAND"
    if printf '%s' "$body" | grep -qi 'choices'; then
      esito="risponde"; extra="ha risposto davvero ($modello)"
    elif printf '%s' "$body" | grep -qiE '^\s*OK'; then
      esito="risponde"; extra="ha risposto davvero ($modello)"
    elif printf '%s' "$body" | grep -qiE 'invalid.*key|unauthorized'; then
      esito="chiave-no"; extra="chiave rifiutata"
    elif printf '%s' "$body" | grep -qiE 'rate|429|quota|limit|credit'; then
      esito="occupato"; extra="limite o credito finito adesso"
    elif [ -z "$body" ]; then
      esito="rete"; extra="non raggiungibile"
    else
      esito="strano"; extra=$(printf '%s' "$body" | head -c 90 | tr '\n\t' '  ')
    fi
    printf '%s' "$body" > "$TMP/$id.body"
  fi
  t1=$(date +%s%N)
  local prova_di="modelli"
  { [ "$SVELTO" = "0" ] && [ "$modo" = "chat" ]; } && prova_di="chat"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$eti" "$esito" "$(( (t1-t0)/1000000 ))" "$extra" "${modello:-}" "$prova_di" > "$TMP/$id.res"
}

echo "── 🗣️  APPELLO DELLE CHIAVI ($(date '+%H:%M')) ──"
echo

# id | etichetta | riga del portachiavi | pattern chiave | base url | modello | modo
# L'ordine è: prima le più affidabili (diventano riserva in quest'ordine).
while IFS='|' read -r id eti riga pat base modello modo; do
  [ -z "$id" ] && continue
  prova "$id" "$eti" "$riga" "$pat" "$base" "$modello" "$modo" &
  # max 6 alla volta
  while [ "$(jobs -rp | wc -l)" -ge 6 ]; do sleep 0.3; done
done <<'REGISTRO'
groq|Groq|groq|gsk_[A-Za-z0-9_-]+|https://api.groq.com/openai/v1|llama-3.3-70b-versatile|chat
gemini|Google AI Studio|google ai|AQ\.[A-Za-z0-9_-]+|https://generativelanguage.googleapis.com/v1beta/openai|gemini-2.0-flash|chat
mistral|Mistral|mistral|mstrl_[A-Za-z0-9_-]+|https://api.mistral.ai/v1|mistral-small-latest|chat
cohere|Cohere|cohere|[A-Za-z0-9]{40}|https://api.cohere.ai/compatibility/v1|command-r-plus-08-2024|chat
openrouter|OpenRouter|openrouter|sk-or-[A-Za-z0-9_-]+|https://openrouter.ai/api/v1|openrouter/auto|chat
nvidia|NVIDIA|nvidia|nvapi-[A-Za-z0-9_-]+|https://integrate.api.nvidia.com/v1|meta/llama-3.1-8b-instruct|chat
huggingface|HuggingFace|huggingface|hf_[A-Za-z0-9]+|https://router.huggingface.co/v1|meta-llama/Llama-3.1-8B-Instruct|chat
pollinations|Pollinations|pollinations|sk_[A-Za-z0-9]+|https://text.pollinations.ai/openai|openai|chat
githubmodels|GitHub Models|github models|ghp_[A-Za-z0-9]+|https://models.github.ai/inference|openai/gpt-4o-mini|chat
agentrouter|AgentRouter|agentrouter|sk-[A-Za-z0-9]{30,}|https://agentrouter.org/v1|auto|modelli
opencode|OpenCode Zen|opencode zen|oc_sk_[A-Za-z0-9_]+|https://opencode.ai/zen/v1|glm-5.3|chat
pollinationsfree|Pollinations (senza chiave)|pollinations senza|SENZA|https://text.pollinations.ai/openai|openai-fast|chat
aihorde|AI Horde (senza chiave)|ai horde|SENZA|https://oai.aihorde.net/v1|koboldcpp/LLaMA2-13B-Tiefighter|modelli
REGISTRO
wait

# raccolgo i risultati
{
  echo "# 🗣️ Appello delle chiavi — $(date '+%d/%m/%Y %H:%M')"
  echo
  echo "Chiavi provate: $(ls "$TMP"/*.res 2>/dev/null | wc -l)"
  echo
  echo "| Provider | Esito | ms | Nota |"
  echo "|---|---|---|---|"
  for f in "$TMP"/*.res; do
    IFS=$'\t' read -r id eti esito ms extra modello < "$f"
    case "$esito" in
      risponde) icona="✅ risponde" ;;
      occupato) icona="🟡 occupato adesso" ;;
      chiave-no) icona="🔴 chiave rifiutata" ;;
      rete) icona="⚪ non raggiungibile" ;;
      no-chiave) icona="— nessuna chiave" ;;
      *) icona="🟡 $esito" ;;
    esac
    echo "| $eti | $icona | $ms | $extra |"
  done
} > "$RAP"

# JSON per la GUI: ordine = prima chi risponde (riserva)
python3 - "$TMP" "$OUT" <<'PY'
import glob, json, os, sys
tmp, out = sys.argv[1], sys.argv[2]
voci = []
for f in glob.glob(os.path.join(tmp, "*.res")):
    riga = open(f, encoding="utf-8", errors="replace").read().rstrip("\n").split("\t")
    while len(riga) < 7:
        riga.append("")
    voci.append({"id": riga[0], "nome": riga[1], "esito": riga[2],
                 "ms": int(riga[3] or 0), "nota": riga[4], "modello": riga[5],
                 "prova": riga[6] or "modelli",
                 "verificato": bool(riga[2] == "risponde" and riga[6] == "chat")})
ordine = {"risponde": 0, "occupato": 1, "strano": 2, "rete": 3, "chiave-no": 4, "no-chiave": 5}
voci.sort(key=lambda v: (0 if v["esito"] == "risponde" and v.get("prova") == "chat" else
                         1 if v["esito"] == "risponde" else 2, v["ms"]))
dati = {"quando": __import__("time").strftime("%d/%m/%Y %H:%M"),
        "riserva": [v["id"] for v in voci if v["esito"] == "risponde"],
        "voci": voci}
json.dump(dati, open(out, "w"), ensure_ascii=False, indent=1)
print(json.dumps(dati, ensure_ascii=False))
PY

if [ "$JSON" = "0" ]; then
  echo
  for f in "$TMP"/*.res; do
    IFS=$'\t' read -r id eti esito ms extra modello < "$f"
    case "$esito" in
      risponde)  printf "  ${G}✓${O} %-18s %6s ms  %s\n" "$eti" "$ms" "$extra" ;;
      occupato)  printf "  ${Y}◐${O} %-18s %6s ms  %s\n" "$eti" "$ms" "$extra" ;;
      no-chiave) printf "  ${Y}—${O} %-18s %s\n" "$eti" "nessuna chiave nel portachiavi" ;;
      *)         printf "  ${R}✗${O} %-18s %6s ms  %s\n" "$eti" "$ms" "$extra" ;;
    esac
  done
  echo
  echo "  Rapporto: $RAP"
  echo "  Riserva pronta: $OUT"
fi
rm -rf "$TMP"
