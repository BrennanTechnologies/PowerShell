 <#
.SYNOPSIS
Get all restore points from Veeam and match with VM names.

.DESCRIPTION
Get all restore points from Veeam and match with VM names.

.PARAMETER ServerTags
[PSCustomObject] -- Servers Names and Server Tags from VMWare.

.PARAMETER AllRestorePoints
[switch - Gets all Restore Points for each server.

.EXAMPLE
Get-VeeamRestorePoints -serverTags $ServerTags

.INPUTS
[PSCustomObject]$serverTags

.OUTPUTS
[PSCustomObject]$VeeamRestorePoints

#>

function Get-VeeamRestorePoints {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ServerTags
        ,
        [Parameter(Mandatory = $false)]
        [switch]$AllRestorePoints
    )
    Begin {
        Write-Log -LogString "Start : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray
    }
    Process 
    {
        try {
            if( $AllRestorePoints -eq $true ){
                ### Get All Restore Points per Server
                ###-----------------------------------
                foreach($Server in $ServerTags){
                    $RestorePoint = Get-VBRRestorePoint -Name $server.ServerName | Select-Object -Property Name,CreationTime | Sort-Object CreationTime -Descending | Select-Object -First 1
                    if($DeveloperMode){
                        Write-Host "ServerName       : " $Server.ServerName         -ForegroundColor Magenta
                        Write-Host "RestorePointName : " $RestorePoint.Name         -ForegroundColor DarkCyan
                        Write-Host "RestorePointDate : " $RestorePoint.CreationTime -ForegroundColor DarkCyan
                    }

                    $Server | Add-Member -MemberType NoteProperty -Name RestorePointName -Value "" -Force
                    $Server | Add-Member -MemberType NoteProperty -Name RestorePointDate -Value "" -Force
                    
                    $Server.RestorePointName = $RestorePoint.Name
                    $Server.RestorePointDate = $RestorePoint.CreationTime
                }
                $VeeamRestorePoints = $ServerTags
            }
            ### Get Veeam Restore Points
            ###-----------------------------------
            $RestorePoints = (Get-VBRRestorePoint).Name | Select-Object -Unique
            $VeeamRestorePoints = $ServerTags 
            $VeeamRestorePoints | Add-Member -MemberType NoteProperty -Name VeeamRestorePoint -Value "" -Force
            foreach ($Server in $VeeamRestorePoints){
                $Server.VeeamRestorePoint = $($RestorePoints -match $Server.ServerName)
            }
        } 
        catch {
            $ErrMsg = "ERROR: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
            Write-Log -LogString $ErrMsg -LogLevel Warning -LogObject $VeeamReportLog
        }
    }
    End {
        if($DeveloperMode){Write-Log -LogString "End   : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray}
        return $VeeamRestorePoints
    }
}