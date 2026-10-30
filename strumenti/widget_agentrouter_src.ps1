$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
while ($true) {
  $now = Get-Date
  $dir = Join-Path $env:LOCALAPPDATA 'agenti'
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $flag = Join-Path $dir ('agentrouter_fatto_' + $now.ToString('yyyy-MM-dd') + '.txt')
  $dopo1805 = ($now.Hour -gt 18) -or ($now.Hour -eq 18 -and $now.Minute -ge 5)
  if ($dopo1805 -and -not (Test-Path $flag)) {
    try { Start-Process 'chrome.exe' 'https://agentrouter.org' } catch { Start-Process 'https://agentrouter.org' }
    $msg = "CHECK-IN AGENTROUTER (+25 dollari al giorno)`n`nChrome si e' aperto sul sito: fai logout e login per il check-in.`n`nFatto?`n`nSI = fatto per oggi    NO = riaprimi tutto tra 20 minuti"
    $r = [System.Windows.Forms.MessageBox]::Show($msg, 'AGENTROUTER - CHECK-IN (dalle 18:05)', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Information, [System.Windows.Forms.MessageBoxDefaultButton]::Button2, [System.Windows.Forms.MessageBoxOptions]::DefaultDesktopOnly)
    if ($r -eq [System.Windows.Forms.DialogResult]::Yes) {
      New-Item -ItemType File -Path $flag -Force | Out-Null
      Get-ChildItem $dir -Filter 'agentrouter_fatto_*.txt' | Where-Object { $_.Name -ne (Split-Path $flag -Leaf) } | Remove-Item -Force
    } else {
      Start-Sleep -Seconds 1200
    }
  } else {
    Start-Sleep -Seconds 120
  }
}
