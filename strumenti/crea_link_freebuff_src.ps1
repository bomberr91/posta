$ErrorActionPreference = 'Stop'
$ws = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut("$env:USERPROFILE\Desktop\Freebuff.lnk")
$lnk.TargetPath = "C:\Windows\System32\wsl.exe"
$lnk.Arguments = 'bash -lc ". ~/.nvm/nvm.sh; cd /mnt/c/Users/giopi/Documents/AgentWorkspace && freebuff"'
$lnk.WorkingDirectory = "C:\Users\giopi\Documents\AgentWorkspace"
$lnk.IconLocation = "C:\Users\giopi\AppData\Local\agenti\freebuff.ico,0"
$lnk.Description = "Freebuff CLI nel workspace degli agenti"
$lnk.Save()
Write-Output "LINK_CREATO"
