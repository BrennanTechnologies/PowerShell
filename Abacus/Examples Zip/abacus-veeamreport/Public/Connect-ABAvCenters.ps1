```````````<#
.SYNOPSIS
Connect to VMWare vCenters.

.DESCRIPTION
Connect to VMWare vCenters.

.PARAMETER Credentials
PSCredentials object to connect to Veeam Backup & Restore Server.

.PARAMETER ABAvCenters
[array] of vCenters to connect.

.PARAMETER ServiceAccount
Service Account to connect to vCenter.

.EXAMPLE
Connect-ABAVCenters @vCenters -SerivceAccount $svcAccount

#>

function Connect-ABAvCenters {
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory = $false)]
        [PSCredential]$Credentials
        ,
        [Parameter(Mandatory = $false)]
        [string]$ServiceAccount = "srv-devopsveeam"
        ,
        [Parameter(Mandatory = $false)]
        [array]$ABAvCenters =  @(
            "nymgmtvc01.management.corp1",
            "sfmgmtvc01.management.corp",
            "l1mgmtvc01.management.corp",
            "txmgmtvc01.management.corp",
            "l2mgmtvc01.management.corp"
        )
    )

    Begin {
        Write-Log -LogString "Start: $((Get-PSCallStack)[0].Command) ... " -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkMagenta

        ### Get Credentials from Secret Server
        ###---------------------------------------------
        [PSCredential]$Credentials = Get-Secret -SecretName $ServiceAccount | Convert-secretToKerb -domain Management -prefix
    }

    Process {
        ### Set WebOperationTimeoutSeconds value.
        ###---------------------------------------------
        Set-PowerCLIConfiguration -WebOperationTimeoutSeconds 180 -DefaultVIServerMode Multiple -Scope Session -InvalidCertificateAction Ignore -DisplayDeprecationWarnings $false -Confirm:$false | Out-Null

        ### Connect to VIServers
        ###---------------------------------------------
        foreach ($vCenter in $ABAvCenters){
            try {
                Connect-VIServer -Server $vCenter -Credential $Credentials -ErrorAction Stop
                Write-Log -LogString ("Connected to vCenter: " + $vCenter) -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor Magenta
            } 
            catch {
                ### Send Alert
                ###---------------------------------------------
                $ErrMsg = "ERROR: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
                Write-Log -LogString $ErrMsg -LogLevel Warning -LogObject $VeeamReportLog
                Send-Alert -Message $ErrMsg -Script $((Get-PSCallStack)[-1].Command) -Function $((Get-PSCallStack)[0].Command)
                Exit
            }
        }
        ### Verify vCenter Connections
        ###---------------------------------------------
        foreach ($vCenter in $ABAvCenters){
            if (($global:defaultviservers).Name -contains $vCenter){
                Write-Log -LogString ("Verified vCenter Connection: " + $vCenter) -LogLevel Output -LogObject $VeeamReportLog  -ForegroundColor DarkMagenta
            } 
            else {
                ### Send Alert
                ###---------------------------------------------
                Write-Error -Message ("vCenter Not Connected: " + $vCenter)
                $ErrMsg = "ERROR: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
                Write-Log -LogString $ErrMsg -LogLevel Warning -LogObject $VeeamReportLog
                Send-Alert -Message $ErrMsg -Script $((Get-PSCallStack)[-1].Command) -Function $((Get-PSCallStack)[0].Command)
                Exit
            }
        }
    }
    End {
        Write-Log -LogString "End: $((Get-PSCallStack)[0].Command) ... " -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkMagenta
    }
}
