# Risposta a «caccia_intruso»

_01/11/2026 09:36 · FilippoPC_

## CACCIA ALL'INTRUSO CMD — 09:36
### 1. Quanti postini girano? (se >1 = GUAIO doppi-job)
agenti      14  0.0  0.0  17152  6448 tty2     S    09:17   0:00 bash -lc sleep 15; while true; do flock -n /tmp/postino.lk bash -c 'cd ~/posta; git pull -q; bash postino.sh --loop'; sleep 60; done
agenti      15  0.0  0.0  17020  6212 tty4     S    09:17   0:01 bash /home/agenti/posta/postino.sh --loop
agenti    1473  0.0  0.0  11160   888 tty2     S    09:18   0:00 flock -n /tmp/postino.lk bash -c cd ~/posta; git pull -q; bash postino.sh --loop
agenti    1475  0.0  0.0  17016  6224 tty2     S    09:18   0:00 bash postino.sh --loop
→ conteggio loop postino: 4

### 2. Avvii automatici nel REGISTRO di Windows
    [CHIAVE-RIMOSSA]    REG_SZ    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --no-startup-window --win-session-start
    OneDrive    REG_SZ    "C:\Users\giopi\AppData\Local\Microsoft\OneDrive\OneDrive.exe" /background
    Opera Stable    REG_SZ    "C:\Users\giopi\AppData\Local\Programs\Opera\opera.exe" --autostart
    RaiDrive    REG_SZ    C:\Program Files\OpenBoxLab\RaiDrive\RaiDrive.exe /background
    NeatDM    REG_SZ    C:\Program Files (x86)\Neat Download Manager\NeatDM.exe -autostart
    CometUpdaterTaskUser145.2.7632.4583    REG_SZ    "C:\Users\giopi\AppData\Local\Perplexity\CometUpdater\145.2.7632.4583\updater.exe" --wake
    Opera Browser Assistant    REG_SZ    "C:\Users\giopi\AppData\Local\Programs\Opera\assistant\browser_assistant.exe"

### 3. Utilità di pianificazione (voci sospette)
"\Agenti - Postino","N/D","In esecuzione"
"\Microsoft\Windows\SpacePort\SpaceAgentTask","N/D","Pronta"
"\Microsoft\Windows\SpacePort\SpaceAgentTask","N/D","Pronta"

### 4. Esecuzione automatica COMUNE (tutti gli utenti)
desktop.ini

### 5. Chi è il terminale predefinito? (bizza Win11)



<!-- fine caccia_intruso -->
