#!/usr/bin/env bash
# indaga_quota_8provider.sh — indagine PROFONDA su 8 provider che l'appello ha
# trovato fermi (2/11 sera). Nessuna conclusione, solo FATTI: codice HTTP, corpo
# della risposta e HEADER (le testate x-ratelimit / retry-after dicono se è quota
# giornaliera, quota al minuto, o quota di crediti).
#
# I 8: NaraRouter · UnoRouter · Chutes · HuggingFace Router · Google AI Studio ·
#     OpenCode Zen · Api.Airforce · AI Horde
#
# Per ogni provider:
#   1) GET  /models            -> la chiave è accettata? quali id ci sono?
#   2) POST /chat/completions  -> UNA domanda vera col modello in lista
#      (e fino a 2 candidati solo se l'errore è "modello inesistente")
#   3) GET  sugli endpoint di quota/uso più comuni (usage, quota, billing/usage,
#      rate_limit, api/usage) -> lo stato crediti/quota se il provider lo espone
#   4) dal catalogo freellmapi: rpm/rpd e i quirk (le "istruzioni" del provider)
#   5) AI Horde: il roster dei volontari (serve un id con worker online)
#
# Il report esce su stdout: il postino lo mette in dal_pc/indaga_quota_8provider.md
set -u
QUI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
TMPD=$(mktemp -d)

echo "# Indagine quota sui provider fermi — $(date '+%d/%m/%Y %H:%M')"
echo
echo "Nessuna conclusione qui dentro: solo codici, corpi e testate. Le domande"
echo "\"quando torna\" e \"cosa fare\" le risponde l'agente, dopo."
echo

dalla_lista(){
  python3 - "$QUI/portiere_lista.txt" "$1" << 'PY'
import sys
percorso, wanted = sys.argv[1], sys.argv[2]
for riga in open(percorso, encoding="utf-8"):
    riga = riga.rstrip("\n")
    if not riga or riga.startswith("#"):
        continue
    c = riga.split("|")
    if len(c) >= 10 and c[0].strip() == wanted:
        print("|".join([c[1].strip(), c[2].strip(), c[3].strip(), c[4].strip(), c[5].strip(), c[6].strip(), c[8].strip()]))
        break
PY
}

dal_catalogo(){
  python3 - "$QUI/lavori/catalogo_freellmapi.json" "$1" << 'PY'
import json, sys
try:
    cat = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception as e:
    print("  catalogo non leggibile:", e); raise SystemExit
prov = cat.get("provider", {})
chiave = sys.argv[2].lower()
for nome, p in prov.items():
    n = nome.lower()
    if chiave in n or n in chiave:
        rpm = sorted({m.get("rpm") for m in p.get("modelli", []) if m.get("rpm") is not None})
        rpd = sorted({m.get("rpd") for m in p.get("modelli", []) if m.get("rpd") is not None})
        print(f"  catalogo freellmapi: '{nome}' · modelli={len(p.get('modelli', []))} rpm={rpm} rpd={rpd}")
        print("    id gratuiti dal catalogo (dal piu' promettente):")
        for m in p.get("modelli", [])[:12]:
            print(f"      - {m.get('id')} (rank {m.get('rank')}, rpm {m.get('rpm')}, rpd {m.get('rpd')})")
        q = p.get("quirk") or []
        for x in q:
            if isinstance(x, dict):
                print(f"   · [{x.get('titolo','')}] {str(x.get('testo',''))[:400]}")
            else:
                print("   ·", str(x)[:300])
        break
else:
    print("  catalogo freellmapi: questo provider NON c'è nel catalogo (limiti da documentare a parte)")
PY
}

testate(){   # stampa solo le testate che contengono la parola chiave
  grep -iE "ratelimit|rate-limit|retry-after|quota|remaining|limit|x-|usage|reset|expires" "$1" 2>/dev/null \
    | grep -viE "^date:|^server:|^content-type:|^connection:" | head -14
}

