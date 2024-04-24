<#
.SYNOPSIS
Imports the specified PFX File (Certificate & Key).

.DESCRIPTION
Imports the specified PFX File (Certificate & Key).

.PARAMETER CertFilePath
Path to the PFX Certificate File

.PARAMETER CertStoreLocation
Cert Store Location

.PARAMETER Password
Password as a Secure String
Setting [System.Security.SecureString] and (Mandatory = $True) will automatically prompt for password

.EXAMPLE
Import-ABAPfxCertificate 

.EXAMPLE
Import-ABAPfxCertificate -CertFilePath '\\management.corp\shares\Kits\Certificates\CodeSigning\CodeSigningCert.pfx' -CertStoreLocation = 'Cert\localmachine\TrustedPublisher\'

.NOTES
    - Importing a PFX Cert to 'Cert\localmachine\TrustedPublisher\' requires admin premissions.
    - This function will self elevate its privlidges if not already running as Administrator.
    - Parameters, including the Secure Password, are passed to a new process though a script block.
#>
function Import-ABAPfxCertificate {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [string]$CertFilePath = '\\management.corp\shares\Kits\Certificates\CodeSigning\CodeSigningCert.pfx'
        ,
        [Parameter(Mandatory = $False)]
        [string]$CertStoreLocation = 'Cert:\localmachine\TrustedPublisher\'
        ,
        [Parameter(Mandatory = $False)]
        [string]$CertThumbprint = '852909CCF83A2037BB1ED408B175529AE1E2662D'
        ,
        [Parameter(Mandatory = $True)]
        [System.Security.SecureString]
        $Password
    )
    Process{
        ### Pass the Secure Password to the ScriptBlock
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        $ParamPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        $Params = @{
            "#CertFilePath#"      = $CertFilePath
            "#CertStoreLocation#" = $CertStoreLocation
            "#ParamPassword#"     = $ParamPassword
        }
        ### ScriptBlock to Invoke w/ Elevated Privledges (runs in a new process)
        $ScriptBlock = {
            $CertFilePath      = '#CertFilePath#'
            $CertStoreLocation = '#CertStoreLocation#'
            $ParamPassword     = '#ParamPassword#'
            
            ### Import the PFX Cert
            $Password = ConvertTo-SecureString -String $ParamPassword -AsPlainText -Force
            try {
                Import-PfxCertificate -FilePath $CertFilePath -CertStoreLocation $CertStoreLocation -Password $Password
            } 
            catch {
                Write-Warning -Message ("Error Importing PFX Certificate. `r`n" + $global:Error[0].Exception.Message) -ErrorAction Stop
            }
        }
        ### Replace Parameters in ScriptBlock with #LiteralValues# 
        foreach ($Param in $Params.GetEnumerator()) {
            $ScriptBlock =  $ScriptBlock -replace $Param.Key,$Param.Value
        }
        ### Elevate the Script to Admin Level Privlidges in order to Import the Cert to "Trusted Publishers"
        if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')){
            try {
                ### Invoke ScriptBlock w/ Elevated Privledges
                Write-Host "Elevating Privledges" -ForegroundColor Yellow
                Start-Process -FilePath C:\Windows\System32\WindowsPowerShell\v1.0\PowerShell.exe -Verb Runas -ArgumentList "-NoExit", "-NoProfile", "-Command &{$ScriptBlock}"
            } 
            catch {
                Write-Warning -Message ("Error Elevating New Process. `r`n" + $global:Error[0].Exception.Message) -ErrorAction Stop
            }
        } 
        else {
            ### Elevation Not Required; Aleady Running as Admin
            Write-Host "Already Running with Elevated Privledges" -ForegroundColor Yellow
            $scriptBlock = [Scriptblock]::Create($ScriptBlock)
            Invoke-Command -ScriptBlock $ScriptBlock
        }
        ### Verify Certificate Store
        ###---------------------------------------
        $ABAPfxCert = (Get-ChildItem $CertStoreLocation -codesigning | Select-Object -Property * | Where-Object {$_.Thumbprint -eq $CertThumbprint})
        if($null -ne $ABAPfxCert){
            Write-Host "The Abacus Code Signing Cert is present on this computer." -ForegroundColor Green
        } 
        else {
            Write-Warning -Message "Error Finding Abacus CodeSigning Cert on this computer. `r`n" -ErrorAction Stop
        }
    }
}