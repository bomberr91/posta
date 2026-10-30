# REGOLE VINCOLANTI (chi analizza DEVE rispettarle — violazione = SCARTO o DECIDE-IL-CAPO)
1. COSTO ZERO: niente carta, niente abbonamenti, niente pay-per-token.
2. STRADA A: cervello.py RESTA il motore. Le idee si COPIANO dentro cervello.py;
   mai proporre di sostituirlo con un prodotto esterno.
3. Chiavi upstream SOLO nel portachiavi del cervello, MAI negli agenti.
4. NIENTE sostituzione silenziosa del modello: fallback permesso solo su "auto".
5. NIENTE sonda LLM per ogni richiesta (punteggi solo euristici/statistici).
6. NIENTE endpoint esposti su LAN/Internet senza autenticazione (ora: solo localhost).
7. Agenti manuali, niente autostart. Rilascio: audit -> mock -> anteprima -> revisione -> push.
8. Ambiente: Windows + WSL1, utente principiante, cervello.py = Python puro semplice
   (no Postgres, no Redis, no Docker).
9. MAI installare 9Router (pacchetto privato non auditabile) ne' roba in zona grigia
   (bulk account, cookie web). Porta 20128 = OmniRoute, 20129 = Portiere: non toccarle.
10. Mistral di OpenClaw non si tocca. ModelScope escluso. Telefono cinese no.
11. Focus primario: RISPARMIO TOKEN, affidabilita' rotazione chiavi/provider, memoria,
    orchestrazione. Tutto il resto e' secondario.
