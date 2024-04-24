cls
$Report = @()

### Import the ActiveDirectory module
Import-Module -Name ActiveDirectory


### Import Data File
$DataFile = "C:\Users\christopher.brennon\Documents\PowerShell\Regeneron_Users.csv"
$Data = Import-CSV $DataFile
$UPNs = @()
$UPNs = $Data.Mail
#$UPNs = "Adam.Mohl@regeneron.com"
$UPNs = "SegTestAW2@regeneron.com","SegTestAW3@regeneron.com"


#$OU = "OU=Active Users,OU=Tarrytown,OU=Regeneron Users,DC=regeneron,DC=regn,DC=com"
$OU = "OU=Test,OU=Tarrytown,OU=Regeneron Users,DC=regeneron,DC=regn,DC=com"
$OU = "DC=regeneron,DC=regn,DC=com"
write-host $OU -foregroundcolor cyan

$Users = @()
#$Users = Get-ADUser -searchbase $OU -Properties * -Filter *
#$Users = Get-ADUser -searchbase $OU -Properties * -Filter 'Name -eq $Mail'
#$Users = Get-ADUser -searchbase $OU -Properties EmailAddress -Filter {UserPrincipalName -like $Mail}

foreach ($UPN in $UPNs)
{
    $upn
    $Users = Get-ADUser -searchbase $OU -Properties * -Filter * #{mail -like $UPN}
    $Users.count
           
    write-host $user.Name
    write-host $user.sAMAccountName
    #write-host $user.CanonicalName
    write-host $user.mail
    write-host ""
}

        <#
        foreach ($User in $Users)
        {
            #write-host $user.Name
            write-host $user.sAMAccountName
            #write-host $user.CanonicalName
            write-host $user.mail
            write-host ""

            
            $PSObject = New-Object PSObject
            $PSObject | Add-Member -type NoteProperty -name ou -value $ou
            $PSObject | Add-Member -type NoteProperty -name SSMail -value $Mail
            $PSObject | Add-Member -type NoteProperty -name cn -value $user.cn
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
            $PSObject | Add-Member -type NoteProperty -name mail -value $user.mail
            $PSObject | Add-Member -type NoteProperty -name EmailAddress -value $user.EmailAddress
            #$PSObject | Add-Member -type NoteProperty -name createTimeStamp -value $users.createTimeStamp
            #$PSObject | Add-Member -type NoteProperty -name accountExpires -value $expiretime
            $PSObject | Add-Member -type NoteProperty -name AccountExpirationDate -value $user.AccountExpirationDate
            $PSObject | Add-Member -type NoteProperty -name Enabled -value $user.Enabled
            $PSObject | Add-Member -type NoteProperty -name userAccountControl -value $user.userAccountControl
            $Report += $PSObject
            
        }
        #>
  

#Export & Show the File
$Path = "c:\logs\"
$ReportDate = Get-Date -Format ddmmyyyy
$ReportFile = $Path + "\Report_$reportdate.txt"

#$Report | Export-Csv -Path $ReportFile -NoTypeInformation 
#start-process $ReportFile

#>
