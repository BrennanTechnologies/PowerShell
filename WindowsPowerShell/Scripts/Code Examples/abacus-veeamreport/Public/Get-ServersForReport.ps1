<#
.SYNOPSIS
Compares the Target Servers Date in SQL to filter out any servers until they are at least 5 days old.

.DESCRIPTION
Compares the Target Servers Date in SQL to filter out any servers until they are at least 5 days old.

.PARAMETER TargetServers
Target Server object.

.PARAMETER ServerRecordAge
# of Days until servers show up in the report.

.EXAMPLE
Get-ServersForReport -TargetServers $TargetServers -ServerRecordAge $ServerParams.ServerRecordAge

.OUTPUTS
[PSCustomObject]$Report
Object with server properties for the report.

#>
function Get-ServersForReport {
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TargetServers
        ,
        [Parameter(Mandatory = $true)]
        [int]$ServerRecordAge
    )
    Begin {
        Write-Log -LogString "Start : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray
    }
    Process {
        $Report = @()
        foreach($TargetServer in $TargetServers){
            $ServerRecord = Get-ServerFromSQL -ServerName $TargetServer.ServerName
            if($null -eq $ServerRecord){
                Write-Host "No Server Record Found. Adding Server to SQL. " $TargetServer.ServerName -ForegroundColor Yellow
                ### Write Server Record to SQL
                ###-------------------------------
                Write-ServerToSQL -TargetServer $TargetServer
            }
            if($null -ne $ServerRecord){
                Write-Host "Server Record Found: " $ServerRecord.ServerName -ForegroundColor Yellow
                ### Check Server FirstSeen Date
                ###-------------------------------
                if($DeveloperMode){
                    Write-Host "vCenter           : " $ServerRecord.vCenter           -ForegroundColor DarkCyan
                    Write-Host "ServerName        : " $ServerRecord.ServerName        -ForegroundColor DarkCyan
                    Write-Host "TagCategory       : " $ServerRecord.TagCategory       -ForegroundColor DarkCyan
                    Write-Host "TagName           : " $ServerRecord.TagName           -ForegroundColor DarkCyan
                    Write-Host "VeeamRestorePoint : " $ServerRecord.VeeamRestorePoint -ForegroundColor DarkCyan
                    Write-Host "FirstSeen         : " $ServerRecord.FirstSeen         -ForegroundColor DarkCyan
                }
                ### Get Server Record Date from SQL
                ### ----------------------------------------------------
                [datetime]$FirstSeen = $ServerRecord.FirstSeen

                ### Only Report Servers Older than 5 Days
                ### ----------------------------------------------------
                if( $FirstSeen -lt (Get-Date).AddDays( -($ServerRecordAge) )){
                    if($DeveloperMode){
                        Write-Host "SERVER EXISTS :  Server is GREATER than $ServerAge days old. Adding to Report." -ForegroundColor Yellow
                        Write-Host "FirstSeen     : " $FirstSeen -ForegroundColor DarkYellow
                        Write-Host "ServerName    : " $ServerRecord.ServerName -ForegroundColor DarkYellow
                    }
                    $Object = [PSCustomObject]@{
                        vCenter           = $ServerRecord.vCenter
                        ServerName        = $ServerRecord.ServerName
                        TagCategory       = $ServerRecord.TagCategory
                        TagName           = $ServerRecord.TagName
                        VeeamRestorePoint = $ServerRecord.VeeamRestorePoint
                        FirstSeen         = $(Get-Date $($ServerRecord.FirstSeen) -Format "MM-dd-yyyy")
                    }
                    $Report += $Object
                }
                elseif( $FirstSeen -gt (Get-Date).AddDays( -($ServerAge) )){
                    if($DeveloperMode){
                        Write-Host "SERVER EXISTS :  Server is LESS than $ServerAge days old. Not Adding to Report." -ForegroundColor Yellow
                        Write-Host "ServerName    : " $ServerRecord.ServerName -ForegroundColor DarkYellow
                        Write-Host "FirstSeen     : " $ServerRecord.FirstSeen  -ForegroundColor DarkYellow
                    }
                }
            }
        }
    }
    End {
        if( (($Report | Measure-Object).Count) -lt 1 ){
            $Report = New-Object PSObject -Property @{ Message = ( "No Servers Found." )}
        }
        Write-Host "Report: " $Report.Message -ForegroundColor Magenta
        if($DeveloperMode){Write-Log -LogString "End   : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray}
        return $Report
    }
}