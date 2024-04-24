<#
.SYNOPSIS
Execute SQL to Insert New Servers into the database.

.DESCRIPTION
Execute SQL to Insert New Servers into the database.

.PARAMETER TargetServers
Target Server object.

.EXAMPLE
Write-ServerToSQL -TargetServer $TargetServer

.OUTPUTS
[PSCustomObject]$TargetServer
Target Server object.

#>

function Write-ServerToSQL {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$TargetServer
    )
    Begin {
        Write-Log -LogString "Start : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray

        ### Database Variables
        ###--------------------------
        $Database         = "DevOps"
        $Table            = "VeeamReportServers"
    }
    Process {
        foreach($Row in $TargetServer){
            $vCenter           = $Row.vCenter
            $ServerName        = $Row.ServerName
            $TagCategory       = $Row.TagCategory
            $TagName           = $Row.TagName
            $VeeamRestorePoint = $Row.VeeamRestorePoint
            $FirstSeen         = (Get-Date) 

            if($DeveloperMode){
                Write-Host "Database          : " $Database          -ForegroundColor DarkCyan
                Write-Host "Table             : " $Table             -ForegroundColor DarkCyan
                Write-Host "vCenter           : " $vCenter           -ForegroundColor DarkCyan
                Write-Host "ServerName        : " $ServerName        -ForegroundColor DarkCyan
                Write-Host "TagCategory       : " $TagCategory       -ForegroundColor DarkCyan
                Write-Host "TagName           : " $TagName           -ForegroundColor DarkCyan
                Write-Host "VeeamRestorePoint : " $VeeamRestorePoint -ForegroundColor DarkCyan
                Write-Host "FirstSeen         : " $FirstSeen         -ForegroundColor DarkCyan
            }

            ### Build SQL Query
            ###--------------------------
            $Query = [string]" 
            INSERT INTO [dbo].[$Table] 
                    (
                        [vCenter],
                        [ServerName],
                        [TagCategory],
                        [TagName],
                        [VeeamRestorePoint],
                        [FirstSeen]
                        ) 
                VALUES 
                    (
                        '$vCenter',
                        '$ServerName',
                        '$TagCategory',
                        '$TagName',
                        '$VeeamRestorePoint',
                        '$FirstSeen'
                        )" 

            ### Exececute SQL Command
            ###--------------------------
            try {
                Invoke-ADOcmd -ServerInstance $ServerInstance -Database $Database -Query $Query
            } 
            catch {
                $ErrMsg = "ERROR: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
                Write-Log -LogString $ErrMsg -LogLevel Warning -LogObject $VeeamReportLog
            }
        }
    }
    End {
        if($DeveloperMode){Write-Log -LogString "End   : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray}
    }
}