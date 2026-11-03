# Risposta a «avviso_pulizia_reddit»

_03/11/2026 22:27 · FilippoPC_

# 🧹 PRIVACY REDDIT — meccanica attiva (3/11)

Nessun nuovo modulo Reddit inviato (come deciso: due ticket bastano, il terzo
solo tra molto tempo e se serve davvero).

Quello che è cambiato nel sistema:
- `lavori/pulizia_reddit.sh` nel repo: cancella i file con "reddit" nel nome
  più vecchi di 48h (SOLO fatti/, RISPOSTE_AGENTI/, lavori/; anteprima di
  default; cancellazione esplicita con --esegui; commit recupera tutto da git).
  È la meccanica della promessa PRIVACY.md del repo pubblico.
- Se un giorno l'API verrà approvata: lo slot REDDIT_CLIENT_ID di Deep Dog è
  pronto, e il collaudo si può delegare al ponte (target: secondhand).
- Il canale attuale (fallback via motori di ricerca) resta primario finché
  l'API non arriva.

<!-- fine avviso_pulizia_reddit -->
