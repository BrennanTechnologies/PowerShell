<#
    This script will find all mailboxes with Linked Master Accounts that do not have the user’s UPN from their AD Object in the client’s domain
#>

cls

### Create Session to Import Exchange Tools
$ExchangeCAS = (HostName).split("-")[0] + "-htcas01.ecicloud.com"
### Check for Existing Session
$SessionID = Get-PSSession | where { $_.ConfigurationName -eq "Microsoft.Exchange"  -and $_.State -eq 'Opened' }

if (!$SessionID) 
{
    write-host "Creating New Session"    
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeCAS/PowerShell/ -Authentication Kerberos
    Import-PSSession $Session -AllowClobber #-ea "silentlycontinue"  
}
else
{
    write-host "Using Current Session: " $SessionId 
}

### Create &  Clear the Arrays
$ClientMailBoxes       = @()
$NoLinkedMasterAccount = @()

### Get the MailBoxes
$OU = "ecicloud.com/clients/pier88" 
#$OU = "ecicloud.com/Clients/SchoenerMgmt/Users"
$OU = "ecicloud.com/clients" 

write-host "Getting mailboxes for: " $OU -ForegroundColor Cyan
$ClientMailBoxes = Get-Mailbox -OrganizationalUnit $OU -ResultSize unlimited | Where-Object {($_.LinkedMasterAccount -notlike "NT AUTHORITY*") -AND ($_.LinkedMasterAccount -notlike "ECICLOUD\Domain Controllers")}

foreach($MailBox in $ClientMailBoxes)
{
    ### Check if a Linked Master Account exists, if it exists then lookup the users UPN in the client domain.
    if ($MailBox.LinkedMasterAccount)
    {
        write-host Getting AD User Account:`t $MailBox.LinkedMasterAccount -ForegroundColor Cyan

        $Domain    = $MailBox.LinkedMasterAccount.split("\")[0]
        $UserName  = $MailBox.LinkedMasterAccount.split("\")[1]
        
        $PDC = Get-ADDomain -Identity $Domain | Select-Object -Property PDCEmulator
        $ADAccount = Get-ADUser -Server $PDC.PDCEmulator -Identity $UserName

        

        ### Test to see if the UPN exists in the Mailbox Aliases
        if(-not($MailBox.EmailAddresses -match $ADAccount.UserPrincipalName))
        {
            ### Alert on mailbox
            $NoLinkedMasterAccount += $MailBox.LinkedMasterAccount
            write-host "There is no matching UPN associated with the mailbox for: "`t $MailBox.LinkedMasterAccount -ForegroundColor Red
        }
        else
        {
            write-host "The UPN for acccount $Username is: "`t $ADAccount.UserPrincipalName -ForegroundColor Green 
        }
    }
    else
    {
        write-host "This Mailbox Does NOT have A Linked Master Account:"`t $MailBox.DisplayName  -ForegroundColor Yellow
        Continue
    }
}

### Export the Results to Out-File
write-host "Total Mailboxes Checked: " $ClientMailBoxes.count
write-host "Mailboxes without Linked Master Accounts: "$NoLinkedMasterAccount.count

$script:ScriptPath  = split-path -parent $MyInvocation.MyCommand.Definition 
$LogFile = $ScriptPath + "\LogFile.txt"
$NoLinkedMasterAccount | out-file $LogFile -Force
