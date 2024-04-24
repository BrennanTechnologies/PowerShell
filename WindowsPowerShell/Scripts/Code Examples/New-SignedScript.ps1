function New-SignedScript {
<#
.SYNOPSIS
Code Sign the specified script.

.DESCRIPTION
Code Sign the specified script.

.PARAMETER FilePath
A string that specifies the full path of the script to sign.

.PARAMETER CertFilePath
A string that specifies the full path of certificate to use for signing. It defaults to the Abacus Code Signing Certificate.

.PARAMETER TimeStampServer
Using the TimeStampServer parameter will allow the signed script to execute even after the Cert expires, because the Cert was valid at the time of the signing.

.EXAMPLE
New-SignedScript -FilePath $FilePath

.EXAMPLE
Optional Parameters:
New-SignedScript -FilePath $FilePath -CertFilePath $CertFilePath -TimeStampServer $TimeStampServer

.NOTES

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True,
        HelpMessage="Enter the full path and file name of the script to sign.")]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
        ,
        [Parameter(Mandatory = $False)]
        [string]$CertFilePath = "\\management.corp\shares\Kits\Certificates\CodeSigning\CodeSigningCert.pfx"
        ,
        [Parameter(Mandatory = $False)]
        [string]$TimeStampServer = 'http://timestamp.digicert.com'
    )
    Begin{
        $UserName = $env:USERNAME
        $ComputerName = $env:COMPUTERNAME
    }
    Process{
        ### Create File for the New Signed Script from the Original
        if(Test-Path -Path $FilePath){
            $SignedScript = (Split-Path -Path $FilePath -Parent) + "\" + (Split-Path -Path $FilePath -Leaf).Split(".")[0] + "-Signed." + (Split-Path -Path $FilePath -Leaf).Split(".")[1] 
            Get-Content -Path $FilePath | Set-Content -Path $SignedScript
        } 
        else {
            Write-Error -Message "File not found. $FilePath" -ErrorAction Stop
        }
        try {
            ### Sign the Script with the Code Signing Signature
            Set-AuthenticodeSignature -FilePath $SignedScript -Certificate @(Get-ChildItem -recurse Cert:\LocalMachine\TrustedPublisher -codesigning | Where-Object {$_.Subject -match "CN=Abacus Group LLC"})[0] -TimeStampServer $TimeStampServer
            ### Verify Signed Script Code Signature
            if( (Get-AuthenticodeSignature -FilePath $SignedScript).Status -eq 'Valid'){
                Write-Host "The script was successfully signed." -ForegroundColor Green
                Write-Host "Signed Script: " $SignedScript -ForegroundColor White
            } 
            else {
                Write-Warning -Message ("Error Verifying Authenticode Signature." ) -ErrorAction Stop
            }
        } 
        catch {
            Write-Warning -Message ("Error Setting Authenticode Signature. `r`n" + $global:Error[0].Exception.Message) -ErrorAction Stop
        }
    }
    End {
        ### Create a Database Record
        $Query = [string] "INSERT INTO [dbo].[ScriptSigning] `
                            ([UserName],[ComputerName],[FilePath],[SignedScript],[CertFilePath]) `
                            VALUES ('$UserName','$ComputerName','$FilePath','$SignedScript','$CertFilePath')"
        Invoke-localADODataInsert -Database "DevOps" -Query $Query
    }
}
