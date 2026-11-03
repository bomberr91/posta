# Risposta a «diagnostica_cervello»

_03/11/2026 09:34 · FilippoPC_

## Porte in ascolto (20128 motore, 20129 portiere, 18789 gateway, 18800 browser)
nessuna delle 4 porte in ascolto

## Processi: cervello, motore, guardiani
- [scorta_cervello]
    agenti      13    10  0 08:32 tty3     00:00:02 bash /home/agenti/posta/lavori/scorta_cervello.sh
- [scorta_motore]
    agenti      12     9  0 08:32 tty2     00:00:00 bash /home/agenti/posta/lavori/scorta_motore.sh
- [cervello.py]
    agenti     987    13  0 08:33 tty3     00:00:01 python3 cervello.py
- [omni]
    agenti    1004    12  0 08:33 tty2     00:00:00 flock -n /tmp/omni.lk bash -c . ~/.nvm/nvm.sh; OMNIROUTE_SERVER_HOST=127.0.0.1 omniroute
    agenti    1005  1004  0 08:33 tty2     00:00:06 node /home/agenti/.nvm/versions/node/v22.23.3/bin/omniroute
    agenti    4454  1005  0 08:36 tty2     00:00:32 omniroute (v16.3.8)
- [omniroute]
    agenti    1004    12  0 08:33 tty2     00:00:00 flock -n /tmp/omni.lk bash -c . ~/.nvm/nvm.sh; OMNIROUTE_SERVER_HOST=127.0.0.1 omniroute
    agenti    1005  1004  0 08:33 tty2     00:00:06 node /home/agenti/.nvm/versions/node/v22.23.3/bin/omniroute
    agenti    4454  1005  0 08:36 tty2     00:00:32 omniroute (v16.3.8)
- [postino]
    agenti    1026  1023  0 08:33 tty1     00:00:04 bash postino.sh --loop
    agenti    2650  1026  0 09:34 tty1     00:00:00 bash postino.sh --loop

## Log dei guardiani
- /tmp/scorta_cervello.log (ultime 5 righe)
    [02/11 22:02] guardiano avviato (pid 4908)
    [03/11 08:33] guardiano avviato (pid 13)
    [03/11 08:33] cervello DOWN: lo riavvio
    [03/11 08:33] cervello risorto (~27s)
    [03/11 08:34] lancio la sentinella delle chiavi
- /tmp/scorta_motore.log: ASSENTE
- /tmp/scorta_posta.log (ultime 5 righe)
    [01/11 22:48] ✓ risposta pronta in dal_pc/guardiano_fix.md
    [02/11 13:27] -> il postino non gira: lo riavvio
    [02/11 13:27] -> il postino non gira: lo riavvio
    [03/11 08:33] ⚠ il postino è GELATO sul pull da 29444s: lo ammazzo e lo riavvio
    [03/11 08:33] -> il postino non gira: lo riavvio

## Il portiere vede il motore?
- /salute: {"ok": true, "nome": "Portiere", "porta": 20129, "f3": true, "provider": 59, "gruppi": 3, "regole": 0, "motore": true, "riserva": 5, "struttura": []}
- 20128/v1/models: HTTPError
- 20128/salute: HTTPError
- 20128/: RISPONDE

## Il motore si accende con [9] in centrale.sh?
    131:      echo "  • OmniRoute  : $( (exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null && echo "🟢 acceso" || echo "🔴 spento — menu [9]")"
    162:        echo "OmniRoute NON è ancora installato (78k+ stelle, MIT, 359 provider di cui 90+ gratis)."
    181:        echo "Stato motore: $OMNI_ST  ·  Dashboard: http://localhost:20128  ·  API: http://localhost:20128/v1 (model: auto)"
    191:               pgrep -f omniroute >/dev/null && echo "🟢 Motore avviato! Dashboard: http://localhost:20128" || echo "❌ Problema all'avvio: guarda /tmp/omniroute.log" ;;
    192:          d|D) cmd.exe /c start "" "http://localhost:20128" 2>/dev/null || echo "Apri a mano: http://localhost:20128" ;;

## Ultime richieste al portiere
{"tipo": "cache", "agente": "cervello-0ce8fd8054a79bcc", "rotta": "cache", "ms": 0, "quando": "2026-11-02 22:06:02"}
{"tipo": "cache", "agente": "cervello-0ce8fd8054a79bcc", "rotta": "cache", "ms": 0, "quando": "2026-11-02 22:06:46"}
{"tipo": "cache", "agente": "cervello-0ce8fd8054a79bcc", "rotta": "cache", "ms": 0, "quando": "2026-11-02 22:06:48"}
{"tipo": "sentinella", "nota": "fonti quote aggiornate: FREE-LLM-API-Provider (push 2026-11-02) — ricontrollare portiere_quote.txt", "quando": "2026-11-02 23:18:14"}
{"tipo": "richiesta", "agente": "cervello-0ce8fd8054a79bcc", "politica": "migliore", "rotta": "motore-mappato", "modello": "auto/best-reasoning", "ms": 8148, "quando": "2026-11-02 23:18:19"}

<!-- fine diagnostica_cervello -->
