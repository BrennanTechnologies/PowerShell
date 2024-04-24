cls

### Import the ActiveDirectory module
Import-Module -Name ActiveDirectory


### Import Data File
$DataFile = "C:\Users\christopher.brennon\Documents\PowerShell\Regeneron_Users.csv"
$Data = Import-CSV $DataFile
$UPNs = @()
$UPNs = $Data.Mail


### AD

$OU = "DC=regeneron,DC=regn,DC=com"
$Users =  Get-ADUser -SearchBase $OU -SearchScope Subtree -Properties name -Filter * #| where {$_.mail -like $UPN}
#$Users
#$Users.count

Foreach ($User in $Users | where {$_.mail -eq $UPN})
{
            write-host "AD SAM: "$user.sAMAccountName
            write-host "AD Mail: "$user.mail

            $PSObject = New-Object PSObject
            $PSObject | Add-Member -type NoteProperty -name AD_SamAccountName -value $user.samAccountName
            $PSObject | Add-Member -type NoteProperty -name AD_CN -value $user.cn
            $PSObject | Add-Member -type NoteProperty -name AD_Mail -value $user.mail
            #$PSObject | Add-Member -type NoteProperty -name DistinguishedName -value $user.DistinguishedName
            #$PSObject | Add-Member -type NoteProperty -name CanonicalName -value $user.CanonicalName
            #$PSObject | Add-Member -type NoteProperty -name DisplayName -value $user.DisplayName
            #$PSObject | Add-Member -type NoteProperty -name Department -value $user.Department
            #$PSObject | Add-Member -type NoteProperty -name Description -value $user.Description
            #$PSObject | Add-Member -type NoteProperty -name GivenName -value $user.GivenName
            #$PSObject | Add-Member -type NoteProperty -name Surname -value $user.Surname
            #$PSObject | Add-Member -type NoteProperty -name PasswordNeverExpires -value $user.PasswordNeverExpires
            #$PSObject | Add-Member -type NoteProperty -name PasswordNotRequired -value $users.PasswordNotRequired
            #$PSObject | Add-Member -type NoteProperty -name PasswordLastSet -value $user.PasswordLastSet
            #$PSObject | Add-Member -type NoteProperty -name lastLogonTimestamp -value $userTime
            #$PSObject | Add-Member -type NoteProperty -name logonCount -value $user.logonCount
            #$PSObject | Add-Member -type NoteProperty -name ObjectClass -value $user.ObjectClass
            #$PSObject | Add-Member -type NoteProperty -name EmailAddress -value $user.EmailAddress
            #$PSObject | Add-Member -type NoteProperty -name createTimeStamp -value $users.createTimeStamp
            #$PSObject | Add-Member -type NoteProperty -name accountExpires -value $expiretime
            $PSObject | Add-Member -type NoteProperty -name AD_AccountExpirationDate -value $user.AccountExpirationDate
            $PSObject | Add-Member -type NoteProperty -name AD_Enabled -value $user.Enabled
            #$PSObject | Add-Member -type NoteProperty -name userAccountControl -value $user.userAccountControl
            $Report += $PSObject 
   

}

#Export & Show the File
$Path = "c:\logs\"
$ReportDate = Get-Date -Format ddmmyyyy
$ReportFile = $Path + "\Report_$reportdate.txt"

$Report | Export-Csv -Path $ReportFile -NoTypeInformation 
start-process $ReportFile