probe(){
  local id="$1" etichetta nome base modello modo tipo extra
  IFS='|' read -r etichetta nome base modello modo tipo extra <<< "$(dalla_lista "$id")"
  [ -z "${base:-}" ] && { echo "### $id: non presente in portiere_lista.txt"; return; }

  echo "================================================================"
  echo "### $etichetta  (id=$id)"
  echo "  indirizzo: $base   modello in lista: $modello   modo: ${modo:-chat}   tipo: ${tipo:-chat}"
  echo "  extra in lista: ${extra:-nessuno}"

  local key="0000000000"
  if [ "${nome}" != "SENZA" ]; then
    key=$(python3 "$QUI/chiave_di.py" "$nome" 2>/dev/null)
    if [ -z "${key:-}" ]; then
      echo "  CHIAVE: non trovata nel portachiavi"
      dal_catalogo "$id"
      echo
      return
    fi
    echo "  chiave: trovata, ${#key} caratteri"
  else
    echo "  chiave: nessuna (keyless)"
  fi

  # 1) catalogo
  local url="$base/models" code
  code=$(curl -s --max-time 40 -H "Authorization: Bearer $key" -H "User-Agent: $UA" \
        "$url" -o "$TMPD/${id}_m.txt" -D "$TMPD/${id}_mh.txt" -w "%{http_code}")
  echo "  GET $url -> HTTP $code"
  [ -s "$TMPD/${id}_mh.txt" ] && { echo "  testate:"; testate "$TMPD/${id}_mh.txt" | sed 's/^/    /'; }
  if [ "$code" = "200" ]; then
    python3 - "$TMPD/${id}_m.txt" << 'PY'
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
print("    id nel catalogo:", len(ids))
for i in ids[:10]:
    print("      -", i)
open(sys.argv[1] + ".ids", "w", encoding="utf-8").write("\n".join(ids))
PY
  else
    echo "    corpo: $(head -c 260 "$TMPD/${id}_m.txt" 2>/dev/null | tr -d '\n')"
  fi

  # 2) chat vera (una; due candidati in piu' SOLO se l'errore e' "modello inesistente")
  local candidati="$modello"
  [ -f "$TMPD/${id}_m.txt.ids" ] && while IFS= read -r c; do
      [ -z "$c" ] && continue
      case " $candidati " in *" $c "*) continue ;; esac
      candidati="$candidati $c"
    done < <(head -12 "$TMPD/${id}_m.txt.ids")
  local n=0 cand
  for cand in $candidati; do
    n=$((n+1))
    [ "$n" -gt 3 ] && break
    code=$(curl -s --max-time 60 -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
          -H "User-Agent: $UA" \
          -d "{\"model\":\"$cand\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with exactly: OK\"}],\"max_tokens\":64}" \
          "$base/chat/completions" -o "$TMPD/${id}_c.txt" -D "$TMPD/${id}_ch.txt" -w "%{http_code}")
    echo "  chat '$cand' -> HTTP $code"
    echo "    corpo: $(head -c 300 "$TMPD/${id}_c.txt" 2>/dev/null | tr -d '\n')"
    [ -s "$TMPD/${id}_ch.txt" ] && { echo "    testate:"; testate "$TMPD/${id}_ch.txt" | sed 's/^/      /'; }
    if grep -qiE "does not exist|not supported for chat|unsupported model|model_not_found|invalid.*model" "$TMPD/${id}_c.txt" 2>/dev/null; then
      echo "    (errore di NOME MODELLI: provo il prossimo candidato)"
      continue
    fi
    break
  done

  # 3) endpoint di quota/uso
  echo "  endpoint di quota:"
  for q in usage quota billing/usage rate_limit api/usage limits account; do
    qc=$(curl -s --max-time 15 -H "Authorization: Bearer $key" -H "User-Agent: $UA" \
         "$base/$q" -o "$TMPD/${id}_q.txt" -w "%{http_code}" 2>/dev/null)
    if [ "$qc" != "000" ] && [ "$qc" != "404" ] && [ "$qc" != "405" ]; then
      echo "    /$q -> HTTP $qc : $(head -c 220 "$TMPD/${id}_q.txt" 2>/dev/null | tr -d '\n')"
    fi
  done

  # 4) catalogo freellmapi: rpm/rpd e quirk
  dal_catalogo "$id"
  echo
}

# AI Horde: il roster dei volontari (serve un id con worker online)
echo "================================================================"
echo "### AI Horde — roster dei volontari"
ROSTER=""
if [ -f "$QUI/lavori/modelli_aihorde.py" ]; then
  ROSTER=$(timeout 90 python3 "$QUI/lavori/modelli_aihorde.py" 2>/dev/null | head -8)
  echo "$ROSTER" | sed 's/^/  worker online: /'
else
  echo "  (modelli_aihorde.py non presente)"
fi
# chat con il primo id del roster (e con quello in lista): serve un worker ONLINE
AH_ID_IN_LISTA=$(dalla_lista aihorde | cut -d'|' -f4)
for cand in $(echo "$ROSTER" | head -2) "$AH_ID_IN_LISTA"; do
  [ -z "$cand" ] && continue
  code=$(curl -s --max-time 70 -H "Authorization: Bearer 0000000000" -H "Content-Type: application/json" \
        -H "User-Agent: $UA" \
        -d "{\"model\":\"$cand\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with exactly: OK\"}],\"max_tokens\":32}" \
        "https://oai.aihorde.net/v1/chat/completions" -o "$TMPD/ah.txt" -w "%{http_code}")
  echo "  chat AI Horde '$cand' -> HTTP $code : $(head -c 200 "$TMPD/ah.txt" 2>/dev/null | tr -d '\n')"
  grep -qiE "has responded|\"content\":\"[^\"]+" "$TMPD/ah.txt" 2>/dev/null && break
done
dal_catalogo aihorde
echo

for id in nara unorouter chutes huggingface gemini opencode api-airforce; do
  probe "$id"
done

echo "================================================================"
echo "Fine: qui ci sono solo i fatti. Il verdetto (chi tiene, chi esce, quando torna)"
echo "lo scrive l'agente nel compito successivo."
rm -rf "$TMPD"
