#!/usr/bin/env bash
# indaga_navy_longcat.sh — indagine mirata su NavyAI e LongCat (2/11 sera).
#
# Perche' esiste: nell'appello dal PC (15:19) i due provider risultano
#   NavyAI   -> "The model 'navy-auto' does not exist or is not supported for chat completion"
#   LongCat  -> "Unsupported model (model=auto)"
# cioe' NON e' chiaro se la chiave e' morta, se il free tier e' finito o se
# il nome del modello e' sbagliato. Questo script lo distingue con i fatti:
#   1) GET /models  -> la chiave e' accettata? quali id ci sono davvero?
#   2) POST /chat/completions sul modello curato e poi sui candidati di /models
#      -> una chat vera: l'esito si decide sul CORPO, non sul codice HTTP.
#   3) ricerca web (Exa/Tavily) sul free tier e sulla documentazione.
#
# Il report esce su stdout: il postino lo mette in dal_pc/indaga_navy_longcat.md
set -u
QUI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
TMPD=$(mktemp -d)

echo "# Indagine NavyAI e LongCat — $(date '+%d/%m/%Y %H:%M')"
echo
echo "Metodo: catalogo con la chiave, poi chat vera sul modello curato e sui candidati"
echo "del catalogo (max 4), poi ricerca del free tier. L'esito si decide sul corpo"
echo "della risposta: un HTTP 200 con HTML non prova niente."
echo

dalla_lista(){   # dalla_lista <id> -> "base|modello|extra"
  python3 - "$QUI/portiere_lista.txt" "$1" << 'PY'
import sys
percorso, wanted = sys.argv[1], sys.argv[2]
for riga in open(percorso, encoding="utf-8"):
    riga = riga.rstrip("\n")
    if not riga or riga.startswith("#"):
        continue
    c = riga.split("|")
    if len(c) < 10:
        continue
    if c[0].strip() == wanted:
        print("|".join([c[3].strip(), c[4].strip(), c[8].strip()]))
        break
PY
}

probe(){
  local etichetta="$1" id="$2"
  local riga base modello extra
  riga=$(dalla_lista "$id")
  base=${riga%%|*}; riga=${riga#*|}
  modello=${riga%%|*}; extra=${riga#*|}
  local key
  key=$(python3 "$QUI/chiave_di.py" "$etichetta" 2>/dev/null)

  echo "================================================================"
  echo "$etichetta (id in lista: $id)"
  echo "  indirizzo: $base"
  echo "  modello in lista: $modello"
  echo "  modelli extra in lista: ${extra:-nessuno}"
  if [ -z "${key:-}" ]; then
    echo "  CHIAVE: non trovata nel portachiavi"
    echo
    return
  fi
  echo "  chiave: trovata, ${#key} caratteri"

  # 1) catalogo
  local url="$base/models"
  case "$base" in
    */v1|*/openai/v1) url="$base/models" ;;
    *) url="$base/v1/models" ;;
  esac
  local code
  code=$(curl -s --max-time 45 -H "Authorization: Bearer $key" -H "User-Agent: $UA" \
        "$url" -o "$TMPD/${id}_models.json" -w "%{http_code}")
  echo "  GET $url -> HTTP $code"
  if [ "$code" = "200" ]; then
    python3 - "$TMPD/${id}_models.json" << 'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception as e:
    print("    catalogo non leggibile:", e); raise SystemExit
ids = []
if isinstance(d, dict):
    for k in ("data", "models", "object"):
        v = d.get(k)
        if isinstance(v, list):
            for m in v:
                if isinstance(m, dict):
                    for kk in ("id", "name", "model"):
                        if m.get(kk):
                            ids.append(str(m[kk])); break
                elif isinstance(m, str):
                    ids.append(m)
            break
print("    modelli nel catalogo:", len(ids))
for i in ids[:12]:
    print("      -", i)
open("/tmp/_ids_" + sys.argv[1].split("/")[-1] + ".txt", "w", encoding="utf-8").write("\n".join(ids))
PY
  else
    echo "    corpo: $(head -c 220 "$TMPD/${id}_models.json" 2>/dev/null | tr -d '\n')"
  fi

  # 2) chat vera sui candidati
  local candidati="$modello"
  local idsfile="/tmp/_ids_${id}_models.json.txt"
  if [ -f "$idsfile" ]; then
    while IFS= read -r c; do
      [ -z "$c" ] && continue
      case " $candidati " in *" $c "*) continue ;; esac
      candidati="$candidati $c"
    done < <(head -20 "$idsfile")
  fi
  local n=0 cand chat_url body
  chat_url="$base/chat/completions"
  for cand in $candidati; do
    n=$((n+1)); [ "$n" -gt 4 ] && break
    code=$(curl -s --max-time 60 -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
          -H "User-Agent: $UA" \
          -d "{\"model\":\"$cand\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with exactly: OK\"}],\"max_tokens\":128}" \
          "$chat_url" -o "$TMPD/${id}_chat.json" -w "%{http_code}")
    body=$(head -c 260 "$TMPD/${id}_chat.json" 2>/dev/null | tr -d '\n')
    echo "  chat modello '$cand' -> HTTP $code"
    echo "    corpo: $body"
  done
  echo
}

probe "NavyAI" "navy"
probe "LongCat" "longcat"

echo "================================================================"
echo "Ricerca del free tier (Exa/Tavily, gratis)"
for domanda in \
  "NavyAI API free tier chat completion model names" \
  "LongCat API free tier quota model names openai compatible" ; do
  echo "--- $domanda"
  if [ -f "$QUI/lavori/cerca.sh" ]; then
    timeout 120 bash "$QUI/lavori/cerca.sh" "$domanda" 5 2>&1 | head -30
  else
    echo "  (cerca.sh non trovato)"
  fi
  echo
done

echo "================================================================"
echo "Fine. Adesso serve un verdetto: tenere i due provider in lista o toglierli."
rm -rf "$TMPD"
