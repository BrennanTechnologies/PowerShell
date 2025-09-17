function Invoke-ADOcmd {
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
        ,
        [Parameter(Mandatory = $False)]
        [switch]$Quiet
        )
    Begin {    
        ### Create Database Connection String
        ###----------------------------------
        $ConnectionString = "Data Source=$ServerInstance;Initial Catalog=$Database;Integrated Security=true;"
        ### Open DB Connection
        ###----------------------------------
        $Connection = New-Object System.Data.SqlClient.SqlConnection
        $Connection.ConnectionString = $ConnectionString
        $Connection.Open()
        ### SQL Command
        ###----------------------------------
        $SQLCommand = New-Object System.Data.SqlClient.SqlCommand
        $SQLCommand.Connection = $Connection
        $SQLCommand.CommandText = $Query
        # Create Exit Code Object 
        ###----------------------------------
        $ExitCode = New-Object PSObject -Property @{Status = ""}
        # Set Query Type
        ###----------------------------------
        if(($Query.ToUpper()).Contains("SELECT")){
            $DateReader = $True
        }
        else{
            $DateReader = $False
        }
    }
    Process {
        if($DateReader){
            ### Execute the SQL Query
            ###----------------------------------
            try {
                $DataReader = $SQLCommand.ExecuteReader()
                $DataTable = New-Object 'System.Data.DataTable'
                $DataTable.Load($DataReader)
                $Status.ExitCode = $True
            } catch {
                Write-Warning -Message ("ERROR EXECUTING SQL: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message) 
                $Status.ExitCode = $False
            }
            return $DataTable
        }
        else {
            ### Execute the SQL Query
            ###----------------------------------
            try {
                $SQLCommand.ExecuteNonQuery() | Out-Null
                $Status.ExitCode = $True
            } catch {
                Write-Warning -Message ("ERROR EXECUTING SQL: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message) 
                $Status.ExitCode = $False
            }
            if(-Not $Quiet){
                return $ExitCode
            }
        }
    }
    End {
        ### Close DB Connection
        ###----------------------------------
        $Connection.Close()
        if(-Not $Quiet){
            Write-Host "Data Connection Closed: " $Connection.Database
        }
    }
}
