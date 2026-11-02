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
LISTA="$QUI/portiere_lista.txt"   # la lista del Portiere: una sola per tutti
SVELTO=0; JSON=0; SOLOPROBLEMI=0
for a in "$@"; do
  [ "$a" = "--svelto" ] && SVELTO=1
  [ "$a" = "--json" ] && JSON=1
  [ "$a" = "--solo-problemi" ] && SOLOPROBLEMI=1
done
# --solo-problemi: salta chi ha gia' risposto all'ultimo appello (il capo lavora solo
# sui casi ancora rotti). Si legge il catalogo dell'ultima run.
SKIP=""
if [ "$SOLOPROBLEMI" = "1" ] && [ -f "$OUT" ]; then
  SKIP=$(python3 - "$OUT" << 'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
print(" ".join(v["id"] for v in d.get("voci", []) if v.get("esito") == "risponde"))
PY
)
fi
if [ "${1:-}" = "--chiave" ]; then
  ID="${2:-}"
  # cerca l'id nella lista del Portiere e tira fuori la chiave col vero estrattore
  NOME=$(awk -F'|' -v id="$ID" '$1==id {print $3; exit}' "$LISTA" 2>/dev/null)
  [ -z "$NOME" ] && exit 1
  if [ "$NOME" = "SENZA" ]; then echo "free"; exit 0; fi
  python3 "$QUI/chiave_di.py" "$NOME" 2>/dev/null
  exit 0
fi

mkdir -p "$QUI/dal_pc"
TMP=$(mktemp -d)
[ -f "$K" ] || { echo "  ✗ ~/CHIAVI_LOCALI.md non trovato"; exit 0; }

UA_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
G="$(printf '\033[32m')"; R="$(printf '\033[31m')"; Y="$(printf '\033[33m')"; O="$(printf '\033[0m')"

# cerca_chiave <etichetta> <pattern>
chiave_di(){
  # usa lo stesso estrattore del resto (chiave_di.py): legge solo la riga del provider
  python3 "$QUI/chiave_di.py" "$1" 2>/dev/null
}

# scegli_modello <file-json-modelli>  → stampa l'id di un modello CHAT decente
scegli_modello(){
  python3 - "$1" <<'PY' 2>/dev/null
import json, re, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8", errors="replace"))
except Exception:
    sys.exit(0)
# AUDIT FINALE (1/11 sera): la lista dei modelli arriva in forme diverse
# ("data", "models", {"object":"list","data":[...]}, lista nuda, {"data":{"models":[...]}})
# e prima si usciva: il provider finiva col modello "auto" -> "model not found".
voci = None
if isinstance(d, dict):
    for chiave in ("data", "models", "result", "results", "items"):
        v = d.get(chiave)
        if isinstance(v, list):
            voci = v
            break
        if isinstance(v, dict):
            for sotto in ("models", "data", "items", "list"):
                s = v.get(sotto)
                if isinstance(s, list):
                    voci = s
                    break
            if voci:
                break
elif isinstance(d, list):
    voci = d
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
    # nessun nome "buono": prendo comunque i primi nomi disponibili, meglio un
    # modello strano che un "auto" che non esiste
    for v in voci[:40]:
        if isinstance(v, dict):
            n = v.get("id") or v.get("name") or v.get("model") or v.get("slug")
            if isinstance(n, str) and n:
                nomi.append(n.replace("models/", ""))
        elif isinstance(v, str) and v:
            nomi.append(v)
    if not nomi:
        sys.exit(0)
# prima i "buoni", poi gli altri; fra i buoni il più corto (di solito il nome base)
buoni_prima = sorted(nomi, key=lambda n: (0 if buoni.search(n) else 1, len(n)))
for n in buoni_prima[:8]:
    print(n)
PY
}

