# Relazione su Typhoon

## 1. Differenza tra "elenco modelli" e "chat vera"

L'**elenco modelli** (endpoint `/models`) verifica la disponibilità dei modelli sull'API, mentre la **chat vera** (endpoint `/chat/completions`) testa l'effettiva capacità di generare risposte. Il 2/11, l'elenco modelli di Typhoon non rispondeva (non 200), ma la chat vera con `typhoon-v2.5-30b-a3b-instruct` funzionava. Questo perché l'endpoint `/models` potrebbe essere temporaneamente inaccessibile per manutenzione o overload, mentre l'endpoint chat remained operativo. Ora il roster usa la chat vera per verificare la disponibilità, garantendo maggiore affidabilità.

## 2. Verifica di altri modelli gratuiti e limiti

Testati i modelli gratuiti di Typhoon:
- **typhoon-ocr-preview**: Risposta ricevuta (output: `{"natural_text": "ตราด"}`).
- **typhoon-v2.5-30b-a3b-instruct**: Risposta ricevuta (output: "Hello! How can I assist you today? 😊").

L'endpoint `/models` elenca 7 modelli, ma nessuno è contrassegnato come gratuito. Tuttavia, `typhoon-v2.5-30b-a3b-instruct` e `typhoon-ocr-preview` hanno risposto senza errori di quota. **Limiti non specificati** dall'API; si consiglia monitoraggio per evitare rate limit.

## 3. Idoneità per la riserva del Portiere

Typhoon è **pronto per entrare nella riserva del Portiere come chat di scorta** con il modello **`typhoon-v2.5-30b-a3b-instruct`**. La sua stabilità e la capacità di gestire richieste chat lo rendono adatto come backup affidabile.