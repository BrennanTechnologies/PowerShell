cls


###### Regeneron Disabled Accounts

### Import the ActiveDirectory module
Import-Module -Name ActiveDirectory
$Report = @()

#$OU = "DC=regeneron,DC=regn,DC=com"
#$OU = "DC=regn,DC=com"
#$OU = "OU=Tarrytown,OU=Regeneron Users,DC=regeneron,DC=regn,DC=com"
#$OU = "OU=Regeneron Users,DC=regeneron,DC=regn,DC=com"

$OUs =  Get-ADOrganizationalUnit -SearchBase "DC=regeneron,DC=regn,DC=com" -SearchScope Subtree -Filter * -Properties *
#$OUs =  Get-ADOrganizationalUnit -SearchBase "OU=Regeneron Disabled Accounts,DC=regeneron,DC=regn,DC=com","OU=Regeneron Disabled Accounts,DC=regeneron,DC=regn,DC=com" -SearchScope Base -Filter * -Properties *

foreach ($OU in $Ous)
{


    write-host $ou.Name

    #$Users =  Get-ADUser -SearchBase $OU -SearchScope "Subtree" -Properties * -Filter *
    $Users =  Get-ADUser -SearchBase $OU -SearchScope Subtree -Properties * -Filter *

    Foreach ($User in $Users) 
    { 
        
        write-host "OU:  "    $OU.name
        write-host "SAM:  "    $user.sAMAccountName
        write-host "CN: "      $user.distinguishedName
        write-host "Mail: "    $user.mail
        write-host "Manager: " $user.manager
        write-host "ExpDate: " $user.AccountExpirationDate
        write-host "Enabled: " $user.Enabled
        write-host "Enabled: " $user.lastLogonTimestamp
        write-host ""

        $PSObject = New-Object PSObject
        $PSObject | Add-Member -type NoteProperty -name OU -value $ou.name
        $PSObject | Add-Member -type NoteProperty -name SamAccountName -value $user.samAccountName
        $PSObject | Add-Member -type NoteProperty -name distinguishedName -value $user.distinguishedName
        $PSObject | Add-Member -type NoteProperty -name Mail -value $user.mail
        $PSObject | Add-Member -type NoteProperty -name AccountExpirationDate -value $user.AccountExpirationDate
        $PSObject | Add-Member -type NoteProperty -name Enabled -value $user.Enabled
        $PSObject | Add-Member -type NoteProperty -name lastLogonTimestamp -value $user.lastLogonTimestamp

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
        #$PSObject | Add-Member -type NoteProperty -name userAccountControl -value $user.userAccountControl
        $Report += $PSObject 
    }
}


#Export & Show the File
$Path = "c:\logs\"
$ReportDate = Get-Date -Format ddmmyyyy
$ReportFile = $Path + "\Report_$reportdate.txt"

$Report | Export-Csv -Path $ReportFile -NoTypeInformation 
start-process $ReportFile





   $hash = @{            
        LineNumber       = $LineNumber                 
        Date             = $TodayDate              
        ServerName       = $svr            
        DatabaseName     = $Database            
        UserName         = $user.name            
        CreateDate       = $CreateDate            
        DateLastModified = $DateLastModified            
        AsymMetricKey    = $user.AsymMetricKey            
        DefaultSchema    = $user.DefaultSchema            
        HasDBAccess      = $user.HasDBAccess            
        ID               = $user.ID            
        LoginType        = $user.LoginType            
        Login            = $user.Login            
        Orphan           = ($user.Login -eq "")            
    }                           
                                    
    $Object = New-Object PSObject -Property $hash


