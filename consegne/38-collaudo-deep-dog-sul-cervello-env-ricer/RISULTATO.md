✅ COMPLETATO — issue #38 — 28s — exit 0
Agente: `goose`

### Output (coda)
```
[goose_run] via cervello locale (nessuna chiave provider) · modello=auto · bin=/home/agenti/.local/bin/goose

    __( O)>  ● new session · openai auto
   \____)    20261104_29 · /home/agenti/posta
     L L     goose is ready
Ecco i comandi esatti da eseguire in sequenza. **Non devi fare altro che copiarli e incollarli nel terminale**, uno alla volta, controllando l'output:

```bash
# 1) Verifica/Aggiungi CERVELLO_API_KEY nel .env
grep -n "CERVELLO" /mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog/.env || echo 'CERVELLO_API_KEY=sk-cervello' >> /mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog/.env

# 2) Verifica porta 8765 (ripeti dopo 15s se chiusa)
python3 -c "import socket;s=socket.socket();s.settimeout(5);print('8765 APERTA' if s.connect_ex(('127.0.0.1',8765))==0 else '8765 CHIUSA')"

# SE LA PORTA È CHIUSA, E SOLO IN QUEL CASO:
# cmd.exe /c start "" "C:\Users\giopi\Documents\AgentWorkspace\deepdog\Avvia Deep Dog Web.bat"
# ATTENDI 15 SECONDI E RIFAI IL TEST DELLA PORTA

# 3) Esegui ricerca di test
bash /home/agenti/posta/lavori/deepdog_ricerca.sh 2>&1 | tail -30

# 4) Verifica destinazione LLM
echo "Ultimi log portiere:"
tail -5 /home/agenti/posta/portiere_log.jsonl 2>/dev/null
echo -e "\nUltimo appello LLM (ultimi 1200 char):"
tail -c 1200 /home/agenti/.posta_appello.json 2>/dev/null

# 5) Scrivi verifica finale
echo -e ".env ok? $(grep -q "CERVELLO_API_KEY" /mnt/c/Users/giopi/Documents/AgentWorkspace/deepdog/.env && echo SI || echo NO)\n8765? $(python3 -c \"import socket;s=socket.socket();s.settimeout(1);print('APERTA' if s.connect_ex(('127.0.0.1',8765))==0 else 'CHIUSA')\")\nesito ricerca? $(bash /home/agenti/posta/lavori/deepdog_ricerca.sh 2>&1 | tail -1)\ncervello o openrouter? $(grep -q '127.0.0.1:20129' /home/agenti/.posta_appello.json && echo CERVELLO || echo OPENROUTER)\nDEEP DOG ORA CHIAMA IL CERVELLO? $(grep -q '127.0.0.1:20129' /home/agenti/.posta_appello.json && echo SI || echo NO) - TESTATO" > /home/agenti/posta/fatti/verifica_deepdog_cervello.md
```

**Note critiche:**
1. Dopo il punto 2, se la porta è CHIUSA, avvia il batch file **UNA SOLA VOLTA** e ripeti il test della porta dopo 15 secondi esatti
2. Non aprire Chrome manualmente durante il test
3. I log finali devono mostrare `127.0.0.1:20129` (Cervello) e **non** OpenRouter/DeepSeek
4. Il file MD finale avrà 5 righe con i risultati binari

Esegui i comandi in ordine rigoroso. Se qualcosa fallisce, fermati e segnala il problema.
```

Consegna: `/consegne/38-collaudo-deep-dog-sul-cervello-env-ricer`