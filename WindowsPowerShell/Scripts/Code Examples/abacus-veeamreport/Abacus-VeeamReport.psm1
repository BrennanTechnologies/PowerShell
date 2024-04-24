
#Get public and private function definition files.
$PublicPath = "$PSScriptRoot\Public\*.ps1"
$PrivatePath = "$PSScriptRoot\Private\*.ps1"


# Check & Import Public
if (   $true -eq [Boolean]$(Test-Path -Path $PublicPath -ErrorAction SilentlyContinue)   ){
    [Array]$Public  = $(Get-ChildItem -Path $PublicPath -ErrorAction SilentlyContinue)
    if ($Null -ne $Public){
        foreach($Import in $Public | Sort-Object -Descending -Property Name){
            try
            {
                . $Import.FullName #| Out-Null
            }
            catch {
                Write-Warning -Message "(Public Import): Failed to import function $($Import.Fullname): $_"
            }
        }
    }
    Export-ModuleMember -Function $Public.Basename -Alias *
}

# Check & Import Private
if (   $true -eq [Boolean]$(Test-Path -Path $PrivatePath -ErrorAction SilentlyContinue)   ){
    [Array]$Private = $(Get-ChildItem -Path $PrivatePath -ErrorAction SilentlyContinue)
    if ($Null -ne $Private){
        foreach($Import in $Private){
            try
            {
                . $Import.FullName | Out-Null
            }
            catch {
                Write-Warning -Message "(Private Import): Failed to import function $($Import.Fullname): $_"
            }
        }
    }
}

try {
    $script_name = "Abacus-VeeamReport"
    $logname = "Abacus-VeeamReport.log"
    $audit_logroot = "\\service02.corp\DFS\SHARES\PSAuditLogs\"
    $log_logroot = "C:\PSlogs"

    $audit_logpath = Join-Path $(Join-Path $audit_logRoot $script_name) $logname
    $log_logpath = Join-Path $(Join-Path $log_logroot $script_name) $logname

    $VeeamReportLog = Start-Log -LogPath $log_logpath -ScriptName $script_name -Audit True -AuditLogPath $audit_logpath -Global False
}
catch {
    Throw "Failed to initiate log $($PortalLogObject | Out-String) `n($_.exception)"
}