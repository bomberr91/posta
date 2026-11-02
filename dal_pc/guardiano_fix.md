# Risposta a «guardiano_fix»

_01/11/2026 22:47 · FilippoPC_

### 1. il guardiano vecchio era vivo?
32602 bash [CHIAVE-RIMOSSA].sh
   (fermo quello vecchio)

### 2. avvio il guardiano nuovo
32660 bash [CHIAVE-RIMOSSA].sh
[01/11 22:47] guardiano avviato (pid 32602)
[01/11 22:47] guardiano avviato (pid 32660)

### 3. COLLAUDO VIVO: ammazzo il cervello e guardo se torna da solo
   il cervello era gia' giu
   TORNATO DA SOLO dopo ~25s

### 4. salute
{"ok": true, "nome": "Portiere", "porta": 20129, "f3": true, "provider": 62, "gruppi": 3, "regole": 0, "motore": true, "riserva": 6, "struttura": []}

### 5. il log del guardiano (le ultime righe)
[01/11 22:47] guardiano avviato (pid 32602)
[01/11 22:47] guardiano avviato (pid 32660)
[01/11 22:48] cervello DOWN: lo riavvio
[01/11 22:48] cervello risorto (~3s)

GUARDIANO OK: il cervello e' tornato da solo, senza che nessuno lo avviasse a mano

<!-- fine guardiano_fix -->
