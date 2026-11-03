# boot_check.ps1 - riquadro di stato all'avvio del PC.
#
# Controlla, in ordine di affidabilita':
#   cervello/portiere  20129  (WSL)   - il cervello con le sue rotte
#   motore OmniRoute   20128  (WSL)   - il modello che il cervello usa
#   Gateway OpenClaw   18789  (Win)   - puo' mettere 2 minuti: lo aspettiamo
#   browser isolato    18800  (Win)   - atteso SPENTO: si apre solo se serve
#   postino            (WSL)           - il ciclo di sincronizzazione
#
# Uso:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Users\giopi\BootCheck\boot_check.ps1
#   ... -NoPopup   scrive il referto e basta (niente riquadro)
#   ... -Fast      salta l'attesa iniziale
param([switch]$NoPopup, [switch]$Fast)

$ErrorActionPreference = 'SilentlyContinue'
$inizio = Get-Date

function Test-Port {
    param([int]$Port, [int]$TimeoutMs = 1500)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        if ($async.AsyncWaitHandle.WaitOne($TimeoutMs)) {
            $client.EndConnect($async)
            $client.Close()
            return $true
        }
    } catch { }
    try { $client.Close() } catch { }
    return $false
}

# 1) il PC deve svegliarsi: stessa regola dei 60 secondi degli altri guardiani
if (-not $Fast) { Start-Sleep -Seconds 75 }

# 2) il Gateway puo' mettere due minuti: lo aspettiamo fino a 5 minuti
$gateway = $false
$attesaGateway = 0
if (-not $Fast) {
    $deadline = (Get-Date).AddMinutes(5)
    while ((Get-Date) -lt $deadline) {
        $gateway = Test-Port 18789
        if ($gateway) { break }
        Start-Sleep -Seconds 10
        $attesaGateway += 10
    }
} else {
    $gateway = Test-Port 18789
}

$cervello = Test-Port 20129
$motore   = Test-Port 20128
$browser  = Test-Port 18800

# 3) il postino gira dentro la WSL
$postino = 'non verificato'
try {
    $out = & wsl.exe bash -lc "pgrep -f postino >/dev/null 2>&1 && echo POSTINO_OK || echo POSTINO_NO" 2>$null
    $testo = ("$out").Trim()
    if ($testo -match 'POSTINO_OK') { $postino = 'OK' }
    elseif ($testo -match 'POSTINO_NO') { $postino = 'KO' }
} catch { }

# 4) referto
$righe = @()
$righe += "Stato dei servizi del PC - controllato alle $(Get-Date -Format 'HH:mm:ss')"
$righe += ""
if ($cervello) {
    $righe += "[ OK ] Cervello / portiere (20129) - il cervello risponde"
} else {
    $righe += "[KO  ] Cervello / portiere (20129) - NON risponde"
    $righe += "        rimedio: apri ACCENDI_CERVELLO.bat, o aspetta il guardiano del cervello"
}
if ($motore) {
    $righe += "[ OK ] Motore OmniRoute (20128) - il modello e' vivo"
} else {
    $righe += "[KO  ] Motore OmniRoute (20128) - NON risponde"
    $righe += "        rimedio: riavvia OmniRoute (ACCENDI_OMNIROUTE.bat), poi il cervello riparte da solo"
}
if ($gateway) {
    $righe += "[ OK ] Gateway OpenClaw (18789) - attivo (ha impiegato ~$([int]((Get-Date) - $inizio).TotalSeconds) s per alzarsi)"
    $righe += "        pannello: http://127.0.0.1:18789/"
} else {
    $righe += "[KO  ] Gateway OpenClaw (18789) - NON in ascolto"
    $righe += "        rimedio: apri OpenClaw dal collegamento sul desktop (il Gateway riparte da solo)"
}
if ($browser) {
    $righe += "[ OK ] Browser isolato degli agenti (18800) - aperto"
} else {
    $righe += "[ --- ] Browser isolato degli agenti (18800) - chiuso (NORMALE: si apre solo quando un agente lo usa)"
}
if ($postino -eq 'OK') {
    $righe += "[ OK ] Postino (sincronizzazione) - attivo"
} elseif ($postino -eq 'KO') {
    $righe += "[KO  ] Postino (sincronizzazione) - fermo"
    $righe += "        rimedio: guarda se il WSL e' partito (finestra Ubuntu dal collegamento sul desktop)"
} else {
    $righe += "[??? ] Postino (sincronizzazione) - non verificato"
}

$testo = $righe -join "`r`n"
$file = Join-Path $env:USERPROFILE 'boot_check_last.txt'
try { Set-Content -Path $file -Value $testo -Encoding UTF8 } catch { }

if (-not $NoPopup) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($testo, 'Avvio PC - stato dei servizi', 'OK', 'Information') | Out-Null
}
Write-Output $testo
