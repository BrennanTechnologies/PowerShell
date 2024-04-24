clear-host
$CSV = @()
$rptData = "c:\logparserscripts\scripts\ServerApps.csv"

#Import CSV for ServerApps.csv
$CSV = import-csv -path $rptData 
$AppNames = $CSV | Select-Object AppName, LogPath -Unique
#$AppNames = $AppNames | Where-Object {$_.AppName -eq "Member"}
#$AppNames


$Servers = $Servers | foreach {
    $Server = $_
    $match = $AppNames | where {$_.AppName -eq $Server.AppName} | select -unique
    
}

$sERVERS