clear-host
$CSV = @()
$rptData = "c:\logparserscripts\scripts\ServerApps.csv"

#Import CSV for ServerApps.csv
$CSV = import-csv -path $rptData 
$AppNames = $CSV | Select-Object AppName -Unique
#$AppNames
    
ForEach ($App in $AppNames) {
    Write-Output "`r`n"
    Write-output $App
    Write-output "------------------"
    $Servers = $CSV | Select-Object ServerName | Where-Object {$_.AppName -eq $csv.AppName}
    foreach ($Server in $Servers) { $Server.servername }  
    start-sleep -s 1
}