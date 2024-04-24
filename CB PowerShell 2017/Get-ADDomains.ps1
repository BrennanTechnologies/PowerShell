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
        write-host "OU: $OU.name" -foregroundcolor cyan
        $Users =  Get-ADUser -SearchBase $OU -SearchScope Subtree -Properties * -Filter *
        
        foreach($User in $Users)
        {
            ############################
            # Convert LastLogonTime
            ############################
            
            if ($user.lastlogontimestamp -gt 0)
            {
                $userdatetime = $user.lastlogontimestamp
                $usertime = [datetime]::FromFileTime($userdatetime) 
            }
            else 
            {
                $usertime = "<Never>"
            }

            write-host $User.name

            $PSObject = New-Object PSObject
            $PSObject | Add-Member -type NoteProperty -name Domain -value $Domain.name
            $PSObject | Add-Member -type NoteProperty -name OU -value $ou.name
            $PSObject | Add-Member -type NoteProperty -name SamAccountName -value $user.samAccountName
            $PSObject | Add-Member -type NoteProperty -name distinguishedName -value $user.distinguishedName
            $PSObject | Add-Member -type NoteProperty -name whenCreated -value $user.whenCreated
            $PSObject | Add-Member -type NoteProperty -name lastLogonTimestamp -value $user.userTime
            $PSObject | Add-Member -type NoteProperty -name logonCount -value $user.logonCount
            $PSObject | Add-Member -type NoteProperty -name Enabled -value $user.Enabled
            $PSObject | Add-Member -type NoteProperty -name userAccountControl -value $user.userAccountControl

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