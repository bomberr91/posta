#!/usr/bin/env bash
# prova.sh — manda un compito di prova al postino e mostra la risposta
cd "$HOME/posta" 2>/dev/null || { echo "Manca ~/posta"; exit 1; }
F="da_me/prova_$(date +%H%M%S).md"
cat > "$F" <<'SOS'
Rispondi in italiano, in 5 righe al massimo:
1) chi sei e quale modello stai usando
2) le versioni di opencode e goose
3) scrivi la riga esatta: PONTE OK
SOS
echo "→ compito creato: $F"
bash "$HOME/posta/postino.sh"
echo
echo "──── ULTIMA RISPOSTA ────"
ls -t dal_pc/*.md 2>/dev/null | head -1 | xargs -r cat
