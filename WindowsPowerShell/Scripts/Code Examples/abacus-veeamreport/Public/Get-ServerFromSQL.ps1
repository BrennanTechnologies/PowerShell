<#
.SYNOPSIS
Executes a SQL query that gets Server Records from SQL.

.DESCRIPTION
Executes a SQL query that gets Server Records from SQL.

.PARAMETER ServerName
Name of the server to retrieve.

.EXAMPLE
Get-ServerFromSQL -ServerName $TargetServer.ServerName

.OUTPUTS
[PSCustomObject]$ServerRecord
This object contains all the server record properties from the SQL table.

#>
function Get-ServerFromSQL {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName
    )
    Begin {
        Write-Log -LogString "Start : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray
    }
    Process {
        ### Database Variables
        ###-----------------------------------------
        $Database = "DevOps"
        $Table    = "VeeamReportServers"

        ### Build SQL Query
        ###-----------------------------------------
        $Query = " SELECT * FROM [dbo].[$Table] WHERE Servername = '$ServerName' "

        ### Exececute SQL Command
        ###-----------------------------------------
        try {
            [PSCustomObject]$ServerRecord = Invoke-ADOcmd -ServerInstance $ServerInstance -Database $Database -Query $Query
            if($DeveloperMode){
                Write-Host "ServerRecord:" $ServerRecord.ServerName -ForegroundColor Cyan
            }
        } 
        catch {
            $ErrMsg = "ERROR: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
            Write-Log -LogString $ErrMsg -LogLevel Warning -LogObject $VeeamReportLog
        }
        return $ServerRecord
    }
    End {
        if($DeveloperMode){Write-Log -LogString "End   : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray}
    }
}