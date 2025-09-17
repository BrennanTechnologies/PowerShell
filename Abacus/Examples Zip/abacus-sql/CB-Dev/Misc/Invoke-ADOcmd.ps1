function Invoke-ADOcmd {
    <#
    .SYNOPSIS
    Invoke a .NET ADO Database Connection & Runs a SQL Query.
    
    .DESCRIPTION
    Invoke a .NET ADO Database Connection & Runs a SQL Query.
    
    .PARAMETER Database
    Database Name
    
    .PARAMETER Query
    SQL Query String
    
    .EXAMPLE
    Invoke-ADOcmd -ServerInstance $ServerInstance -Database $Database -Query $Query
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [string]$ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433"
        ,
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Database
        ,
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Query
        )
    Begin {
        ### Database Variables
        ###--------------------------
        $DBServer = "nymgmtdodb01.management.corp"
        $ConnectionString = "Server=$DBServer;Initial Catalog=$Database;Integrated Security=True;"

        ### Open DB Connection
        ###--------------------------
        $Connection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
        $Connection.Open()
        $Cmd = New-Object System.Data.SqlClient.SqlCommand
        $Cmd.Connection = $Connection

        <#
        ### Database Variables
        ###--------------------------
        $ConnectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"

        ### Open DB Connection
        ###--------------------------
        $Connection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
        $Connection.Open()
        $Cmd = New-Object System.Data.SqlClient.SqlCommand
        $Cmd.Connection = $Connection
#>
    }
    Process {

        ### Execute SQL Query
        ###--------------------------
        $cmd.CommandText = $Query
        try {
            #$Data = 
            $Cmd.ExecuteNonQuery() #| Out-Null
        }
        catch {
            $ErrMsg = "ERROR: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
            Write-Error -Message $ErrMsg -ErrorAction Stop ### Using Write-Error because No modules are loaded at this time.
        }

<#
        ### Execute SQL Query
        ###--------------------------
        $cmd.CommandText = $Query
        try {
            $Cmd.ExecuteNonQuery() | Out-Null
        }
        catch {
            Write-Error -Message ("ERROR EXECUTING SQL: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message) -ErrorAction Stop 
        }
#>
    }
    End {
        ### Close DB Connection
        ###--------------------------
        $Connection.Close()
        #Return $Data
    }
}