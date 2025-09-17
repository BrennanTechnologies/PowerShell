function Test-ADODataReader {
    ### Database Variables
    ###--------------------------
    $ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433"
    $Database       = "DevOps"
    $Table          = "Test"

    $Query = [string]"Select * FROM [dbo].[$Table]"
    ### Invoke with ADO .Net
    $Data = Invoke-ADOcmd -ServerInstance $ServerInstance -Database $Database -Query $Query
    Return $Data
}

Import-Module Abacus-SQL -Force
$Records = Test-ADODataReader
foreach($Record in $Records){
    $record.FName
}

