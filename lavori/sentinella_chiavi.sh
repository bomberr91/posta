#!/usr/bin/env bash
# sentinella_chiavi.sh — la sentinella che tiene VIVE le chiavi.
#
# Cosa fa, una volta ogni SEI ORE (non di piu': i piani gratis hanno limiti):
#   1. rigenera il catalogo freellmapi (https://api.freellmapi.co/v1/latest):
#      i modelli gratis cambiano nome e id, il catalogo e' l'unica fonte sicura.
#   2. ri-prova SOLO chi e' in cooldown/reset (appello --solo-problemi): chi
#      rispondeva continua a valere, chi e' scaduto viene riprovato.
#   3. sentinella dedicata di NavyAI: se il free tier torna, lo reintegriamo.
#   4. check-in AgentRouter (+25$/giorno) se il browser degli agenti e' acceso
#      e non e' gia' stato fatto oggi.
#   4. lascia un rapporto in dal_pc/sentinella_chiavi.md (il postino lo pubblica).
#
# Il file di stato (fatti/sentinella_ultimo_giro) dice quando e' passata
# l'ultima volta: nessuna aspettativa, nessun loop che morde.
set -u
DIR="$HOME/posta"
LOG="/tmp/sentinella_chiavi.log"
STATO="$DIR/fatti/sentinella_ultimo_giro"
ORE=6
say(){ echo "[$(date '+%d/%m %H:%M')] $*" >> "$LOG"; }
cd "$DIR" 2>/dev/null || { say "non trovo ~/posta"; exit 1; }
mkdir -p fatti dal_pc

# --- guardia: non due giri ravvicinati
if [ -f "$STATO" ]; then
  ORA=$(date +%s); PRIMA=$(cat "$STATO" 2>/dev/null || echo 0)
  case "$PRIMA" in ''|*[!0-9]*) PRIMA=0 ;; esac
  if [ $(( (ORA - PRIMA) )) -lt $((ORE * 3600)) ]; then
    say "non e' ancora passato il tempo (aspetto)"
    exit 0
  fi
fi
date +%s > "$STATO"
say "giro iniziato"

RAPPORTO="dal_pc/sentinella_chiavi.md"
{
  echo "# 🛡️ Sentinella delle chiavi — $(date '+%d/%m/%Y %H:%M')"
  echo
} > "$RAPPORTO"

# 1) catalogo
echo "## 1. Catalogo freellmapi" >> "$RAPPORTO"
CAT_OUT=$(python3 lavori/aggiorna_catalogo.py 2>&1)
echo '```' >> "$RAPPORTO"; echo "$CAT_OUT" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
say "catalogo: $(echo "$CAT_OUT" | head -1)"

# 2) ri-prova di chi e' in cooldown/reset
echo >> "$RAPPORTO"; echo "## 2. Appello (solo i problemi)" >> "$RAPPORTO"
APP=$(timeout 600 bash appello_chiavi.sh --solo-problemi 2>&1 | tail -25)
echo '```' >> "$RAPPORTO"; echo "$APP" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
RES=$(python3 - << 'PY' 2>/dev/null
import json, os
p = os.path.expanduser("~/.posta_appello.json")
try:
    d = json.load(open(p, encoding="utf-8"))
except Exception:
    print("catalogo non letto")
    raise SystemExit
print(f"riserva ora: {len(d.get('riserva', []))} su {len(d.get('voci', []))} provider")
PY
)
echo >> "$RAPPORTO"; echo "$RES" >> "$RAPPORTO"
say "appello: $RES"

# 3) sentinella dedicata di NavyAI (2/11 sera): il free tier e' in pausa lato
#    loro, non e' la chiave: se torna, va reintegrato nella lista.
echo >> "$RAPPORTO"; echo "## 3. NavyAI (sentinella dedicata)" >> "$RAPPORTO"
NAVY=$(timeout 180 bash fatti/prova_navyai.sh 2>&1 | tail -12)
echo '```' >> "$RAPPORTO"; echo "$NAVY" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
say "navyai: $(echo "$NAVY" | grep -c 'HTTP 200') risposte 200"

# 4) check-in AgentRouter (+25$/giorno)
echo >> "$RAPPORTO"; echo "## 4. Check-in AgentRouter" >> "$RAPPORTO"
FLAG="$HOME/.ar_checkin_$(date +%F)"
if [ "$(date +%H%M)" -ge 1805 ] && [ ! -f "$FLAG" ] && [ ! -f "$HOME/.ar_login_manuale" ] \
   && curl -s --max-time 2 http://127.0.0.1:9222/json/version >/dev/null 2>&1; then
  AR=$(timeout 300 bash checkin_agentrouter.sh 2>&1 | tail -20)
  echo '```' >> "$RAPPORTO"; echo "$AR" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
  say "check-in agentrouter eseguito"
else
  echo "check-in non eseguito: o non e' l'ora (dopo le 18:05), o il browser degli agenti non risponde, o e' gia' stato fatto oggi." >> "$RAPPORTO"
  say "check-in agentrouter saltato"
fi

# 5) LongCat: a che ora rinnova la quota giornaliera (l'orario non e' nei docs)
echo >> "$RAPPORTO"; echo "## 5. LongCat - quota giornaliera" >> "$RAPPORTO"
if [ -f "$HOME/sonda_longcat.log" ]; then
  OK200=$(grep ' | 200 | ' "$HOME/sonda_longcat.log" | tail -1)
  KO402=$(grep ' | 402 | ' "$HOME/sonda_longcat.log" | tail -1)
  echo "- ultimo 200 (quota tornata): ${OK200:-nessuno}" >> "$RAPPORTO"
  echo "- ultimo 402 (quota esaurita): ${KO402:-nessuno}" >> "$RAPPORTO"
  echo '```' >> "$RAPPORTO"; tail -20 "$HOME/sonda_longcat.log" >> "$RAPPORTO"; echo '```' >> "$RAPPORTO"
else
  echo "sonda non avviata: nessun log in ~/sonda_longcat.log" >> "$RAPPORTO"
fi

say "giro finito · rapporto: $RAPPORTO"
exit 0