# prova <id> <etichetta> <riga-portachiavi> <pattern> <base_url> <modello-suggerito> <chat|modelli>
prova(){
  local id="$1" eti="$2" nome="$3" base="$4" mod="$5" modo="$6"
  local key NOAUTH=0
  if [ "$nome" = "SENZA" ]; then
    # I "SENZA" NON SONO TUTTI UGUALI (2/11, verificato con chat vera):
    #   auth=none     -> NESSUN header Authorization (Kilo, OVH, Pollinations)
    #   auth=sentinel -> Bearer 0000000000 (AI Horde)
    # Mandare un header Authorization QUALSIASI a Kilo/OVH li' fa rispondere 401/403.
    case "$auth" in
      sentinel) key="0000000000" ;;
      *)        key="" ;;
    esac
  else
    key=$(chiave_di "$nome")
  fi
  if [ "$nome" != "SENZA" ] && [ -z "$key" ]; then
    printf '%s\t%s\tno-chiave\t0\tnessuna chiave nel portachiavi\t\n' "$id" "$eti" > "$TMP/$id.res"; return
  fi
  local t0 t1 code esito extra modello MODELLI_KO=""
  t0=$(date +%s%N)

  # CLOUDFLARE: l'indirizzo dipende dall'account, che sta DENTRO la chiave («account_id:token»),
  # e l'elenco modelli non sta su /models ma su /ai/models/search. (21/10: verificato)
  local base_probe="$base" key_hdr="$key"
  local -a HAUTH=()
  if [ "$base" = "SPECIALE-CLOUDFLARE" ]; then
    base="https://api.cloudflare.com/client/v4/accounts/${key%%:*}/ai/v1"
    base_probe="https://api.cloudflare.com/client/v4/accounts/${key%%:*}/ai/models/search?per_page=200"
    key_hdr="${key#*:}"          # nel «Bearer» va solo il token
    mod="${mod}"
  fi
  [ -n "$key_hdr" ] && HAUTH=(-H "Authorization: Bearer $key_hdr")

  # 1) elenco modelli: dice se la chiave vale e QUALE modello esiste OGGI
  code=$(curl -s -o "$TMP/$id.mod" -w '%{http_code}' -m 25 -A "$UA_BROWSER" ${HAUTH[@]+"${HAUTH[@]}"} "$base_probe" 2>/dev/null)
  case "$code" in
    401|403) MODELLI_KO="$code" ;;   # non si esce: si prova anche la chat (2/11)
  esac
  CAND=$(scegli_modello "$TMP/$id.mod")
  ORIG="$mod"                       # il modello CURATO (quello della nostra lista)
  [ -z "$CAND" ] && CAND="$mod"
  modello=$(printf '%s\n' "$CAND" | head -1)
  # CATALOGO FREELLMAPI (2/11): il catalogo firmato di freellmapi e' PUBBLICO
  # (api.freellmapi.co/v1/latest, si aggiorna ogni 12h) e dice per ogni provider
  # quali modelli sono gratis e come si chiamano. Con quel catalogo non si piu'
  # tirare a indovinare ("auto"): si provano i suoi id, in ordine di intelligenza.
  # NB: il file va letto con "python3 -": con "python3 file" python esegue il
  # JSON come script e la lettura non avviene MAI (bug trovato e corretto 2/11).
  CATMOD=$(python3 - "$QUI/lavori/catalogo_freellmapi.json" "$eti" << 'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
cattivi = re.compile(r"embed|whisper|tts|audio|image|vision|rerank|moderation|guard|safety|dall|stable-diffusion|sd-|flux|ocr|document", re.I)
for p in d.get("provider", {}).values():
    if str(p.get("etichetta", "")).lower() == sys.argv[2].lower():
        ms = [m for m in p.get("modelli", []) if isinstance(m.get("id"), str)]
        ms = [m for m in ms if not cattivi.search(m["id"])]
        # il file e' gia' ordinato per rango crescente (1 = migliore)
        for m in ms[:6]:
            print(m["id"])
        break
PY
)
  # AUDIT 2/11: il modello curato si prova per PRIMO. Prima questo script buttava
  # via quello scelto da noi e usava il primo id che tornava da /models: e quel
  # primo id era spesso un UUID o un modello morto (Cloudflare, NVIDIA, Moondream...).
  EXTRA=$(printf '%s' "$extra" | tr ';' '\n' | awk 'NF && !v[$0]++')
  # AI HORDE: il roster cambia ogni ora e un modello puo' essere valido ma senza
  # nessun worker online. L'unica fonte affidabile e' il contatore dei worker.
  if [ "$base" = "https://oai.aihorde.net/v1" ]; then
    ROSTER=$(python3 "$QUI/lavori/modelli_aihorde.py" 2>/dev/null)
    [ -n "$ROSTER" ] && CAND=$(printf '%s\n%s\n' "$ROSTER" "$CAND" | awk 'NF && !v[$0]++')
  fi
  if [ -n "$ORIG" ] && [ "$ORIG" != "auto" ] && [ "$ORIG" != "free" ]; then
    CAND=$(printf '%s\n%s\n' "$ORIG" "$CAND" | awk 'NF && !v[$0]++')
  fi
  if [ -n "$EXTRA" ]; then
    CAND=$(printf '%s\n%s\n' "$EXTRA" "$CAND" | awk 'NF && !v[$0]++')
  fi
  if [ -n "$CATMOD" ]; then
    CAND=$(printf '%s\n%s\n' "$CATMOD" "$CAND" | awk 'NF && !v[$0]++')
  fi

  # AUDIT FINALE (1/11 sera): i provider in modo "modelli" NON venivano
  # interrogati col chat: finivano in "strano / elenco modelli 404" senza mai
  # essere provati davvero. Molti di loro (NVIDIA, HuggingFace Router, Kilo,
  # LLM7, Inferbase...) rispondono invece su /chat/completions: ora si prova
  # la domanda vera ANCHE per loro, con il modello suggerito se /models
  # non ha dato niente.
  if [ "$SVELTO" = "1" ]; then
    if [ "$code" = "200" ]; then esito="risponde"; extra="chiave valida · modello visto: ${modello:-?}"
    elif [ "$code" = "429" ]; then esito="occupato"; extra="troppe richieste adesso (429)"
    elif [ "$code" = "000" ] || [ -z "$code" ]; then esito="rete"; extra="non raggiungibile"
    else esito="strano"; extra="elenco modelli: risposta $code"; fi
  elif [ "$modo" = "no" ]; then
    # provider NON-chat (immagini, video, visione): non si chat-provano
    if [ "$code" = "200" ]; then esito="risponde"; extra="indirizzo valido (non e' un provider di chat)"
    elif [ "$code" = "429" ]; then esito="occupato"; extra="troppe richieste adesso (429)"
    elif [ "$code" = "000" ] || [ -z "$code" ]; then esito="rete"; extra="non raggiungibile"
    else esito="strano"; extra="elenco modelli: risposta $code"; fi
  else
    # 2) domanda vera, col modello che il provider DICE di avere adesso
    local body=""
    # provo i modelli che il provider dichiara di avere, dal più promettente in giù
    # (i nomi cambiano spesso: così non resta mai indietro)
    # 2/11: si provano TUTTI i candidati, non solo il primo. Motivi: il nome del
    # modello cambia spesso, qualche modello e' valido ma senza worker online in
    # quel momento (AI Horde), e il catalogo sa quale id e' gratis ma l'id puo'
    # essere vecchio. Gli errori "decisivi" (chiave rifiutata / quota esaurita /
    # servizio intasato) si ricordano su qualunque tentativo.
    local ok=0 vede401=0 vede429=0 ultimo="" i=0
    while IFS= read -r tentativo; do
      [ -z "$tentativo" ] && continue
      i=$((i+1)); [ "$i" -gt 3 ] && break
      body=$(curl -s -m 30 -A "$UA_BROWSER" ${HAUTH[@]+"${HAUTH[@]}"} -H "Content-Type: application/json" \
        -d "{\"model\":\"$tentativo\",\"messages\":[{\"role\":\"user\",\"content\":\"Rispondi soltanto con OK\"}],\"max_tokens\":20}" \
        "$base/chat/completions" 2>/dev/null)
      [ -n "$body" ] && ultimo="$body"
      if printf '%s' "$body" | grep -qi 'choices'; then modello="$tentativo"; ok=1; break; fi
      if printf '%s' "$body" | grep -qiE 'invalid.*key|unauthorized|forbidden|invalid.token|authentication'; then vede401=1; break; fi
      if printf '%s' "$body" | grep -qiE 'rate|429|quota|limit|credit|insufficient|overload|high demand|try again later|too many requests|busy|1305'; then vede429=1; break; fi
      modello="$tentativo"
    done <<< "$CAND"
    # AUDIT FINALE (1/11 sera): molti provider rispondono "model not found" e
    # NELLO STESSO ERRORE dicono quale modello usare ("Try gemma4:31b-cloud",
    # "model X not found", "use /v1/models"). Se lo dicono, lo si prova.
    if ! printf '%s' "$body" | grep -qi 'choices'; then
      SUGGERITO=$(printf '%s' "$body" | grep -oiE "\b(try|use|instead)\b\s+\"?[A-Za-z0-9_.:/-]{4,60}\"?" | head -1 \
        | sed -E 's/.*\b(try|use|instead)\b\s+\"?//I; s/"$//')
      # il provider a volte "suggerisce" una cosa che NON e' un modello
      case "$SUGGERITO" in
        ""|again|models|/v1/models|it|that|this|the|your|model|our|free) SUGGERITO="" ;;
      esac
      # un UUID non e' un nome di modello
      case "$SUGGERITO" in
        *-*-*-*-*) SUGGERITO="" ;;
      esac
      if [ -n "$SUGGERITO" ] && [ "$SUGGERITO" != "$modello" ]; then
        body=$(curl -s -m 30 -A "$UA_BROWSER" ${HAUTH[@]+"${HAUTH[@]}"} -H "Content-Type: application/json" \
          -d "{\"model\":\"$SUGGERITO\",\"messages\":[{\"role\":\"user\",\"content\":\"Rispondi soltanto con OK\"}],\"max_tokens\":20}" \
          "$base/chat/completions" 2>/dev/null)
        if printf '%s' "$body" | grep -qi 'choices'; then
          modello="$SUGGERITO"; ok=1
        fi
      fi
    fi
    if [ "$ok" = "1" ]; then
      esito="risponde"; extra="ha risposto davvero ($modello)"
    elif [ "$vede401" = "1" ]; then
      esito="chiave-no"; extra="chiave rifiutata"
    elif [ "$vede429" = "1" ]; then
      esito="occupato"; extra="limite o credito finito adesso"
    elif [ -z "$ultimo" ]; then
      esito="rete"; extra="non raggiungibile"
    else
      esito="strano"; extra=$(printf '%s' "$ultimo" | head -c 90 | tr '\n\t' '  ')
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

