clear-host
$rptData = "c:\logparserscripts\scripts\ServerApps.csv"

#Import CSV for ServerApps.csv
$CSV = import-csv -path $rptData 
$AppNames = $CSV | Select-Object AppName -Unique
#$AppNames

ForEach ($App in $AppNames) {
    $ServerNames = $CSV | Where-Object {$_.AppName -eq $App}
    #$ServerNames = $CSV.ServerName  | Where $App -eq $CSV.AppName
    $ServerNames

}


    





	