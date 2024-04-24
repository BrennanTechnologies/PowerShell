<#
.SYNOPSIS
Find Servers without Restore Points

.DESCRIPTION
Find Servers without Restore Points

.PARAMETER VeeamRestorePoints
PSObject containing Veeam Restore Points.

.EXAMPLE
Get-TargetServers -VeeamRestorePoints $VeeamRestorePoints

.INPUTS
[PSCustomObject]VeeamRestorePoints

.OUTPUTS
[PSCustomObject]$TargetServers
Server Targets for the Report.

#>

function Get-TargetServers {
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$VeeamRestorePoints
    )
    Begin {
        Write-Log -LogString "Start : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray
    }
    Process {
        ### Find Servers without Restore Points
        ###----------------------------------------------------
        try {
            $TargetServers = @()
            foreach($VeeamRestorePoint in $VeeamRestorePoints){
                ### Target GlobalSync Tag Names
                if( $VeeamRestorePoint.TagName -match "GlobalSync" ){
                    $ServerSuffix = ($VeeamRestorePoint.ServerName).Split("-")[1]
                    $GlobalSyncServers = $VeeamRestorePoints | Where-Object {$_.ServerName -like "*$ServerSuffix*"} 
                    [int]$RestorePointCount = 0
                    [int]$TagGroupCount = 0
                    Write-Host (("-" * 50) + "`r`n" + "TagGroup          : " + $ServerSuffix + "`r`n" + ("-" * 50)) -ForegroundColor Cyan
                    
                    foreach($Server in $GlobalSyncServers){
                        ### Increment Counter for each Server Tag Group in each Tag Filter
                        ### ----------------------------------------------------------------
                        $TagGroupCount++   

                        ### if Server has a Restore Point then Increment ResorePoint Counter
                        ### ----------------------------------------------------------------
                        if( $null -ne $Server.VeeamRestorePoint ){ $RestorePointCount++ }

                        if($DeveloperMode){
                            Write-Host "ServerName        : " $Server.ServerName         -ForegroundColor Magenta
                            Write-Host "TagName           : " $Server.TagName            -ForegroundColor DarkMagenta
                            Write-Host "VeeamRestorePoint : " $Server.VeeamRestorePoint  -ForegroundColor DarkMagenta
                            Write-Host "TagCategory       : " $Server.TagCategory        -ForegroundColor DarkMagenta
                            Write-Host "TagGroup          : " $ServerSuffix              -ForegroundColor DarkMagenta
                            Write-Host "vCenter           : " $Server.vCenter            -ForegroundColor DarkMagenta
                        }
                    }
                    ### Add Server to Report Object
                    ###---------------------------------------
                    if($RestorePointCount -lt 1){
                        $Object = [PSCustomObject]@{
                            TagGroup          = $serverSuffix
                            vCenter           = $server.vCenter
                            ServerName        = $server.ServerName
                            TagName           = $server.TagName
                            TagCategory       = $server.TagCategory
                            VeeamRestorePoint = $server.VeeamRestorePoint
                        }
                        $TargetServers += $Object
                        Write-Host "GlobalSync Servers Missing Restore Points:" $Server.ServerName -ForegroundColor Yellow
                        Write-Host "RestorePointCount : " $RestorePointCount -ForegroundColor Yellow
                    }
                    Write-Host "TagGroupCount     : " $TagGroupCount -ForegroundColor DarkCyan
                    Write-Host "RestorePointCount : " $RestorePointCount -ForegroundColor DarkCyan
                } 
                else {
                    $TargetServers += $VeeamRestorePoints | Where-Object { ( $null -eq $_.veeamRestorePoint ) -AND ( $_.TagName -notmatch "GlobalSync" )}
                    foreach ($Server in $TargetServers){
                        if( $null -eq $Server.VeeamRestorePoint ){
                            $Server.VeeamRestorePoint = "None"
                        }
                    }
                }
            }
        } 
        catch {
            $ErrMsg = "ERROR: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
            Write-Log -LogString $ErrMsg -LogLevel Warning -LogObject $VeeamReportLog
        }
    }
    End {
        if($DeveloperMode){Write-Log -LogString "End   : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray}

        ### Report when No Servers are Missing Restore Points.
        ###----------------------------------------------------
        if ( $null -eq $TargetServers ){
            $TargetServers = New-Object PSObject -Property @{ Message = ( "There are no servers with missing restore points." )}
            return $TargetServers
        } 
        else {
            return $TargetServers
        }
    }
}