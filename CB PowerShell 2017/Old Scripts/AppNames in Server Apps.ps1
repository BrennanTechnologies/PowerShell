clear-host
$CSV = @()
$rptData = "c:\logparserscripts\scripts\ServerApps.csv"

#Import CSV for ServerApps.csv
$CSV = import-csv -path $rptData 
$AppNames = $CSV | Select-Object AppName, LogPath -Unique
#$AppNames = $AppNames | Where-Object {$_.AppName -eq "Member"}
#$AppNames

ForEach ($App in $AppNames) {
    $App
    $Servers = Select-Object $CSV.ServerName | Where-Object {$App.AppName -eq "Member"}
    $Servers.ServerName
 
    
    #$ServerNames= Select-Object ServerName | Where-Object {$App.AppName -eq "Member"}
    #$ServerNames = $CSV | Where-Object {$_.AppName -eq "Member"}
    ##$ServerNames = $CSV.ServerName  | Where $App -eq $CSV.AppName
    #$Server = $ServerNames.ServerName
    #$ServerNames
    
}


    





	