# La lista è UNA: portiere_lista.txt (id|etichetta|nome nel portachiavi|indirizzo|modello|modo)
# L'ordine è quello del file: prima le più affidabili (diventano riserva in quest'ordine).
while IFS='|' read -r id eti nome base modello modo tipo classe extra auth; do
  if [ "${id:0:2}" = "##" ]; then break; fi          # da qui in poi sono i "da confermare"
  case "$id" in ''|\#*) continue ;; esac
  if [ -n "$SKIP" ]; then
    case " $SKIP " in *" $id "*) continue ;; esac
  fi
  prova "$id" "$eti" "$nome" "$base" "$modello" "${modo:-chat}" "$extra" "$auth" &
  # max 6 alla volta
  while [ "$(jobs -rp | wc -l)" -ge 6 ]; do sleep 0.3; done
done < "$LISTA"
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
# --solo-problemi: si unisce anche il catalogo precedente (chi non e' stato
# riprovato continua a valere, altrimenti la GUI perderebbe la riserva).
try:
    vecchio = json.load(open(out, encoding="utf-8"))
except Exception:
    vecchio = {"voci": []}
gia = {v["id"]: v for v in vecchio.get("voci", [])}
provati = set()
for f in glob.glob(os.path.join(tmp, "*.res")):
    provati.add(os.path.basename(f)[:-4])
for vid, v in gia.items():
    if vid not in provati:
        voci.append(v)
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
# CURA-AUDIT F13 (AUDIT FINALE): scrittura ATOMICA: prima scriveva sul file
# definitivo -> se il processo moriva li', il catalogo restava a meta'.
_tmp = out + ".tmp"
with open(_tmp, "w", encoding="utf-8") as _f:
    json.dump(dati, _f, ensure_ascii=False, indent=1)
os.replace(_tmp, out)
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
