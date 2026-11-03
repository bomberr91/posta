#!/usr/bin/env bash
# verifica_riavvio.sh — referto di stato del PC dopo il riavvio.
# SOLO LETTURA: non avvia, non cancella, non tocca nulla.
# Va in dal_pc/verifica_riavvio.md (lo scrive il postino).
set -u
D="$HOME/posta"; [ -d "$D" ] || D="$HOME/posta_ponte"

porta(){
  if (exec 3<>/dev/tcp/127.0.0.1/"$1") 2>/dev/null; then echo "VIVO"; else echo "KO"; fi
}

echo "Data: $(date '+%d/%m/%Y %H:%M:%S')"
echo "Acceso da: $(uptime -p 2>/dev/null || uptime)"
echo

echo "## Attesa del boot (Gateway e motore sono lenti)"
for i in $(seq 1 20); do   # 10 minuti: dopo il reboot il Gateway mette ~4-5 minuti a mettersi in ascolto
  M=$(porta 20128); G=$(porta 18789)
  [ "$M" = "VIVO" ] && [ "$G" = "VIVO" ] && break
  sleep 30
done
echo "(attesa conclusa: motore=$M gateway=$G)"
echo

echo "## Porte"
echo "- Gateway OpenClaw  18789 : $(porta 18789)"
echo "- Motore OmniRoute  20128 : $(porta 20128)"
echo "- Cervello portiere 20129 : $(porta 20129)"
echo "- Browser agenti    18800 : $(porta 18800)   (chiuso a riposo: normale)"
echo

echo "## Guardiani"
for p in scorta_posta.sh scorta_cervello.sh scorta_motore.sh "postino.sh --loop" omniroute; do
  n=$(pgrep -fc "$p" 2>/dev/null || echo 0)
  echo "- $p : $n"
done
echo "- sonda LongCat : $(pgrep -fc 'sonda_longcat_loop' 2>/dev/null || echo 0)"
echo "- sveglia 19:00 : $(pgrep -fc 'sveglia_loop' 2>/dev/null || echo 0)"
echo

echo "## Sonda LongCat: ultimi 3 campioni"
tail -3 "$HOME/sonda_longcat.log" 2>/dev/null || echo "(nessun log)"
echo

echo "## Portiere: ultime 2 richieste"
tail -2 "$D/portiere_log.jsonl" 2>/dev/null || echo "(nessun log)"
echo

echo "## Motore (guardiano)"
tail -6 /tmp/scorta_motore.log 2>/dev/null || echo "(nessun log)"
echo

echo "## Postino"
tail -8 /tmp/postino.log 2>/dev/null || echo "(nessun log)"
