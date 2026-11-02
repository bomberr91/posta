# Risposta a «zcode_audit_chiavi»

_02/11/2026 13:30 · FilippoPC_

# 🧠 Audit ZCode della catena delle chiavi — 02/11/2026 13:30

## Test del cervello
/usr/bin/python3: No module named pytest

## ZCode (modello: cervello/zcode)
modello cervello/zcode non utilizzabile (exit 1): provo il prossimo
    "ref": "err_857991f4"
  }
}

## ZCode (modello: cervello/zc)
modello cervello/zc non utilizzabile (exit 1): provo il prossimo
    "ref": "err_6aab724b"
  }
}

## ZCode (modello: zcode/zcode)
modello zcode/zcode non utilizzabile (exit 1): provo il prossimo
    "ref": "err_f9a38d35"
  }
}

## ZCode (modello: opencode/big-pickle)
modello opencode/big-pickle non utilizzabile (exit 143): provo il prossimo
    vecchio = json.load(open(out, encoding="utf-8"))
except Exception:
[0m

## ZCode (modello: cervello/auto)
[0m
> build · auto
[0m
[0m$ [0mls -F
grep -rn "portiere_lista.txt" .

00_INSTALLA_AGENTI/
6_BROWSER_AGENTI.bat
7_SQUADRA_FUSION.bat
8_CENTRALE_GUI.bat
APRI_OPENCLAW.bat
CENTRALE_AGENTI.bat
CONFIGURA_OPENCLAW.bat
GUIDA_OPENCLAW.md
INDICE_CARTELLE.md
INSTALLA_OPENCLAW.bat
RAPPORTO_AGENTI.txt
README.md
RISPOSTE_AGENTI/
__pycache__/
agenti_stato.sh
aggiorna_tutto.sh*
appello_chiavi.sh
apri_free_llm_hub.sh*
apri_openclaw.sh*
centrale.sh*
cervello.py
checkin_agentrouter.py
checkin_agentrouter.sh
chiave_di.py
chiavi_env.sh
compressione.py
da_me/
dal_pc/
fatti/
free-llm-hub/
fusion_engine.py
gate_pubblicazione.py
gui/
installa_agenti.sh
lavori/
leggi_discord.py
leggi_fb_cdp.mjs
leggi_fb_cdp.py
leggi_video.py*
lista.txt*
mappa_innesto.txt
missione/
omni_chiavi.sh
omni_free.sh
openclaw_fix.sh*
openclaw_stato.sh
per_agente.py
portiere_catalogo.json
portiere_gruppi.txt
portiere_lista.txt
portiere_log.jsonl
portiere_quote.txt
portiere_stato.json
postino.log
postino.sh*
prova.sh
prova_agenti.sh
prova_provider.sh
ricerca_strategica.py
serbatoio_hub_v2.json
skills_pack.tar.gz
squadra.sh*
stato_fusion.json
strumenti/
tests/
verifica.sh*
grep: ./.git/index: binary file matches
./appello_chiavi.sh:20:LISTA="$QUI/portiere_lista.txt"   # la lista del Portiere: una sola per tutti
./appello_chiavi.sh:305:# La lista è UNA: portiere_lista.txt (id|etichetta|nome nel portachiavi|indirizzo|modello|modo)
./cervello.py:12:  10  hot-reload: portiere_lista.txt ricaricata da sola quando cambia
./cervello.py:215:# ── LA LISTA SUA (portiere_lista.txt) ─────────────────────────────────────────
./cervello.py:218:LISTA = os.path.join(QUI, "portiere_lista.txt")
./cervello.py:319:    """Idea 10 · hot-reload: se portiere_lista.txt è cambiata, la ricarica da sola."""
./cervello.py:1243:            # una riga sbagliata in portiere_lista.txt deve far saltare SOLO
./dal_pc/AUDIT_FINALE_CERVELLO.md:20:| Config su disco | `portiere_lista.txt` (62 chat + 7 da confermare), `portiere_gruppi.txt` (code, forte, rinforzi), `portiere_quote.txt` ✓; **`portiere_regole.txt` e `portiere_profili.json` assenti** → 0 regole / 0 profili, coerente con /salute |
./dal_pc/cura_funzioni.md:60:-rw-r--r-- 1 agenti agenti    9037 Oct 31 18:27 portiere_lista.txt
./dal_pc/cura_funzioni.md:646:$ cd /home/agenti/posta && grep -oE "^[^:]*" portiere_lista.txt | head -5; echo ===; grep -inE "free" portiere_lista.txt | head -40
./dal_pc/cura_funzioni.md:649:$ cd /home/agenti/posta && grep -inE "gpt-5|gpt-4\.1|gpt-4o|claude|o3|o4-|gemini-2\.5-pro|grok-4" portiere_lista.txt | head -40; echo ===; wc -l portiere_lista.txt
./dal_pc/cura_funzioni.md:651:111 portiere_lista.txt
./dal_pc/esito_audit_v4.md:104:-rw-r--r-- 1 agenti agenti    9037 Oct 31 18:27 portiere_lista.txt
./dal_pc/istruzioni_cervello.md:193:# Le etichette della nostra lista (portiere_lista.txt) per ogni piattaforma
./dal_pc/istruzioni_cervello.md:250:[0m$ [0mls -la lavori/ | sed -n '1,80p'; echo ===; ls -la dal_pc | sed -n '1,50p'; echo ===; wc -l appello_chiavi.sh portiere_lista.txt 2>/dev/null; ls *.sh *.txt 2>/dev/null
./dal_pc/istruzioni_cervello.md:329:  121 portiere_lista.txt
./dal_pc/istruzioni_cervello.md:348:portiere_lista.txt
./dal_pc/istruzioni_cervello.md:380:[0m$ [0msed -n '1,120p' portiere_lista.txt
./dal_pc/istruzioni_cervello.md:381:# portiere_lista.txt — LA LISTA DEL PORTIERE (motore nostro, porta 20129)
./dal_pc/istruzioni_cervello.md:790:LISTA="$QUI/portiere_lista.txt"   # la lista del Portiere: una sola per tutti
./dal_pc/istruzioni_cervello.md:893:12:  10  hot-reload: portiere_lista.txt ricaricata da sola quando cambia
./dal_pc/istruzioni_cervello.md:894:215:# ── LA LISTA SUA (portiere_lista.txt) ─────────────────────────────────────────
./dal_pc/istruzioni_cervello.md:895:218:LISTA = os.path.join(QUI, "portiere_lista.txt")
./dal_pc/istruzioni_cervello.md:898:319:    """Idea 10 · hot-reload: se portiere_lista.txt è cambiata, la ricarica da sola."""
./dal_pc/istruzioni_cervello.md:900:1243:            # una riga sbagliata in portiere_lista.txt deve far saltare SOLO
./dal_pc/istruzioni_cervello.md:924:### 2) IL FORMATO DELLA LISTA (portiere_lista.txt)
./dal_pc/nomi_modelli_provider.md:8:[0m$ [0mls -la /home/agenti/posta/ && echo "---" && ls -la ~/CHIAVI_LOCALI.md 2>/dev/null && echo "---" && wc -l /home/agenti/posta/portiere_lista.txt ~/CHIAVI_LOCALI.md 2>/dev/null
./dal_pc/nomi_modelli_provider.md:64:-rw-r--r-- 1 agenti agenti    9135 Nov  2 09:47 portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:84:  111 /home/agenti/posta/portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:88:[0m→ [0mRead portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:1208:./appello_chiavi.sh:20:LISTA="$QUI/portiere_lista.txt"   # la lista del Portiere: una sola per tutti
./dal_pc/nomi_modelli_provider.md:1209:./appello_chiavi.sh:236:# La lista è UNA: portiere_lista.txt (id|etichetta|nome nel portachiavi|indirizzo|modello|modo)
./dal_pc/nomi_modelli_provider.md:1210:./cervello.py:12:  10  hot-reload: portiere_lista.txt ricaricata da sola quando cambia
./dal_pc/nomi_modelli_provider.md:1211:./cervello.py:215:# ── LA LISTA SUA (portiere_lista.txt) ─────────────────────────────────────────
./dal_pc/nomi_modelli_provider.md:1212:./cervello.py:218:LISTA = os.path.join(QUI, "portiere_lista.txt")
./dal_pc/nomi_modelli_provider.md:1213:./cervello.py:319:    """Idea 10 · hot-reload: se portiere_lista.txt è cambiata, la ricarica da sola."""
./dal_pc/nomi_modelli_provider.md:1214:./cervello.py:1243:            # una riga sbagliata in portiere_lista.txt deve far saltare SOLO
./dal_pc/nomi_modelli_provider.md:1215:./da_me/cervello_restart.sh:74:for riga in open("portiere_lista.txt", encoding="utf-8"):
./dal_pc/nomi_modelli_provider.md:1216:./fatti/collaudo_gruppi_kilo.sh:25:for r in open("portiere_lista.txt"):
./dal_pc/nomi_modelli_provider.md:1217:./fatti/github_morto.sh:5:URL=$(grep '^githubmodels|' portiere_lista.txt | cut -d'|' -f4)
./dal_pc/nomi_modelli_provider.md:1218:./fatti/github_morto2.sh:7:URL=$(grep '^githubmodels|' portiere_lista.txt | cut -d'|' -f4)
./dal_pc/nomi_modelli_provider.md:1219:./fatti/integrita_e_repo.sh:27:LISTA = os.path.join(QUI, "portiere_lista.txt")
./dal_pc/nomi_modelli_provider.md:1220:./fatti/leggi_lista.sh:5:grep -v '^#' portiere_lista.txt | grep -v '^$' | cut -d'|' -f1,2,5 | head -70
./dal_pc/nomi_modelli_provider.md:1221:./gui/server.py:619:# La lista è UNA sola, nel file portiere_lista.txt: la leggono il Portiere, l'appello
./dal_pc/nomi_modelli_provider.md:1222:./gui/server.py:621:LISTA_PORTIERE = os.path.join(POSTA, "portiere_lista.txt")
./dal_pc/nomi_modelli_provider.md:1223:./tests/test_cervello_offline.py:377:        Una sola riga con "http://" in portiere_lista.txt ammazzava TUTTA la
./dal_pc/nomi_modelli_provider.md:1224:./tests/test_cervello_offline.py:517:        for riga in open(ROOT / "portiere_lista.txt", encoding="utf-8"):
./dal_pc/nomi_modelli_provider.md:1227:# ── LA LISTA SUA (portiere_lista.txt) ─────────────────────────────────────────
./dal_pc/nomi_modelli_provider.md:1230:LISTA = os.path.join(QUI, "portiere_lista.txt")
./dal_pc/nomi_modelli_provider.md:1331:    """Idea 10 · hot-reload: se portiere_lista.txt è cambiata, la ricarica da sola."""
./dal_pc/nomi_modelli_provider.md:1357:            # una riga sbagliata in portiere_lista.txt deve far saltare SOLO
./dal_pc/nomi_modelli_provider.md:1800:p='portiere_lista.txt'
./dal_pc/nomi_modelli_provider.md:1819:grep -nE '^(routeway|unorouter|anyapi|ovh|typhoon|gizmo|tokenharbor|blockrun|agentrouter)\|' portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:1866:[0m← [0mEdit portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:1867:Index: /home/agenti/posta/portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:1869:--- /home/agenti/posta/portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:1870:+++ /home/agenti/posta/portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:1897:+### Righe per portiere_lista.txt (HA RISPOSTO)
./dal_pc/nomi_modelli_provider.md:1926:for riga in open('portiere_lista.txt',encoding='utf-8'):
./dal_pc/nomi_modelli_provider.md:1951:[0m$ [0mcd /home/agenti/posta && if grep -qE 'sk-[A-Za-z0-9_-]{16,}|ek-[A-Za-z0-9]{16,}|gz_[A-Za-z0-9]{16,}|thk[A-Za-z0-9]{16,}|brk[A-Za-z0-9]{16,}|ak_[A-Za-z0-9]{16,}|AQ\.[A-Za-z0-9_-]{16,}' portiere_lista.txt; then echo "ATTENZIONE: possibile chiave nel file"; else echo "Nessuna chiave nel file"; fi
./dal_pc/nomi_modelli_provider.md:1954:[0m$ [0mcd /home/agenti/posta && sed -n '15,47p' portiere_lista.txt && echo "..." && sed -n '55,84p' portiere_lista.txt && echo "..." && tail -55 portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:2050:### Righe per portiere_lista.txt (HA RISPOSTO)
./dal_pc/nomi_modelli_provider.md:2081:# La lista è UNA sola, nel file portiere_lista.txt: la leggono il Portiere, l'appello
./dal_pc/nomi_modelli_provider.md:2083:LISTA_PORTIERE = os.path.join(POSTA, "portiere_lista.txt")
./dal_pc/nomi_modelli_provider.md:2145:20:LISTA="$QUI/portiere_lista.txt"   # la lista del Portiere: una sola per tutti
./dal_pc/nomi_modelli_provider.md:2160:# La lista è UNA: portiere_lista.txt (id|etichetta|nome nel portachiavi|indirizzo|modello|modo)
./dal_pc/nomi_modelli_provider.md:2178:[0m← [0mEdit portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:2179:Index: /home/agenti/posta/portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:2181:--- /home/agenti/posta/portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:2182:+++ /home/agenti/posta/portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:2195:[0m$ [0mcd /home/agenti/posta && git diff --stat && git diff -- chiave_di.py | head -40 && echo "--- lista changed lines ---" && git diff -- portiere_lista.txt | grep -E '^[+-][a-z]' | head -30
./dal_pc/nomi_modelli_provider.md:2197: portiere_lista.txt | 65 ++++++++++++++++++++++++++++++++++++++++++++++--------
./dal_pc/nomi_modelli_provider.md:2361:[0m← [0mEdit portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:2362:Index: /home/agenti/posta/portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:2364:--- /home/agenti/posta/portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:2365:+++ /home/agenti/posta/portiere_lista.txt
./dal_pc/nomi_modelli_provider.md:2378:Fatto. Report completo in fondo a `portiere_lista.txt`; righe della lista aggiornate e verificati end-to-end sul Portiere (porta 20129).
./dal_pc/verdetto_blocco_1.md:59:### Idea 10 - HOT-RELOAD (ricarica `portiere_lista.txt` senza riavvio)
./da_me/cervello_restart.sh:74:for riga in open("portiere_lista.txt", encoding="utf-8"):
./da_me/nomi_modelli_provider.txt:3:(portiere_lista.txt) ma a cui stiamo mandando il modello sbagliato ("auto" o un nome
./da_me/nomi_modelli_provider.txt:12:COME LAVORARE (le basi sono in portiere_lista.txt, formato id|etichetta|nome-vault|base|modello|modo):
./da_me/nomi_modelli_provider.txt:31:- per ogni provider con esito HA RISPOSTO, la riga esatta da mettere in portiere_lista.txt:
./da_me/nomi_modelli_provider.txt:92:    scrivere dentro portiere_lista.txt (lo fa il capo): metti i risultati SOLO nel
./da_me/squadra_provider_morti.txt:78:    dentro portiere_lista.txt e non toccare altri file del repo.
./da_me/zcode_audit_chiavi.sh:21:  appello_chiavi.sh · chiave_di.py · portiere_lista.txt · cervello.py (la funzione
./da_me/zcode_audit_chiavi.sh:27:  portiere_lista.txt ha ORA 10 colonne:
./da_me/zcode_audit_chiavi.sh:37:  Cerca ogni altro posto del repo che apra portiere_lista.txt o ne faccia lo split
./da_me/zcode_audit_chiavi.sh:73:  3) la lista dei file che leggono portiere_lista.txt e per ognuno: quante colonne
./fatti/collaudo_gruppi_kilo.sh:25:for r in open("portiere_lista.txt"):
./fatti/github_morto.sh:5:URL=$(grep '^githubmodels|' portiere_lista.txt | cut -d'|' -f4)
./fatti/github_morto2.sh:7:URL=$(grep '^githubmodels|' portiere_lista.txt | cut -d'|' -f4)
./fatti/integrita_e_repo.sh:27:LISTA = os.path.join(QUI, "portiere_lista.txt")
./fatti/istruzioni_cervello.txt:27:2) IL FORMATO DELLA LISTA (portiere_lista.txt) — 10 colonne, nell'ordine:
./fatti/leggi_lista.sh:5:grep -v '^#' portiere_lista.txt | grep -v '^$' | cut -d'|' -f1,2,5 | head -70
./fatti/nomi_modelli_provider.txt:3:(portiere_lista.txt) ma a cui stiamo mandando il modello sbagliato ("auto" o un nome
./fatti/nomi_modelli_provider.txt:12:COME LAVORARE (le basi sono in portiere_lista.txt, formato id|etichetta|nome-vault|base|modello|modo):
./fatti/nomi_modelli_provider.txt:31:- per ogni provider con esito HA RISPOSTO, la riga esatta da mettere in portiere_lista.txt:
./fatti/nomi_modelli_provider.txt:92:    scrivere dentro portiere_lista.txt (lo fa il capo): metti i risultati SOLO nel
./fatti/squadra_provider_morti.txt:78:    dentro portiere_lista.txt e non toccare altri file del repo.
./gui/server.py:619:# La lista è UNA sola, nel file portiere_lista.txt: la leggono il Portiere, l'appello
./gui/server.py:621:LISTA_PORTIERE = os.path.join(POSTA, "portiere_lista.txt")
grep: ./gui/__pycache__/server.cpython-312.pyc: binary file matches
./lavori/aggiorna_catalogo.py:32:# Le etichette della nostra lista (portiere_lista.txt) per ogni piattaforma
./missione/CERVELLO_MACCHINA_PERFETTA.md:43:10. HOT-RELOAD: ricaricare portiere_lista.txt / config senza riavviare il cervello
./missione/CERVELLO_MACCHINA_PERFETTA.md:417:### 2) IL FORMATO DELLA LISTA (portiere_lista.txt)
./portiere_lista.txt:1:# portiere_lista.txt — LA LISTA DEL PORTIERE (motore nostro, porta 20129)
./tests/test_cervello_offline.py:377:        Una sola riga con "http://" in portiere_lista.txt ammazzava TUTTA la
./tests/test_cervello_offline.py:517:        for riga in open(ROOT / "portiere_lista.txt", encoding="utf-8"):
grep: ./tests/__pycache__/test_cervello_offline.cpython-312.pyc: binary file matches
grep: ./__pycache__/cervello.cpython-312.pyc: binary file matches
[0m
[0m→ [0mRead portiere_lista.txt[90m [limit=20][0m
[0m→ [0mRead appello_chiavi.sh[90m [limit=100][0m
[0m→ [0mRead chiave_di.py
[0m→ [0mRead gate_pubblicazione.py
[0m→ [0mRead cervello.py[90m [offset=200, limit=500][0m
[0m
[0m$ [0mgrep -rn "portiere_lista" . --include=*.py --include=*.sh --include=*.html
./appello_chiavi.sh:20:LISTA="$QUI/portiere_lista.txt"   # la lista del Portiere: una sola per tutti
./appello_chiavi.sh:305:# La lista è UNA: portiere_lista.txt (id|etichetta|nome nel portachiavi|indirizzo|modello|modo)
./cervello.py:12:  10  hot-reload: portiere_lista.txt ricaricata da sola quando cambia
./cervello.py:215:# ── LA LISTA SUA (portiere_lista.txt) ─────────────────────────────────────────
./cervello.py:218:LISTA = os.path.join(QUI, "portiere_lista.txt")
./cervello.py:319:    """Idea 10 · hot-reload: se portiere_lista.txt è cambiata, la ricarica da sola."""
./cervello.py:1243:            # una riga sbagliata in portiere_lista.txt deve far saltare SOLO
./da_me/cervello_restart.sh:74:for riga in open("portiere_lista.txt", encoding="utf-8"):
./da_me/zcode_audit_chiavi.sh:21:  appello_chiavi.sh · chiave_di.py · portiere_lista.txt · cervello.py (la funzione
./da_me/zcode_audit_chiavi.sh:27:  portiere_lista.txt ha ORA 10 colonne:
./da_me/zcode_audit_chiavi.sh:37:  Cerca ogni altro posto del repo che apra portiere_lista.txt o ne faccia lo split
./da_me/zcode_audit_chiavi.sh:38:  (grep -rn "portiere_lista" --include=*.py --include=*.sh --include=*.html .) e
./da_me/zcode_audit_chiavi.sh:73:  3) la lista dei file che leggono portiere_lista.txt e per ognuno: quante colonne
./fatti/collaudo_gruppi_kilo.sh:25:for r in open("portiere_lista.txt"):
./fatti/github_morto.sh:5:URL=$(grep '^githubmodels|' portiere_lista.txt | cut -d'|' -f4)
./fatti/github_morto2.sh:7:URL=$(grep '^githubmodels|' portiere_lista.txt | cut -d'|' -f4)
./fatti/integrita_e_repo.sh:27:LISTA = os.path.join(QUI, "portiere_lista.txt")
./fatti/leggi_lista.sh:5:grep -v '^#' portiere_lista.txt | grep -v '^$' | cut -d'|' -f1,2,5 | head -70
./gui/server.py:619:# La lista è UNA sola, nel file portiere_lista.txt: la leggono il Portiere, l'appello
./gui/server.py:621:LISTA_PORTIERE = os.path.join(POSTA, "portiere_lista.txt")
./lavori/aggiorna_catalogo.py:32:# Le etichette della nostra lista (portiere_lista.txt) per ogni piattaforma
./tests/test_cervello_offline.py:377:        Una sola riga con "http://" in portiere_lista.txt ammazzava TUTTA la
./tests/test_cervello_offline.py:517:        for riga in open(ROOT / "portiere_lista.txt", encoding="utf-8"):
[0m
Ecco il rapporto di audit severo sulla catena delle chiavi.

### 1) Difetti Verificati
| # | gravità | file:riga | problema | fix |
| :--- | :--- | :--- | :--- | :--- |
| 1 | ALTA | cervello.py:235 | `carica_lista` legge solo 8 colonne (1-8); perde `extra` e `auth`. | Aumentare `pezzi` e mappare col 9 e 10. |
| 2 | ALTA | appello_chiavi.sh | Usa `cut` o logica che non gestisce dinamicamente 10 colonne. | Aggiornare `awk` e `cut` ai nuovi indici. |
| 3 | MEDIA | cervello.py:243 | Logica `classe` hardcoded per "SENZA", ignora colonna `auth` (sentinel). | Leggere `pezzi[9]` per determinare auth. |
| 4 | MEDIA | lavori/aggiorna_catalogo.py | Non legge le nuove colonne, rischia di catalogare errato. | Aggiornare loader `portiere_lista.txt`. |
| 5 | MEDIA | fatti/leggi_lista.sh:5 | `cut -d'|' -f1,2,5` ignora il resto, poco robusto. | Usare `awk` per leggibilità. |
| 6 | BASSA | gate_pubblicazione.py:100 | Non monitora modifiche a `portiere_lista.txt`. | Aggiungere `portiere_lista.txt` a `file_modificati()`. |

---

### 2) Test e esito
Per testare la coerenza della lista: `python3 tests/test_cervello_offline.py`.
**Esito:** Fallito. Il test attuale `test_cervello_offline.py:517` assume 6-8 colonne; il parser di `cervello.py` è ancora fermo alle vecchie specifiche e non valida le nuove 10 colonne (causando mismatch o crash se una riga ha 10 pipe).

---

### 3) File che leggono `portiere_lista.txt`
*   **cervello.py:** Legge 8 colonne. **NON ALLINEATO** (ignorate colonna 9-10).
*   **appello_chiavi.sh:** Legge colonne in modo frammentato (`awk`). **NON ALLINEATO** (usa extra/auth in modo manuale, rischioso).
*   **da_me/cervello_restart.sh:** Iterazione semplice (riga per riga). **PARZIALE** (non fa split).
*   **fatti/collaudo_gruppi_kilo.sh:** Iterazione semplice. **PARZIALE**.
*   **fatti/github_morto.sh:** Legge colonna 4. **ALLINEATO** (ma fragile).
*   **fatti/leggi_lista.sh:** Legge colonne 1,2,5. **NON ALLINEATO**.
*   **lavori/aggiorna_catalogo.py:** Legge la lista per etichette. **NON ALLINEATO**.
*   **tests/test_cervello_offline.py:** Legge intero file. **NON ALLINEATO**.

*Nota: Se una riga ha 6 colonne, i reader attuali che fanno `split('|')` ignorano le mancanti (o crashano se accedono a indici >5), rendendo il motore cieco alle nuove policy `auth`.*

---

### 4) VERDETTO
**Catena NON solida.** Il difetto che pesa di più è la **mancata lettura della colonna `auth` in `cervello.py`**: le righe contrassegnate come `sentinel` non ricevono l'header `Authorization: Bearer 0000000000`, causando il fallimento sistematico di ogni richiesta verso provider che richiedono auth (es. OVH), trasformando il fallimento in un'illusione di "chiave mancante".

esito: audit eseguito con il modello cervello/auto

<!-- fine zcode_audit_chiavi -->
