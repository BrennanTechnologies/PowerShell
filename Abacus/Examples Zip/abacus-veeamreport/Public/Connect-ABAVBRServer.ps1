<#
.SYNOPSIS
Connect to Veeam Backup & Restore Server.

.DESCRIPTION
Connect to Veeam Backup & Restore Server.

.PARAMETER Credentials
PSCredentials object to connect to Veeam Backup & Restore Server.

.PARAMETER VBRServer
Veeam Backup & Restore Server connection name.

.PARAMETER ServiceAccount
Service Account to connect to Veeam Backup & Restore Server.

.EXAMPLE
Connect-ABAVBRServer -VBRServer $vBRServer -SerivceAccount $svcAccount

#>

function Connect-ABAVBRServer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [PSCredential]$Credentials
        ,
        [Parameter(Mandatory = $false)]
        [string]$VBRServer = "nymgmt-vem01.management.corp"
        ,
        [Parameter(Mandatory = $false)]
        [string]$ServiceAccount = "srv-devopsveeam"
    )
    Begin {
        Write-Log -LogString "Start : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray
        
        if($null -eq $Credentials){
            ### Get Credentials from Secret Server
            ###---------------------------------------------
            [PSCredential]$Credentials = Get-Secret -SecretName $ServiceAccount | Convert-secretToKerb -domain Management -prefix
        }
    }
    Process {
        if ( [bool](Get-VBRServerSession) -eq $true){ 
            Disconnect-VBRServer
        }
        try {
            ### Connect-VBRServer
            ###---------------------------------------------
            Connect-VBRServer -Server $VBRServer -Credential $Credentials
            Write-Host ("Connected to Veeam VBR Server: " + $(Get-VBRServerSession).Server)  -ForegroundColor Green
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
    End {
        if($DeveloperMode){Write-Log -LogString "End   : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray}
    }
}