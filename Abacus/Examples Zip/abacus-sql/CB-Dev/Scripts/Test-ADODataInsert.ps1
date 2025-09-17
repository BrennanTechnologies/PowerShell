function Test-ADODataInsert {
    ### Database Variables
    ###--------------------------
    $ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433"
    $Database = "DevOps"
    $Table    = "Test"

    $Fname = "Chris2"
    $LName = "Brennan2"

    $Query = [string]" 
    INSERT INTO [dbo].[$Table]
        (
            [FName],
            [LName]
        )
        VALUES 
        (
            '$FName',
            '$LName'
        )"
    ### Invoke with ADO .Net
    Invoke-ADOcmd -ServerInstance $ServerInstance -Database $Database -Query $Query #-Quiet
    
}
Import-Module Abacus-SQL -Force
Test-ADODataInsert
