cls

import-module ActiveDirectory
$Report = @()

$Domains += "risk-strategies.com"
$Domains += "dewittstern.com"


foreach ($Domain in $Domains)
{

    write-host "Getting OU's for domain: $Domain" -foregroundcolor yellow
    $OUs =  Get-ADOrganizationalUnit -Filter * -Properties * #-SearchBase $Domain -SearchScope Subtree 
    
    foreach ($OU in $OUs)
    {
        Get-ADComputer -Filter * -Properties * -SearchBase $OU -SearchScope SubTree

    }
}

exit



CanonicalName
Description
DisplayName
DistinguishedName
DNSHostName

IPv4Address

OperatingSystem

whenChanged
whenCreated
