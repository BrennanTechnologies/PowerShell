cls

import-module ActiveDirectory
$Report = @()

$Domains = @()
$Domains += "risk-strategies.com"
$Domains += "dewittstern.com"

foreach ($Domain in $Domains)
{
    write-host "Getting users for domain: $Domain" -foregroundcolor yellow
    $OUs =  Get-ADOrganizationalUnit -Filter * -Properties * #-SearchBase $Domain -SearchScope Subtree 
    
    foreach ($OU in $OUs)

    {
        #$Created = Get-Date
        #$Created = $Created.AddDays(-90)
        #(Get-Date).AddDays(-90)

        write-host "OU: $OU.name" -foregroundcolor cyan
        $Users =  Get-ADUser -SearchBase $OU -SearchScope Subtree -Properties * -Filter *  | Where-Object {$_.whenCreated -gt (Get-Date).AddDays(-90)} 
        
        foreach($User in $Users)
        {
            ############################
            # Convert LastLogonTime
            ############################
            
            if ($user.lastlogontimestamp -gt 0)
            {
                $logindatetime = $user.lastlogontimestamp
                $lastlogintime = [datetime]::FromFileTime($logindatetime) 
            }
            else 
            {
                $usertime = "<Never>"
            }
            
            write-host $User.name
            $PSObject = New-Object PSObject
            $PSObject | Add-Member -type NoteProperty -name Domain -value $Domain
            $PSObject | Add-Member -type NoteProperty -name OU -value $ou.name
            $PSObject | Add-Member -type NoteProperty -name SamAccountName -value $user.samAccountName
            $PSObject | Add-Member -type NoteProperty -name DisplayName -value $user.DisplayName
            $PSObject | Add-Member -type NoteProperty -name distinguishedName -value $user.distinguishedName
            $PSObject | Add-Member -type NoteProperty -name Enabled -value $user.Enabled
            $PSObject | Add-Member -type NoteProperty -name userAccountControl -value $user.userAccountControl
            $PSObject | Add-Member -type NoteProperty -name whenCreated -value $user.whenCreated
            $PSObject | Add-Member -type NoteProperty -name createTimeStamp -value $user.createTimeStamp
            $PSObject | Add-Member -type NoteProperty -name lastLogonTimestamp -value $lastlogintime
            $Report += $PSObject 

        }
    }
}

#Export & Show the File
$Path = "c:\reports\"
$ReportDate = Get-Date -Format ddmmyyyy
$ReportFile = $Path + "\Report_$reportdate.txt"

$Report | Export-Csv -Path $ReportFile -NoTypeInformation 
start-process $ReportFile


<#
### USER ACCOUNT CONTROL

Property Flag	Value In Decimal
SCRIPT	1
ACCOUNTDISABLE	2
HOMEDIR_REQUIRED	8
LOCKOUT	16
PASSWD_NOTREQD	32
PASSWD_CANT_CHANGE	64
ENCRYPTED_TEXT_PWD_ALLOWED	128
TEMP_DUPLICATE_ACCOUNT	256
NORMAL_ACCOUNT	512
Disabled Account	514
Enabled, Password Not Required	544
Disabled, Password Not Required	546
INTERDOMAIN_TRUST_ACCOUNT	2048
WORKSTATION_TRUST_ACCOUNT	4096
SERVER_TRUST_ACCOUNT	8192
DONT_EXPIRE_PASSWORD	65536
Enabled, Password Doesn’t Expire	66048
Disabled, Password Doesn’t Expire	66050
Disabled, Password Doesn’t Expire & Not Required	66082
MNS_LOGON_ACCOUNT	131072
SMARTCARD_REQUIRED	262144
Enabled, Smartcard Required	262656
Disabled, Smartcard Required	262658
Disabled, Smartcard Required, Password Not Required	262690
Disabled, Smartcard Required, Password Doesn’t Expire	328194
Disabled, Smartcard Required, Password Doesn’t Expire & Not Required	328226
TRUSTED_FOR_DELEGATION	524288
Domain controller	532480
NOT_DELEGATED	1048576
USE_DES_KEY_ONLY	2097152
DONT_REQ_PREAUTH	4194304
PASSWORD_EXPIRED	8388608
TRUSTED_TO_AUTH_FOR_DELEGATION	16777216
PARTIAL_SECRETS_ACCOUNT	67108864

#>