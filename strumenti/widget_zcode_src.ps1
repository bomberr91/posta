$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
while ($true) {
  $now = Get-Date
  $dir = Join-Path $env:LOCALAPPDATA 'agenti'
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $flag = Join-Path $dir ('zcode_fatto_' + $now.ToString('yyyy-MM-dd') + '.txt')
  if ($now.Hour -ge 12 -and -not (Test-Path $flag)) {
    $msg = "Riscatta i token ZCode di oggi: apri ZCode e premi CLAIM (card in basso a sinistra).`n`nHai gia riscattato?`n`nSI = fatto per oggi    NO = richiedimelo tra 20 minuti"
    $r = [System.Windows.Forms.MessageBox]::Show($msg, 'ZCODE - RISCATTO GIORNALIERO', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Information, [System.Windows.Forms.MessageBoxDefaultButton]::Button2, [System.Windows.Forms.MessageBoxOptions]::DefaultDesktopOnly)
    if ($r -eq [System.Windows.Forms.DialogResult]::Yes) {
      New-Item -ItemType File -Path $flag -Force | Out-Null
      Get-ChildItem $dir -Filter 'zcode_fatto_*.txt' | Where-Object { $_.Name -ne (Split-Path $flag -Leaf) } | Remove-Item -Force
    } else {
      Start-Sleep -Seconds 1200
    }
  } else {
    Start-Sleep -Seconds 120
  }
}
