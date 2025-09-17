function Test-ADODataDelete {
    ### Database Variables
    ###--------------------------
    $ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433"
    $Database = "DevOps"
    $Table    = "Test"

    $Fname = "Chris"
    $LName = "Brennan"

    $ID = 8

    ### Build SQL Query
    ###--------------------------
    $Query = [string]" DELETE FROM [dbo].[$Table] WHERE ID = '$ID' "

    ### Invoke with ADO .Net
    Invoke-ADOcmd -ServerInstance $ServerInstance -Database $Database -Query $Query -Quiet
    
}
Import-Module Abacus-SQL -Force
Test-ADODataDelete