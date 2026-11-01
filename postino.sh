#!/usr/bin/env bash
# postino.sh — il ponte: prende i compiti da ~/posta/da_me, li fa eseguire a OpenCode (o bash per .sh),
# mette il risultato in ~/posta/dal_pc e lo spinge su GitHub (repo "posta").
set -u
# CURA-AUDIT (1/11 sera): git non deve MAI aspettare una password da terminale.
# Il 1/11 il postino è rimasto APPESO su un prompt di credenziali: teneva il
# flock, non vedeva nessun compito, non produceva nessuna notizia, e il
# guardiano (che usa flock -n) non poteva riavviarlo. 40 minuti di coda
# muta. Ora git fallisce subito e il postino lo dice ad alta voce.
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
if [ -f "$HOME/CHIAVI_LOCALI.md" ]; then
  OC_KEY=$(grep -oE 'oc_sk_[A-Za-z0-9_-]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
  [ -n "$OC_KEY" ] && export OPENCODE_API_KEY="$OC_KEY"
fi
pgrep -f 'magpie serve' >/dev/null 2>&1 || (nohup magpie serve >/dev/null 2>&1 &)

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="/tmp/postino.log"
mkdir -p "$DIR/da_me" "$DIR/dal_pc" "$DIR/fatti"
cd "$DIR" || exit 1

TOKEN=""; [ -s "$HOME/.posta_token" ] && TOKEN="$(tr -d '\r\n' < "$HOME/.posta_token")"
LOGIN=""; [ -s "$HOME/.posta_login" ] && LOGIN="$(tr -d '\r\n' < "$HOME/.posta_login")"
[ -z "$LOGIN" ] && [ -s "$DIR/.padrone" ] && LOGIN="$(tr -d '\r\n' < "$DIR/.padrone")"
REMOTE="origin"
[ -n "$TOKEN" ] && [ -n "$LOGIN" ] && REMOTE="https://x-access-token:$TOKEN@github.com/$LOGIN/posta.git"

say(){ echo "[$(date '+%d/%m %H:%M')] $*" | tee -a "$LOG"; }

sync_down(){
  # CURA-AUDIT (1/11 sera): un pull che fallisce in SILENZIO lascia il postino
  # a girare per sempre senza mai vedere i compiti nuovi. Qui il fallimento
  # si VEDE, si rimedia e non può durare all'infinito (timeout).
  echo "pull $(date +%s)" > /tmp/postino_stato 2>/dev/null || true
  if timeout 120 git pull -q --autostash --rebase "$REMOTE" main >/dev/null 2>&1 \
     || timeout 120 git pull -q --autostash --rebase >/dev/null 2>&1; then
    :
  else
    say "⚠ il pull è fallito: rimedio"
    git rebase --abort >/dev/null 2>&1 || true
    git merge --abort >/dev/null 2>&1 || true
    git stash drop >/dev/null 2>&1 || true
    git checkout -- portiere_log.jsonl portiere_stato.json >/dev/null 2>&1 || true
    if timeout 120 git pull -q --autostash --rebase "$REMOTE" main >/dev/null 2>&1 \
       || timeout 120 git pull -q --autostash --rebase >/dev/null 2>&1; then
      say "✓ pull rimediato"
    else
      say "⛔ il pull continua a fallire: i compiti in coda NON possono arrivare. Guarda: cd ~/posta && git status"
    fi
  fi
  echo "idle $(date +%s)" > /tmp/postino_stato 2>/dev/null || true
  if [ -f "$DIR/skills_pack.tar.gz" ] && [ ! -f "$HOME/.skills_v2_installed" ]; then
    tar -xzf "$DIR/skills_pack.tar.gz" -C "$HOME" && date -Is > "$HOME/.skills_v2_installed"
    say "✓ 26 skill aggiornate automaticamente in ~/.config/opencode e ~/.config/goose"
  fi
}
sync_up(){
  # CURA-AUDIT: il GATE. Un file che non passa il suo collaudo non sale su
  # master. Il 1/11 una commit di CURA-AUDIT pubblicò un cervello.py rotto
  # (ogni chat moriva con "empty reply") e nessuno se ne accorse: il collaudo
  # non poteva distinguere "rotto" da "lento". Qui il file rotto resta in
  # locale e il capo legge l'avviso in dal_pc/gate_pubblicazione.txt.
  ESCLUDI="$(python3 "$DIR/gate_pubblicazione.py" --escludi 2>/dev/null)"
  # CURA-AUDIT (1/11 sera): il postino non deve MAI committare tutto l'albero.
  # Con `git add -A` finivano in commit anche file strani o giganti che stanno
  # nella cartella: GitHub rifiutava la push ("push declined due to repository
  # rule violations"), il lavoro restava LOCALE e il postino non capiva perché.
  # Il postino si occupa solo delle sue tre cartelle.
  git add -A dal_pc fatti da_me >/dev/null 2>&1 \
    || git add -A dal_pc fatti >/dev/null 2>&1 \
    || git add -A >/dev/null 2>&1
  if [ -n "$ESCLUDI" ]; then
    for fe in $ESCLUDI; do git reset -q -- "$fe" >/dev/null 2>&1 || true; done
    say "⛔ gate: non pubblico $(echo $ESCLUDI | tr '\n' ' ') (lavoro tenuto in locale)"
  fi
  git diff --cached --quiet && return 0
  git commit -qm "postino $(date '+%d/%m %H:%M')" >/dev/null 2>&1 || true
  timeout 120 git push -q "$REMOTE" HEAD:main >/dev/null 2>&1 \
    || timeout 120 git push -q >/dev/null 2>&1 \
    || say "⚠️ push fallito (il lavoro resta locale: riprovo al prossimo giro)"
}

gira(){
  sync_down
  # check-in AgentRouter +25$/gg — SOLO dalle 18:05 italiane (regola anti-ban) e solo se serve.
  # Le guardie vere (flag del giorno, max 3 tentativi, login manuale) stanno dentro checkin_agentrouter.py
  FLAG="$HOME/.ar_checkin_$(date +%F)"
  if [ "$(date +%H%M)" -ge 1805 ] && [ ! -f "$FLAG" ] && [ ! -f "$HOME/.ar_login_manuale" ] \
     && curl -s --max-time 2 http://127.0.0.1:9222/json/version >/dev/null 2>&1; then
    say "→ check-in agentrouter (+25\$/gg)"
    timeout 300 bash "$DIR/checkin_agentrouter.sh" >/dev/null 2>&1 || say "⚠ check-in agentrouter: vedi dal_pc/agentrouter_checkin.md"
  fi
  for f in da_me/*; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"; n="${b%.*}"; ext="${b##*.}"
    [ -f "fatti/$n.done" ] && continue
    # CURA-AUDIT: un compito che fallisce NON viene archiviato come fatto.
    # Si ritenta al massimo 3 volte, poi resta in fatti/ come .abbandonato.
    TENT=0
    if [ -f "fatti/$n.tentativi" ]; then
      TENT=$(grep -oE '^[0-9]+$' "fatti/$n.tentativi" 2>/dev/null | head -1)
      [ -z "$TENT" ] && TENT=0
    fi
    if [ "$TENT" -ge 3 ]; then
      say "⛔ compito $n: fallito $TENT volte, non lo ritento (vedi dal_pc/$n.md)"
      mv "$f" "fatti/$b" >/dev/null 2>&1
      date -Is > "fatti/$n.abbandonato"
      continue
    fi
    TENT=$((TENT+1)); printf '%s\n' "$TENT" > "fatti/$n.tentativi"
    say "→ compito: $b (tentativo $TENT/3)"
    echo "compito $(date +%s)" > /tmp/postino_stato 2>/dev/null || true
    OUT="dal_pc/$n.md"
    { echo "# Risposta a «$n»"; echo; echo "_$(date '+%d/%m/%Y %H:%M') · $(hostname)_"; echo; } > "$OUT"
    ESITO=0
    if [ "$ext" = "sh" ]; then
      timeout 1800 bash "$f" >> "$OUT" 2>&1 || ESITO=$?
    elif [[ "$b" == squadra_* ]] && [ -x "$DIR/squadra.sh" ]; then
      timeout 2700 "$DIR/squadra.sh" "$(cat "$f")" "$OUT" >/dev/null 2>&1 || ESITO=$?
    else
      timeout 2700 opencode run -m opencode/big-pickle "$(cat "$f")" >> "$OUT" 2>&1 \
        || timeout 2700 opencode run "$(cat "$f")" >> "$OUT" 2>&1 || ESITO=$?
    fi
    if [ "$ESITO" -ne 0 ]; then
      # CURA-AUDIT: questo e' il buco che nascondeva tutto. Il .done si scrive
      # SOLO se il job e' uscito con 0. Un timeout (124) o un errore (1) non
      # passano: il compito resta da fare e viene ritentato.
      echo "" >> "$OUT"
      echo "<!-- FALLITO (exit $ESITO) $n -->" >> "$OUT"
      date -Is > "fatti/$n.failito"
      sync_up
      say "✗ compito $n FALLITO (exit $ESITO): non dichiarato fatto, tentativo $TENT/3"
      continue
    fi
    echo "" >> "$OUT"; echo "<!-- fine $n -->" >> "$OUT"
    mv "$f" "fatti/$b"; date -Is > "fatti/$n.done"
    rm -f "fatti/$n.failito" "fatti/$n.tentativi" "fatti/$n.abbandonato"
    sync_up
    echo "idle $(date +%s)" > /tmp/postino_stato 2>/dev/null || true
    say "✓ risposta pronta in dal_pc/$n.md"
  done
  sync_up
}

say "postino acceso · repo: ${LOGIN:-?} · opencode: $(command -v opencode || echo NON_TROVATO)"
if [ "${1:-}" = "--loop" ]; then
  while :; do gira; sleep 45; done
else
  gira
fi
