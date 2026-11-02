#!/usr/bin/env bash
# sonda_longcat.sh — misura l'ora in cui LongCat rinnova la quota giornaliera.
#
# Perche' serve: nei docs ufficiali l'orario di reset NON c'e' (402 =
# "Insufficient token quota", nessun header x-ratelimit-reset). L'unica
# maniera per saperlo e' guardare quando una richiesta passa da 402 a 200:
# quindi un campione lento e costante, sul PC (il WSL resta vivo).
#
# Il campione non scrive mai la chiave: la rilegge ogni giro dal portachiavi.
set -u
DIR="$HOME/posta"
[ -d "$DIR" ] || DIR="$HOME/posta_ponte"
LOG="$HOME/sonda_longcat.log"
PIDF="$HOME/.sonda_longcat.pid"
LOOP="$HOME/.sonda_longcat_loop.sh"

if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; then
  echo "sonda gia' attiva (pid $(cat "$PIDF"))"
  [ -f "$LOG" ] && tail -5 "$LOG"
  exit 0
fi

cat > "$LOOP" << 'EOF'
#!/usr/bin/env bash
DIR="$HOME/posta"
[ -d "$DIR" ] || DIR="$HOME/posta_ponte"
LOG="$HOME/sonda_longcat.log"
BASE="https://api.longcat.chat/openai/v1/chat/completions"
while true; do
  TS=$(date '+%d/%m %H:%M')
  KEY=$(cd "$DIR" && python3 chiave_di.py "LongCat" 2>/dev/null | head -1)
  if [ -z "$KEY" ]; then
    echo "$TS | nokey | chiave LongCat non trovata nel portachiavi" >> "$LOG"
  else
    BODY='{"model":"LongCat-2.5","messages":[{"role":"user","content":"Say OK"}],"max_tokens":16}'
    CODE=$(curl -s -o /tmp/_lc_probe.txt -w '%{http_code}' -m 45 -X POST "$BASE" \
      -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
      -H 'User-Agent: Mozilla/5.0' --data "$BODY" 2>/dev/null)
    MSG=$(head -c 200 /tmp/_lc_probe.txt | tr -d '\r\n' | cut -c1-90)
    echo "$TS | $CODE | $MSG" >> "$LOG"
  fi
  sleep 600
done
EOF
chmod 700 "$LOOP"
setsid nohup "$LOOP" >/dev/null 2>&1 &
echo $! > "$PIDF"
sleep 5
echo "sonda LongCat avviata (pid $(cat "$PIDF")) — campione ogni 10 minuti"
echo "log: $LOG"
tail -3 "$LOG" 2>/dev/null
exit 0
