<#
.SYNOPSIS
This function was used to load the initial SQL table.

.DESCRIPTION
This function was used to load the initial SQL table.

.PARAMETER Report
Initial Report of Servers without Veeam Restore Points.

.EXAMPLE
Write-ReportToSQL -Report $Report

.OUTPUTS
[PSCustomObject]$Report
All server object from initial report.

.OUTPUTS
None.

#>
function Write-ReportToSQL {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Report
    )

    ###--------------------------------
    ### Write Server Request to SQL
    ###--------------------------------

    Begin {
        Write-Log -LogString "Start : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray

        ### Database Variables
        ###--------------------------
        $Database         = "DevOps"
        $Table            = "VeeamReport"
    }

    Process {
        foreach($Row in $Report){
            $vCenter           = $Row.vCenter
            $ServerName        = $Row.ServerName
            $TagCategory       = $Row.TagCategory
            $TagName           = $Row.TagName
            $VeeamRestorePoint = $Row.VeeamRestorePoint
            $InitDate          = (Get-Date)

            Write-Host "Database          : " $Database          -ForegroundColor Cyan
            Write-Host "Table             : " $Table             -ForegroundColor Cyan
            Write-Host "vCenter           : " $vCenter           -ForegroundColor Cyan
            Write-Host "ServerName        : " $ServerName        -ForegroundColor Cyan
            Write-Host "TagCategory       : " $TagCategory       -ForegroundColor Cyan
            Write-Host "TagName           : " $TagName           -ForegroundColor Cyan
            Write-Host "VeeamRestorePoint : " $VeeamRestorePoint -ForegroundColor Cyan
            Write-Host "InitDate          : " $InitDate          -ForegroundColor Cyan

            ### Build SQL Query
            ###--------------------------
            $InsertQuery = [string]" 
            INSERT INTO [dbo].[$Table] 
                    (
                        [vCenter],
                        [ServerName],
                        [TagCategory],
                        [TagName],
                        [VeeamRestorePoint],
                        [InitDate]
                        ) 
                VALUES 
                    (
                        '$vCenter',
                        '$ServerName',
                        '$TagCategory',
                        '$TagName',
                        '$VeeamRestorePoint',
                        '$InitDate'
                        )" 

            ### Exececute SQL Command
            ###--------------------------
            try {
                Invoke-SQLcmd -ServerInstance $ServerInstance -Database $Database -query $InsertQuery
            }
            catch {
                $ErrMsg = "ERROR: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
                Write-Log -LogString $ErrMsg -LogLevel Warning -LogObject $VeeamReportLog
            }
        }
    }
    End {
        Write-Log -LogString "End   : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray
    }
}