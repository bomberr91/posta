#!/usr/bin/env bash
# zcode_audit_chiavi.sh — il pezzo PESANTE affidato a ZCode.
#
# Cosa fa: prende ZCode (il modello del capo, GLM Coding Plan) e gli chiede
# l'audit severo della catena delle chiavi, mentre ZCode può leggere e provare
# i file del repo. Il risultato va in dal_pc/zcode_audit_chiavi.md (il postino
# lo salva da solo).
#
# Se ZCode non risponde, si va con cervello/auto (il motore di sempre): il
# lavoro si fa comunque.
set -u
DIR="$HOME/posta"
cd "$DIR" || { echo "non trovo ~/posta"; exit 1; }

SPEC=$(cat << 'EOF'
Sei l'auditore severo della catena delle chiavi del nostro motore LLM locale.
Guarda i file REALI (leggi tu i file, non fidarti di nessun riassunto) e cerca i
difetti VERI. Non inventare problemi: ogni riga deve poter essere verificata.

I file da guardare:
  appello_chiavi.sh · chiave_di.py · portiere_lista.txt · cervello.py (la funzione
  carica_lista e tutto cio' che legge la lista) · gui/cruscotto.html · tests/ ·
  lavori/aggiorna_catalogo.py · lavori/modelli_aihorde.py · lavori/sentinella_chiavi.sh ·
  lavori/scorta_cervello.sh · postino.sh · gate_pubblicazione.py

IL PUNTO PIU' DELICATO (l'ho appena cambiato, controllalo con attenzione):
  portiere_lista.txt ha ORA 10 colonne:
    id|etichetta|nome nel portachiavi|indirizzo|modello|modo|tipo|classe|extra|auth
  Ogni lettore della lista deve essere allineato:
    - cervello.py carica_lista() legge le colonne 1-8 (id, etichetta, nome, url, modello,
      modo, tipo, classe). È giusto? O c'è un punto in cui il numero delle colonne
      cambia il significato di un campo?
    - appello_chiavi.sh legge id,eti,nome,base,modello,modo,tipo,classe,extra,auth e
      usa extra e auth. È allineato?
    - la GUI (gui/cruscotto.html) e i test (tests/test_cervello_offline.py) leggono la
      lista? Se sì, con quali colonne? Devono stare al passo.
  Cerca ogni altro posto del repo che apra portiere_lista.txt o ne faccia lo split
  (grep -rn "portiere_lista" --include=*.py --include=*.sh --include=*.html .) e
  verifica che sia allineato alle 10 colonne.
  Per ogni file che legge la lista: che cosa succede se una riga ha 6 colonne invece
  di 10 (le righe vecchie)? Che cosa succede se la colonna auth contiene "none" o
  "sentinel" e qualcuno la scambia per una classe di policy?

ALTRI PUNTI DA AUDITARE (con dei fatti, non con delle opinioni):
  1. L'appello può perdere o corrompere una chiave? (chiave_di.py: se una riga del
     portachiavi nomina un altro provider, la chiave sbagliata viene usata: verifica
     che il match sia sulla riga GIUSTA e che non ci siano falsi abbinamenti.)
  2. Il catalogo freellmapi viene letto davvero? (la lettura con "python3 -" invece
     che "python3 file": se qualcuno l'ha rimessa storta, il catalogo non entra e
     l'appello torna a tirare a indovinare.)
  3. La sentinella: quante volte puo' girare al giorno, scrive il suo stato, lascia
     un rapporto, e soprattutto: se il portachiavi manca o il cervello e' giu' la
     sentinella muore in silenzio? (un guardiano senza log e' un guardiano muto.)
  4. Le richieste che l'appello fa: sono poche? Un provider con 2 richieste al minuto
     (OVH) regge se l'appello prova 3 candidati? (nel catalogo: rpm per provider.)
  5. Perdita di segreti: c'e' un modo in cui una chiave finisca in un file versionato
     o in un report? Controlla anche che gate_pubblicazione.py copra i file nuovi
     (lavori/catalogo_freellmapi.json, lavori/sentinella_chiavi.sh).

COME LAVORI:
  - Puoi eseguire comandi (bash) e leggere file: USALI, non tirare a indovinare.
  - Puoi fare richieste vere ai provider con una chiave letta in locale
    (K=$(grep ... ~/CHIAVI_LOCALI.md)) per verificare un sospetto. MAI stampare la
    chiave, MAI scriverla nel report. User-Agent di browser (Chrome), max_tokens 20.
  - Non modificare i file del repo: solo il report.
  - Se un controllo richiede la rete e la rete non c'e', scrivi "NON VERIFICATO" e
    spiega come si verifica.

CONSEGNA (markdown, in italiano, secco):
  1) una tabella | # | gravita | file:riga | problema | fix in una riga |
     (massimo 12 righe, solo problemi REALI)
  2) il comando esatto per eseguire i test e il suo esito vero
  3) la lista dei file che leggono portiere_lista.txt e per ognuno: quante colonne
     legge e se e' allineato
  4) un VERDETTO in una riga: la catena e' solida o no, e il difetto che peserebbe di piu'.
EOF
)

echo "# 🧠 Audit ZCode della catena delle chiavi — $(date '+%d/%m/%Y %H:%M')"
echo
echo "## Test del cervello"
python3 -m pytest tests/ -q 2>&1 | tail -5
echo

for M in cervello/zcode cervello/zc zcode/zcode opencode/big-pickle cervello/auto; do
  echo "## ZCode (modello: $M)"
  OUT=$(timeout 1500 opencode run -m "$M" "$SPEC" 2>&1)
  RC=$?
  if [ "$RC" = "0" ] && [ -n "$OUT" ]; then
    echo "$OUT"
    echo
    echo "esito: audit eseguito con il modello $M"
    exit 0
  fi
  echo "modello $M non utilizzabile (exit $RC): provo il prossimo"
  echo "$OUT" | tail -3
  echo
done

echo "NESSUN modello ha risposto: l'audit va rilanciato."
exit 1
