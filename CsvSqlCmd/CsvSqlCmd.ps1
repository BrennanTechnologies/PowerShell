#> get-help csvsqlcmd -full

Import-Module -Name CsvSqlcmd
#Invoke-CsvSqlcmd  
$Csv = C:\Users\brenn\OneDrive\Documents\__Repo\PowerShell\CsvSqlCmd\CsvSqlCmd.xlsx
Invoke-CsvSqlcmd -csv $Csv -sql "select * from csv where FName = 'Chris'"