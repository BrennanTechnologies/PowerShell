
<#
.SYNOPSIS
Create an encrypted a password for use in PowerShell scripts.

.DESCRIPTION
Create an encrypted a password for use in PowerShell scripts.

.PARAMETER KeyFolder
The output folder for the new key pair.

.PARAMETER PasswordFile
File name for the encrypted password file.

.PARAMETER AESKey
File name for the AES Key file.

.EXAMPLE
New-EncryptedPassword 

.EXAMPLE
Optional Parameters:
New-EncryptedPassword -KeyFolder $myFolder -PasswordFile $myPassswordFile -AESKey $myAESKey

.NOTES
Returns 0 (success) or 1 (error)
#>
function New-EncryptedPassword {
    Param(
        [Parameter(Mandatory = $False,
        HelpMessage="Enter the full destination path for the password key files.(i.e C:\Temp\)")]
        [string]
        $KeyFolder = "\\management.corp\shares\Kits\AESKeys"
        ,
        [Parameter(Mandatory = $False,
        HelpMessage="Enter only the password file name.(i.e myPassword.txt)")]
        [string]
        $PasswordFile = "Password.txt"
        ,
        [Parameter(Mandatory = $False,
        HelpMessage="Enter only the AESKey file name.(i.e myAESKey.txt)")]
        [string]
        $AESKey = "AES.key"
        ,
        [Parameter(Mandatory = $False)]
        [switch]
        $FullCredentials
    )
    Process {
        #########################################################
        ### Password Encryption Using 256-bit AES Encryption Key
        #########################################################

        ### Create Key Files
        $KeyFolder    = ($KeyFolder + "\" + (Get-Date -Format "MM-dd-yyyy.HH-mm-ss"))
        New-Item -Path ($KeyFolder + "\" + $KeyData) -ItemType Directory -Force | Out-Null
        $PasswordFile = $KeyFolder + "\" + $PasswordFile
        $AESKey       = $KeyFolder + "\" + $AESKey

        ### Generate 256-bit AES Key
        $Key = New-Object Byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
        New-Item -Path $AESKey -Force | Out-Null
        $Key | Out-File $AESKey -Force

        if($FullCredentials -eq $True){
            ### Create Password File with Full Credentials
            Write-Host "Encrypting Full Credentials."  -ForegroundColor Cyan
            try {
                (Get-Credential).Password | ConvertFrom-SecureString -Key (Get-Content $AESKey) | Set-Content -Path $PasswordFile -ErrorAction Stop
            } 
            catch {
                Write-Warning -Message ("Error Creating Encypted Password File. `r`n" + $global:Error[0].Exception.Message) -ErrorAction Stop
            }
        }
        else {
            ### Create Password File with Password Only
            Write-Host "Encrypting Password Only."  -ForegroundColor Cyan
            try {
                $Password = Read-Host -Prompt 'Enter Password to Encrypt ' -AsSecureString
                $Password | ConvertFrom-SecureString -Key (Get-Content $AESKey) | Set-Content -Path $PasswordFile -ErrorAction Stop
            } 
            catch {
                Write-Warning -Message ("Error Creating Encypted Password File. `r`n" + $global:Error[0].Exception.Message) -ErrorAction Stop
            }
        }
        Write-Host "The Encrypted Password Key Pair was created in the folder:`r`n $KeyFolder " -ForegroundColor Green
        Write-Host "PasswordFile : " $PasswordFile -ForegroundColor White
        Write-Host "AESKey       : " $AESKey -ForegroundColor White
    }
}
