#Author: CBrennan

#Get public and private function definition files.
$PublicPath = "$PSScriptRoot\Public\*.ps1"
$PrivatePath = "$PSScriptRoot\Private\*.ps1"


# Check & Import Public
If (   $True -eq [Boolean]$(Test-Path -Path $PublicPath -ErrorAction SilentlyContinue)   ) {
    [Array]$Public  = $(Get-ChildItem -Path $PublicPath -ErrorAction SilentlyContinue)
    If ($Null -ne $Public) {
        ForEach($Import in $Public | Sort-Object -Descending -Property Name) {
            Try
            {
                . $Import.FullName #| Out-Null
            }
            Catch
            {
                Write-Warning -Message "(Public Import): Failed to import function $($Import.Fullname): $_"
            }
        }
    }
    Export-ModuleMember -Function $Public.Basename -Alias *
}

# Check & Import Private
If (   $True -eq [Boolean]$(Test-Path -Path $PrivatePath -ErrorAction SilentlyContinue)   ) {
    [Array]$Private = $(Get-ChildItem -Path $PrivatePath -ErrorAction SilentlyContinue)
    If ($Null -ne $Private) {
        ForEach($Import in $Private) {
            Try
            {
                . $Import.FullName | Out-Null
            }
            Catch
            {
                Write-Warning -Message "(Private Import): Failed to import function $($Import.Fullname): $_"
            }
        }
    }
}
<#
Try {
    $script_name = "Abacus-ScriptSigning"
    $logname = "ScriptSigning.log"
    $audit_logroot = "\\service02.corp\DFS\SHARES\PSAuditLogs\"
    $log_logroot = "C:\PSlogs"

    $audit_logpath = Join-Path $(Join-Path $audit_logRoot $script_name) $logname
    $log_logpath = Join-Path $(Join-Path $log_logroot $script_name) $logname

    Write-Host $audit_logpath
    Write-Host $log_logpath

    $ScriptSigningLog = Start-Log -LogPath $log_logpath -ScriptName $script_name -Audit True -AuditLogPath $audit_logpath -Global False
}
Catch{
    Throw "Failed to initiate log $($PortalLogObject | Out-String) `n($_.exception)"
}
#>