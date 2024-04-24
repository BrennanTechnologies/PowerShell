clear-host
$CSV = @()
$rptData = "c:\logparserscripts\scripts\ServerApps.csv"

#Import CSV for ServerApps.csv
$CSV = import-csv -path $rptData 

$AppNames = $CSV | Select-Object AppName -Unique
#$AppNames
$LogPath  = $CSV | Select-Object LogPath
$LogPath


<#    
ForEach ($App in $AppNames) {
    $Server   = $CSV | Select-Object ServerName | Where-Object {$_.AppName -eq $csv.AppName}
    $FullPath = $App.LogPath
    $FullPath
}
  #>  
    
    



    





	