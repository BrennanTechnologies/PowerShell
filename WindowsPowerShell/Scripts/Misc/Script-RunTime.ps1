$StartTime = Get-Date

$t = 5
Write-Host "Starting Sleep for $t seconds."
Start-sleep -Seconds $t
$EndTime = Get-Date

$RunTime = $EndTime - $StartTime
$RunTime -f "dd.HH.ss.ssss"
