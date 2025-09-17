function Test-ADODataUpdate {
    ### Database Variables
    ###--------------------------
    $ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433"
    $Database = "DevOps"
    $Table    = "Test"

    $Fname = "Chris"
    $LName = "Brennan"

    $ID = 6
    $NewLName = "Brennan2"
    
    ### Build SQL Query
    ###--------------------------
    $Query = [string]" UPDATE [dbo].[$Table] SET [LName] = '$NewLName' WHERE ID ='$ID' "

    ### Invoke with ADO .Net
    Invoke-ADOcmd -ServerInstance $ServerInstance -Database $Database -Query $Query  -Quiet
    
}
Import-Module Abacus-SQL -Force
Test-ADODataUpdate