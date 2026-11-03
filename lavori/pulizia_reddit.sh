#!/bin/bash
# pulizia_reddit.sh — meccanica della promessa PRIVACY (cancellazione dati Reddit).
# Cancella SOLO file con "reddit" nel nome, più vecchi di 48h, SOLO nelle cartelle
# elencate sotto. Git li conserva comunque nella storia: recuperabile > perduto per sempre.
#
# Uso:   bash pulizia_reddit.sh              → ANTEPRIMA (non cancella nulla)
#        bash pulizia_reddit.sh --esegui      → cancella davvero + commit
# Per automatizzare: chiamata quotidiana dal capo-orchestratore (arena/hermes).

GIORNI=2
DIRS=(
  "$HOME/posta/fatti"
  "$HOME/posta/RISPOSTE_AGENTI"
  "$HOME/posta/lavori"
)
LIMITE=$(( $(date +%s) - GIORNI * 86400 ))
TROVATI=()

for d in "${DIRS[@]}"; do
  [ -d "$d" ] || continue
  while IFS= read -r -d '' f; do
    mt=$(stat -c %Y "$f" 2>/dev/null) || continue
    [ "$mt" -lt "$LIMITE" ] && TROVATI+=("$f")
  done < <(find "$d" -type f -iname '*reddit*' -print0 2>/dev/null)
done

if [ "${#TROVATI[@]}" -eq 0 ]; then
  echo "pulizia reddit: nessun file Reddit oltre i ${GIORNI} giorni. Tutto pulito."
  exit 0
fi

echo "file Reddit piu' vecchi di ${GIORNI} giorni:"
for f in "${TROVATI[@]}"; do echo "  - $f"; done

if [ "$1" != "--esegui" ]; then
  echo "(anteprima: rilancia con --esegui per cancellare)"
  exit 0
fi

cd "$HOME/posta" || exit 1
for f in "${TROVATI[@]}"; do
  [ -f "$f" ] && git rm -q --cached "$f" 2>/dev/null; rm -f "$f"
done
git add -A fatti RISPOSTE_AGENTI lavori 2>/dev/null
git commit -q -m "pulizia privacy: dati Reddit oltre ${GIORNI} giorni ($(date '+%d/%m %H:%M'))" && \
  git push -q origin HEAD:main && echo "cancellati ${#TROVATI[@]} file, commit spinto."
