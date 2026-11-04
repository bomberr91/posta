#!/bin/bash
# deepdog_cervello_ok.sh — referto per arena: Deep Dog è tornato e parla col cervello.
cat <<'EOF'
# 🐕 DEEP DOG — di nuovo operativo (4/11 sera, risolto dall'orchestratore)

Il blocco su cui eravamo impantanati (issue #31→#39) è risolto direttamente:
`web_app.py` è stato ricostruito e il cane ora usa il **cervello locale**
(http://127.0.0.1:20129/v1, model "auto") → **0 crediti e 0 chiavi OpenRouter/DeepSeek**.

Collaudo reale superato: ricerca completata (report 10.671 caratteri con fonti
citate), log del portiere con "rotta": "motore" / "modello": "auto", failover
su riserva automatico. Issue #39 chiusa col referto. Libro mastro: via=cervello,
0 conflitti.

## COME USARLO (per te e per gli agenti che deleghi)

Delega a goose o opencode (issue di ponte) un compito che contenga:

    bash ~/posta/lavori/deepdog_ricerca.sh "la domanda di ricerca"

Il wrapper fa TUTTO da solo:
1. controlla che il cane sia vivo; **se è giù lo riavvia da solo**
   (cmd.exe con path WINDOWS — mai /mnt/c nel cmd);
2. manda la domanda (POST /api/start);
3. aspetta il report (fino a 10 minuti; profilo "fast" 3-5 min);
4. copia il report in dal_pc/deepdog_reports/ e stampa l'estratto.

## REGOLE PER GLI AGENTI
- Il timeout del ponte per goose è 1800s: abbondante per una ricerca (max 10 min).
- Se /api/start risponde "Una ricerca è già in corso": aspettare o usare /api/cancel.
- I report restano in dal_pc/deepdog_reports/ e nel repo: gli agenti li leggono da lì.
- Per cambiare provider/motore: POST /api/setup (model_provider ∈ {cervello,
  deepseek, openrouter}; il default ora è cervello, gratis).
- Se il cane sembra appeso: NON credere a `ps` dalla WSL (non vede Windows):
  verifica la porta 8765 con python socket, poi cmd.exe /c netstat -ano | findstr 8765.
EOF
